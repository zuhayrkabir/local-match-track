import "package:cbor/simple.dart";
import "package:flutter/foundation.dart";
import "package:meta/meta.dart";

import "analysis/annotations.dart";
import "bridge/bridge.dart" as core;

import "devtools_extension_helpers.dart";
import "ditto_config.dart";
import "exception.dart";
import "globals.dart";
import "registry.dart";
import "shared/cbor.dart";
import "supported_platform.dart";
import "transport_config.dart";
import "auth.dart";
import "logger.dart";
import "presence/presence.dart";
import "small_peer_info.dart";
import "store/store.dart";
import "sync.dart";
import "transport_conditions.dart";
import "transports.dart";

bool _dittoIsInit = false;

@internal
void privateCheckDittoInit() {
  if (!_dittoIsInit) {
    throw privateMakeDittoError(
      "Ditto not initialized. Call `Ditto.init()` and await the `Future` before using any Ditto functionality",
    );
  }
}

/// The main entrypoint for all Ditto-related functionality.
///
/// To create a Ditto instance, use [Ditto.open] which automatically handles initialization.
/// Explicit calls to [Ditto.init] are now optional for most use cases.
///
/// This class cannot be sent between isolates.
@external
@pragma("vm:isolate-unsendable")
final class Ditto {
  /// A string containing the semantic version of the Ditto SDK. Example: `4.4.3`.
  static String get version => core.dittoGetSdkSemver();

  /// The current platform.
  ///
  /// This serves as an alternative to `Platform.isAndroid`, etc., which cannot
  /// be imported into a cross-platform app. Since the `Platform` type is
  /// provided by `dart:io`, which is not available on the web, even
  /// **importing** `Platform` will cause your code to fail to compile on web.
  static SupportedPlatform get currentPlatform => core.utilGetCurrentPlatform();

  /// The default root directory used for Ditto data persistence.
  ///
  /// This is set to the value of `await getApplicationDocumentsDirectory()`
  /// from `package:path_provider` on native platforms. On web, it is `""` -
  /// the empty string.
  ///
  /// See also:
  /// - [Ditto.absolutePersistenceDirectory]
  /// - [DittoConfig.persistenceDirectory]
  static String get defaultRootDirectory {
    privateCheckDittoInit();
    return Globals.instance.documentsDirectory ?? "";
  }

  /// Initialize systems that are used across [Ditto] instances.
  ///
  /// **NOTE**: As of SDK 5.0, calling this method explicitly is optional when using
  /// [Ditto.open]. The [Ditto.open] method automatically initializes Ditto if needed,
  /// matching the zero-config initialization behavior of other Ditto SDKs like Kotlin.
  ///
  /// You only need to call this method explicitly if:
  /// - You want to initialize with custom WebAssembly URLs ([wasmUrl] or [wasmShimUrl])
  /// - You are using [Ditto.openSync] (which cannot auto-initialize)
  /// - You want to initialize Ditto early, before creating any instances
  ///
  /// Repeated calls are no-ops.
  ///
  /// By default, on web, both the WebAssembly binary and the associated JavaScript shim
  /// are loaded from the package's assets. Provide a URL for [wasmUrl] and/or
  /// [wasmShimUrl] to load them from a different location, for example a CDN.
  ///
  /// WebAssembly-related parameters have no effect on non-web platforms.
  static Future<void> init({String? wasmUrl, String? wasmShimUrl}) {
    if (_initFuture != null) return _initFuture!;
    _initFuture = Ditto._init(wasmUrl: wasmUrl, wasmShimUrl: wasmShimUrl);

    return _initFuture!;
  }

  static Future<void>? _initFuture;
  static Future<void> _init({String? wasmUrl, String? wasmShimUrl}) async {
    registerDittoServiceExtensionIfNeeded();

    await core.init(wasmUrl: wasmUrl, wasmShimUrl: wasmShimUrl);

    await Globals.load();
    // Android context is now set automatically in DittoPlugin.onAttachedToEngine()
    // No need to call initializeAndroidContext() here

    privateSetupLogCallback();
    _dittoIsInit = true;
  }

