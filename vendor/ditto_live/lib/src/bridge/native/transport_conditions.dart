// ignore_for_file: ditto_missing_visibility, ditto_store_ditto_ptr
part of "native.dart";

/// Registers a callback that fires whenever a transport reports a new
/// condition.
///
/// The returned [CPFreeable] is a [CPMultiFreeable] whose first member
/// unregisters the native callback (passing `null` to
/// `ditto_register_transport_condition_changed_callback`) and whose second
/// member closes the [NativeCallable]. Drain in-flight callbacks between the
/// two steps; see SDKS-3134 for the rationale.
CPFreeable dittoRegisterTransportConditionChangedCallback(
  CPPointer<CPDitto> ditto,
  void Function(TransportConditionEvent event) callback,
) {
  final dittoPtr = ditto.asFfi();

  void wrapped(Pointer<Void> ctx, int rawSource, int rawCondition) {
    callback(
      TransportConditionEvent(
        condition: _transportConditionFromInt(rawCondition),
        source: _conditionSourceFromInt(rawSource),
      ),
    );
  }

  final callable = NativeCallable<
      Void Function(
        Pointer<Void>,
        Int32,
        Int32,
      )>.listener(wrapped);

  bindings.ditto_register_transport_condition_changed_callback(
    dittoPtr.inner.cast(),
    nullptr,
    // The Dart side owns callback lifetime via [NativeCallable]; reuse the
    // shared no-op retain/release pair from the FFI. See
    // doc_internal/src/architecture/core_api.md "Ref Count and Ownership".
    bindings.dittoffi_get_noop_void_ptr_fn(),
    bindings.dittoffi_get_noop_void_ptr_fn(),
    callable.nativeFunction,
  );

  return CPMultiFreeable([
    CPDartFnFreeable(
      () => _dittoUnregisterTransportConditionChangedCallback(
        dittoPtr.inner.cast(),
      ),
    ),
    NativeCallableFreeable(callable),
  ]);
}

void _dittoUnregisterTransportConditionChangedCallback(
  Pointer<CDitto_t> dittoPtr,
) {
  // Passing nullptr for all four params is the documented unregister path
  // (see crates/dittoffi/src/ditto.rs ditto_register_transport_condition_changed_callback_js).
  bindings.ditto_register_transport_condition_changed_callback(
    dittoPtr,
    nullptr,
    nullptr,
    nullptr,
    nullptr,
  );
}

// Mirrors integer values in dittoffi.h TransportCondition_t. Unknown values
// degrade to `TransportCondition.unknown` so older Flutter SDKs do not crash
// if the FFI grows new conditions.
TransportCondition _transportConditionFromInt(int raw) => switch (raw) {
      generated_bindings.TransportCondition.TRANSPORT_CONDITION_UNKNOWN =>
        TransportCondition.unknown,
      generated_bindings.TransportCondition.TRANSPORT_CONDITION_OK =>
        TransportCondition.ok,
      generated_bindings
            .TransportCondition.TRANSPORT_CONDITION_GENERIC_FAILURE =>
        TransportCondition.genericFailure,
      generated_bindings
            .TransportCondition.TRANSPORT_CONDITION_APP_IN_BACKGROUND =>
        TransportCondition.appInBackground,
      generated_bindings.TransportCondition.TRANSPORT_CONDITION_MDNS_FAILURE =>
        TransportCondition.mdnsFailure,
      generated_bindings
            .TransportCondition.TRANSPORT_CONDITION_TCP_LISTEN_FAILURE =>
        TransportCondition.tcpListenFailure,
      generated_bindings
            .TransportCondition.TRANSPORT_CONDITION_NO_BLE_CENTRAL_PERMISSION =>
        TransportCondition.noBleCentralPermission,
      generated_bindings.TransportCondition
            .TRANSPORT_CONDITION_NO_BLE_PERIPHERAL_PERMISSION =>
        TransportCondition.noBlePeripheralPermission,
      generated_bindings.TransportCondition
            .TRANSPORT_CONDITION_CANNOT_ESTABLISH_CONNECTION =>
        TransportCondition.cannotEstablishConnection,
      generated_bindings.TransportCondition.TRANSPORT_CONDITION_BLE_DISABLED =>
        TransportCondition.bleDisabled,
      generated_bindings
            .TransportCondition.TRANSPORT_CONDITION_NO_BLE_HARDWARE =>
        TransportCondition.noBleHardware,
      generated_bindings.TransportCondition.TRANSPORT_CONDITION_WIFI_DISABLED =>
        TransportCondition.wifiDisabled,
      generated_bindings
            .TransportCondition.TRANSPORT_CONDITION_TEMPORARILY_UNAVAILABLE =>
        TransportCondition.temporarilyUnavailable,
      _ => TransportCondition.unknown,
    };

// Mirrors integer values in dittoffi.h ConditionSource_t. Unknown values
// degrade to `TransportConditionSource.unknown` so older Flutter SDKs do not
// crash (NativeCallable.listener cannot throw) if the FFI grows new sources.
TransportConditionSource _conditionSourceFromInt(int raw) => switch (raw) {
      generated_bindings.ConditionSource.CONDITION_SOURCE_BLUETOOTH =>
        TransportConditionSource.bluetooth,
      generated_bindings.ConditionSource.CONDITION_SOURCE_TCP =>
        TransportConditionSource.tcp,
      generated_bindings.ConditionSource.CONDITION_SOURCE_AWDL =>
        TransportConditionSource.awdl,
      generated_bindings.ConditionSource.CONDITION_SOURCE_MDNS =>
        TransportConditionSource.mdns,
      generated_bindings.ConditionSource.CONDITION_SOURCE_WIFI_AWARE =>
        TransportConditionSource.wifiAware,
      _ => TransportConditionSource.unknown,
    };

// Test-only accessors for the unknown-input degrade path of the decoders.
// `NativeCallable.listener` cannot throw, so a SIGABRT-risk regression would
// be the decoders panicking instead of returning `.unknown` when the FFI
// grows a new variant ahead of this SDK. See SDKS-3847. The integer literal
// is deliberately well outside any documented `ConditionSource_t` or
// `TransportCondition_t` value; the test asserts only the fall-through
// branch, not a specific raw value.

// Raw integer chosen as a sentinel: well outside any documented
// `ConditionSource_t` / `TransportCondition_t` value at the time SDKS-3847
// landed (max variants then were 4 / 12 respectively). The Dart switch
// matches on exact identity, so 9999 will hit the `_` fall-through arm
// even if the FFI grows substantially.
const int _kUnknownRawSentinel = 9999;

/// Test-only: returns the result of decoding a sentinel `ConditionSource_t`
/// value that is not a documented variant. Used by the SDKS-3847 regression
/// test to assert the decoder degrades to `.unknown` rather than panic.
@visibleForTesting
TransportConditionSource debugDecodeUnknownConditionSource() =>
    _conditionSourceFromInt(_kUnknownRawSentinel);

/// Test-only: returns the result of decoding a sentinel `TransportCondition_t`
/// value that is not a documented variant. Used by the SDKS-3847 regression
/// test to assert the decoder degrades to `.unknown` rather than panic.
@visibleForTesting
TransportCondition debugDecodeUnknownTransportCondition() =>
    _transportConditionFromInt(_kUnknownRawSentinel);
