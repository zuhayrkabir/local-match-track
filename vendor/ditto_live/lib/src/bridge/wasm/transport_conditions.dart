// ignore_for_file: ditto_missing_visibility
part of "wasm.dart";

CPFreeable dittoRegisterTransportConditionChangedCallback(
  CPPointer<CPDitto> peer,
  void Function(TransportConditionEvent event) callback,
) {
  // safer_ffi exposes the FFI enums as JS strings; see
  // sdks/js/sources/ffi.ts (ConditionSource / TransportCondition unions).
  final wrappedCallback = wrapBackgroundCbForFFI(
    onBackgroundError: (err, stackTrace) {
      dittoLog(
        LogLevel.error,
        "Transport condition callback failed: $err\n$stackTrace",
      );
    },
    (JSString jsSource, JSString jsCondition) {
      callback(
        TransportConditionEvent(
          condition: _transportConditionFromJS(jsCondition),
          source: _conditionSourceFromJS(jsSource),
        ),
      );
    },
  );

  _dittoCore.dittoRegisterTransportConditionChangedCallback(
    peer.asWasm(),
    wrappedCallback,
  );

  return CPDartFnFreeable(() {
    _dittoCore.dittoRegisterTransportConditionChangedCallback(
      peer.asWasm(),
      null,
    );
  });
}

TransportCondition _transportConditionFromJS(JSString js) =>
    switch (js.toDart) {
      "Unknown" => TransportCondition.unknown,
      "Ok" => TransportCondition.ok,
      "GenericFailure" => TransportCondition.genericFailure,
      "AppInBackground" => TransportCondition.appInBackground,
      "MdnsFailure" => TransportCondition.mdnsFailure,
      "TcpListenFailure" => TransportCondition.tcpListenFailure,
      "NoBleCentralPermission" => TransportCondition.noBleCentralPermission,
      "NoBlePeripheralPermission" =>
        TransportCondition.noBlePeripheralPermission,
      "CannotEstablishConnection" =>
        TransportCondition.cannotEstablishConnection,
      "BleDisabled" => TransportCondition.bleDisabled,
      "NoBleHardware" => TransportCondition.noBleHardware,
      "WifiDisabled" => TransportCondition.wifiDisabled,
      "TemporarilyUnavailable" => TransportCondition.temporarilyUnavailable,
      _ => TransportCondition.unknown,
    };

TransportConditionSource _conditionSourceFromJS(JSString js) =>
    switch (js.toDart) {
      "Bluetooth" => TransportConditionSource.bluetooth,
      "Tcp" => TransportConditionSource.tcp,
      "Awdl" => TransportConditionSource.awdl,
      "Mdns" => TransportConditionSource.mdns,
      "WiFiAware" => TransportConditionSource.wifiAware,
      _ => TransportConditionSource.unknown,
    };

// Test-only accessors for the unknown-input degrade path of the decoders.
// Symmetric with the native bridge so SDKS-3847's regression test can call
// through the cross-platform `bridge.dart` conditional export and exercise
// whichever decoder is loaded. The sentinel string is deliberately not a
// member of the JS-side ConditionSource / TransportCondition union (see
// `sdks/js/sources/ffi.ts`); the test asserts only the fall-through branch.

// Sentinel strings deliberately not members of the JS-side ConditionSource /
// TransportCondition union (see `sdks/js/sources/ffi.ts`). The double-
// underscore + `ditto_` prefix makes them obviously not real variants.
const String _kUnknownSentinelSource = "__ditto_unknown_sentinel_source__";
const String _kUnknownSentinelCondition =
    "__ditto_unknown_sentinel_condition__";

/// Test-only: returns the result of decoding a sentinel `ConditionSource` JS
/// string that is not a documented variant. Used by the SDKS-3847 regression
/// test to assert the decoder degrades to `.unknown`.
@visibleForTesting
TransportConditionSource debugDecodeUnknownConditionSource() =>
    _conditionSourceFromJS(_kUnknownSentinelSource.toJS);

/// Test-only: returns the result of decoding a sentinel `TransportCondition`
/// JS string that is not a documented variant. Used by the SDKS-3847
/// regression test to assert the decoder degrades to `.unknown`.
@visibleForTesting
TransportCondition debugDecodeUnknownTransportCondition() =>
    _transportConditionFromJS(_kUnknownSentinelCondition.toJS);
