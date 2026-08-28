// ignore_for_file: ditto_missing_visibility
part of "wasm.dart";

bool dittoSmallPeerInfoGetIsEnabled(CPPointer<CPDitto> ditto) => _dittoCore
    .dittoSmallPeerInfoGetIsEnabled(
      ditto.asWasm(),
    )
    .toDart;

void dittoFfiSmallPeerInfoSetEnabled(
  CPPointer<CPDitto> ditto, {
  required bool isEnabled,
}) =>
    _dittoCore.dittoSmallPeerInfoSetEnabled(
      ditto.asWasm(),
      isEnabled.toJS,
    );

String dittoFfiSmallPeerInfoGetMetadata(CPPointer<CPDitto> ditto) {
  final metadataCString = _dittoCore.dittoSmallPeerInfoGetMetadata(
    ditto.asWasm(),
  );
  return _dittoCore.boxCStringIntoString(metadataCString)!.toDart;
}

CPResult<void> dittoSmallPeerInfoSetMetadata(
  CPPointer<CPDitto> ditto,
  String metadata,
) {
  final metadataBytes = bytesFromString(metadata);
  final statusCode = _dittoCore.dittoSmallPeerInfoSetMetadata(
    ditto.asWasm(),
    metadataBytes.toJS,
  );
  switch (statusCode) {
    case 0:
      return CPResult.legacyOk(null);
    case 1:
      final errorMessage =
          "Validation error, size limit exceeded: ${_errorMessageThreadLocal() ?? "metadata is too big"}";
      return CPResult.legacyException(privateMakeDittoException(errorMessage));
    case 2:
      final errorMessage =
          "Validation error, ${_errorMessageThreadLocal() ?? "depth limit for metadata exceeded"}";
      return CPResult.legacyException(privateMakeDittoException(errorMessage));
    case 3:
      final errorMessage =
          "Validation error, ${_errorMessageThreadLocal() ?? "metadata is not a valid JSON object"}";
      return CPResult.legacyException(privateMakeDittoException(errorMessage));
    case -1:
      return CPResult.legacyError(
        privateMakeDittoError(
          "Internal inconsistency, the observability subsystem is unavailable",
        ),
      );
    default:
      throw privateMakeDittoError(
        "Internal inconsistency, ditto_small_peer_info_set_metadata() returned an unknown error code: $statusCode",
      );
  }
}