  String _deviceName;

  // This pointer must not be used except in `.close()`. All other accesses
  // should go through `.ptr` via the extension, which checks whether this Ditto
  // instance is closed
  // ignore: ditto_store_ditto_ptr
  final core.CPPointer<core.CPDitto> _ptrDoNotUseExceptInClose;

  late final Store store = makeStore(this);
  late final Sync sync = makeSync(this);
  late final SmallPeerInfo smallPeerInfo = makeSpi(this);

  // Auth and presence use nullable backing fields so we can check if they
  // were initialized before cleanup (needed to prevent SIGABRT on close).
  Authenticator? _authInstance;
  Authenticator get auth => _authInstance ??= makeAuthenticator(this);

  Presence? _presenceInstance;
  Presence get presence => _presenceInstance ??= makePresence(this);

  TransportConditions? _transportConditionsInstance;
  TransportConditions get _transportConditions =>
      _transportConditionsInstance ??= makeTransportConditions(this);

  /// Observe condition changes reported by the configured transports.
  ///
  /// Transport configuration changes set via [Ditto.transportConfig] are
  /// applied asynchronously and do not throw on invalid input. Observing
  /// transport conditions is the only way to surface unapplied configurations
  /// and other runtime transport issues (missing permissions, disabled
  /// hardware, etc.).
  ///
  /// The returned [TransportConditionsObserver] exposes a broadcast
  /// [Stream] of [TransportConditionEvent]s. Stop receiving updates by
  /// calling [TransportConditionsObserver.stop]; if you do not stop it
  /// explicitly, it is cleaned up when this [Ditto] instance is closed.
  ///
  /// Multiple observers may exist concurrently. The [onChange] callback is
  /// invoked alongside stream emission and matches the required-positional
  /// shape used by [Presence.observe]; callers who only want the [Stream] can
  /// pass `(_) {}` and read events via [TransportConditionsObserver.changes].
  TransportConditionsObserver observeTransportConditions(
    void Function(TransportConditionEvent event) onChange,
  ) =>
      _transportConditions.observe(onChange);

  @internal
  void dispatchTransportConditionForTesting(TransportConditionEvent event) =>
      _transportConditions.dispatchForTesting(event);

  /// Whether the SDK has been activated with a valid license token.
  bool get isActivated => core.dittoIsActivated(ptr);

  Ditto._(
    this._ptrDoNotUseExceptInClose,
    this._deviceName,
  );

  /// Asynchronously creates and returns a new [Ditto] instance using the
  /// provided configuration.
  ///
  /// This method automatically initializes Ditto if it hasn't been initialized yet,
  /// eliminating the need to call [Ditto.init] manually. This matches the behavior
  /// of other Ditto SDKs like Kotlin.
  ///
  /// Throws a [DittoException] if:
  /// - the chosen persistence directory is already locked
  /// - the passed in [DittoConfig]'s contents do not meet the required
  ///   validation criteria. For detailed information on the validation
  ///   requirements, consult the documentation of the individual properties of
  ///   [DittoConfig].
  @DittoEntrypoint()
  static Future<Ditto> open([DittoConfig config = const DittoConfig()]) async {
    // Automatically initialize if not already done
    await init();

    final (:configCbor, :mode, :rootDir) = _constructorPreamble(config);

    // ignore: ditto_store_ditto_ptr
    final dittoPtr = await core
        .dittoffiDittoOpenAsyncThrows(configCbor, mode, rootDir)
        .extract();

    return _constructorPostamble(dittoPtr);
  }

