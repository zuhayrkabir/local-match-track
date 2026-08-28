import "package:ditto_live/ditto_live.dart";
import "package:flutter_test/flutter_test.dart";

/// Pure-Dart unit tests for the parts of [Store] that do not cross the FFI
/// boundary. The FFI-crossing surface (execute, transaction, observers,
/// attachments) is exercised by the integration suite in
/// `ditto_test/lib/store/cross_platform.dart`; this file pins the logic that
/// can be verified without opening a [Ditto].
void main() {
  group("Store.experimentalSkipExecuteIsolateOffload", () {
    // The flag is process-global and persists across the lifetime of the
    // isolate, so snapshot and restore it around every test to keep cases
    // independent regardless of ordering.
    late bool original;

    setUp(() {
      original = Store.experimentalSkipExecuteIsolateOffload;
    });

    tearDown(() {
      Store.experimentalSkipExecuteIsolateOffload = original;
    });

    test("defaults to false", () {
      // setUp has already snapshotted whatever the live default is. Assert
      // without mutating first — a write here would mask a regression of
      // the compiled default in the bridge global.
      expect(Store.experimentalSkipExecuteIsolateOffload, isFalse);
    });

    test("setter round-trips through the getter", () {
      Store.experimentalSkipExecuteIsolateOffload = true;
      expect(Store.experimentalSkipExecuteIsolateOffload, isTrue);

      Store.experimentalSkipExecuteIsolateOffload = false;
      expect(Store.experimentalSkipExecuteIsolateOffload, isFalse);
    });

    test("setting the same value repeatedly is stable", () {
      Store.experimentalSkipExecuteIsolateOffload = true;
      Store.experimentalSkipExecuteIsolateOffload = true;
      expect(Store.experimentalSkipExecuteIsolateOffload, isTrue);
    });
  });
}
