import "dart:async";
import "dart:developer";

import "package:meta/meta.dart";

import "../ditto_live.dart";
import "analysis/annotations.dart";
import "bridge/bridge.dart" as core;
import "ditto.dart";

/// A class with static methods to customize the logging behavior for Ditto.
///
/// Ditto currently uses the persistence directory of the most recently created
/// Ditto instance to store a limited amount of logs. Logs may continue to be
/// written to a persistence directory even after the associated Ditto instance
/// has been deallocated. If this poses a concern, consider either disabling
/// logging by setting [DittoLogger.isEnabled], or by instantiating a new Ditto
/// instance. Once either of these actions is taken, it is safe to remove the
/// persistence directory.
///
/// Refer to [DittoLogger.exportLogs] for more details on locally-collected
/// logs.
@external
abstract final class DittoLogger {
  DittoLogger._();

  /// Whether logging is currently enabled.
  ///
  /// Logs exported through [exportLogs] are not affected by this setting
  /// and will also include logs emitted while [isEnabled] is false.
  @DittoEntrypoint()
  static bool get isEnabled {
    privateCheckDittoInit();
    return core.dittoLoggerEnabledGet();
  }

  static set isEnabled(bool value) {
    privateCheckDittoInit();
    core.dittoLoggerEnabled(isEnabled: value);
  }

  /// The minimum log level at which logs will be recorded.
  ///
  /// This setting controls the granularity of logs captured. Setting a higher level will reduce
  /// the volume of logs by only capturing more severe events.
  @DittoEntrypoint()
  static LogLevel get minimumLogLevel {
    privateCheckDittoInit();
    return core.dittoLoggerMinimumLogLevelGet();
  }

  static set minimumLogLevel(LogLevel level) {
    privateCheckDittoInit();
    core.dittoLoggerMinimumLogLevel(level);
  }

  static void Function(LogLevel, String)? _customLogCallback;

  /// A custom log callback that is called whenever Ditto emits a log event
  ///
  /// This allows for a fully customizable way of handling log events from the logger,
  /// in addition to logging to the console and to a file, if configured.
  @DittoEntrypoint()
  static void Function(LogLevel, String)? get customLogCallback {
    privateCheckDittoInit();
    return _customLogCallback;
  }

  static set customLogCallback(void Function(LogLevel, String)? value) {
    privateCheckDittoInit();
    _customLogCallback = value;
  }

  // Tracks the native-side freeable (NativeCallable on native; null on web)
  // returned by registering the FFI log callback. Owned by [DittoLogger] so
  // [_cleanup] can close the NativeCallable before the isolate tears down,
  // preventing SIGABRT when in-flight callbacks land on a closed callable
  // (SDKS-3630, same crash class as SDKS-3134).
  static core.CPFreeable? _logCallbackFreeable;
  static var _hasSetLogCallback = false;
  static var _isShuttingDown = false;

  static void _setLogCallbackOnce() {
    if (_hasSetLogCallback) return;
    _hasSetLogCallback = true;
    _isShuttingDown = false;
    _logCallbackFreeable = core.dittoLoggerSetCustomLogCb(_logCallbackImpl);
  }

  static var _developerLog = false;

  /// If enabled, logs emitted by Ditto will be sent to Devtools using [log] from `dart:developer`
  @DartSpecific("Flutter devtools are only available on Flutter")
  @DittoEntrypoint()
  static bool get isDevtoolsLoggingEnabled {
    privateCheckDittoInit();
    return _developerLog;
  }

  static set isDevtoolsLoggingEnabled(bool enabled) {
    privateCheckDittoInit();
    _setLogCallbackOnce();
    _developerLog = enabled;
  }

  static var _developerLogSeq = 0;
  static void _logCallbackImpl(LogLevel level, String message) {
    // Guard against callbacks arriving during/after shutdown (SDKS-3630).
    // Mirrors the presence cleanup pattern from SDKS-3134: the native side
    // may have queued callbacks that land here after `_cleanup` told it to
    // stop but before the NativeCallable is closed.
    if (_isShuttingDown) return;

    if (_developerLog) {
      _developerLogSeq++;
      log(
        message,
        time: DateTime.now(),
        name: "ditto_live",
        sequenceNumber: _developerLogSeq,
        // these are copied from https://pub.dev/documentation/logging/latest/logging/Level-class.html
        level: switch (level) {
          LogLevel.error => 1000,
          LogLevel.warning => 900,
          LogLevel.info => 800,
          LogLevel.debug => 500,
          LogLevel.verbose => 400,
        },
      );
    }

    customLogCallback?.call(level, message);
  }

