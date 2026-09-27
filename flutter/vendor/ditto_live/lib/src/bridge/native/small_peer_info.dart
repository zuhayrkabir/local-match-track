// ignore_for_file: ditto_missing_visibility, ditto_store_ditto_ptr
part of "native.dart";

bool dittoSmallPeerInfoGetIsEnabled(CPPointer<CPDitto> ditto) {
  final dittoPtr = ditto.asFfi();
  return bindings.ditto_small_peer_info_get_is_enabled(dittoPtr.inner.cast());
}

void dittoFfiSmallPeerInfoSetEnabled(
  CPPointer<CPDitto> ditto, {
  required bool isEnabled,
}) {
  final dittoPtr = ditto.asFfi();
  bindings.ditto_small_peer_info_set_enabled(dittoPtr.inner.cast(), isEnabled);
}

String dittoFfiSmallPeerInfoGetMetadata(CPPointer<CPDitto> ditto) {
  final dittoPtr = ditto.asFfi();
  final ptr = bindings.ditto_small_peer_info_get_metadata(
    dittoPtr.inner.cast(),
  );
  return stringFromCharStar(ptr, free: true);
}

CPResult<void> dittoSmallPeerInfoSetMetadata(
  CPPointer<CPDitto> ditto,
  String metadata,
) {
  final dittoPtr = ditto.asFfi();
  return withStringAsPtr(metadata, (metadataPtr) {
    final result = bindings.ditto_small_peer_info_set_metadata(
      dittoPtr.inner.cast(),
      metadataPtr,
    );

    return switch (result) {
      0 => CPResult.legacyOk(null),
      1 => CPResult.legacyException(
          privateMakeDittoException("Metadata too large"),
        ),
      2 => CPResult.legacyException(
          privateMakeDittoException("Metadata too deeply nested"),
        ),
      3 => CPResult.legacyException(
          privateMakeDittoException(
            "Metadata couldn't be parsed as `Map<String, dynamic>`",
          ),
        ),
      -1 => CPResult.legacyError(
          privateMakeDittoError("observability subsystem unavailable"),
        ),
      final other => CPResult.legacyError(
          privateMakeDittoError("unknown error code: $other"),
        ),
    };
  });
}
