import "package:ditto_live/ditto_live.dart" show ConnectionRequestAuthorization;
import "package:ditto_live/src/bridge/cross_platform/connection_request_lifecycle.dart";
import "package:ditto_live/src/bridge/cross_platform/types.dart";
import "package:flutter_test/flutter_test.dart";

class _FakeRequest implements CPPointer<CPConnectionRequest> {
  @override
  final int address = 0xDEAD;
}

class _Spy {
  final List<ConnectionRequestAuthorization> authorizeCalls = [];
  int freeCalls = 0;
  final List<Object> errors = [];

  void authorize(
    CPPointer<CPConnectionRequest> _,
    ConnectionRequestAuthorization auth,
  ) {
    authorizeCalls.add(auth);
  }

  void free(CPPointer<CPConnectionRequest> _) {
    freeCalls++;
  }

  void onError(Object e, StackTrace _) {
    errors.add(e);
  }
}

void main() {
  group("runConnectionRequestHandler", () {
    test("authorizes and frees on handler success (allow)", () async {
      final spy = _Spy();
      await runConnectionRequestHandler(
        request: _FakeRequest(),
        handler: (_) async => ConnectionRequestAuthorization.allow,
        authorize: spy.authorize,
        free: spy.free,
        onError: spy.onError,
      );
      expect(spy.authorizeCalls, [ConnectionRequestAuthorization.allow]);
      expect(spy.freeCalls, 1);
      expect(spy.errors, isEmpty);
    });

    test("authorizes and frees on handler success (deny)", () async {
      final spy = _Spy();
      await runConnectionRequestHandler(
        request: _FakeRequest(),
        handler: (_) async => ConnectionRequestAuthorization.deny,
        authorize: spy.authorize,
        free: spy.free,
        onError: spy.onError,
      );
      expect(spy.authorizeCalls, [ConnectionRequestAuthorization.deny]);
      expect(spy.freeCalls, 1);
      expect(spy.errors, isEmpty);
    });

    test("denies and frees when the handler throws synchronously", () async {
      final spy = _Spy();
      final boom = Exception("sync throw");
      await runConnectionRequestHandler(
        request: _FakeRequest(),
        handler: (_) => throw boom,
        authorize: spy.authorize,
        free: spy.free,
        onError: spy.onError,
      );
      expect(spy.authorizeCalls, [ConnectionRequestAuthorization.deny]);
      expect(spy.freeCalls, 1);
      expect(spy.errors, [boom]);
    });

    test("denies and frees when the handler rejects asynchronously", () async {
      final spy = _Spy();
      final boom = Exception("async reject");
      await runConnectionRequestHandler(
        request: _FakeRequest(),
        handler: (_) async => throw boom,
        authorize: spy.authorize,
        free: spy.free,
        onError: spy.onError,
      );
      expect(spy.authorizeCalls, [ConnectionRequestAuthorization.deny]);
      expect(spy.freeCalls, 1);
      expect(spy.errors, [boom]);
    });

    test("frees even when authorize itself throws", () async {
      final spy = _Spy();
      final boom = Exception("authorize failed");
      await runConnectionRequestHandler(
        request: _FakeRequest(),
        handler: (_) async => ConnectionRequestAuthorization.allow,
        authorize: (_, __) => throw boom,
        free: spy.free,
        onError: spy.onError,
      );
      expect(spy.freeCalls, 1);
      expect(spy.errors, [boom]);
    });

    test("calls authorize before free", () async {
      final order = <String>[];
      await runConnectionRequestHandler(
        request: _FakeRequest(),
        handler: (_) async => ConnectionRequestAuthorization.allow,
        authorize: (_, __) => order.add("authorize"),
        free: (_) => order.add("free"),
        onError: (_, __) {},
      );
      expect(order, ["authorize", "free"]);
    });
  });
}
