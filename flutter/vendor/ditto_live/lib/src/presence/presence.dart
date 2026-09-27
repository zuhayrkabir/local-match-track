import "dart:collection";
import "dart:convert";

import "package:meta/meta.dart";

import "../bridge/bridge.dart" as core;
import "../analysis/annotations.dart";
import "../ditto.dart";
import "../exception.dart";
import "presence_graph.dart";

@external
typedef ConnectionRequestHandler = Future<ConnectionRequestAuthorization>
    Function(ConnectionRequest);

@external

/// Indicates whether a connection should be authorized.
enum ConnectionRequestAuthorization {
  allow,
  deny,
}

@internal
Presence makePresence(Ditto ditto) => Presence._(ditto);

@internal
Future<void> cleanupPresence(Presence presence) => presence._cleanup();

/// Manages the lifecycle of multiple presence observers on a single Ditto instance.
///
/// The native FFI supports many concurrent observers via
/// `dittoffi_presence_register_observer_throws` (HashMap-keyed on the Rust
/// side), but the SDK multiplexes so we only pay one native callback and
/// one presence-graph decode per event regardless of how many Dart observers
/// are registered. The native observer is registered on first `observe()`
/// and freed on `Ditto.close()` — never in `_unregister`, to keep the
/// SDKS-3134 invariant that in-flight callbacks are never called into a
/// closed callable.
final class _PresenceObserverMultiplexer {
  final Ditto _ditto;
  final Map<int, void Function(String)> _callbacks = {};
  // Observers that have received at least one callback. Used by the
  // initial-state delivery (see [_scheduleInitialDelivery]) to avoid
  // double-firing if the native callback races ahead. (SDKS-804)
  final Set<int> _notifiedIds = {};
  int _nextId = 0;
  core.CPFreeable? _nativeFreeable;
  bool _isShuttingDown = false;

  _PresenceObserverMultiplexer(this._ditto);

  /// Registers a new observer and returns an ID and freeable for cleanup
  (int, core.CPFreeable) register(void Function(String json) callback) {
    final id = _nextId++;
    _callbacks[id] = callback;

    // The modern observer FFI is HashMap-backed on the Rust side, so this
    // registration must fire only once per multiplexer — otherwise a
    // second `observe()` after every observer stopped would register a
    // parallel Rust observer and every subsequent event would double-dispatch.
    // Guard on the freeable, not `_callbacks.length`, because `_unregister`
    // intentionally does not free the native observer.
    _nativeFreeable ??= core.dittoRegisterPresenceObserver(
      _ditto.ptr,
      _dispatchToAll,
    );

    // SDKS-804: Deliver the current presence graph asynchronously to this new
    // observer so registration produces an immediate first callback, matching
    // the behavior of the Swift/Kotlin SDKs.
    _scheduleInitialDelivery(id);

    // Return a freeable that removes this specific callback
    return (id, core.CPDartFnFreeable(() => _unregister(id)));
  }

  /// Schedule a one-shot initial-state delivery for [id] on the next event
  /// loop turn. Mirrors the Swift SDK pattern (DITPresence#observeWithTransformerNamed:):
  /// dispatch async so any in-flight native callback can fire first; if it
  /// does, [_notifiedIds] is set and this delivery is skipped to avoid a
  /// duplicate first callback.
  ///
  /// The Future is fire-and-forget; cancellation is implicit through the
  /// `_callbacks[id] == null` check below — [_unregister] is the sole signal.
  /// Do not add early-returns before that lookup or cancellation will silently
  /// break.
  void _scheduleInitialDelivery(int id) {
    Future<void>(() {
      if (_isShuttingDown) return;
      if (_notifiedIds.contains(id)) return;
      final callback = _callbacks[id];
      if (callback == null) return;

      String json;
      try {
        json = core.dittoPresenceV3(_ditto.ptr);
      } on DittoClosedException {
        // Ditto was closed between scheduling and execution.
        return;
      } catch (e, stackTrace) {
        try {
          core.dittoLog(
            core.LogLevel.warning,
            "Presence observer initial-state fetch failed: $e\n$stackTrace",
          );
        } catch (_) {
          // Ignore logging errors in test/non-native contexts
        }
        return;
      }

      _invokeCallback(id, callback, json, "initial-state delivery");
    });
  }

