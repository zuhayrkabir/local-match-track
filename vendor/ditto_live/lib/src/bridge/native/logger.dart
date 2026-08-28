// ignore_for_file: ditto_missing_visibility
part of "native.dart";

bool dittoLoggerEnabledGet() => bindings.ditto_logger_enabled_get();
void dittoLoggerEnabled({required bool isEnabled}) =>
    bindings.ditto_logger_enabled(isEnabled);

LogLevel dittoLoggerMinimumLogLevelGet() =>
    _intToLogLevel(bindings.ditto_logger_minimum_log_level_get());
void dittoLoggerMinimumLogLevel(LogLevel logLevel) =>
    bindings.ditto_logger_minimum_log_level(_logLevelToInt(logLevel));

bool dittoLoggerEmojiHeadingsEnabledGet() =>
    bindings.ditto_logger_emoji_headings_enabled_get();
void dittoLoggerEmojiHeadingsEnabled({required bool isEnabled}) =>
    bindings.ditto_logger_emoji_headings_enabled(isEnabled);

void dittoLog(LogLevel level, String message) {
  withStringAsPtr(
    message,
    (msgPtr) => bindings.ditto_log(_logLevelToInt(level), msgPtr),
  );
}

Future<CPResult<int>> dittoFfiLoggerTryExportToFileAsync(
  String filePath,
) =>
    withStringAsPtr(filePath, (filePathPtr) async {
      final completer = Completer<CPResult<int>>();

      void onCall(Pointer<Void> ctx, dittoffi_result_uint64 res) {
        if (res.error != nullptr) {
          final error = privateMakeFfiError(res.error);
          completer.complete(CPResult.legacyError(error));
        } else {
          completer.complete(CPResult.legacyOk(res.success));
        }
      }

      final onCallCb = NativeCallable<
          Void Function(
            Pointer<Void>,
            dittoffi_result_uint64,
          )>.listener(onCall);

      final completion = calloc<BoxDynFnMut1_void_dittoffi_result_uint64>();
      completion.ref.call = onCallCb.nativeFunction;
      // See doc_internal/src/architecture/core_api.md "Ref Count and Ownership"
      completion.ref.free = bindings.dittoffi_get_noop_void_ptr_fn();
      completion.ref.env_ptr = dummyNonNullPointer;

      bindings.dittoffi_logger_try_export_to_file_async(
        filePathPtr,
        completion.ref,
      );

      final res = await completer.future;

      onCallCb.close();
      calloc.free(completion);

      return res;
    });

CPFreeable? dittoLoggerSetCustomLogCb([
  void Function(LogLevel level, String message)? callback,
]) {
  if (callback == null) {
    bindings.ditto_logger_set_custom_log_cb(nullptr);
    return null;
  }

  void cb(int levelInt, Pointer<Char> messagePtr) {
    final level = _intToLogLevel(levelInt);
    final message = messagePtr.cast<Utf8>().toDartString();
    bindings.ditto_c_string_free(messagePtr);

    callback(level, message);
  }

  final callable =
      NativeCallable<Void Function(Int32, Pointer<Char>)>.listener(cb);

  bindings.ditto_logger_set_custom_log_cb(callable.nativeFunction);
  return NativeCallableFreeable(callable);
}

int _logLevelToInt(LogLevel level) => switch (level) {
      LogLevel.error => CLogLevel.C_LOG_LEVEL_ERROR,
      LogLevel.warning => CLogLevel.C_LOG_LEVEL_WARNING,
      LogLevel.info => CLogLevel.C_LOG_LEVEL_INFO,
      LogLevel.debug => CLogLevel.C_LOG_LEVEL_DEBUG,
      LogLevel.verbose => CLogLevel.C_LOG_LEVEL_VERBOSE,
    };

LogLevel _intToLogLevel(int level) => switch (level) {
      CLogLevel.C_LOG_LEVEL_ERROR => LogLevel.error,
      CLogLevel.C_LOG_LEVEL_WARNING => LogLevel.warning,
      CLogLevel.C_LOG_LEVEL_INFO => LogLevel.info,
      CLogLevel.C_LOG_LEVEL_DEBUG => LogLevel.debug,
      CLogLevel.C_LOG_LEVEL_VERBOSE => LogLevel.verbose,
      _ => throw privateMakeDittoError("unknown log level: $level"),
    };