  /// A synchronous alternative to [Ditto.open].
  ///
  /// **IMPORTANT**: You must call [Ditto.init] and await the returned [Future] before
  /// calling this method, since synchronous initialization is not possible.
  ///
  /// For most use cases, prefer [Ditto.open] which automatically handles initialization.
  ///
  /// For detailed documentation, see [Ditto.open].
  @DittoEntrypoint()
  factory Ditto.openSync([DittoConfig config = const DittoConfig()]) {
    // Note: We cannot auto-initialize here since this is synchronous
    // Users must call Ditto.init() first
    final (:configCbor, :mode, :rootDir) = _constructorPreamble(config);

    // ignore: ditto_store_ditto_ptr
    final dittoPtr =
        core.dittoffiDittoOpenThrows(configCbor, mode, rootDir).extract();

    return _constructorPostamble(dittoPtr);
  }

  late final DittoConfig config = DittoConfig.fromJson(
    decodeTrivialCbor(core.dittoffiDittoConfig(ptr)) as Map<String, dynamic>,
  );

  /// The current transport configuration.
  ///
  /// By default peer-to-peer transports (Bluetooth, WiFi and AWDL) are enabled.
  /// You may use this property to alter the configuration at any time.
  /// Sync will not begin until [Sync.start] is called.
  TransportConfig get transportConfig => getTransportConfig(this);
  set transportConfig(TransportConfig newConfig) =>
      setTransportConfig(this, newConfig);

  /// Convenience method for updating the current transport configuration.
  ///
  /// The [TransportConfig] passed to the callback is a deep copy of the current config.
  void updateTransportConfig(
    void Function(TransportConfigBuilder newConfig) update,
  ) {
    final builder = transportConfig.toBuilder();
    update(builder);
    transportConfig = builder.build();
  }

  /// Activate an offline [Ditto] instance by setting a license token. You
  /// cannot sync data across instances using an offline identity before you
  /// have activated the associated Ditto instance. Offline identities include:
  ///
  /// This method is a no-op on web builds.
  // TODO(cameron): what about this
  void setOfflineOnlyLicenseToken(String licenseToken) {
    if (kIsWeb) {
      core.dittoLog(
        core.LogLevel.warning,
        "setOfflineOnlyLicenseToken is a no-op on the web platform.",
      );
    }
    core.dittoFfiTryVerifyLicense(ptr, licenseToken).extract();
  }

  /// A custom identifier for this peer.
  ///
  /// When using [presence], each remote peer is represented by a short UTF-8 “device name”.
  /// A default value will be derived from the current device model.
  ///
  /// Device names longer than 24 bytes are truncated to 24 bytes immediately
  /// when this setter is called; the getter reflects the truncated value.
  ///
  /// Changes to this property after [Sync.start] was called will only take
  /// effect after the next restart of sync. The value does not need to be
  /// unique among peers.
  String get deviceName => _deviceName;
  set deviceName(String name) {
    final actualName = core.dittoSetDeviceName(ptr, name);
    _deviceName = actualName;
  }

  /// The persistence directory used by Ditto to persist data.
  ///
  /// It is not recommended to directly read or write to this directory
  /// as its structure and contents are managed by Ditto and may change
  /// in future versions.
  ///
  /// When [DittoLogger] is enabled, logs may be written to this directory
  /// even after a [Ditto] instance was deallocated.
  /// Please refer to the documentation of [DittoLogger] for more information.
  String get absolutePersistenceDirectory =>
      core.dittoffiDittoAbsolutePersistenceDirectory(ptr);

  /// Whether this [Ditto] instance has been closed by calling [Ditto.close]
  ///
  /// If `true` all operations on [Ditto] (including any in long-running tasks)
  /// will throw [DittoClosedException].
  bool get isClosed => _isClosed;
  var _isClosed = false;