  /// Dispatches a JSON presence-graph string to every registered callback.
  /// The FFI delivers the graph as a UTF-8 JSON string (decoded in the
  /// native bridge from a Rust-owned byte slice).
  void _dispatchToAll(String json) {
    // Guard against callbacks arriving during/after shutdown (SDKS-3134).
    if (_isShuttingDown) return;

    // Copy entries to avoid concurrent modification during iteration
    final entries = List.of(_callbacks.entries);
    for (final entry in entries) {
      _invokeCallback(entry.key, entry.value, json, "native dispatch");
    }
  }

  /// Invokes [callback] with [json] on behalf of observer [id], marking [id]
  /// in [_notifiedIds] so the async initial-state delivery does not re-fire.
  ///
  /// Marks [id] BEFORE invoking the callback. This ordering is load-bearing:
  /// a callback that throws would otherwise leave [_notifiedIds] unset and
  /// the same observer would receive a duplicate first callback via
  /// [_scheduleInitialDelivery]'s race-guard. (SDKS-804)
  void _invokeCallback(
    int id,
    void Function(String) callback,
    String json,
    String context,
  ) {
    _notifiedIds.add(id);
    try {
      callback(json);
    } catch (e, stackTrace) {
      try {
        core.dittoLog(
          core.LogLevel.error,
          "Presence observer callback failed ($context): $e\n$stackTrace",
        );
      } catch (_) {
        // Ignore logging errors in test/non-native contexts
      }
    }
  }

  /// Unregisters a specific observer by ID.
  ///
  /// Note: We intentionally do NOT free the native observer here, even when
  /// the last observer is removed. The native observer is freed in cleanup()
  /// when Ditto.close() is called.
  void _unregister(int id) {
    _callbacks.remove(id);
    _notifiedIds.remove(id);
    // Don't free _nativeFreeable here - let cleanup() handle it safely
  }

  /// Force cleanup of the native observer, clearing all observers.
  /// Called when Ditto is closing to ensure proper cleanup before shutdown.
  ///
  /// Ordering (load-bearing):
  /// 1. Set `_isShuttingDown` synchronously. This makes `_dispatchToAll`
  ///    a no-op for any callback already in flight AND short-circuits any
  ///    pending initial-delivery Future scheduled by
  ///    `_scheduleInitialDelivery` (SDKS-804 — those Futures all check
  ///    `_isShuttingDown` first).
  /// 2. Clear the callback map (belt and suspenders with the flag).
  /// 3. Call `.free()` on the native freeable: the closure invokes
  ///    `dittoffi_presence_observer_cancel` + `dittoffi_presence_observer_free`
  ///    synchronously, Rust drops its `Box<FfiDynPresenceCallback>` which
  ///    fires the `free` fn-pointer, and Dart closes the backing
  ///    `NativeCallable`s via `scheduleMicrotask` (SDKS-2389 pattern).
  Future<void> cleanup() async {
    _isShuttingDown = true;
    _callbacks.clear();
    _notifiedIds.clear();
    final freeable = _nativeFreeable;
    _nativeFreeable = null;
    freeable?.free();
  }
}

/// An object that provides access to information about Ditto peers connected to this peer.
///
/// An instance of [Presence] can be obtained from [Ditto.presence]:
/// ```dart
/// final ditto = await Ditto.open(/* ... */);
/// final presence = ditto.presence;
/// ```
/// This class is not user-constructible.
@external
final class Presence {
  final Ditto _ditto;
  late final _PresenceObserverMultiplexer _multiplexer;

  Presence._(this._ditto) {
    _multiplexer = _PresenceObserverMultiplexer(_ditto);
  }

  /// Internal cleanup method called when Ditto is closing.
  /// Ensures the native presence callback is properly freed before shutdown.
  ///
  /// This method is async and MUST be awaited to ensure cleanup completes
  /// before the Dart VM/isolate shuts down.
  Future<void> _cleanup() async {
    await _multiplexer.cleanup();
    // Also clean up the connection request handler if set.
    // Apply same sequenced cleanup pattern as multiplexer to prevent SIGABRT.
    if (_handlerGuard != null) {
      final guard = _handlerGuard;
      _handlerGuard = null;
      _handler = null;
      await _freeWithDelay(guard!);
    }
  }

