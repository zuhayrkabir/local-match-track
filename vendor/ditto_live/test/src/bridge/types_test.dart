import "package:ditto_live/src/bridge/cross_platform/types.dart";
import "package:ditto_live/src/exception.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("CPAttachmentFileOperation", () {
    test("has copy operation", () {
      expect(CPAttachmentFileOperation.copy, isNotNull);
    });

    test("has move operation", () {
      expect(CPAttachmentFileOperation.move, isNotNull);
    });

    test("enum values are distinct", () {
      expect(
        CPAttachmentFileOperation.copy,
        isNot(equals(CPAttachmentFileOperation.move)),
      );
    });
  });

  group("CPBase64PaddingMode", () {
    test("has padded mode", () {
      expect(CPBase64PaddingMode.padded, isNotNull);
    });

    test("has unpadded mode", () {
      expect(CPBase64PaddingMode.unpadded, isNotNull);
    });

    test("enum values are distinct", () {
      expect(
        CPBase64PaddingMode.padded,
        isNot(equals(CPBase64PaddingMode.unpadded)),
      );
    });
  });

  group("LogLevel", () {
    test("has all expected log levels", () {
      expect(LogLevel.error, isNotNull);
      expect(LogLevel.warning, isNotNull);
      expect(LogLevel.info, isNotNull);
      expect(LogLevel.debug, isNotNull);
      expect(LogLevel.verbose, isNotNull);
    });

    test("all log levels are unique", () {
      const levels = LogLevel.values;
      final uniqueLevels = levels.toSet();
      expect(levels.length, equals(uniqueLevels.length));
    });

    test("has expected ordering", () {
      expect(LogLevel.error.index, lessThan(LogLevel.warning.index));
      expect(LogLevel.warning.index, lessThan(LogLevel.info.index));
      expect(LogLevel.info.index, lessThan(LogLevel.debug.index));
      expect(LogLevel.debug.index, lessThan(LogLevel.verbose.index));
    });

    test("error has index 0", () {
      expect(LogLevel.error.index, equals(0));
    });

    test("verbose is the last level", () {
      expect(LogLevel.verbose.index, equals(LogLevel.values.length - 1));
    });
  });

  group("CPErrorCode", () {
    test("has all expected error codes", () {
      // Activation errors
      expect(CPErrorCode.activationLicenseTokenExpired, isNotNull);
      expect(CPErrorCode.activationLicenseTokenInvalid, isNotNull);
      expect(CPErrorCode.activationLicenseUnsupportedFutureVersion, isNotNull);
      expect(CPErrorCode.activationNotActivated, isNotNull);
      expect(CPErrorCode.activationUnnecessary, isNotNull);

      // Authentication errors
      expect(CPErrorCode.authenticationExpirationHandlerMissing, isNotNull);

      // Encoding errors
      expect(CPErrorCode.base64Invalid, isNotNull);
      expect(CPErrorCode.cborInvalid, isNotNull);
      expect(CPErrorCode.cborUnsupported, isNotNull);

      // Core errors
      expect(CPErrorCode.crdt, isNotNull);

      // Differ errors
      expect(CPErrorCode.differIdentityKeyPath, isNotNull);

      // DQL errors
      expect(CPErrorCode.dqlEvaluationError, isNotNull);
      expect(CPErrorCode.dqlInvalidQueryArgs, isNotNull);
      expect(CPErrorCode.dqlQueryCompilation, isNotNull);
      expect(CPErrorCode.dqlUnsupported, isNotNull);

      // Encryption errors
      expect(CPErrorCode.encryptionExtraneousPassphraseGiven, isNotNull);
      expect(CPErrorCode.encryptionPassphraseInvalid, isNotNull);
      expect(CPErrorCode.encryptionPassphraseNotGiven, isNotNull);

      // JS-specific errors
      expect(CPErrorCode.jsFloatingStoreOperation, isNotNull);

      // IO errors
      expect(CPErrorCode.ioAlreadyExists, isNotNull);
      expect(CPErrorCode.ioNotFound, isNotNull);
      expect(CPErrorCode.ioOperationFailed, isNotNull);
      expect(CPErrorCode.ioPermissionDenied, isNotNull);

      // Other errors
      expect(CPErrorCode.lockedDittoWorkingDirectory, isNotNull);
      expect(CPErrorCode.parameterQuery, isNotNull);

      // Store errors
      expect(CPErrorCode.storeDatabase, isNotNull);
      expect(CPErrorCode.storeDocumentId, isNotNull);
      expect(CPErrorCode.storeDocumentNotFound, isNotNull);
      expect(CPErrorCode.storeQuery, isNotNull);
      expect(CPErrorCode.storeTransactionReadOnly, isNotNull);

      // Transport errors
      expect(CPErrorCode.transport, isNotNull);

      // Validation errors
      expect(CPErrorCode.validationDepthLimitExceeded, isNotNull);
      expect(CPErrorCode.validationInvalidCbor, isNotNull);
      expect(CPErrorCode.validationInvalidJson, isNotNull);
      expect(CPErrorCode.validationInvalidTransportConfig, isNotNull);
      expect(CPErrorCode.validationInvalidDittoConfig, isNotNull);
      expect(CPErrorCode.validationNotAMap, isNotNull);
      expect(CPErrorCode.validationSizeLimitExceeded, isNotNull);

      // Generic errors
      expect(CPErrorCode.unsupported, isNotNull);
      expect(CPErrorCode.unknown, isNotNull);
      expect(CPErrorCode.internal, isNotNull);
    });

    test("shouldBeError returns true for unknown and internal", () {
      expect(CPErrorCode.unknown.shouldBeError, isTrue);
      expect(CPErrorCode.internal.shouldBeError, isTrue);
    });

    test("shouldBeError returns false for other error codes", () {
      expect(CPErrorCode.activationLicenseTokenExpired.shouldBeError, isFalse);
      expect(CPErrorCode.cborInvalid.shouldBeError, isFalse);
      expect(CPErrorCode.dqlEvaluationError.shouldBeError, isFalse);
      expect(CPErrorCode.ioNotFound.shouldBeError, isFalse);
      expect(CPErrorCode.storeDocumentNotFound.shouldBeError, isFalse);
      expect(CPErrorCode.transport.shouldBeError, isFalse);
      expect(CPErrorCode.unsupported.shouldBeError, isFalse);
    });

    test("all error codes are unique", () {
      const codes = CPErrorCode.values;
      final uniqueCodes = codes.toSet();
      expect(codes.length, equals(uniqueCodes.length));
    });
  });

  group("CPTransportConfigMode", () {
    test("has platformDependent mode", () {
      expect(CPTransportConfigMode.platformDependent, isNotNull);
    });

    test("has platformIndependent mode", () {
      expect(CPTransportConfigMode.platformIndependent, isNotNull);
    });

    test("enum values are distinct", () {
      expect(
        CPTransportConfigMode.platformDependent,
        isNot(equals(CPTransportConfigMode.platformIndependent)),
      );
    });
  });

  group("AuthResponse", () {
    test("can be constructed with null exception (success case)", () {
      const response = AuthResponse("{'user': 'test'}", null);
      expect(response.clientInfo, equals("{'user': 'test'}"));
      expect(response.exception, isNull);
    });

    test("can be constructed with null clientInfo", () {
      final exception = privateMakeDittoException("auth failed");
      final response = AuthResponse(null, exception);
      expect(response.clientInfo, isNull);
      expect(response.exception, equals(exception));
    });

    test("can be constructed with both clientInfo and exception", () {
      final exception = privateMakeDittoException("auth failed");
      final response = AuthResponse("{'reason': 'expired'}", exception);
      expect(response.clientInfo, equals("{'reason': 'expired'}"));
      expect(response.exception, equals(exception));
    });

    test("successful response has no exception", () {
      const response = AuthResponse("{'token': 'abc123'}", null);
      expect(response.exception, isNull);
    });

    test("failed response has exception", () {
      final exception = privateMakeDittoException("invalid credentials");
      final response = AuthResponse(null, exception);
      expect(response.exception, isNotNull);
      expect(response.exception.toString(), contains("invalid credentials"));
    });

    test("clientInfo can be empty string", () {
      const response = AuthResponse("", null);
      expect(response.clientInfo, equals(""));
      expect(response.exception, isNull);
    });

    test("clientInfo can contain JSON", () {
      const json = "{'userId': '123', 'permissions': ['read', 'write']}";
      const response = AuthResponse(json, null);
      expect(response.clientInfo, equals(json));
    });
  });
}
