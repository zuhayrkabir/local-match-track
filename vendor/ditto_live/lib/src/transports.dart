import "package:cbor/simple.dart";
import "package:flutter/services.dart";
import "package:meta/meta.dart";

import "bridge/bridge.dart" as core;

import "shared/cbor.dart";
import "supported_platform.dart";
import "ditto.dart";
import "sync_permissions.dart";
import "transport_config.dart";

@internal
Future<void> initializeAndroidContext() async {
  if (Ditto.currentPlatform == SupportedPlatform.android) {
    // Same Kotlin DittoPlugin channel as DittoSyncPermissions — reference the
    // shared constant so a rename in production source breaks compile here
    // too, not just at runtime on Android.
    await MethodChannel(DittoSyncPermissions.channelName)
        .invokeMethod("setAndroidContext");
  }
}

@internal
TransportConfig getTransportConfig(Ditto ditto) {
  final bytes = core.dittoFfiDittoTransportConfig(ditto.ptr);
  return transportConfigFromCborBytes(bytes.bytes);
}

@internal
void setTransportConfig(Ditto ditto, TransportConfig value) {
  // ignore: avoid_dynamic_calls
  final bytes = cbor.encode(value.toJson(), toEncodable: (obj) => obj.toJson());
  core
      .dittoFfiDittoTrySetTransportConfig(ditto.ptr, Uint8List.fromList(bytes))
      .extract();
}

@internal
TransportConfig transportConfigFromCborBytes(Uint8List bytes) {
  final decoded = decodeTrivialCbor(bytes) as Map<String, dynamic>;
  return TransportConfig.fromJson(decoded);
}
