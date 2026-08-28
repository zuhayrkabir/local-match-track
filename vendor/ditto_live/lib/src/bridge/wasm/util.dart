// ignore_for_file: ditto_missing_visibility
part of "wasm.dart";

/// Convert a string to a null terminated Uint8List.
Uint8List bytesFromString(String string) {
  final codeUnits = Uint8List.fromList(string.codeUnits);
  final result = Uint8List(codeUnits.length + 1)
    ..setAll(0, codeUnits)
    ..[codeUnits.length] = 0; // Append null terminator
  return result;
}

void _defaultBackgroundErrorHandler(Object err, StackTrace stackTrace) {
  dittoLog(
    LogLevel.error,
    "The registered callback failed with $err\n$stackTrace",
  );
}

/// Wrap a callback so that it transmits its return value to FFI by calling a
/// provided return sender function.
///
/// The callback wrapper is called from Ditto FFI with a dynamic number of
/// arguments which we can't model using a spread operator like in JavaScript so
/// this implementation accepts up to four arguments and ignores the rest.
///
/// The callback is run in a guarded zone. If no [onBackgroundError] handler is provided,
/// the default implementation will print all errors to the Ditto logger
///
/// If [onBackgroundError] is explicitly set to `null`, then this is not
/// considered a "background" callback, and no error catching is attempted
JSFunction wrapBackgroundCbForFFI(
  Function cb, {
  void Function(Object err, StackTrace stackTrace)? onBackgroundError =
      _defaultBackgroundErrorHandler,
}) {
  // Wrapping the Dart callback with error handling logic and returning a JS function
  return ((
    JSFunction returnSender, [
    JSAny? arg0,
    JSAny? arg1,
    JSAny? arg2,
    JSAny? arg3,
    JSAny? overflowArg,
  ]) {
    void runCallback() {
      if (overflowArg != null) {
        throw ArgumentError(
          "The callback wrapper supports up to four arguments but has been called with at least five arguments.",
        );
      }

      final args = [
        if (arg0 != null) arg0,
        if (arg1 != null) arg1,
        if (arg2 != null) arg2,
        if (arg3 != null) arg3,
      ];

      // We don't know whether the callback is synchronous or asynchronous, but since
      // we handle the result using a continuation we can handle both cases by converting
      // the return value to a Future. If the callback is a Future and throws, the error
      // will still be caught by the zone error handler.
      Future.sync(() => Function.apply(cb, args)).then(
        (returnValue) => returnSender.callAsFunction(
          null,
          _jsifyObjectWithEnumeratedType(returnValue),
        ),
      );
    }

    if (onBackgroundError == null) {
      return runCallback();
    }

    return runZonedGuarded(
      runCallback,
      onBackgroundError,
    );
  }).toJS;
}

Future<String> utilsMakePersistenceDirectory(
  String path, {
  bool createIfMissing = true,
}) async =>
    path;

Future<String> utilDefaultDeviceName() => Future.value("Flutter Web");

/// A weak map implementation that uses weak references for values.
// IDEA: implement operator [] and []= to make it more map-like
class _WeakMap<K extends Object, V extends Object> {
  final Map<K, WeakReference<V>> _map = {};

  void set(K key, V value) {
    _map[key] = WeakReference(value);
  }

  V? get(K key) {
    final weakValue = _map[key];
    if (weakValue?.target == null) {
      remove(key);
    }
    return weakValue?.target;
  }

  void remove(K key) {
    _map.remove(key);
  }

  int get length {
    _map.removeWhere((key, value) => value.target == null);
    return _map.length;
  }
}

/// This is a custom reimplementation of `jsify()` from `dart:js_util`
///
/// It should only be used in contexts where we are aware of the full set of
/// possible types it will be called with. In other words, do not allow a
/// user-provided callback to return an object which is passed into this
/// function.
///
/// We don't use that function because importing `dart:js_util` prevents
/// compilation to a Wasm-based Flutter Web app (i.e. where Dart code is
/// compiled to Wasm rather than JS)
///
/// The use of that function is disouraged generally in this PR:
/// https://github.com/dart-lang/sdk/issues/55222
JSAny? _jsifyObjectWithEnumeratedType(Object? dartObj) {
  if (dartObj == null) return null;
  if (dartObj is bool) return dartObj.toJS;
  if (dartObj is int) return dartObj.toJS;
  if (dartObj is double) return dartObj.toJS;
  if (dartObj is String) return dartObj.toJS;
  if (dartObj is List) return dartObj.jsify();
  if (dartObj is Map) return dartObj.jsify();

  throw privateMakeDittoError("attempted to jsify unknown type");
}
