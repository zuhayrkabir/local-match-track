import "dart:async";

import "package:meta/meta.dart";

import "analysis/annotations.dart";
import "bridge/bridge.dart" as core;
import "ditto.dart";
import "exception.dart";

/// A condition reported by one of the transports configured on a [Ditto] peer.
///
/// Transport conditions surface health and configuration issues that cannot be
/// reported synchronously when [Ditto.transportConfig] is set. Observe them via
/// [Ditto.observeTransportConditions].
@external
enum TransportCondition {
  /// The condition could not be classified, or is one this SDK version does
  /// not recognize.
  unknown,

  /// The transport is functioning normally.
  ok,

  /// The transport failed for an unspecified reason.
  genericFailure,

  /// The application is in the background. Some transports are unavailable
  /// while the application is suspended.
  appInBackground,

  /// mDNS service discovery is unavailable.
  mdnsFailure,

  /// The configured TCP listener could not bind.
  tcpListenFailure,

  /// The application is missing the BLE central permission.
  ///
  /// Grant the permission and restart sync to recover.
  noBleCentralPermission,

  /// The application is missing the BLE peripheral permission.
  ///
  /// Grant the permission and restart sync to recover.
  noBlePeripheralPermission,

  /// A connection could not be established to a remote peer.
  cannotEstablishConnection,

  /// Bluetooth is disabled at the OS level.
  bleDisabled,

  /// The device has no BLE hardware available.
  noBleHardware,

  /// Wi-Fi is disabled at the OS level.
  wifiDisabled,

  /// The transport is temporarily unavailable. It may recover without further
  /// configuration changes.
  temporarilyUnavailable;
}

/// The transport subsystem that produced a [TransportCondition].
@external
enum TransportConditionSource {
  /// The source could not be classified, or is one this SDK version does not
  /// recognize.
  unknown,

  /// Bluetooth LE transport.
  bluetooth,

  /// LAN (TCP / mTLS) transport.
  tcp,

  /// AWDL (Apple peer-to-peer Wi-Fi) transport.
  awdl,

  /// mDNS service discovery.
  mdns,

  /// Wi-Fi Aware (Android peer-to-peer Wi-Fi) transport.
  wifiAware;
}

/// A condition reported by a specific transport subsystem.
@external
@immutable
final class TransportConditionEvent {
  /// The reported condition.
  final TransportCondition condition;

  /// The subsystem that produced [condition].
  final TransportConditionSource source;

  const TransportConditionEvent({
    required this.condition,
    required this.source,
  });

  @override
  String toString() =>
      "TransportConditionEvent(condition: $condition, source: $source)";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransportConditionEvent &&
          other.condition == condition &&
          other.source == source;

  @override
  int get hashCode => Object.hash(condition, source);
}

@internal
TransportConditions makeTransportConditions(Ditto ditto) =>
    TransportConditions._(ditto);

@internal
Future<void> cleanupTransportConditions(TransportConditions tc) =>
    tc._cleanup();

/// Manages the lifecycle of [TransportConditionsObserver]s on a single [Ditto]
/// instance.
///
/// The FFI exposes a single transport-condition callback per [Ditto], so this
/// type multiplexes multiple Dart observers onto one native registration. The
/// native callback is registered on the first observer and kept alive until
/// [Ditto.close] runs, which avoids SIGABRTs from in-flight native callbacks
/// arriving after a `NativeCallable` is closed (mirrors the cleanup pattern in
/// `presence.dart`; see SDKS-3134).
///
/// This class is not part of the public SDK surface; users interact with it
/// only via [Ditto.observeTransportConditions].
@internal
final class TransportConditions {
  final Ditto _ditto;
  final Map<int, void Function(TransportConditionEvent)> _callbacks = {};
  // Tracks controllers parallel to [_callbacks] so [_cleanup] can deliver a
  // done event to subscribers awaiting the close sequence — see the public
  // docstring on [observe] which promises this behaviour.
  final Map<int, StreamController<TransportConditionEvent>> _controllers = {};
  int _nextId = 0;
  core.CPFreeable? _nativeFreeable;
  bool _isShuttingDown = false;

  TransportConditions._(this._ditto);

