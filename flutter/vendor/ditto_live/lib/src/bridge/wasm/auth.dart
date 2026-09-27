// ignore_for_file: ditto_missing_visibility
part of "wasm.dart";

extension type _JSAuthResponse._(JSObject _) implements JSObject {
  @JS("status_code")
  external JSNumber get _statusCode;

  @JS("c_string")
  external _JSPointer<CPCString>? get _cString;

  factory _JSAuthResponse(JSObject value) {
    final self = _JSAuthResponse._(value);

    assert(self._statusCode == self._statusCode);
    assert(self._cString == self._cString);

    return self;
  }

  AuthResponse toCP() {
    final userInfo = _dittoCore.boxCStringIntoString(_cString);
    // Our `login_with_token_and_feedback()` API returns the `clientInfo` string
    // even when authentication has failed, so this function does not throw an
    // error when the status code is non-zero.
    return switch (_statusCode) {
      0 => AuthResponse(userInfo?.toDart, null),
      _ => AuthResponse(
          userInfo?.toDart,
          privateMakeDittoException(
            _errorMessageThreadLocal() ??
                "Ditto failed to authenticate (status code: $_statusCode)",
          ),
        ),
    };
  }
}

Future<AuthResponse> dittoAuthClientLoginWithTokenAndFeedback(
  CPPointer<CPDitto> peer,
  String token,
  String provider,
) async {
  final tokenBytes = bytesFromString(token);
  final providerBytes = bytesFromString(provider);

  final result = await _dittoCore
      .dittoAuthClientLoginWithTokenAndFeedback(
        peer.asWasm(),
        tokenBytes.toJS,
        providerBytes.toJS,
      )
      .toDart;

  return result.toCP();
}

Future<CPResult<void>> dittoAuthClientLogout(CPPointer<CPDitto> peer) async {
  final statusCode = await _dittoCore
      .dittoAuthClientLogout(
        peer.asWasm(),
      )
      .toDart;

  return switch (statusCode) {
    0 => CPResult.legacyOk(null),
    1 => CPResult.legacyException(
        privateMakeDittoException(
          _errorMessageThreadLocal() ??
              "Ditto failed to log out (code: $statusCode)",
        ),
      ),
    _ => throw privateMakeDittoError(
        "Unknown error occurred (code $statusCode)",
      ),
  };
}

String? dittoAuthClientUserId(CPPointer<CPDitto> ditto) {
  final cString = _dittoCore.dittoAuthClientUserId(ditto.asWasm());
  return _dittoCore.boxCStringIntoString(cString)?.toDart;
}

(CPPointer<CPAuthLoginProvider>, CPFreeable) dittoAuthClientMakeLoginProvider(
  CPPointer<CPDitto> ditto,
  void Function(int seconds) expiringCallback,
) {
  final provider = _dittoCore
      .dittoAuthClientMakeLoginProvider(
        wrapBackgroundCbForFFI(
          (JSNumber seconds) => expiringCallback(seconds.toDartInt),
        ),
      )
      .toCP();

  // Web has no NativeCallable so the SDKS-3626 pre-shutdown cleanup is a no-op.
  return (provider, CPFreeable.noop());
}

Future<void> dittoAuthSetLoginProvider(
  CPPointer<CPDitto> ditto,
  CPPointer<CPAuthLoginProvider>? provider,
) async =>
    _dittoCore
        .dittoAuthSetLoginProvider(
          ditto.asWasm(),
          provider?.asWasm(),
        )
        .toDart;

bool dittoAuthClientIsWebValid(CPPointer<CPDitto> ditto) =>
    switch (_dittoCore.dittoAuthClientIsWebValid(ditto.asWasm()).toDartInt) {
      0 => false,
      1 => true,
      final other => throw privateMakeDittoError(
          "Unexpected auth client web validity: $other",
        ),
    };

String dittoffiGetDevelopmentProvider() {
  final cString = _dittoCore.dittoffiGetDevelopmentProvider();
  // dittoffi_DITTO_DEVELOPMENT_PROVIDER returns `char const *` (borrowed),
  // so use refCStringToString — boxCStringIntoString would take ownership
  // and crash the WASM dispatcher. The pointer is a process-lifetime
  // static, so refCStringToString never returns null.
  return _dittoCore.refCStringToString(cString)!.toDart;
}
