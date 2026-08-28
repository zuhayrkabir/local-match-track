// ignore_for_file: ditto_missing_visibility
part of "wasm.dart";

CPErrorCode dittoffiErrorCode(CPPointer<CPError> error) =>
    _errorCodeFromJsString(_dittoCore.dittoffiErrorCode(error.asWasm()));

String dittoffiErrorDescription(CPPointer<CPError> error) {
  final ptr = _dittoCore.dittoffiErrorDescription(error.asWasm());
  return _dittoCore.boxCStringIntoString(ptr)!.toDart;
}

/// This is maintained by-hand whenever `ffi/src/result/error.rs` changes
CPErrorCode _errorCodeFromJsString(JSString s) => switch (s.toDart) {
      "ActivationLicenseTokenExpired" =>
        CPErrorCode.activationLicenseTokenExpired,
      "ActivationLicenseTokenInvalid" =>
        CPErrorCode.activationLicenseTokenInvalid,
      "ActivationLicenseUnsupportedFutureVersion" =>
        CPErrorCode.activationLicenseUnsupportedFutureVersion,
      "ActivationNotActivated" => CPErrorCode.activationNotActivated,
      "ActivationUnnecessary" => CPErrorCode.activationUnnecessary,
      "Base64Invalid" => CPErrorCode.base64Invalid,
      "CborInvalid" => CPErrorCode.cborInvalid,
      "CborUnsupported" => CPErrorCode.cborUnsupported,
      "Crdt" => CPErrorCode.crdt,
      "DifferIdentityKeyPath" => CPErrorCode.differIdentityKeyPath,
      "DqlEvaluationError" => CPErrorCode.dqlEvaluationError,
      "DqlInvalidQueryArgs" => CPErrorCode.dqlInvalidQueryArgs,
      "DqlQueryCompilation" => CPErrorCode.dqlQueryCompilation,
      "DqlUnsupported" => CPErrorCode.dqlUnsupported,
      "EncryptionExtraneousPassphraseGiven" =>
        CPErrorCode.encryptionExtraneousPassphraseGiven,
      "EncryptionPassphraseInvalid" => CPErrorCode.encryptionPassphraseInvalid,
      "EncryptionPassphraseNotGiven" =>
        CPErrorCode.encryptionPassphraseNotGiven,
      "JsFloatingStoreOperation" => CPErrorCode.jsFloatingStoreOperation,
      "IoAlreadyExists" => CPErrorCode.ioAlreadyExists,
      "IoNotFound" => CPErrorCode.ioNotFound,
      "IoOperationFailed" => CPErrorCode.ioOperationFailed,
      "IoPermissionDenied" => CPErrorCode.ioPermissionDenied,
      "LockedDittoWorkingDirectory" => CPErrorCode.lockedDittoWorkingDirectory,
      "ParameterQuery" => CPErrorCode.parameterQuery,
      "StoreDatabase" => CPErrorCode.storeDatabase,
      "StoreDocumentId" => CPErrorCode.storeDocumentId,
      "StoreDocumentNotFound" => CPErrorCode.storeDocumentNotFound,
      "StoreQuery" => CPErrorCode.storeQuery,
      "StoreTransactionReadOnly" => CPErrorCode.storeTransactionReadOnly,
      "Transport" => CPErrorCode.transport,
      "Unsupported" => CPErrorCode.unsupported,
      "ValidationDepthLimitExceeded" =>
        CPErrorCode.validationDepthLimitExceeded,
      "ValidationInvalidCbor" => CPErrorCode.validationInvalidCbor,
      "ValidationInvalidJson" => CPErrorCode.validationInvalidJson,
      "ValidationInvalidTransportConfig" =>
        CPErrorCode.validationInvalidTransportConfig,
      "ValidationNotAMap" => CPErrorCode.validationNotAMap,
      "ValidationSizeLimitExceeded" => CPErrorCode.validationSizeLimitExceeded,
      "Unknown" => CPErrorCode.unknown,
      "Internal" => CPErrorCode.internal,
      final other => throw privateMakeDittoError("Unknown error code: $other"),
    };
