// ignore_for_file: ditto_missing_visibility
part of "wasm.dart";

/// Provides access to Ditto WebAssembly functions.
_DittoCore get _dittoCore {
  if (!_isWasmInitialized) {
    if (_isCurrentlyInitializingWasm) {
      throw Exception(
        "Unable to access Ditto WebAssembly while it is being initialized. "
        "Always await `Ditto.init()` before using any other Ditto features.",
      );
    } else {
      throw Exception(
        "Unable to access Ditto WebAssembly before it has been initialized. "
        "Please refer to the documentation of the `Ditto.init()` function.",
      );
    }
  }
  return _uncheckedDittoCore;
}

/// Avoid using this and prefer the `_dittoCore` getter instead, which makes
/// sure that the WebAssembly module has been initialized before accessing it.
late _DittoCore _uncheckedDittoCore;
bool _isCurrentlyInitializingWasm = false;
bool _isWasmInitialized = false;

Future<void> init({String? wasmUrl, String? wasmShimUrl}) async {
  if (_isCurrentlyInitializingWasm) {
    throw Exception("Ditto WebAssembly is already being initialized.");
  }
  if (_isWasmInitialized) return;
  _isCurrentlyInitializingWasm = true;

  try {
    final assetPath =
        wasmShimUrl ?? "/assets/packages/ditto_live/lib/assets/ditto.wasm.js";

    // The following is a workaround for the `importModule` function having
    // changed the type of its parameter from `String` to `JSAny` in Dart 3.5.0.
    // We don't want to break compatibility with older Dart versions.

    _uncheckedDittoCore = _DittoCore(
      switch (importModule) {
        // ignore: dead_code, unreachable_switch_case
        final JSPromise<JSObject> Function(String) f =>
          await f(assetPath).toDart,
        // ignore: dead_code, unreachable_switch_case
        final JSPromise<JSObject> Function(JSAny) f =>
          await f(assetPath.toJS).toDart,
      },
    );

    final webAssemblyModule =
        wasmUrl != null ? wasmUrl.toJS : await _loadWasmFromAssets();
    await _uncheckedDittoCore.init(webAssemblyModule).toDart;
  } catch (e) {
    throw Exception("Failed to initialize Ditto WebAssembly: $e");
  } finally {
    _isCurrentlyInitializingWasm = false;
  }
  _isWasmInitialized = true;

  final semVer = bytesFromString(privateSdkVersion);
  _dittoCore.dittoInitSdkVersion("Web".toJS, "Flutter".toJS, semVer.toJS);
}

Future<JSArrayBuffer> _loadWasmFromAssets() async {
  const assetPath = "packages/ditto_live/lib/assets/ditto.wasm";
  final byteData = await rootBundle.load(assetPath);
  return byteData.buffer.toJS;
}
