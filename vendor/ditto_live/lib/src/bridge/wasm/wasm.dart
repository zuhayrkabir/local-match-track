// This file is never used in non-web platforms.
// ignore_for_file: avoid_web_libraries_in_flutter
// ignore_for_file: ditto_missing_visibility

import "dart:async";
import "dart:convert";
import "dart:core";
import "dart:js_interop";

import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:meta/meta.dart";

import "../../exception.dart";
import "../../presence/presence.dart";
import "../../presence/presence_graph.dart";
import "../../supported_platform.dart";
import "../../store/transaction.dart";
import "../../transport_conditions.dart";
import "../cross_platform/connection_request_lifecycle.dart";
import "../cross_platform/constants.dart";
import "../cross_platform/error.dart";
import "../cross_platform/freeable.dart";
import "../cross_platform/types.dart";

part "types.dart";
part "error.dart";
part "util.dart";
part "ditto_core.dart";
part "auth.dart";
part "open.dart";
part "differ.dart";
part "identity.dart";
part "init.dart";
part "logger.dart";
part "presence.dart";
part "store.dart";
part "sync.dart";
part "small_peer_info.dart";
part "transport_conditions.dart";

// we can incrementally remove these when we want to add web support
Never get _$ => throw UnsupportedError("Wasm is currently not supported");

Never get _noWebSupport$ =>
    throw UnsupportedError("Not supported on the web platform");

String dittoGetSdkSemver() {
  final cStringPointer = _dittoCore.dittoffiGetSdkSemver();
  // As dittoffiGetSdkSemver() is not fallible, we can safely unwrap the result.
  return _dittoCore.boxCStringIntoString(cStringPointer)!.toDart;
}

CPPointer<CPDitto> dittoMake(
  String path,
  CPPointer<CPIdentityConfig> identityConfig,
) {
  final pathBytes = bytesFromString(path);

  // "Platform dependent" transport config mode enables/disables transports
  // depending on the current platform. In this case, p2p transports are
  // disabled in the Wasm build.
  final transportConfigMode = "PlatformDependent".toJS;

  final dittoPointer = _dittoCore.dittoMakeWithTransportConfigMode(
    pathBytes.toJS,
    identityConfig.asWasm(),
    transportConfigMode,
  );
  return _WasmPointer(dittoPointer);
}

/// Retrieves and resets any thread-local error message. May return `null` even
/// if an error message has been set (see CORE-233).
String? _errorMessageThreadLocal() {
  final cStringPointer = _dittoCore.dittoErrorMessage();
  return _dittoCore.boxCStringIntoString(cStringPointer)?.toDart;
}

void dittoInitSdkVersion() {
  // On the web this is set during initialization with [init].
}

Future<void> dittoShutdown(CPPointer<CPDitto> peer) =>
    _dittoCore.dittoShutdown(peer.asWasm()).toDart;

// === Peer Management Functions ===
String dittoSetDeviceName(CPPointer<CPDitto> ditto, String deviceName) {
  final deviceNameBytes = bytesFromString(deviceName);
  final truncatedDeviceNameCString = _dittoCore.dittoSetDeviceName(
    ditto.asWasm(),
    deviceNameBytes.toJS,
  );
  return _dittoCore.boxCStringIntoString(truncatedDeviceNameCString)!.toDart;
}

bool dittoIsActivated(CPPointer<CPDitto> ditto) => _dittoCore
    .dittoffiDittoIsActivated(
      ditto.asWasm(),
    )
    .toDart;

CPResult<void> dittoFfiTryVerifyLicense(
  CPPointer<CPDitto> ditto,
  String licenseKey,
) =>
    _dittoCore
        .dittoffiTryVerifyLicense(
          ditto.asWasm(),
          bytesFromString(licenseKey).toJS,
        )
        .toCP();

CPResult<void> dittoSdkTransportsInit() {
  // This is a no-op on the web platform.
  return CPResult.legacyOk(null);
}

