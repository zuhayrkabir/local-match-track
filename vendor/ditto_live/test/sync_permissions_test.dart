import "package:ditto_live/ditto_live.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(DittoSyncPermissions.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  group("DittoSyncPermissions on Android", () {
    late DittoSyncPermissions syncPermissions;

    setUp(() {
      syncPermissions =
          DittoSyncPermissions.forPlatform(SupportedPlatform.android);
    });

    test("requiredPermissions invokes method channel and casts result",
        () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return <Object?>[
          "android.permission.BLUETOOTH_CONNECT",
          "android.permission.BLUETOOTH_SCAN",
          "android.permission.BLUETOOTH_ADVERTISE",
        ];
      });

      final permissions = await syncPermissions.requiredPermissions();

      expect(calls, hasLength(1));
      expect(
        calls.single.method,
        DittoSyncPermissions.getRequiredPermissionsMethod,
      );
      expect(permissions, [
        "android.permission.BLUETOOTH_CONNECT",
        "android.permission.BLUETOOTH_SCAN",
        "android.permission.BLUETOOTH_ADVERTISE",
      ]);
    });

    test("requiredPermissions returns empty list when channel returns null",
        () async {
      messenger.setMockMethodCallHandler(channel, (call) async => null);

      final permissions = await syncPermissions.requiredPermissions();

      expect(permissions, isEmpty);
    });

    test("missingPermissions without args passes empty argument map", () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return <Object?>["android.permission.BLUETOOTH_CONNECT"];
      });

      final missing = await syncPermissions.missingPermissions();

      expect(calls, hasLength(1));
      expect(
        calls.single.method,
        DittoSyncPermissions.getMissingPermissionsMethod,
      );
      expect(calls.single.arguments, <String, dynamic>{});
      expect(missing, ["android.permission.BLUETOOTH_CONNECT"]);
    });

    test("missingPermissions forwards explicit permissions argument", () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return <Object?>["android.permission.BLUETOOTH_SCAN"];
      });

      final missing = await syncPermissions.missingPermissions([
        "android.permission.BLUETOOTH_SCAN",
      ]);

      expect(calls, hasLength(1));
      expect(
        calls.single.method,
        DittoSyncPermissions.getMissingPermissionsMethod,
      );
      expect(calls.single.arguments, {
        "permissions": ["android.permission.BLUETOOTH_SCAN"],
      });
      expect(missing, ["android.permission.BLUETOOTH_SCAN"]);
    });

    test("requiredPermissions swallows PlatformException and returns empty",
        () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: "ERROR", message: "boom");
      });

      final permissions = await syncPermissions.requiredPermissions();
      expect(permissions, isEmpty);
    });

    test("missingPermissions swallows PlatformException and returns empty",
        () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: "ERROR", message: "boom");
      });

      final missing = await syncPermissions.missingPermissions();
      expect(missing, isEmpty);
    });

    // Negative-space: characterizes what the wrapper does when the native side
    // throws something other than PlatformException. Flutter's MethodChannel
    // test infrastructure wraps ANY throw at the mock handler in a
    // PlatformException, so the wrapper's `on PlatformException catch`
    // swallows even Dart Errors (StateError, ArgumentError) and returns an
    // empty list. Arguably a bug — Errors usually indicate programmer
    // mistakes that shouldn't be silently masked — but it is the current
    // behavior, and pinning it down here means a future change to the
    // wrapper's catch shape will fail this test instead of silently shifting
    // the contract.
    test("requiredPermissions silently swallows non-Exception Errors",
        () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw StateError("native plugin returned an unexpected state");
      });

      final permissions = await syncPermissions.requiredPermissions();
      expect(permissions, isEmpty);
    });

    test("missingPermissions silently swallows non-Exception Errors", () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw StateError("native plugin returned an unexpected state");
      });

      final missing = await syncPermissions.missingPermissions();
      expect(missing, isEmpty);
    });

    // Negative-space: if the platform side returns a non-list (a single string,
    // a map, etc.) the wrapper's `invokeMethod<List<Object?>>` raises a typed
    // exception. Pinning that down here means a future change to the wrapper
    // signature (e.g. accepting `dynamic`) will fail this test loudly instead
    // of silently letting garbage propagate.
    test("requiredPermissions throws on non-list channel result", () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return "not-a-list";
      });

      await expectLater(
        syncPermissions.requiredPermissions(),
        throwsA(isA<TypeError>()),
      );
    });

    // The cast `result.cast<String>()` is lazy — type mismatches surface when
    // the caller iterates, not at the wrapper boundary. Documented here so
    // future changes that intend to make the validation eager don't silently
    // regress.
    test("requiredPermissions returns lazy cast view of non-string elements",
        () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return <Object?>[42, "android.permission.BLUETOOTH_CONNECT"];
      });

      final permissions = await syncPermissions.requiredPermissions();
      // Iterating the cast view is where the type error lands.
      expect(permissions.toList, throwsA(isA<TypeError>()));
    });
  });

  group("DittoSyncPermissions on non-Android platforms", () {
    for (final platform in [
      SupportedPlatform.ios,
      SupportedPlatform.linux,
      SupportedPlatform.macos,
      SupportedPlatform.web,
      SupportedPlatform.windows,
    ]) {
      test("$platform: both methods short-circuit without touching the channel",
          () async {
        var invoked = false;
        messenger.setMockMethodCallHandler(channel, (call) async {
          invoked = true;
          return <Object?>["should.not.be.returned"];
        });

        final syncPermissions = DittoSyncPermissions.forPlatform(platform);

        expect(await syncPermissions.requiredPermissions(), isEmpty);
        expect(await syncPermissions.missingPermissions(), isEmpty);
        expect(invoked, isFalse);
      });
    }
  });
}
