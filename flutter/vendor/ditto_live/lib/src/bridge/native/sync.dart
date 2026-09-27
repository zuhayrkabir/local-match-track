// ignore_for_file: ditto_missing_visibility, ditto_store_ditto_ptr
part of "native.dart";

final _syncSubscriptionFinalizer = NativeFinalizer(
  bindings.addresses.dittoffi_sync_subscription_free.cast(),
);

CPResult<void> dittoFfiDittoTryStartSync(CPPointer<CPDitto> ditto) {
  final dittoPtr = ditto.asFfi();
  return _NativeResult(
    bindings.dittoffi_ditto_try_start_sync(dittoPtr.inner.cast()),
    getSuccess: (_) {},
    getError: (res) => res.error,
  );
}

void dittoFfiDittoStopSync(CPPointer<CPDitto> ditto) {
  final dittoPtr = ditto.asFfi();
  bindings.dittoffi_ditto_stop_sync(dittoPtr.inner.cast());
}

bool dittoFfiDittoIsSyncActive(CPPointer<CPDitto> ditto) {
  final dittoPtr = ditto.asFfi();
  return bindings.dittoffi_ditto_is_sync_active(dittoPtr.inner.cast());
}

CPResult<CPPointer<CPSyncSubscription>> dittoFfiSyncRegisterSubscriptionThrows(
  CPPointer<CPDitto> ditto,
  String query,
  Uint8List queryArgumentsCBOR,
) {
  final dittoPtr = ditto.asFfi();
  final result = withQueryAndArgs(
    query: query,
    argsCbor: queryArgumentsCBOR,
    (queryPtr, argsSlice) =>
        bindings.dittoffi_sync_register_subscription_throws(
      dittoPtr.inner.cast(),
      queryPtr,
      argsSlice,
    ),
  );

  return _NativeResult(
    result,
    getSuccess: (res) {
      final pointer = res.success.toCP<CPSyncSubscription>();
      _syncSubscriptionFinalizer.attach(pointer, res.success.cast());
      return pointer;
    },
    getError: (res) => res.error,
  );
}

bool dittoFfiSyncSubscriptionIsCancelled(
  CPPointer<CPSyncSubscription> subscription,
) {
  final subscriptionPtr = subscription.asFfi();
  return bindings.dittoffi_sync_subscription_is_cancelled(
    subscriptionPtr.inner.cast(),
  );
}

void dittoFfiSyncSubscriptionCancel(
  CPPointer<CPSyncSubscription> subscription,
) {
  final subscriptionPtr = subscription.asFfi();
  bindings.dittoffi_sync_subscription_cancel(
    subscriptionPtr.inner.cast(),
  );
}

void dittoFfiSyncSubscriptionFree(
  CPPointer<CPSyncSubscription> subscription,
) {
  final subscriptionPtr = subscription.asFfi();
  bindings.dittoffi_sync_subscription_free(
    subscriptionPtr.inner.cast(),
  );
}

String dittoFfiSyncSubscriptionQueryString(
  CPPointer<CPSyncSubscription> subscription,
) {
  final subscriptionPtr = subscription.asFfi();
  final queryStringPointer = bindings.dittoffi_sync_subscription_query_string(
    subscriptionPtr.inner.cast(),
  );
  return stringFromCharStar(queryStringPointer, free: true);
}

Uint8List dittoFfiSyncSubscriptionQueryArgumentsCbor(
  CPPointer<CPSyncSubscription> subscription,
) {
  final subscriptionPtr = subscription.asFfi();
  final queryArgsBytes =
      bindings.dittoffi_sync_subscription_query_arguments_cbor(
    subscriptionPtr.inner.cast(),
  );

  return bytesFromNative(queryArgsBytes, free: true);
}

String dittoFfiSyncSubscriptionQueryArgumentsJson(
  CPPointer<CPSyncSubscription> subscription,
) {
  final subscriptionPtr = subscription.asFfi();
  final queryArgsJsonBytes =
      bindings.dittoffi_sync_subscription_query_arguments_json(
    subscriptionPtr.inner.cast(),
  );
  return utf8.decode(bytesFromNative(queryArgsJsonBytes, free: true));
}

Uint8List dittoFfiSyncSubscriptionId(
  CPPointer<CPSyncSubscription> subscription,
) {
  final subscriptionPtr = subscription.asFfi();
  final idBytes = bindings.dittoffi_sync_subscription_id(
    subscriptionPtr.inner.cast(),
  );
  return bytesFromNative(idBytes, free: true);
}

List<CPPointer<CPSyncSubscription>> dittoFfiSyncSubscriptions(
  CPPointer<CPDitto> ditto,
) {
  final dittoPtr = ditto.asFfi();
  final syncSubsVec = bindings.dittoffi_sync_subscriptions(
    dittoPtr.inner.cast(),
  );

  final syncSubPtrs = List.generate(syncSubsVec.len, (i) {
    final syncSubPtr = syncSubsVec.ptr[i];
    final cpPtr = syncSubPtr.toCP<CPSyncSubscription>();
    _syncSubscriptionFinalizer.attach(cpPtr, syncSubPtr.cast());
    return cpPtr;
  });

  bindings.dittoffi_sync_subscriptions_free_sparse(syncSubsVec);
  return syncSubPtrs;
}
