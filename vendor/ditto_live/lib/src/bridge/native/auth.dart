// ignore_for_file: ditto_missing_visibility, ditto_store_ditto_ptr
part of "native.dart";

(CPPointer<CPAuthLoginProvider>, CPFreeable) dittoAuthClientMakeLoginProvider(
  CPPointer<CPDitto> ditto,
  void Function(int seconds) expiringCallback,
) {
  final dittoPtr = ditto.asFfi();

  void wrappedCallback(Pointer<Void> _, int seconds) {
    expiringCallback(seconds);
  }

  final callable =
      NativeCallable<Void Function(Pointer<Void>, Uint32)>.listener(
    wrappedCallback,
  );

  // See doc_internal/src/architecture/core_api.md "Ref Count and Ownership"
  final pointer = bindings.ditto_auth_client_make_login_provider(
    nullptr,
    bindings.dittoffi_get_noop_void_ptr_fn(), // retain
    bindings.dittoffi_get_noop_void_ptr_fn(), // release
    callable.nativeFunction,
  );

  final cpPointer = pointer.toCP<CPAuthLoginProvider>();

  // Mirrors presence's V3 callback freeable (SDKS-3134). Free order matters
  // for SDKS-3626: [0] tells the auth client to drop the provider so no new
  // callbacks are scheduled; [1] closes the NativeCallable. The SDK layer
  // free()s [0] first, awaits a drain delay, then free()s [1].
  //
  // We do NOT include `ditto_auth_login_provider_free`: setting the provider
  // on the auth client transfers ownership to it, and the auth client frees
  // the previous provider on replacement (or on null). Calling our own free
  // would be a double-free.
  final freeable = CPMultiFreeable([
    CPDartFnFreeable(() {
      bindings.ditto_auth_set_login_provider(dittoPtr.inner.cast(), nullptr);
    }),
    NativeCallableFreeable(callable),
  ]);

  return (cpPointer, freeable);
}

Future<void> dittoAuthSetLoginProvider(
  CPPointer<CPDitto> ditto,
  CPPointer<CPAuthLoginProvider>? provider,
) async {
  final dittoPtr = ditto.asFfi();
  final providerPtr = provider?.asFfi();
  bindings.ditto_auth_set_login_provider(
    dittoPtr.inner.cast(),
    providerPtr?.inner.cast() ?? nullptr,
  );
}

typedef _LoginRequest = ({int dittoPtr, String token, String provider});
typedef _LoginResponse = ({int statusCode, String? message});

Future<AuthResponse> dittoAuthClientLoginWithTokenAndFeedback(
  CPPointer<CPDitto> ditto,
  String token,
  String provider,
) async {
  final dittoPtr = ditto.asFfi();
  final dittoAddress = dittoPtr.address;
  final (statusCode: statusCode, message: message) = await compute(
    _dittoAuthClientLoginWithTokenAndFeedbackSync,
    (dittoPtr: dittoAddress, token: token, provider: provider),
  );

  return switch (statusCode) {
    0 => AuthResponse(message, null),
    1 => AuthResponse(
        message,
        privateMakeDittoException(
          "Error logging in. Status code $statusCode. Client info: $message",
        ),
      ),
    final other => throw privateMakeDittoError("unknown status code: $other"),
  };
}

_LoginResponse _dittoAuthClientLoginWithTokenAndFeedbackSync(
  _LoginRequest request,
) =>
    withStringsAsPtrs([request.token, request.provider], (ptrs) {
      final [tokenPtr, providerPtr] = ptrs;
      final result = bindings.ditto_auth_client_login_with_token_and_feedback(
        Pointer.fromAddress(request.dittoPtr),
        tokenPtr.cast(),
        providerPtr.cast(),
      );
      return (
        statusCode: result.status_code,
        message: nullableStringFromCharStar(result.c_string),
      );
    });

Future<CPResult<void>> dittoAuthClientLogout(CPPointer<CPDitto> ditto) async {
  final dittoPtr = ditto.asFfi();
  final result = bindings.ditto_auth_client_logout(dittoPtr.inner.cast());
  return switch (result) {
    0 => CPResult.legacyOk(null),
    1 => CPResult.legacyException(
        privateMakeDittoException(
          "Failed to log out (code $result)",
        ),
      ),
    _ => CPResult.legacyError(
        privateMakeDittoError(
          "Unknown error occurred (code $result)",
        ),
      ),
  };
}

String? dittoAuthClientUserId(CPPointer<CPDitto> ditto) {
  final dittoPtr = ditto.asFfi();
  return nullableStringFromCharStar(
    bindings.ditto_auth_client_user_id(dittoPtr.inner.cast()),
  );
}

bool dittoAuthClientIsWebValid(CPPointer<CPDitto> ditto) {
  final dittoPtr = ditto.asFfi();
  return switch (
      bindings.ditto_auth_client_is_web_valid(dittoPtr.inner.cast())) {
    0 => false,
    1 => true,
    final other => throw privateMakeDittoError("unknown int: $other"),
  };
}

String dittoffiGetDevelopmentProvider() {
  final cString = bindings.dittoffi_DITTO_DEVELOPMENT_PROVIDER();
  return stringFromCharStar(cString, free: false);
}
