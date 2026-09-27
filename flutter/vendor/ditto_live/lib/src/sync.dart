import "dart:typed_data";

import "package:equatable/equatable.dart";
import "package:meta/meta.dart";

import "analysis/annotations.dart";
import "bridge/native/ffi/cbor.dart"; // TODO: move this to a non-native-specific place

import "ditto.dart";

import "bridge/bridge.dart" as core;
import "exception.dart";
import "shared/cbor.dart";
import "sync_controller.dart";

@internal
Sync makeSync(Ditto ditto) => Sync._(ditto);

/// An object that provides sync-related functionality of Ditto.
///
/// An instance of [Sync] can be obtained from [Ditto.sync]:
/// ```dart
/// final ditto = await Ditto.open(/* ... */);
/// final sync = ditto.sync;
/// ```
/// This class is not user-constructible.
@external
final class Sync {
  final Ditto _ditto;
  late final PrivateSyncController _syncController =
      PrivateSyncController(_ditto);

  Sync._(this._ditto);

  /// Whether sync has been started for this [Ditto] instance.
  ///
  /// [start] and [stop] can be used to control sync.
  bool get isActive => _syncController.syncing;

  /// Starts the network transports. Ditto will connect to other devices.
  ///
  /// By default Ditto enables the stable peer-to-peer transports supported on
  /// the current platform. Reliable UDP multicast is excluded from this default
  /// and must be enabled explicitly. The default network configuration can be
  /// modified with [Ditto.updateTransportConfig] or replaced via the
  /// [Ditto.transportConfig] property.
  ///
  /// If this peer is already syncing, this function is a no-op.
  void start() => _syncController.start();

  /// Stops all network transports.
  ///
  /// You may continue to use the [Ditto] store locally but no data will sync to or from other devices.
  ///
  /// If this peer is not currently syncing, this function is a no-op.
  void stop() => _syncController.stop();

  /// All currently active sync subscriptions.
  ///
  /// **Note:** Manage sync subscriptions using
  /// [registerSubscription] to register a new sync subscription and
  /// [SyncSubscription.cancel] to remove an existing sync subscription.
  Set<SyncSubscription> get subscriptions {
    final syncSubscriptions = core.dittoFfiSyncSubscriptions(_ditto.ptr);
    return syncSubscriptions
        .map((ptr) => SyncSubscription._(_ditto, ptr))
        .toSet();
  }

  /// Installs and returns a sync subscription for a query, configuring Ditto to
  /// receive updates from other peers for documents matching that [query].
  /// The passed in [query] must be a `SELECT` query, otherwise an error is thrown.
  ///
  /// [query] is a string containing a valid query expressed in DQL.
  /// [arguments] is a map containing the arguments for the query.
  /// For example: `{mileage: 123}` for a query with `:mileage` placeholder.
  /// This method returns an active [SyncSubscription] for the passed in [query] and
  /// [arguments]. It will remain active until it is cancelled or the
  /// Ditto instance managing the sync subscription has been closed.
  ///
  /// Throws if:
  ///  - the [query] argument is not valid DQL.
  ///  - [arguments] is invalid (e.g., contains unsupported types).
  ///  - the [query] is not a `SELECT` query.
  SyncSubscription registerSubscription(
    String query, {
    Map<String, dynamic> arguments = const {},
  }) {
    return SyncSubscription._fromQueryAndArguments(
      _ditto,
      query,
      arguments,
    );
  }
}

/// Configures Ditto to receive updates from remote peers
/// about documents matching the subscription's query.
///
/// Create a sync subscription by calling [Sync.registerSubscription].
/// The subscription will remain active until either explicitly cancelled via
/// [SyncSubscription.cancel] or the owning [Ditto] object is closed.
@external
interface class SyncSubscription with EquatableMixin {
  final Ditto _ditto;
  final core.CPPointer<core.CPSyncSubscription> _ptr;