  /// Helper to free a CPFreeable with a delay to let in-flight callbacks drain.
  /// This prevents SIGABRT by ensuring callbacks complete before we close
  /// the NativeCallable.
  Future<void> _freeWithDelay(core.CPFreeable freeable) async {
    // Wait for any in-flight callbacks to complete.
    // Using 500ms to provide sufficient margin on slower CI machines.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    freeable.free();
  }

  /// Request information about [Ditto] peers in range of this device.
  ///
  /// This method returns a [PresenceObserver] which should stopped by calling
  /// [PresenceObserver.stop] when you are done with it. A newly registered
  /// observer will have a peers update delivered to it immediately. From then
  /// on it will be invoked repeatedly when Ditto devices come and go, or the
  /// active connections to them change.
  PresenceObserver observe(
    void Function(PresenceGraph graph) onChange,
  ) {
    final (id, freeable) = _multiplexer.register((string) {
      final graph = _graphFromString(string);
      onChange(graph);
    });

    return PresenceObserver._(freeable);
  }

  /// The current presence graph capturing all known peers and connections between them.
  PresenceGraph get graph => _graphFromString(core.dittoPresenceV3(_ditto.ptr));

  /// Simulate a native presence callback carrying the current graph, routed
  /// through the real dispatch path.
  ///
  /// Exposed so a test can deterministically force the "native callback fires
  /// before the async initial-state delivery" sequence without depending on
  /// FFI dispatch timing. After this returns, every active observer has been
  /// invoked once and marked in [notifiedIdsForTesting]; a still-pending
  /// initial-delivery Future must then skip rather than fire a duplicate first
  /// callback. (SDKS-804 dedup contract; SDKS-3877 coverage.)
  ///
  /// No-op once shutdown has begun, so a test that calls this against a
  /// closing instance cannot trigger a use-after-close FFI call.
  @internal
  void dispatchCurrentGraphForTesting() {
    if (_multiplexer._isShuttingDown) return;
    _multiplexer._dispatchToAll(core.dittoPresenceV3(_ditto.ptr));
  }

  /// Read-only view of the observer ids that have received at least one
  /// callback.
  ///
  /// Lets a test assert that the native-dispatch path marked an observer, so
  /// the async initial-state delivery is guaranteed to skip. (SDKS-804)
  @internal
  Set<int> get notifiedIdsForTesting =>
      UnmodifiableSetView(_multiplexer._notifiedIds);

  /// Metadata associated with the current peer.
  ///
  /// This is a convenience property that wraps [peerMetadataJsonString].
  /// Changes to either property will affect the other.
  Map<String, dynamic> get peerMetadata =>
      jsonDecode(peerMetadataJsonString) as Map<String, dynamic>;
  set peerMetadata(Map<String, dynamic> metadata) =>
      peerMetadataJsonString = jsonEncode(metadata);

  /// Metadata associated with the current peer as a JSON-encoded string.
  ///
  /// Other peers in the same mesh can access this user-provided dictionary of metadata
  /// via the presence [graph] and when evaluating connection requests using
  /// [connectionRequestHandler].
  ///
  /// The metadata must not exceed 4KB when JSON-encoded.
  ///
  /// This will throw if:
  ///  - the string contains invalid JSON
  ///  - the string encodes a JSON value that is not an object
  ///  - the size limit for a JSON string has been exceeded
  String get peerMetadataJsonString =>
      core.dittoFfiPresencePeerMetadataJson(_ditto.ptr);
  set peerMetadataJsonString(String metadataJson) => core
      .dittoFfiPresenceTrySetPeerMetadataJson(
        _ditto.ptr,
        metadataJson,
      )
      .extract();

  core.CPFreeable? _handlerGuard;
  ConnectionRequestHandler? _handler;

  /// Set this handler to control which peers in a Ditto mesh can connect to the current peer.
  ///
  /// Each peer in a Ditto mesh will attempt to connect to other peers that it can reach.
  /// By default, the mesh will try and establish connections that optimize for the best overall
  /// connectivity between peers. However, you can set this handler to assert some
  /// control over which peers you connect to.
  ///
  /// If set, this handler is called for every incoming connection request from a
  /// remote peer and is passed the other peer’s `peerKey`, `peerMetadata`, and `identityServiceMetadata`.
  /// The handler can then accept or reject the request by returning an
  /// according [ConnectionRequestAuthorization] value.
  /// When the connection request is rejected, the remote peer may retry
  /// the connection request after a short delay.
  ///
  /// Connection request handlers must reliably respond to requests within a short time.
  /// If a handler takes too long to respond or throws an exception, the connection request will be denied.
  /// The response currently times out after 10 seconds, but this exact value may be subject to change in future releases.
  ConnectionRequestHandler? get connectionRequestHandler => _handler;

