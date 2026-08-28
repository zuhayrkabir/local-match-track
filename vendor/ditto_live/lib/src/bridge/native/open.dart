// ignore_for_file: ditto_missing_visibility, ditto_store_ditto_ptr
part of "native.dart";

Future<CPResult<CPPointer<CPDitto>>> dittoffiDittoOpenAsyncThrows(
  Uint8List configCbor,
  CPTransportConfigMode mode,
  String defaultRootDirectory,
) async {
  final configCborPtr = bytesToSlice(configCbor);
  final modeInt = switch (mode) {
    CPTransportConfigMode.platformDependent => 0,
    CPTransportConfigMode.platformIndependent => 1,
  };

  final completer = Completer<dittoffi_result_CDitto_ptr_t>();
  void cb(Pointer<Void> env, dittoffi_result_CDitto_ptr_t ptr) {
    completer.complete(ptr);
  }

  final nativeCallable = NativeCallable<
      Void Function(Pointer<Void>, dittoffi_result_CDitto_ptr_t)>.listener(cb);

  final continuation = malloc<BoxDynFnMut1_void_dittoffi_result_CDitto_ptr>();

  continuation.ref.env_ptr = dummyNonNullPointer;
  continuation.ref.free = bindings.dittoffi_get_noop_void_ptr_fn();
  continuation.ref.call = nativeCallable.nativeFunction;

  withStringAsPtr(
    defaultRootDirectory,
    (dirPtr) => bindings.dittoffi_ditto_open_async_throws(
      configCborPtr.ref,
      modeInt,
      dirPtr,
      continuation.ref,
    ),
  );

  final result = await completer.future;

  freeSliceRef(configCborPtr);
  nativeCallable.close();
  malloc.free(continuation);

  return _NativeResult(
    result,
    getError: (result) => result.error,
    getSuccess: (result) => result.success.toCP(),
  );
}

CPResult<CPPointer<CPDitto>> dittoffiDittoOpenThrows(
  Uint8List configCbor,
  CPTransportConfigMode mode,
  String defaultRootDirectory,
) {
  final configCborPtr = bytesToSlice(configCbor);
  final modeInt = switch (mode) {
    CPTransportConfigMode.platformDependent => 0,
    CPTransportConfigMode.platformIndependent => 1,
  };

  final result = withStringAsPtr(
    defaultRootDirectory,
    (dirPtr) => bindings.dittoffi_ditto_open_throws(
      configCborPtr.ref,
      modeInt,
      dirPtr,
    ),
  );

  freeSliceRef(configCborPtr);

  return _NativeResult(
    result,
    getError: (result) => result.error,
    getSuccess: (result) => result.success.toCP(),
  );
}

Uint8List dittoffiDittoConfig(CPPointer<CPDitto> ditto) {
  final dittoPtr = ditto.asFfi();
  final slice = bindings.dittoffi_ditto_config(dittoPtr.inner.cast());
  return bytesFromNative(slice, free: true);
}

String dittoffiDittoAbsolutePersistenceDirectory(CPPointer<CPDitto> ditto) {
  final dittoPtr = ditto.asFfi();
  final charStar = bindings
      .dittoffi_ditto_absolute_persistence_directory(dittoPtr.inner.cast());
  return stringFromCharStar(charStar, free: true);
}

Uint8List dittffiDittoConfigDefault() => bytesFromNative(
      free: true,
      bindings.dittoffi_ditto_config_default(),
    );
