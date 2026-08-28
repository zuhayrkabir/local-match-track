// ignore_for_file: ditto_missing_visibility, ditto_store_ditto_ptr
part of "native.dart";

String dittoPresenceV3(CPPointer<CPDitto> ditto) {
  final dittoPtr = ditto.asFfi();
  return stringFromCharStar(
    bindings.ditto_presence_v3(dittoPtr.inner.cast()),
    free: true,
  );
}

String dittoFfiPresencePeerMetadataJson(CPPointer<CPDitto> ditto) {
  final dittoPtr = ditto.asFfi();
  final slice = bindings.dittoffi_presence_peer_metadata_json(
    dittoPtr.inner.cast(),
  );
  return utf8.decode(bytesFromNative(slice, free: true));
}

CPResult<void> dittoFfiPresenceTrySetPeerMetadataJson(
  CPPointer<CPDitto> ditto,
  String metadata,
) {
  final dittoPtr = ditto.asFfi();
  final slice = bytesToSlice(metadata.toUtf8Bytes());

  final result = bindings.dittoffi_presence_try_set_peer_metadata_json(
    dittoPtr.inner.cast(),
    slice.ref,
  );

  freeSliceRef(slice);

  return _NativeResult(
    result,
    getSuccess: (_) {},
    getError: (res) => res.error,
  );
}

CPFreeable dittoFfiPresenceSetConnectionRequestHandler(
  CPPointer<CPDitto> ditto,
  Future<ConnectionRequestAuthorization> Function(
    CPPointer<CPConnectionRequest>,
  ) handler,
) {
  final dittoPtr = ditto.asFfi();
  void cb(
    Pointer<Erased_t> _,
    Pointer<dittoffi_connection_request> requestPtr,
  ) {
    final request = requestPtr.toCP<CPConnectionRequest>();
    // Drive the handle lifecycle through the cross-platform helper so that
    // _free is always called and the remote peer is not left hanging on a
    // ~10s timeout when the customer handler throws. See
    // docs/ffi/src/transports/connections.md.
    unawaited(
      runConnectionRequestHandler(
        request: request,
        handler: handler,
        authorize: dittoFfiConnectionRequestAuthorize,
        free: dittoffiConnectionRequestFree,
        onError: (e, st) => dittoLog(
          LogLevel.error,
          "The registered connection request handler failed: $e\n$st",
        ),
      ),
    );
  }

  final callable = NativeCallable<
      Void Function(
        Pointer<Erased_t>,
        Pointer<dittoffi_connection_request_t>,
      )>.listener(cb);

  late final Pointer<FfiConnectionRequestHandlerVTable_t> vtablePtr;
  late final Pointer<VirtualPtr__Erased_ptr_FfiConnectionRequestHandlerVTable_t>
      virtualPtr;

  vtablePtr = malloc();

  // See doc_internal/src/architecture/core_api.md "Ref Count and Ownership"
  vtablePtr.ref.retain_vptr = bindings.dittoffi_get_noop_void_ptr_fn().cast();
  vtablePtr.ref.release_vptr = bindings.dittoffi_get_noop_void_ptr_fn().cast();
  vtablePtr.ref.on_connecting = callable.nativeFunction;

  virtualPtr = malloc();
  virtualPtr.ref.vtable = vtablePtr.ref;
  // IMPORTANT: ptr must not be `nullptr`. safer-ffi uses null ptr to model
  // Option::None, which makes it interpret the callback as absent.
  // See SDKS-2266
  virtualPtr.ref.ptr = dummyNonNullPointer.cast();

  bindings.dittoffi_presence_set_connection_request_handler(
    dittoPtr.inner.cast(),
    virtualPtr.ref,
  );

  return CPMultiFreeable([
    NativeCallableFreeable(callable),
    NativeMallocFreeable(vtablePtr),
    NativeMallocFreeable(virtualPtr),
  ]);
}

void dittoFfiConnectionRequestAuthorize(
  CPPointer<CPConnectionRequest> request,
  ConnectionRequestAuthorization auth,
) {
  final requestPtr = request.asFfi();
  bindings.dittoffi_connection_request_authorize(
    requestPtr.inner.cast(),
    _authorizationToInt(auth),
  );
}

void dittoffiConnectionRequestFree(CPPointer<CPConnectionRequest> request) {
  final requestPtr = request.asFfi();
  bindings.dittoffi_connection_request_free(requestPtr.inner.cast());
}

ConnectionType dittoFfiConnectionRequestConnectionType(
  CPPointer<CPConnectionRequest> request,
) {
  final requestPtr = request.asFfi();
  return _connectionTypeFromInt(
    bindings.dittoffi_connection_request_connection_type(
      requestPtr.inner.cast(),
    ),
  );
}

String dittoFfiConnectionRequestPeerKeyString(
  CPPointer<CPConnectionRequest> request,
) {
  final requestPtr = request.asFfi();
  return stringFromCharStar(
    bindings.dittoffi_connection_request_peer_key_string(
      requestPtr.inner.cast(),
    ),
    free: true,
  );
}

String dittoFfiConnectionRequestIdentityServiceMetadataJson(
  CPPointer<CPConnectionRequest> request,
) {
  final requestPtr = request.asFfi();
  return stringFromSliceUint8(
    bindings.dittoffi_connection_request_identity_service_metadata_json(
      requestPtr.inner.cast(),
    ),
  );
}

