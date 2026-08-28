// ignore_for_file: ditto_missing_visibility
part of "wasm.dart";

Future<CPResult<int>> dittoFfiLoggerTryExportToFileAsync(String filePath) =>
    _noWebSupport$;

bool dittoLoggerEnabledGet() => _dittoCore.dittoLoggerEnabledGet().toDart;

void dittoLoggerEnabled({required bool isEnabled}) =>
    _dittoCore.dittoLoggerEnabled(isEnabled.toJS);

LogLevel dittoLoggerMinimumLogLevelGet() => _logLevelFromJS(
      _dittoCore.dittoLoggerMinimumLogLevelGet(),
    );

void dittoLoggerMinimumLogLevel(LogLevel logLevel) =>
    _dittoCore.dittoLoggerMinimumLogLevel(_logLevelToJS(logLevel));

bool dittoLoggerEmojiHeadingsEnabledGet() =>
    _dittoCore.dittoLoggerEmojiHeadingsEnabledGet().toDart;

void dittoLoggerEmojiHeadingsEnabled({required bool isEnabled}) =>
    _dittoCore.dittoLoggerEmojiHeadingsEnabled(isEnabled.toJS);

CPFreeable? dittoLoggerSetCustomLogCb(
  void Function(LogLevel level, String message)? callback,
) {
  if (callback == null) {
    // Explicit null argument is required here because null != undefined
    _dittoCore.dittoLoggerSetCustomLogCb(null);
    return null;
  }

  final wrappedCallback = wrapBackgroundCbForFFI(
    (JSString logLevel, _JSPointer<CPCString> messagePointer) {
      final level = _logLevelFromJS(logLevel);
      final message = _dittoCore.boxCStringIntoString(messagePointer)!.toDart;
      try {
        callback(level, message);
      } catch (e) {
        dittoLog(LogLevel.error, "Error in custom log callback: $e");
      }
    },
  );

  _dittoCore.dittoLoggerSetCustomLogCb(wrappedCallback);

  return null;
}

void dittoLog(LogLevel level, String message) {
  final messageBytes = bytesFromString(message);
  final levelJS = _logLevelToJS(level);
  _dittoCore.dittoLog(levelJS, messageBytes.toJS);
}

LogLevel _logLevelFromJS(JSString level) {
  switch (level.toDart) {
    case "Error":
      return LogLevel.error;
    case "Warning":
      return LogLevel.warning;
    case "Info":
      return LogLevel.info;
    case "Debug":
      return LogLevel.debug;
    case "Verbose":
      return LogLevel.verbose;
    default:
      throw ArgumentError("Invalid JS log level: $level");
  }
}

JSString _logLevelToJS(LogLevel level) {
  switch (level) {
    case LogLevel.error:
      return "Error".toJS;
    case LogLevel.warning:
      return "Warning".toJS;
    case LogLevel.info:
      return "Info".toJS;
    case LogLevel.debug:
      return "Debug".toJS;
    case LogLevel.verbose:
      return "Verbose".toJS;
  }
}
