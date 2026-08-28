// ignore_for_file: ditto_missing_visibility
part of "native.dart";

final _errorFinalizer =
    NativeFinalizer(bindings.addresses.dittoffi_error_free.cast());

/// This class is thorougly documented in the internal doc book in the "native
/// details" chapter in the "error handling" section. If you are modifying this
/// class, make sure to update the docs there if appropriate
final class _NativeResult<T, NativeType_> extends CPResult<T>
    implements Finalizable {
  final NativeType_ result;
  final T Function(NativeType_) getSuccess;
  final Pointer<dittoffi_error> Function(NativeType_) getError;

  _NativeResult(
    this.result, {
    required this.getSuccess,
    required this.getError,
  });

  @override
  T get successUnchecked => getSuccess(result);

  @override
  CPFfiError? get error {
    final errorPtr = getError(result);
    if (errorPtr == nullptr) return null;

    final cpErrorPtr = errorPtr.toCP<CPError>();
    _errorFinalizer.attach(cpErrorPtr, errorPtr.cast());

    return CPFfiError(cpErrorPtr);
  }
}

CPErrorCode dittoffiErrorCode(CPPointer<CPError> error) {
  final errorPtr = error.asFfi();
  return _ffiErrorFromInt(bindings.dittoffi_error_code1(errorPtr.inner.cast()));
}

String dittoffiErrorDescription(CPPointer<CPError> error) {
  final errorPtr = error.asFfi();
  return stringFromCharStar(
    bindings.dittoffi_error_description(errorPtr.inner.cast()),
    free: true,
  );
}

/// This is maintained by-hand whenever `ffi/src/result/error.rs` changes
CPErrorCode _ffiErrorFromInt(int errorCode) => switch (errorCode) {
      dittoffi_error_code
            .DITTOFFI_ERROR_CODE_ACTIVATION_LICENSE_TOKEN_EXPIRED =>
        CPErrorCode.activationLicenseTokenExpired,
      dittoffi_error_code
            .DITTOFFI_ERROR_CODE_ACTIVATION_LICENSE_TOKEN_INVALID =>
        CPErrorCode.activationLicenseTokenInvalid,
      dittoffi_error_code
            .DITTOFFI_ERROR_CODE_ACTIVATION_LICENSE_UNSUPPORTED_FUTURE_VERSION =>
        CPErrorCode.activationLicenseUnsupportedFutureVersion,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_ACTIVATION_NOT_ACTIVATED =>
        CPErrorCode.activationNotActivated,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_ACTIVATION_UNNECESSARY =>
        CPErrorCode.activationUnnecessary,
      dittoffi_error_code
            .DITTOFFI_ERROR_CODE_AUTHENTICATION_EXPIRATION_HANDLER_MISSING =>
        CPErrorCode.authenticationExpirationHandlerMissing,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_BASE64_INVALID =>
        CPErrorCode.base64Invalid,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_CBOR_INVALID =>
        CPErrorCode.cborInvalid,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_CBOR_UNSUPPORTED =>
        CPErrorCode.cborUnsupported,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_CRDT => CPErrorCode.crdt,
      dittoffi_error_code
            .DITTOFFI_ERROR_CODE_DIFFER_IDENTITY_KEY_PATH_INVALID =>
        CPErrorCode.differIdentityKeyPath,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_DQL_EVALUATION_ERROR =>
        CPErrorCode.dqlEvaluationError,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_DQL_INVALID_QUERY_ARGS =>
        CPErrorCode.dqlInvalidQueryArgs,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_DQL_QUERY_COMPILATION =>
        CPErrorCode.dqlQueryCompilation,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_DQL_UNSUPPORTED =>
        CPErrorCode.dqlUnsupported,
      dittoffi_error_code
            .DITTOFFI_ERROR_CODE_ENCRYPTION_EXTRANEOUS_PASSPHRASE_GIVEN =>
        CPErrorCode.encryptionExtraneousPassphraseGiven,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_ENCRYPTION_PASSPHRASE_INVALID =>
        CPErrorCode.encryptionPassphraseInvalid,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_ENCRYPTION_PASSPHRASE_NOT_GIVEN =>
        CPErrorCode.encryptionPassphraseNotGiven,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_JS_FLOATING_STORE_OPERATION =>
        CPErrorCode.jsFloatingStoreOperation,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_IO_ALREADY_EXISTS =>
        CPErrorCode.ioAlreadyExists,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_IO_NOT_FOUND =>
        CPErrorCode.ioNotFound,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_IO_OPERATION_FAILED =>
        CPErrorCode.ioOperationFailed,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_IO_PERMISSION_DENIED =>
        CPErrorCode.ioPermissionDenied,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_LOCKED_DITTO_WORKING_DIRECTORY =>
        CPErrorCode.lockedDittoWorkingDirectory,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_PARAMETER_QUERY =>
        CPErrorCode.parameterQuery,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_STORE_DATABASE =>
        CPErrorCode.storeDatabase,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_STORE_DOCUMENT_ID =>
        CPErrorCode.storeDocumentId,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_STORE_DOCUMENT_NOT_FOUND =>
        CPErrorCode.storeDocumentNotFound,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_STORE_QUERY =>
        CPErrorCode.storeQuery,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_STORE_TRANSACTION_READ_ONLY =>
        CPErrorCode.storeTransactionReadOnly,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_TRANSPORT =>
        CPErrorCode.transport,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_UNSUPPORTED =>
        CPErrorCode.unsupported,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_VALIDATION_DEPTH_LIMIT_EXCEEDED =>
        CPErrorCode.validationDepthLimitExceeded,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_VALIDATION_INVALID_CBOR =>
        CPErrorCode.validationInvalidCbor,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_VALIDATION_INVALID_JSON =>
        CPErrorCode.validationInvalidJson,
      dittoffi_error_code
            .DITTOFFI_ERROR_CODE_VALIDATION_INVALID_TRANSPORT_CONFIG =>
        CPErrorCode.validationInvalidTransportConfig,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_VALIDATION_NOT_A_MAP =>
        CPErrorCode.validationNotAMap,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_VALIDATION_SIZE_LIMIT_EXCEEDED =>
        CPErrorCode.validationSizeLimitExceeded,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_UNKNOWN => CPErrorCode.unknown,
      dittoffi_error_code.DITTOFFI_ERROR_CODE_INTERNAL => CPErrorCode.internal,
      final other => throw privateMakeDittoError("Unknown error code: $other"),
    };