  /// Close this instance of [Ditto].
  ///
  /// Any subsequent calls to any method/property on this instance will throw
  /// [DittoClosedException]
  ///
  /// This method is idempotent - calling it multiple times has no effect after
  /// the first call.
  // NOTE: Closing a Flutter peer does not await in-flight API calls to complete
  // as in the JS SDK. Already started API calls will fail on their next attempt
  // to access the Ditto peer pointer.
  Future<void> close() async {
    // Guard against multiple close calls
    if (_isClosed) return;
    _isClosed = true;
    // Stop sync first per FFI shutdown contract: stop_sync → shutdown → free
    core.dittoFfiDittoStopSync(_ptrDoNotUseExceptInClose);

    // Clean up presence native callbacks before shutdown to prevent SIGABRT
    // (SDKS-3134). Only cleanup if presence was initialized.
    // This MUST be awaited to ensure the cleanup delay completes before
    // the Dart VM/isolate shuts down, which would invalidate NativeCallables.
    if (_presenceInstance != null) {
      await cleanupPresence(_presenceInstance!);
    }

    if (_transportConditionsInstance != null) {
      await cleanupTransportConditions(_transportConditionsInstance!);
    }

    if (_authInstance != null) {
      await cleanupAuth(_authInstance!);
    }

    // Kill the per-Ditto execute worker isolate before tearing down the
    // log callback or freeing the FFI handle. Two reasons:
    //   (1) the worker awaits its current FFI call before exiting, so any
    //       log events that FFI call emits land while the log callback is
    //       still alive (avoids the SDKS-3630 SIGABRT class on long calls);
    //   (2) the worker holds the same `Ditto*` address the main isolate
    //       does, so it must finish before `ditto_free` runs (SDKS-3879).
    await core.disposeExecuteWorker(_ptrDoNotUseExceptInClose);

    // Clean up the global custom log callback before shutdown to prevent
    // SIGABRT when a native log event lands on a closed NativeCallable
    // during isolate teardown (SDKS-3630).
    await cleanupLogger();

    await core.dittoShutdown(_ptrDoNotUseExceptInClose);
    core.dittoFree(_ptrDoNotUseExceptInClose);
  }
}

var _initSdkVersionAlreadyCalled = false;

void _initSdkVersion() {
  if (_initSdkVersionAlreadyCalled) return;

  core.dittoInitSdkVersion();

  _initSdkVersionAlreadyCalled = true;
}

@internal
extension PrivateDittoPtrExtension on Ditto {
  /// Do not store this pointer in a local variable that might cross an async
  /// gap.
  ///
  /// Always call `_ditto.ptrDoNotStore` to avoid caching a pointer to ditto in
  /// a local variable that might later be invalidated by a call to `.close()`
  ///
  /// This is checked by a linter rule
  core.CPPointer<core.CPDitto> get ptr {
    if (isClosed) {
      throw DittoClosedException();
    }
    return _ptrDoNotUseExceptInClose;
  }
}

({Uint8List configCbor, core.CPTransportConfigMode mode, String rootDir})
    _constructorPreamble(DittoConfig config) {
  privateCheckDittoInit();
  // Re-arm the log callback in case a previous Ditto.close() tore it down
  // (SDKS-3630). No-op when already registered.
  privateSetupLogCallback();
  _initSdkVersion();

  final configJson = config.toJson();

  // SDKS-3187: When the user hasn't set an explicit persistence directory,
  // provide the v4 default path as a fallback so that v4→v5 upgrades don't
  // silently create a new empty database. The v4 Flutter default was
  // "{documentsDirectory}/ditto" (no database-id in the path).
  if (config.persistenceDirectory == null) {
    final docsDir = Globals.instance.documentsDirectory;
    if (docsDir != null) {
      configJson["legacy_persistence_directory"] = "$docsDir/ditto";
    }
  }

  final configCbor = Uint8List.fromList(
    // ignore: avoid_dynamic_calls
    cbor.encode(toEncodable: (obj) => obj.toJson(), configJson),
  );
  const mode = core.CPTransportConfigMode.platformDependent;
  final rootDir = switch (Ditto.currentPlatform) {
    SupportedPlatform.web => "",
    _ => Globals.instance.documentsDirectory!,
  };

  return (configCbor: configCbor, mode: mode, rootDir: rootDir);
}

Ditto _constructorPostamble(core.CPPointer<core.CPDitto> dittoPtr) {
  final ditto = Ditto._(dittoPtr, Globals.instance.deviceName);
  Registry.instance.registerDitto(ditto);
  return ditto;
}