  set connectionRequestHandler(
    ConnectionRequestHandler? handler,
  ) {
    // FIXME: register a null handler in core when handler is null to avoid
    // defining handler logic for that case in the SDK
    final newGuard = core.dittoFfiPresenceSetConnectionRequestHandler(
        _ditto.ptr, (pointer) async {
      if (_ditto.isClosed) {
        // FIXME: enable when SDKS-326 is implemented
        // core.dittoLog(
        //   core.LogLevel.info,
        //   "Ditto instance is closed; denying connection request.",
        // );
        return ConnectionRequestAuthorization.deny;
      }
      final request = ConnectionRequest._(pointer);
      final result = await handler?.call(request);

      return result ?? ConnectionRequestAuthorization.allow;
    });

    _handlerGuard?.free();

    _handler = handler;
    _handlerGuard = newGuard;
  }
}

/// Contains information about a remote peer that has requested a connection.
///
/// Connection requests and their authorization are scoped to a specific Ditto
/// peer and connection type.
@external
interface class ConnectionRequest {
  final core.CPPointer<core.CPConnectionRequest> _ptr;
  ConnectionRequest._(this._ptr);

  /// The network transport of this connection request.
  ///
  /// Expect to receive separate connection requests for each network transport
  /// that connects the local and remote peer.
  ConnectionType get connectionType =>
      core.dittoFfiConnectionRequestConnectionType(_ptr);

  /// The unique peer key of the remote peer.
  ///
  /// See [Peer.peerKey] for more information.
  String get peerKey => core.dittoFfiConnectionRequestPeerKeyString(_ptr);

  /// Metadata for the remote peer that is provided by the identity service.
  ///
  /// Use an authentication webhook to set this value. See Ditto’s online
  /// documentation for more information on how to configure an authentication
  /// webhook.
  ///
  /// Convenience property that wraps [identityServiceMetadataJsonString]
  Map<String, dynamic> get identityServiceMetadata =>
      jsonDecode(identityServiceMetadataJsonString) as Map<String, dynamic>;

  /// JSON-encoded metadata for the remote peer that is provided by the identity
  /// service.
  ///
  /// Use an authentication webhook to set this value. See Ditto’s online
  /// documentation for more information on how to configure an authentication
  /// webhook.
  String get identityServiceMetadataJsonString =>
      core.dittoFfiConnectionRequestIdentityServiceMetadataJson(_ptr);

  /// Metadata associated with the remote peer.
  ///
  /// Empty dictionary if the remote peer has not set any metadata.
  ///
  /// Set peer metadata for the local peer using [Presence.peerMetadata] or
  /// [Presence.peerMetadataJsonString].
  ///
  /// Convenience property that wraps [peerMetadataJsonString].
  Map<String, dynamic> get peerMetadata =>
      jsonDecode(peerMetadataJsonString) as Map<String, dynamic>;

  /// JSON-encoded metadata associated with the remote peer.
  ///
  /// JSON string representing an empty dictionary if the remote peer has not
  /// set any metadata.
  ///
  /// Set peer metadata for the local peer using [Presence.peerMetadata] or
  /// [Presence.peerMetadataJsonString].
  String get peerMetadataJsonString =>
      core.dittoFfiConnectionRequestPeerMetadataJson(_ptr);
}

PresenceGraph _graphFromString(String string) {
  final presenceJson = jsonDecode(string) as Map<String, dynamic>;
  return PresenceGraph.fromJson(presenceJson);
}

/// A handle returned from [Presence.observe].
///
/// This handle provides the [stop] method, which cancels observation.
@external
interface class PresenceObserver {
  final core.CPFreeable _freeable;

  PresenceObserver._(this._freeable);

  /// Stops this [PresenceObserver].
  ///
  /// The callback passed to [Presence.observe] will no longer be called after
  /// calling [stop].
  void stop() => _freeable.free();
}