  /// Begin observing transport conditions on this [Ditto] peer.
  ///
  /// The returned [TransportConditionsObserver] exposes both a [Stream] of
  /// [TransportConditionEvent]s and an explicit [TransportConditionsObserver.stop]
  /// method. Multiple observers may exist concurrently; each receives every
  /// emitted event until it is stopped.
  ///
  /// The [onChange] callback is invoked synchronously alongside the stream
  /// emission. Callers who only want the [Stream] can pass `(_) {}` (and read
  /// events via [TransportConditionsObserver.changes]); the callback shape is
  /// kept required-positional to match `Presence.observe` and the rest of the
  /// Flutter SDK's observer APIs.
  ///
  /// The single-event shape mirrors the Kotlin SDK's
  /// `DittoTransportConditionEvent` over `Flow`; the React Native SDK delivers
  /// `(condition, source)` as two positional arguments instead.
  ///
  /// Observers do not need to be stopped before calling [Ditto.close]; cleanup
  /// happens as part of the close sequence.
  TransportConditionsObserver observe(
    void Function(TransportConditionEvent event) onChange,
  ) {
    // Reject observer creation once cleanup has begun. Without this guard, the
    // callback id and StreamController are created (and leak) before the
    // `_ditto.ptr` access below throws DittoClosedException.
    if (_isShuttingDown) {
      throw DittoClosedException();
    }
    final id = _nextId++;
    final controller = StreamController<TransportConditionEvent>.broadcast();
    // Store the user's callback verbatim. _dispatchToAll iterates _callbacks
    // and _controllers in parallel so a throwing callback cannot deprive its
    // own observer (or any other) of the stream emission.
    _callbacks[id] = onChange;
    _controllers[id] = controller;

    // Register the single native callback the first time we transition from
    // "no observers" → "observers exist". Re-checking `_nativeFreeable == null`
    // (rather than `_callbacks.length == 1`) means we only re-register if the
    // prior NativeCallable has actually been freed; otherwise we'd orphan the
    // existing one when observers churn through empty.
    _nativeFreeable ??= core.dittoRegisterTransportConditionChangedCallback(
      _ditto.ptr,
      _dispatchToAll,
    );

    return TransportConditionsObserver._(
      controller: controller,
      onStop: () {
        _callbacks.remove(id);
        _controllers.remove(id);
        // Intentionally keep the native callback registered until close().
        // See class doc: closing the NativeCallable while native callbacks
        // are in flight can SIGABRT.
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );
  }

  /// Synthetic event injection used by ditto_test. The enclosing class is
  /// `@internal`, so this is not reachable from app code; exposed so tests
  /// can exercise the dispatch + per-callback exception isolation paths
  /// without waiting on real transport state.
  void dispatchForTesting(TransportConditionEvent event) =>
      _dispatchToAll(event);

  void _dispatchToAll(TransportConditionEvent event) {
    if (_isShuttingDown) return;

    // Snapshot ids to allow observers to stop during iteration without
    // ConcurrentModificationError. Each observer's callback and stream are
    // dispatched independently so a throwing callback does not skip its own
    // stream emission or any subsequent observers (verified by the
    // `observer callback exceptions do not affect other observers` test).
    final ids = _callbacks.keys.toList();
    for (final id in ids) {
      final callback = _callbacks[id];
      if (callback != null) {
        try {
          callback(event);
        } catch (e, stackTrace) {
          try {
            core.dittoLog(
              core.LogLevel.error,
              "Transport condition callback failed: $e\n$stackTrace",
            );
          } catch (_) {
            // Ignore logging errors in non-native test contexts.
          }
        }
      }
      final controller = _controllers[id];
      if (controller != null && !controller.isClosed) {
        controller.add(event);
      }
    }
  }

  Future<void> _cleanup() async {
    _isShuttingDown = true;

    // Deliver a done event to any subscribers that did not explicitly stop()
    // their observer before Ditto.close — the public docstring on [observe]
    // promises this. Drain controllers *before* clearing callbacks so any
    // in-flight dispatch sees the shutdown flag and bails out.
    final controllersToClose = _controllers.values.toList();
    _controllers.clear();
    for (final controller in controllersToClose) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }

    _callbacks.clear();
    final freeable = _nativeFreeable;
    _nativeFreeable = null;
    if (freeable == null) return;

    // Free via the shared drain-then-close helper (see SDKS-3134 for why the
    // drain window is required). presence.dart / auth.dart still inline this
    // pattern; migrating them is a follow-up.
    await core.drainThenClose(freeable);
  }
}

/// A handle returned from [Ditto.observeTransportConditions].
@external
final class TransportConditionsObserver {
  final StreamController<TransportConditionEvent> _controller;
  final void Function() _onStop;

  TransportConditionsObserver._({
    required StreamController<TransportConditionEvent> controller,
    required void Function() onStop,
  })  : _controller = controller,
        _onStop = onStop;

  /// A broadcast stream of [TransportConditionEvent]s observed since this
  /// observer was created.
  ///
  /// The stream is closed when [stop] is called or when the owning [Ditto]
  /// instance is closed.
  Stream<TransportConditionEvent> get changes => _controller.stream;

  /// Stop receiving transport condition updates.
  ///
  /// Subsequent listeners on [changes] receive a done event. Idempotent.
  void stop() => _onStop();
}
