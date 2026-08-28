import "package:ditto_live/src/bridge/cross_platform/freeable.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("CPDartFnFreeable", () {
    test("free calls the provided function", () {
      var called = false;
      final freeable = CPDartFnFreeable(() {
        called = true;
      });

      expect(called, isFalse);
      freeable.free();
      expect(called, isTrue);
    });

    test("free can be called multiple times", () {
      var callCount = 0;
      final freeable = CPDartFnFreeable(() {
        callCount++;
      });

      // ignore: cascade_invocations
      freeable
        ..free()
        ..free()
        ..free();
      expect(callCount, equals(3));
    });

    test("free executes custom cleanup logic", () {
      final state = <String>[];
      final freeable = CPDartFnFreeable(() {
        state.add("freed");
      });

      expect(state, isEmpty);
      freeable.free();
      expect(state, equals(["freed"]));
    });

    test("noop freeable does nothing when freed", () {
      final freeable = CPFreeable.noop();
      // Should not throw
      // ignore: cascade_invocations
      freeable
        ..free()
        ..free();
    });
  });

  group("CPMultiFreeable", () {
    test("frees all freeables in order", () {
      final calls = <int>[];
      final freeables = [
        CPDartFnFreeable(() => calls.add(1)),
        CPDartFnFreeable(() => calls.add(2)),
        CPDartFnFreeable(() => calls.add(3)),
      ];

      final multi = CPMultiFreeable(freeables);
      expect(calls, isEmpty);
      multi.free();
      expect(calls, equals([1, 2, 3]));
    });

    test("works with empty iterable", () {
      // Should not throw
      CPMultiFreeable([]).free();
    });

    test("works with single freeable", () {
      var called = false;
      final freeable = CPDartFnFreeable(() {
        called = true;
      });

      CPMultiFreeable([freeable]).free();
      expect(called, isTrue);
    });

    test("can be called multiple times", () {
      var callCount = 0;
      final freeable = CPDartFnFreeable(() {
        callCount++;
      });
      final multi = CPMultiFreeable([freeable]);

      // ignore: cascade_invocations
      multi
        ..free()
        ..free();
      expect(callCount, equals(2));
    });

    test("frees nested multi-freeables", () {
      final calls = <String>[];
      final inner1 = CPMultiFreeable([
        CPDartFnFreeable(() => calls.add("a")),
        CPDartFnFreeable(() => calls.add("b")),
      ]);
      final inner2 = CPMultiFreeable([
        CPDartFnFreeable(() => calls.add("c")),
        CPDartFnFreeable(() => calls.add("d")),
      ]);

      CPMultiFreeable([inner1, inner2]).free();
      expect(calls, equals(["a", "b", "c", "d"]));
    });

    test("stops freeing after one throws", () {
      final calls = <int>[];
      final freeables = [
        CPDartFnFreeable(() => calls.add(1)),
        CPDartFnFreeable(() => throw Exception("error in freeable")),
        CPDartFnFreeable(() => calls.add(3)),
      ];

      final multi = CPMultiFreeable(freeables);
      // ignore: unnecessary_lambdas
      expect(() => multi.free(), throwsException);
      // First freeable called, but exception stops iteration so third is not called
      expect(calls, equals([1]));
    });

    test("works with various freeable types", () {
      final calls = <String>[];
      final freeables = <CPFreeable>[
        CPDartFnFreeable(() => calls.add("dart")),
        CPFreeable.noop(),
        CPDartFnFreeable(() => calls.add("fn")),
        CPMultiFreeable([
          CPDartFnFreeable(() => calls.add("nested")),
        ]),
      ];

      CPMultiFreeable(freeables).free();
      expect(calls, equals(["dart", "fn", "nested"]));
    });

    test("preserves order with lazy iterable", () {
      final calls = <int>[];
      final lazyFreeables = Iterable.generate(
        5,
        (i) => CPDartFnFreeable(() => calls.add(i)),
      );

      CPMultiFreeable(lazyFreeables).free();
      expect(calls, equals([0, 1, 2, 3, 4]));
    });
  });

  group("Resource management patterns", () {
    test("freeable can manage stateful resources", () {
      var resourceOpen = true;
      final freeable = CPDartFnFreeable(() {
        resourceOpen = false;
      });

      expect(resourceOpen, isTrue);
      freeable.free();
      expect(resourceOpen, isFalse);
    });

    test("freeable can clean up multiple resources", () {
      final resources = {"db": true, "file": true, "network": true};

      expect(resources.length, equals(3));
      CPDartFnFreeable(resources.clear).free();
      expect(resources, isEmpty);
    });

    test("nested freeables manage hierarchical resources", () {
      final log = <String>[];
      final fileFreeable = CPDartFnFreeable(() => log.add("close file"));
      final dbFreeable = CPDartFnFreeable(() => log.add("close db"));
      final networkFreeable = CPDartFnFreeable(() => log.add("close network"));

      CPMultiFreeable([
        networkFreeable,
        dbFreeable,
        fileFreeable,
      ]).free();
      expect(log, equals(["close network", "close db", "close file"]));
    });
  });
}
