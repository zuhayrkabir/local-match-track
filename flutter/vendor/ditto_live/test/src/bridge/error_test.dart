import "package:ditto_live/src/bridge/cross_platform/error.dart";
import "package:ditto_live/src/exception.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("CPResult", () {
    group("LegacyCPResultOk", () {
      test("extract returns the value", () {
        final result = CPResult.legacyOk(42);
        expect(result.extract(), equals(42));
      });

      test("extract works with null values", () {
        final result = CPResult.legacyOk<String?>(null);
        expect(result.extract(), isNull);
      });

      test("extract works with various types", () {
        expect(CPResult.legacyOk("test").extract(), equals("test"));
        expect(CPResult.legacyOk(true).extract(), isTrue);
        expect(CPResult.legacyOk([1, 2, 3]).extract(), equals([1, 2, 3]));
        expect(
          CPResult.legacyOk({"key": "value"}).extract(),
          equals({"key": "value"}),
        );
      });
    });

    group("LegacyCPResultError", () {
      test("extract throws DittoError", () {
        final error = privateMakeDittoError("test error");
        final result = CPResult.legacyError<int>(error);
        // ignore: unnecessary_lambdas
        expect(() => result.extract(), throwsA(isA<DittoError>()));
      });

      test("extract throws the correct error message", () {
        final error = privateMakeDittoError("specific error message");
        final result = CPResult.legacyError<int>(error);
        expect(
          // ignore: unnecessary_lambdas
          () => result.extract(),
          throwsA(
            predicate<DittoError>(
              (e) => e.toString().contains("specific error message"),
            ),
          ),
        );
      });
    });

    group("LegacyCPResultException", () {
      test("extract throws DittoException", () {
        final exception = privateMakeDittoException("test exception");
        final result = CPResult.legacyException<int>(exception);
        // ignore: unnecessary_lambdas
        expect(() => result.extract(), throwsA(isA<DittoException>()));
      });

      test("extract throws the correct exception", () {
        final exception = privateMakeDittoException("specific exception");
        final result = CPResult.legacyException<int>(exception);
        expect(
          // ignore: unnecessary_lambdas
          () => result.extract(),
          throwsA(
            predicate<DittoException>(
              (e) => e.toString().contains("specific exception"),
            ),
          ),
        );
      });
    });

    group("map", () {
      test("maps successful values", () {
        final result = CPResult.legacyOk(5);
        final mapped = result.map((value) => value * 2);
        expect(mapped.extract(), equals(10));
      });

      test("maps through multiple transformations", () {
        final result = CPResult.legacyOk(5);
        final mapped = result
            .map((value) => value * 2)
            .map((value) => value + 3)
            .map((value) => value.toString());
        expect(mapped.extract(), equals("13"));
      });

      test("propagates errors through map", () {
        final error = privateMakeDittoError("test error");
        final result = CPResult.legacyError<int>(error);
        final mapped = result.map((value) => value * 2);
        // ignore: unnecessary_lambdas
        expect(() => mapped.extract(), throwsA(isA<DittoError>()));
      });

      test("propagates exceptions through map", () {
        final exception = privateMakeDittoException("test");
        final result = CPResult.legacyException<int>(exception);
        final mapped = result.map((value) => value * 2);
        // ignore: unnecessary_lambdas
        expect(() => mapped.extract(), throwsA(isA<DittoException>()));
      });

      test("map can change result type", () {
        final result = CPResult.legacyOk(42);
        final mapped = result.map((value) => "number: $value");
        expect(mapped.extract(), equals("number: 42"));
      });

      test("map can transform to complex types", () {
        final result = CPResult.legacyOk(5);
        final mapped = result.map((value) => [value, value * 2, value * 3]);
        expect(mapped.extract(), equals([5, 10, 15]));
      });
    });

    group("protected members", () {
      test("accessing successUnchecked on LegacyCPResult throws", () {
        final result = CPResult.legacyOk(42) as LegacyCPResult<int>;
        expect(
          () => result.successUnchecked,
          throwsA(isA<DittoError>()),
        );
      });

      test("accessing error on LegacyCPResult throws", () {
        final result = CPResult.legacyOk(42) as LegacyCPResult<int>;
        expect(() => result.error, throwsA(isA<DittoError>()));
      });
    });
  });

  group("CPResultExtension", () {
    test("extract works on Future<CPResult>", () async {
      final futureResult = Future.value(CPResult.legacyOk(42));
      final value = await futureResult.extract();
      expect(value, equals(42));
    });

    test("extract propagates errors from Future<CPResult>", () async {
      final error = privateMakeDittoError("async error");
      final futureResult = Future.value(CPResult.legacyError<int>(error));
      await expectLater(
        futureResult.extract(),
        throwsA(isA<DittoError>()),
      );
    });

    test("extract propagates exceptions from Future<CPResult>", () async {
      final exception = privateMakeDittoException("async exception");
      final futureResult =
          Future.value(CPResult.legacyException<int>(exception));
      await expectLater(
        futureResult.extract(),
        throwsA(isA<DittoException>()),
      );
    });

    test("extract works with delayed futures", () async {
      final futureResult = Future.delayed(
        const Duration(milliseconds: 10),
        () => CPResult.legacyOk("delayed"),
      );
      final value = await futureResult.extract();
      expect(value, equals("delayed"));
    });
  });
}