  factory SyncSubscription._fromQueryAndArguments(
    Ditto ditto,
    String query,
    Map<String, dynamic>? arguments,
  ) {
    final argumentsCbor =
        arguments != null ? toCborBytes(arguments) : Uint8List(0);

    final ptr = core
        .dittoFfiSyncRegisterSubscriptionThrows(
          ditto.ptr,
          query,
          argumentsCbor,
        )
        .extract();

    return SyncSubscription._(ditto, ptr);
  }

  // This is the "base" constructor, that the one above should call
  SyncSubscription._(
    this._ditto,
    this._ptr,
  );

  /// The query string of the sync subscription (as passed while registering
  /// it).
  ///
  /// This is the original query string supplied to [Sync.registerSubscription],
  /// not the resolved query with [queryArguments] substituted in.
  late final String queryString =
      core.dittoFfiSyncSubscriptionQueryString(_ptr);

  /// The query arguments of the sync subscription (as passed while registering
  /// it).
  ///
  /// The returned value is not guaranteed to be strictly equal to the value
  /// provided when registering the sync subscription via
  /// [Sync.registerSubscription], as the arguments will have gone through a
  /// serialization roundtrip. This might affect equality checks, particularly
  /// for non-primitive values. If you want to have more control over how to
  /// deserialize the query arguments then use [queryArgumentsCborBytes] or
  /// [queryArgumentsJsonString].
  late final Map<String, dynamic>? queryArguments = _loadQueryArgs();

  /// The query arguments of the sync subscription, serialized as CBOR (as
  /// passed while registering it).
  late final Uint8List? queryArgumentsCborBytes = _loadQueryArgsCbor();

  /// The query arguments of the sync subscription, serialized as JSON (as
  /// passed while registering it).
  late final String? queryArgumentsJsonString = _loadQueryArgsJson();

  Map<String, dynamic>? _loadQueryArgs() {
    final queryArgsBytes = _loadQueryArgsCbor();
    if (queryArgsBytes == null) return null;

    final decoded = decodeTrivialCbor(queryArgsBytes);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw privateMakeDittoError(
      "Expected Map<Object?, Object?> for query arguments, got ${decoded.runtimeType}",
    );
  }

  Uint8List? _loadQueryArgsCbor() {
    final queryArgsBytes =
        core.dittoFfiSyncSubscriptionQueryArgumentsCbor(_ptr);
    if (queryArgsBytes.isEmpty) return null;
    return queryArgsBytes;
  }

  String? _loadQueryArgsJson() {
    return core.dittoFfiSyncSubscriptionQueryArgumentsJson(_ptr);
  }

  /// `true` when the sync subscription has been cancelled or the [Ditto]
  /// instance managing this subscription has been closed.
  ///
  /// The owning-[Ditto]-closed leg is short-circuited before touching the
  /// native subscription handle: [Ditto.close] frees the underlying FFI
  /// machinery without flipping this subscription's cancelled flag, so
  /// reading it post-close would otherwise report `false` (and risk touching
  /// a freed handle). Treat a closed [Ditto] as cancellation (SDKS-3916).
  bool get isCancelled =>
      _ditto.isClosed || core.dittoFfiSyncSubscriptionIsCancelled(_ptr);

  /// Cancels the sync subscription so that new changes matching the query are no longer received from other peers.
  ///
  /// No-op if the sync subscription has already been cancelled or the Ditto
  /// instance managing this subscription has been closed.
  void cancel() {
    // Guard at the Dart layer so a post-close cancel() honors the no-op
    // contract without depending on FFI tolerance of a freed handle
    // (SDKS-3916).
    if (isCancelled) return;
    core.dittoFfiSyncSubscriptionCancel(_ptr);
  }

  /// @nodoc
  @override
  List<Object?> get props => [_id];

  Uint8List get _id => core.dittoFfiSyncSubscriptionId(_ptr);
}
