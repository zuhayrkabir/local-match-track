// ignore_for_file: ditto_missing_visibility
part of "wasm.dart";

CPResult<void> dittoFfiDittoTryStartSync(CPPointer<CPDitto> ditto) => _dittoCore
    .dittoffiDittoTryStartSync(
      ditto.asWasm(),
    )
    .toCP();

void dittoFfiDittoStopSync(CPPointer<CPDitto> ditto) =>
    _dittoCore.dittoffiDittoStopSync(
      ditto.asWasm(),
    );

bool dittoFfiDittoIsSyncActive(CPPointer<CPDitto> ditto) => _dittoCore
    .dittoffiDittoIsSyncActive(
      ditto.asWasm(),
    )
    .toDart;

CPResult<CPPointer<CPSyncSubscription>> dittoFfiSyncRegisterSubscriptionThrows(
  CPPointer<CPDitto> ditto,
  String query,
  Uint8List queryArgumentsCBOR,
) {
  final queryBytes = bytesFromString(query);
  final resultJS = _dittoCore.dittoffiSyncRegisterSubscriptionThrows(
    ditto.asWasm(),
    queryBytes.toJS,
    queryArgumentsCBOR.toJS,
  );
  return resultJS.toCP().map((item) => item!.toCP());
}

bool dittoFfiSyncSubscriptionIsCancelled(
  CPPointer<CPSyncSubscription> subscription,
) {
  return _dittoCore
      .dittoFfiSyncSubscriptionIsCancelled(
        subscription.asWasm(),
      )
      .toDart;
}

void dittoFfiSyncSubscriptionCancel(
  CPPointer<CPSyncSubscription> subscription,
) {
  _dittoCore.dittoFfiSyncSubscriptionCancel(
    subscription.asWasm(),
  );
}

void dittoFfiSyncSubscriptionFree(
  CPPointer<CPSyncSubscription> subscription,
) {
  _dittoCore.dittoFfiSyncSubscriptionFree(
    subscription.asWasm(),
  );
}

String dittoFfiSyncSubscriptionQueryString(
  CPPointer<CPSyncSubscription> subscription,
) {
  final queryStringPointer = _dittoCore.dittoFfiSyncSubscriptionQueryString(
    subscription.asWasm(),
  );
  return _dittoCore.boxCStringIntoString(queryStringPointer)!.toDart;
}

Uint8List dittoFfiSyncSubscriptionQueryArgumentsCbor(
  CPPointer<CPSyncSubscription> subscription,
) {
  final queryArgsBytes = _dittoCore.dittoFfiSyncSubscriptionQueryArgumentsCbor(
    subscription.asWasm(),
  );
  return _dittoCore.boxCBytesIntoBuffer(queryArgsBytes)!.toDart;
}

String dittoFfiSyncSubscriptionQueryArgumentsJson(
  CPPointer<CPSyncSubscription> subscription,
) {
  final queryArgsJsonBytes =
      _dittoCore.dittoFfiSyncSubscriptionQueryArgumentsJson(
    subscription.asWasm(),
  );

  final jsonBuffer = _dittoCore.boxCBytesIntoBuffer(queryArgsJsonBytes);
  return utf8.decode(jsonBuffer!.toDart);
}

Uint8List dittoFfiSyncSubscriptionId(
  CPPointer<CPSyncSubscription> subscription,
) {
  final idBytes = _dittoCore.dittoFfiSyncSubscriptionId(
    subscription.asWasm(),
  );
  return _dittoCore.boxCBytesIntoBuffer(idBytes)!.toDart;
}

List<CPPointer<CPSyncSubscription>> dittoFfiSyncSubscriptions(
  CPPointer<CPDitto> peer,
) {
  final syncSubJSPtrs = _dittoCore
      .dittoFfiSyncSubscriptions(
        peer.asWasm(),
      )
      .toDart;

  return syncSubJSPtrs.map((ptr) => ptr.toCP()).toList();
}
