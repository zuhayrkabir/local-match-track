import "dart:convert";
import "dart:typed_data";

import "package:cbor/simple.dart";
import "package:meta/meta.dart";

import "../analysis/annotations.dart";
import "../bridge/native/ffi/cbor.dart";
import "../exception.dart";
import "../ditto.dart";

import "../bridge/bridge.dart" as core;
import "store.dart";
import "transaction.dart";

@internal
Future<QueryResult> privateExecuteImpl(
  Ditto ditto,
  String query,
  Map<String, dynamic> args,
) async {
  if (privateInTransactionScope) {
    final transactions = privateInScopeTransactions.map(_debugPrintTransaction);

    throw privateMakeDittoException(
      """
Attempting to use `ditto.store.execute` while in a transaction scope. Use
`transaction.execute` instead (where `transaction` is the first parameter of the
`callback` function that is passed to `ditto.store.transaction`).

Transactions currently in scope:
${transactions.map((s) => " - $s").join("\n")}
""",
    );
  }

  final ptr = await core.dittoffiTryExecStatement(
    ditto.ptr,
    query,
    toCborBytes(args),
  );

  return QueryResult._(ptr.extract());
}

String _debugPrintTransaction(Transaction txn) =>
    'id: "${txn.info.id}", hint: ${txn.info.hint}';

@internal
QueryResult privateMakeQueryResult(core.CPPointer<core.CPQueryResult> ptr) =>
    QueryResult._(ptr);

/// Represents the result of executing a DQL query.
@external
interface class QueryResult {
  final core.CPPointer<core.CPQueryResult> _ptr;
  QueryResult._(this._ptr);

  /// Individual items matching a DQL query.
  Iterable<QueryResultItem> get items => _QueryItems._(this);

  /// IDs of documents that were mutated locally by a mutating DQL query passed to [Store.execute].
  ///
  /// This will be empty if no documents have been mutated.
  ///
  /// Document IDs are returned as raw JSON values and can be any JSON-compatible type:
  /// strings, integers, booleans, null, lists, or maps.
  ///
  /// **Important:** The returned document IDs are not cached. Make sure to call
  /// this method once and keep the return value for as long as needed.
  List<dynamic> mutatedDocumentIDs() {
    final count = core.dittoffiQueryResultMutatedDocumentIdCount(_ptr);
    return List.generate(
      count,
      (index) {
        final bytes = core.dittoffiQueryResultMutatedDocumentIdAt(_ptr, index);
        return cbor.decode(bytes);
      },
      growable: false,
    );
  }

  /// The commit ID associated with this query result, if any.
  ///
  /// This ID uniquely identifies the commit in which this change was accepted
  /// into the _local_ store. The commit ID is available for all query results
  /// involving insertions, updates, or deletions. This ID can be used to track
  /// whether a local change has been synced to other peers.
  ///
  /// For write transactions, the commit ID is only available after the
  /// transaction has been successfully committed. Queries executed within an
  /// uncommitted transaction will not have a commit ID.
  int? get commitID {
    if (core.dittoffiQueryResultHasCommitId(_ptr)) {
      return core.dittoffiQueryResultCommitId(_ptr);
    }
    return null;
  }
}

class _QueryItems extends Iterable<QueryResultItem> {
  final QueryResult _result;
  _QueryItems._(this._result);

  @override
  int get length => core.dittoffiQueryResultItemCount(_result._ptr);

  QueryResultItem operator [](int index) {
    if (index < length) {
      final ptr = core.dittoffiQueryResultItemAt(_result._ptr, index);
      return QueryResultItem._(ptr);
    }

    throw IndexError.withLength(index, length);
  }

  @override
  Iterator<QueryResultItem> get iterator =>
      Iterable.generate(length, (index) => this[index]).iterator;
}

/// Represents a single match of a DQL query, similar to a “row” in SQL terms.
///
/// It’s a reference type serving as a “cursor”, allowing for efficient access of the underlying data in various formats.
/// The first time [value] is accessed, it will be loaded from the store and then cached until the [QueryResultItem] is garbage-collected.
@external
interface class QueryResultItem {
  final core.CPPointer<core.CPQueryResultItem> _ptr;

  QueryResultItem._(this._ptr);

  late final Map<String, dynamic> value = _loadQueryResultItem(_ptr);

  /// Returns the content of the item as CBOR data.
  late final Uint8List cborBytes = core.dittoffiQueryResultItemCbor(_ptr);

  /// Returns the content of the item as a JSON string.
  late final String jsonString = core.dittoffiQueryResultItemJson(_ptr);
}

@internal
extension QueryResultItemListExtensions on List<QueryResultItem> {
  /// Converts a list of [QueryResultItem] to a list of [core.CPPointer].
  List<core.CPPointer<core.CPQueryResultItem>> toPointerList() {
    return map((item) {
      // `_ptr` is a private field and will not be available on subtypes.
      if (item.runtimeType != QueryResultItem) {
        throw ArgumentError(
          "List must not contain subtypes of QueryResultItem",
        );
      }
      return item._ptr;
    }).toList(growable: false);
  }
}

Map<String, dynamic> _loadQueryResultItem(
  core.CPPointer<core.CPQueryResultItem> item,
) {
  final json = core.dittoffiQueryResultItemJson(item);
  return jsonDecode(json) as Map<String, dynamic>;
}

/// Create a new [QueryResultItem] from a JSON object.
///
/// To be used in tests only.
// REFACTOR: This is a test utility that would be helpful for customers to have
// access to. It's not public because it is undocumented and untested but if we
// want to do that later, we can also make `QueryResultItem` not an `interface`
// class anymore as that is only needed so customers can mock `QueryResultItem`
/// in tests.
@internal
QueryResultItem queryResultItemFromJson(Map<String, dynamic> jsonData) {
  final bytes = utf8.encode(jsonEncode(jsonData));
  final pointer = core.dittoffiQueryResultItemNew(bytes).extract();

  return QueryResultItem._(pointer);
}