String dittoFfiConnectionRequestPeerMetadataJson(
  CPPointer<CPConnectionRequest> request,
) {
  final requestPtr = request.asFfi();
  return stringFromSliceUint8(
    bindings.dittoffi_connection_request_peer_metadata_json(
      requestPtr.inner.cast(),
    ),
  );
}

ConnectionType _connectionTypeFromInt(int type) => switch (type) {
      dittoffi_connection_type.DITTOFFI_CONNECTION_TYPE_BLUETOOTH =>
        ConnectionType.bluetooth,
      dittoffi_connection_type.DITTOFFI_CONNECTION_TYPE_P2_P_WI_FI =>
        ConnectionType.p2pWifi,
      dittoffi_connection_type.DITTOFFI_CONNECTION_TYPE_WEB_SOCKET =>
        ConnectionType.webSocket,
      dittoffi_connection_type.DITTOFFI_CONNECTION_TYPE_ACCESS_POINT =>
        ConnectionType.accessPoint,
      dittoffi_connection_type.DITTOFFI_CONNECTION_TYPE_MULTICAST =>
        ConnectionType.multicast,
      _ => throw privateMakeDittoError("unknown connection type: $type"),
    };

int _authorizationToInt(ConnectionRequestAuthorization auth) => switch (auth) {
      ConnectionRequestAuthorization.allow =>
        dittoffi_connection_request_authorization
            .DITTOFFI_CONNECTION_REQUEST_AUTHORIZATION_ALLOW,
      ConnectionRequestAuthorization.deny =>
        dittoffi_connection_request_authorization
            .DITTOFFI_CONNECTION_REQUEST_AUTHORIZATION_DENY,
    };

/// Registers a presence observer using the modern observer-handle FFI.
///
/// Rust owns the callback lifecycle and invokes the `free` function pointer
/// when the observer is cancelled/dropped, at which point Dart closes the
/// backing [NativeCallable]s. No empirical drain delay is required.
///
/// The FFI hands us the presence graph as a `slice_boxed_uint8_t` of
/// UTF-8-encoded JSON — see `dittoffi_presence_register_observer_throws` in
/// `crates/dittoffi/src/presence.rs`. The buffer is Rust-owned and must be
/// released via `ditto_c_bytes_free` before the wrapper returns.
CPFreeable dittoRegisterPresenceObserver(
  CPPointer<CPDitto> ditto,
  void Function(String json) callback,
) {
  final dittoPtr = ditto.asFfi();

  var freeWasCalled = false;

  late final NativeCallable<Void Function(Pointer<Void>, slice_boxed_uint8_t)>
      callCallable;

  void callWrapper(Pointer<Void> env, slice_boxed_uint8_t data) {
    // `utf8.decode` copies into an immutable Dart String, so it is safe to
    // free the Rust-owned slice immediately afterwards.
    final json = utf8.decode(data.ptr.cast<Uint8>().asTypedList(data.len));
    bindings.ditto_c_bytes_free(data);
    callback(json);
  }

  callCallable = NativeCallable<
      Void Function(Pointer<Void>, slice_boxed_uint8_t)>.listener(callWrapper);

  late final NativeCallable<Void Function(Pointer<Void>)> freeCallable;

  void freeWrapper(Pointer<Void> env) {
    if (freeWasCalled) return;
    freeWasCalled = true;
    // Defer close via `scheduleMicrotask` so we don't close a NativeCallable
    // from inside its own listener frame — see SDKS-2389 / store.dart.
    scheduleMicrotask(() {
      callCallable.close();
      freeCallable.close();
    });
  }

  freeCallable =
      NativeCallable<Void Function(Pointer<Void>)>.listener(freeWrapper);

  final boxCallback = calloc<BoxDynFnMut1_void_slice_boxed_uint8_t>();
  // safer-ffi's NonNull rejects a null env pointer — see SDKS-2266 and the
  // `dummyNonNullPointer` usage elsewhere in this file.
  boxCallback.ref.env_ptr = dummyNonNullPointer;
  boxCallback.ref.call = callCallable.nativeFunction;
  boxCallback.ref.free = freeCallable.nativeFunction;

  final result = bindings.dittoffi_presence_register_observer_throws(
    dittoPtr.inner.cast(),
    boxCallback.ref,
  );
  // Rust took the struct by value; the calloc buffer is no longer needed.
  calloc.free(boxCallback);

  if (result.error != nullptr) {
    // Rust drops the `Box<FfiDynPresenceCallback>` on the error path, which
    // fires our `freeWrapper` and closes both callables via microtask. Nothing
    // else to release Dart-side here.
    final errorPtr = result.error;
    final errorMsg = stringFromCharStar(
      bindings.dittoffi_error_description(errorPtr),
      free: false,
    );
    bindings.dittoffi_error_free(errorPtr);
    throw privateMakeDittoError(errorMsg);
  }

  final observerPtr = result.success;

  return CPDartFnFreeable(() {
    bindings
      ..dittoffi_presence_observer_cancel(observerPtr)
      ..dittoffi_presence_observer_free(observerPtr);
    // callCallable / freeCallable are closed by `freeWrapper` (invoked by
    // Rust when the observer's Box drops).
  });
}
