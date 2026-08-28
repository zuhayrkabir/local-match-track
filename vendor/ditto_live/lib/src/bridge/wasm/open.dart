// ignore_for_file: ditto_missing_visibility
part of "wasm.dart";

Future<CPResult<CPPointer<CPDitto>>> dittoffiDittoOpenAsyncThrows(
  Uint8List configCbor,
  CPTransportConfigMode mode,
  String defaultRootDirectory,
) async {
  final modeString = switch (mode) {
    CPTransportConfigMode.platformDependent => "PlatformDependent",
    CPTransportConfigMode.platformIndependent => "PlatformIndependent",
  };

  final completer = Completer<_JSResult<_JSPointer<CPDitto>>>();

  _dittoCore.dittoffiDittoOpenAsyncThrows(
    configCbor.toJS,
    modeString.toJS,
    bytesFromString(defaultRootDirectory).toJS,
    _JSVoidCalback1.fromDart(completer.complete),
  );

  final result = await completer.future;

  return result.toCP().map((ptr) => ptr!.toCP());
}

CPResult<CPPointer<CPDitto>> dittoffiDittoOpenThrows(
  Uint8List configCbor,
  CPTransportConfigMode mode,
  String defaultRootDirectory,
) {
  final modeString = switch (mode) {
    CPTransportConfigMode.platformDependent => "PlatformDependent",
    CPTransportConfigMode.platformIndependent => "PlatformIndependent",
  };

  final result = _dittoCore.dittoffiDittoOpenThrows(
    configCbor.toJS,
    modeString.toJS,
    bytesFromString(defaultRootDirectory).toJS,
  );

  return result.toCP().map((ptr) => ptr!.toCP());
}

Uint8List dittoffiDittoConfig(CPPointer<CPDitto> ditto) {
  final bytes = _dittoCore.dittoffiDittoConfig(ditto.asWasm());
  return _dittoCore.boxCBytesIntoBuffer(bytes)!.toDart;
}

String dittoffiDittoAbsolutePersistenceDirectory(CPPointer<CPDitto> ditto) {
  final cString =
      _dittoCore.dittoffiDittoAbsolutePersistenceDirectory(ditto.asWasm());
  return _dittoCore.boxCStringIntoString(cString)!.toDart;
}

Uint8List dittffiDittoConfigDefault() {
  final bytes = _dittoCore.dittoffiDittoConfigDefault();
  return _dittoCore.boxCBytesIntoBuffer(bytes)!.toDart;
}