  /// Indicates if emojis are used in log messages to represent the log level.
  ///
  /// This is purely cosmetic and helps in quickly identifying the severity of log messages in visual representations.
  @DittoEntrypoint()
  static bool get isEmojiLogLevelHeadingsEnabled {
    privateCheckDittoInit();
    return core.dittoLoggerEmojiHeadingsEnabledGet();
  }

  static set isEmojiLogLevelHeadingsEnabled(bool enabled) {
    privateCheckDittoInit();
    core.dittoLoggerEmojiHeadingsEnabled(isEnabled: enabled);
  }

  /// Exports collected logs to a compressed and JSON-encoded file on the
  /// local file system.
  ///
  /// Returns the number of bytes written to disk.
  ///
  /// [DittoLogger] locally collects a limited amount of logs at
  /// [LogLevel.debug] level and above, periodically discarding old logs.
  /// This internal logger is always enabled and works independently of the
  /// [isEnabled] setting and the configured [minimumLogLevel]. Its logs can
  /// be requested and downloaded from any peer that is active in a Ditto app
  /// using the portal's device dashboard. This method provides an alternative
  /// way of accessing those logs by exporting them to the local file system.
  ///
  /// The logs will be written as a gzip compressed file at the file path specified
  /// by the [filePath] parameter. When uncompressed, the file contains one
  /// JSON value per line with the oldest entry on the first line (JSON lines
  /// format).
  ///
  /// By default, Ditto limits the amount of logs it retains on disk to 15 MB
  /// and a maximum age of 15 days. Older logs are periodically discarded once
  /// one of these limits is reached.
  ///
  /// This method currently only exports logs from the most recently created
  /// Ditto instance, even when multiple instances are running in the same
  /// process.
  ///
  /// [filePath] specifies the location to write the logs to. The file
  /// must not already exist, and the containing directory must exist. It is
  /// recommended for the [filePath] to have the `.jsonl.gz` file extension
  /// but Ditto won't enforce it, nor correct it.
  ///
  /// Throws a [DittoError] when the file cannot be written to
  /// disk. Prevent this by ensuring that no file exists at the provided
  /// file path, all parent directories exist, sufficient permissions are
  /// granted, and that the disk is not full.
  @DittoEntrypoint()
  static Future<int> exportLogs(String filePath) {
    privateCheckDittoInit();
    return core.dittoFfiLoggerTryExportToFileAsync(filePath).extract();
  }

  /// Tear down the native log callback before the Dart isolate shuts down.
  ///
  /// To prevent SIGABRT from a native callback landing on a closed
  /// `NativeCallable` (SDKS-3630, same crash class as SDKS-3134), the cleanup
  /// must be sequenced:
  /// 1. Set `_isShuttingDown` so any in-flight callback becomes a no-op.
  /// 2. Clear the user-supplied callback so it cannot be re-entered.
  /// 3. Tell native to stop sending callbacks
  ///    (`ditto_logger_set_custom_log_cb(nullptr)`).
  /// 4. Wait for in-flight callbacks to drain.
  /// 5. Close the `NativeCallable` via the stored freeable.
  ///
  /// After cleanup, `_setLogCallbackOnce` can re-register the native callback
  /// — done by `_constructorPreamble` in `ditto.dart` so the next
  /// [Ditto.open] / [Ditto.openSync] re-arms logging without forcing the
  /// caller to re-run [Ditto.init].
  static Future<void> _cleanup() async {
    if (!_hasSetLogCallback) return;

    _isShuttingDown = true;
    _customLogCallback = null;

    // Tell native to stop sending callbacks. Returns null on native because
    // we passed null; the existing freeable is the one we already hold.
    // Pass null explicitly: the wasm binding takes a required positional
    // parameter, so the stub/native default-value forms don't apply.
    // ignore: avoid_redundant_argument_values
    core.dittoLoggerSetCustomLogCb(null);

    // Wait for in-flight callbacks to land and be safely ignored via the
    // shutdown flag. Empirical drain window — matches the presence cleanup
    // margin (SDKS-3134). The legacy "noop retain/release" registration
    // gives no signal for when in-flight callback messages have been
    // dispatched; the modern observer-handle FFI pattern would replace
    // this with a deterministic `free` ack. Tracked: SDKS-3762.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final freeable = _logCallbackFreeable;
    _logCallbackFreeable = null;
    _hasSetLogCallback = false;
    _isShuttingDown = false;
    freeable?.free();
  }
}

@internal
void privateSetupLogCallback() {
  DittoLogger._setLogCallbackOnce();
}

@internal
Future<void> cleanupLogger() => DittoLogger._cleanup();
