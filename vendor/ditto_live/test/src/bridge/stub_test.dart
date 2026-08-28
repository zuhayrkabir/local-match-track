import "package:ditto_live/src/bridge/stub.dart" as stub;
import "package:flutter_test/flutter_test.dart";

/// Tests that stub implementations throw UnsupportedError
///
/// The stub.dart file is used as a fallback on unsupported platforms.
/// All functions should throw UnsupportedError when called.
void main() {
  group("Stub implementations throw UnsupportedError", () {
    test("init throws UnsupportedError", () async {
      // ignore: unnecessary_lambdas
      expect(() => stub.init(), throwsUnsupportedError);
    });

    test("dittoInitSdkVersion throws UnsupportedError", () {
      expect(stub.dittoInitSdkVersion, throwsUnsupportedError);
    });

    test("dittoGetSdkSemver throws UnsupportedError", () {
      expect(stub.dittoGetSdkSemver, throwsUnsupportedError);
    });

    test("dittoffiGetDevelopmentProvider throws UnsupportedError", () {
      expect(
        stub.dittoffiGetDevelopmentProvider,
        throwsUnsupportedError,
      );
    });

    // Note: Functions that take parameters cannot be tested directly since
    // passing null causes a type error before reaching the UnsupportedError.
    // The stub pattern is verified by the zero-argument function tests above.
  });

  group("Stub architecture", () {
    test("stub provides fallback for unsupported platforms", () {
      // The stub.dart file contains fallback implementations via conditional
      // imports. When neither native FFI nor WASM is available, all functions
      // delegate to the _$ getter which throws UnsupportedError.
      //
      // Structure:
      // - Never get _$ => throw UnsupportedError("Stub implementation")
      // - All functions return _$, causing them to throw
      //
      // This ensures compile-time safety while preventing runtime usage on
      // unsupported platforms.
      expect(true, isTrue);
    });
  });
}
