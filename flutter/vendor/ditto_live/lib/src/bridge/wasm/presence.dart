// ignore_for_file: ditto_missing_visibility
part of "wasm.dart";

JSString connectionRequestAuthorizationToJS(
  ConnectionRequestAuthorization value,
) =>
    switch (value) {
      ConnectionRequestAuthorization.allow => "Allow",
      ConnectionRequestAuthorization.deny => "Deny",
    }
        .toJS;

ConnectionType connectionTypeFromJS(JSString jsConnectionType) =>
    switch (jsConnectionType.toDart) {
      "P2PWiFi" => ConnectionType.p2pWifi,
      "WebSocket" => ConnectionType.webSocket,
      "AccessPoint" => ConnectionType.accessPoint,
      "Bluetooth" => ConnectionType.bluetooth,
      "Multicast" => ConnectionType.multicast,
      _ => throw privateMakeDittoError(
          "Unknown connection type: $jsConnectionType",
        ),
    };

String dittoPresenceV3(CPPointer<CPDitto> ditto) {
  // Presence is guaranteed to be available after initialization.
  return _dittoCore
      .boxCStringIntoString(
        _dittoCore.dittoPresenceV3(ditto.asWasm()),
      )!
      .toDart;
}

String dittoFfiPresencePeerMetadataJson(CPPointer<CPDitto> peer) {
  final jsonBytesRef = _dittoCore.dittoFfiPresencePeerMetadataJson(
    peer.asWasm(),
  );
  final jsonBuffer = _dittoCore.boxCBytesIntoBuffer(jsonBytesRef);
  return utf8.decode(jsonBuffer!.toDart);
}

Future<CPResult<void>> dittoFfiPresenceTrySetPeerMetadataJson(
  CPPointer<CPDitto> peer,
  String metadata,
) async {
  final jsResult = await _dittoCore
      .dittoFfiPresenceTrySetPeerMetadataJson(
        peer.asWasm(),
        bytesFromString(metadata).toJS,
      )
      .toDart;
  return jsResult.toCP();
}

/// Registers a presence observer.
///
/// The JS/wasm layer does not yet expose the modern observer-handle FFI
/// (`dittoffi_presence_register_observer_throws`) — until it does, this
/// bridge delegates to the legacy `ditto_register_presence_v3_callback`.
/// The returned freeable clears the callback on the JS side; the JS runtime
/// GC handles the wrapper's lifetime, so no additional drain is required.
CPFreeable dittoRegisterPresenceObserver(
  CPPointer<CPDitto> peer,
  void Function(String json) callback,
) {
  final wrappedCallback = wrapBackgroundCbForFFI(
    onBackgroundError: (err, stackTrace) {
      dittoLog(
        LogLevel.error,
        "The registered presence callback failed: $err\n$stackTrace",
      );
    },
    (_JSPointer<CPCString> jsonCString) {
      final json = _dittoCore.refCStringToString(jsonCString)!.toDart;
      callback(json);
    },
  );
  _dittoCore.dittoRegisterPresenceV3Callback(
    peer.asWasm(),
    wrappedCallback,
  );

  return CPDartFnFreeable(() {
    _dittoCore.dittoClearPresenceV3Callback(peer.asWasm());
  });
}

//
// Connection Handling
//

CPFreeable dittoFfiPresenceSetConnectionRequestHandler(
  CPPointer<CPDitto> peer,
  Future<ConnectionRequestAuthorization> Function(
    CPPointer<CPConnectionRequest>,
  )? handler,
) {
  if (handler == null) {
    _dittoCore
        .dittoffiPresenceSetConnectionRequestHandler(
          peer.asWasm(),
          null,
        )
        ?.toCP()
        .extract();
    return CPFreeable.noop();
  }

  void onError(dynamic err, StackTrace stackTrace) {
    dittoLog(
      LogLevel.error,
      "The registered connection request handler failed: $err\n$stackTrace",
    );
  }

  Future<void> wrappedHandler(
    _JSPointer<CPConnectionRequest> request,
  ) =>
      runConnectionRequestHandler(
        request: request.toCP(),
        handler: handler,
        authorize: dittoFfiConnectionRequestAuthorize,
        free: dittoffiConnectionRequestFree,
        onError: onError,
      );

  final result = _dittoCore.dittoffiPresenceSetConnectionRequestHandler(
    peer.asWasm(),
    wrapBackgroundCbForFFI(onBackgroundError: onError, wrappedHandler),
  );
  result?.toCP().extract();
  return CPFreeable.noop();
}

void dittoFfiConnectionRequestAuthorize(
  CPPointer<CPConnectionRequest> request,
  ConnectionRequestAuthorization authorization,
) =>
    _dittoCore.dittoFfiConnectionRequestAuthorize(
      request.asWasm(),
      connectionRequestAuthorizationToJS(authorization),
    );

void dittoffiConnectionRequestFree(CPPointer<CPConnectionRequest> request) =>
    _dittoCore.dittoffiConnectionRequestFree(request.asWasm());

ConnectionType dittoFfiConnectionRequestConnectionType(
  CPPointer<CPConnectionRequest> request,
) {
  final jsConnectionType = _dittoCore.dittoFfiConnectionRequestConnectionType(
    request.asWasm(),
  );
  return connectionTypeFromJS(jsConnectionType);
}

String dittoFfiConnectionRequestPeerKeyString(
  CPPointer<CPConnectionRequest> request,
) {
  final peerKeyCString = _dittoCore.dittoFfiConnectionRequestPeerKeyString(
    request.asWasm(),
  );
  return _dittoCore.boxCStringIntoString(peerKeyCString)!.toDart;
}

String dittoFfiConnectionRequestIdentityServiceMetadataJson(
  CPPointer<CPConnectionRequest> request,
) {
  final jsonBytesRef =
      _dittoCore.dittoFfiConnectionRequestIdentityServiceMetadataJson(
    request.asWasm(),
  );
  final jsonBuffer = _dittoCore.refCBytesIntoBuffer(jsonBytesRef);
  return utf8.decode(jsonBuffer!.toDart);
}

String dittoFfiConnectionRequestPeerMetadataJson(
  CPPointer<CPConnectionRequest> request,
) {
  final jsonBytesRef = _dittoCore.dittoFfiConnectionRequestPeerMetadataJson(
    request.asWasm(),
  );
  final jsonBuffer = _dittoCore.refCBytesIntoBuffer(jsonBytesRef);
  return utf8.decode(jsonBuffer!.toDart);
}
