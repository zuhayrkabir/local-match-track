import "dart:async";
import "dart:typed_data";

import "package:cbor/simple.dart";
import "package:meta/meta.dart";

import "../../ditto_live.dart";
import "../analysis/annotations.dart";
import "../bridge/bridge.dart" as core;

import "../ditto.dart";
import "../exception.dart";
import "execute.dart";

@internal
bool privateIsTransactionValid(Transaction txn) => txn._isValid;

/// Represents a transaction in the Ditto store.
///
/// A [Transaction] is used to group multiple operations into a single atomic
/// unit. This ensures that either all operations within the transaction are
/// applied, or none of them are, maintaining the integrity of the data.
///
/// Please consult the documentation of [Store.transaction] for more information
/// on how to create and use transactions. For a complete guide on transactions,
/// please refer to the [Ditto
/// documentation](https://ditto.com/link/sdk-latest-crud-transactions).
@external
final class Transaction {
  final core.CPPointer<core.CPTransaction> _ptr;
  final TransactionInfo _info;

  /// Set to false once the transaction has ended
  bool _isValid = true;

  Transaction._(this._ptr, this._info);

  static Future<Transaction> _begin(
    Ditto ditto, {
    required String? hint,
    required bool isReadOnly,
  }) async {
    final transactionPointerResult =
        await core.dittoffiStoreBeginTransactionAsyncThrows(
      ditto.ptr,
      hint,
      isReadOnly: isReadOnly,
    );

    final transactionPointer = transactionPointerResult.extract();

    return Transaction._(
      transactionPointer,
      TransactionInfo._(transactionPointer, hint: hint, isReadOnly: isReadOnly),
    );
  }

  /// Information about the current transaction.
  TransactionInfo get info {
    _checkValid();
    return _info;
  }

  /// Executes a DQL query and returns matching items as a [QueryResult].
  ///
  /// Note that this method only returns results from the local store without waiting for any
  /// [SyncSubscription]s to have caught up with the latest changes.
  /// Only use this method if your program must proceed with immediate results.
  /// Use a [StoreObserver] (obtained from [Store.registerObserver]) to receive updates to
  /// query results as soon as they have been synced to this peer.
  Future<QueryResult> execute(
    String query, {
    Map<String, dynamic> arguments = const {},
  }) async {
    _checkValid();

    final argsCborBytes = Uint8List.fromList(cbor.encode(arguments));

    final queryResultPtrResult = await core.dittoffiTransactionExecute(
      _ptr,
      query,
      argsCborBytes,
    );

    final queryResultPtr = queryResultPtrResult.extract();
    return privateMakeQueryResult(queryResultPtr);
  }

  Future<TransactionCompletionAction> _complete(
    TransactionCompletionAction action,
  ) async {
    _isValid = false;
    final result = await core.dittoffiTransactionComplete(_ptr, action);
    return result.extract();
  }

  /// This check is used to determine whether we are currently in a transaction scope
  ///
  /// This check, combined with a similar check in [Store.execute], will make
  /// sure that users use the correct `.execute()` when dealing with
  /// transactions (i.e. not using [Store.execute] in a transaction, or using
  /// [Transaction.execute] outside a transaction).
  ///
  /// It is implemeted using Dart's Zone API, which allows us to store a "global
  /// variable" that is tied to a particular async context. We use this to store
  /// handles to every currently in-scope transaction, and then check against
  /// this list when calling one of the `.execute()` methods
  void _checkValid() {
    if (!privateInScopeTransactions.contains(this)) {
      throw privateMakeDittoException("""
Attempting to use transaction outside transaction scope. Make sure to only use a
`Transaction` object within the scope it was created in.
""");
    }

    if (!_isValid) {
      throw privateMakeDittoException("""
Transaction is no longer valid. Do not store the transaction object outside the
transaction callback""");
    }
  }
}

/// Encapsulates information about a transaction.
@external
final class TransactionInfo {
  late final String _id;
  late final String? _hint;
  late final bool _isReadOnly;

  /// A globally unique ID of the transaction.
  String get id => _id;

  /// The user hint passed when creating the transaction, useful for debugging
  /// and testing.
  String? get hint => _hint;

  /// Indicates whether mutating DQL statements can be executed in the
  /// transaction. Defaults to `false`. See [Store.transaction] for more
  /// information.
  bool get isReadOnly => _isReadOnly;

  TransactionInfo._(
    core.CPPointer<core.CPTransaction> ptr, {
    required String? hint,
    required bool isReadOnly,
  }) {
    final bytes = core.dittoffiTransactionInfo(ptr);
    final obj = _decodeCborMap(bytes);

    final {"id": String id} = obj;

    _id = id;
    _hint = hint;
    _isReadOnly = isReadOnly;
  }
}

Map<String, dynamic> _decodeCborMap(Uint8List bytes) {
  final cborMap = cbor.decode(bytes)! as Map<Object?, Object?>;
  return cborMap.map((key, value) => MapEntry(key! as String, value));
}

/// Represents an action that completes a transaction, by either committing it or
/// rolling it back.
@external
enum TransactionCompletionAction {
  /// Represents the action of committing a transaction.
  commit,

  /// Represents the action of rolling back a transaction.
  rollback,
}

@internal
Future<T> privateTransactionImpl<T>(
  Ditto ditto,
  Future<T> Function(Transaction) callback, {
  bool isReadOnly = false,
  String? hint,
}) async {
  final transaction = await Transaction._begin(
    ditto,
    hint: hint,
    isReadOnly: isReadOnly,
  );

  final T returnValue;

  // no need for `runZonedGuarded` here because no background task spawning
  try {
    returnValue = await runZoned(
      () => callback(transaction),
      zoneValues: {
        _inScopeTransactions: [...privateInScopeTransactions, transaction],
      },
    );
  } catch (_) {
    await transaction._complete(TransactionCompletionAction.rollback);
    rethrow;
  }

  final TransactionCompletionAction requestedAction;

  if (returnValue is TransactionCompletionAction) {
    requestedAction = returnValue;
  } else {
    requestedAction = TransactionCompletionAction.commit;
  }

  await transaction._complete(requestedAction);
  return returnValue;
}

const _inScopeTransactions = #inScopeTransactions;

/// A list of all transactions that are currently in scope
@internal
List<Transaction> get privateInScopeTransactions =>
    Zone.current[_inScopeTransactions] as List<Transaction>? ?? [];

/// Whether we are in the scope of any transaction callbacks
@internal
bool get privateInTransactionScope => privateInScopeTransactions.isNotEmpty;