CPBytes dittoFfiDittoTransportConfig(CPPointer<CPDitto> peer) {
  final configPointer = _dittoCore.dittoffiDittoTransportConfig(
    (peer as _WasmPointer)._inner,
  );
  // dittoffi_ditto_transport_config() is guaranteed to return a non-null
  // pointer.
  final bytes = _dittoCore.boxCBytesIntoBuffer(configPointer)!.toDart;
  return _WasmBytes(bytes);
}

CPResult<void> dittoFfiDittoTrySetTransportConfig(
  CPPointer<CPDitto> peer,
  Uint8List transportConfig,
) {
  _dittoCore
      .dittoffiDittoTrySetTransportConfig(
        (peer as _WasmPointer)._inner,
        transportConfig.toJS,
        true.toJS,
      )
      .toCP()
      .extract();
  return CPResult.legacyOk(null);
}

Future<void> dittoRunGarbageCollection(CPPointer<CPDitto> peer) => _$;

// === Identity ===
// see ./identity.dart

// === Authentication Functions ===
// see ./auth.dart

// === Sync Functions ===
// see ./sync.dart

// === Error Handling Functions ===
int dittoFfiErrorCode() => _$;
String dittoErrorMessagePeek() => _$;
String dittoErrorMessage() => _$;

// === Small Peer Info ===
// See ./small_peer_info.dart

// === Logger Functions ===
// See ./logger.dart

typedef CPCancelToken = int;

// === Type Utilities ===

JSString _paddingModeToJS(CPBase64PaddingMode mode) => switch (mode) {
      CPBase64PaddingMode.padded => "Padded".toJS,
      CPBase64PaddingMode.unpadded => "Unpadded".toJS,
    };

String dittoFfiBase64Encode(Uint8List bytes, CPBase64PaddingMode mode) {
  final base64CString =
      _dittoCore.base64encode(bytes.toJS, _paddingModeToJS(mode));
  return _dittoCore.boxCStringIntoString(base64CString)!.toDart;
}

CPResult<Uint8List> dittoFfiTryBase64Decode(
  String base64String,
  CPBase64PaddingMode mode,
) {
  final base64BytesPointer = bytesFromString(base64String);
  final resultJS = _dittoCore.tryBase64decode(
    base64BytesPointer.toJS,
    _paddingModeToJS(mode),
  );

  final slice = resultJS.toCP().extract();
  final x = _dittoCore.boxCBytesIntoBuffer(slice);
  return CPResult.legacyOk(x!.toDart);
}

// === Finalizers ===
void dittoCStringFree(CPPointer<CPCString> cString) =>
    _dittoCore.dittoCStringFree(cString.asWasm());
void dittoDocumentFree(CPPointer<CPDocument> document) =>
    _dittoCore.dittoDocumentFree(document.asWasm());
void dittoFfiErrorFree(CPPointer<CPError> error) =>
    _dittoCore.dittoffiErrorFree(error.asWasm());
void dittoFfiQueryResultFree(CPPointer<CPQueryResult> queryResult) =>
    _dittoCore.dittoffiQueryResultFree(queryResult.asWasm());
void dittoFree(CPPointer<CPDitto> pointer) =>
    _dittoCore.dittoFree(pointer.asWasm());

void utilValidatePersistenceDirectory(String path) {
  if (path.isEmpty) {
    throw ArgumentError(
      "Expected a persistence directory but got an empty string",
    );
  }
}

Future<String?> utilApplicationDocumentsDir() async => null;
SupportedPlatform utilGetCurrentPlatform() => SupportedPlatform.web;

Future<void> utilFileCopy(String source, String destination) => _noWebSupport$;

CPResult<Uint8List> dittoffiCborRoundTrip(String type, Uint8List bytes) {
  final typeBytes = bytesFromString(type);
  final result = _dittoCore.dittoffiCborRoundTrip(typeBytes.toJS, bytes.toJS);
  return result
      .toCP()
      .map((bytes) => _dittoCore.boxCBytesIntoBuffer(bytes)!.toDart);
}

Uint8List dittoffiTransportConfigNew() {
  final bytes = _dittoCore.dittoffiTransportConfigNew();
  return _dittoCore.boxCBytesIntoBuffer(bytes)!.toDart;
}
