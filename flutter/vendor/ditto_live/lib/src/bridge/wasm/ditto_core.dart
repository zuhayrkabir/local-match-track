part of "wasm.dart";

extension type _DittoCore(JSObject _) implements JSObject {
  @JS("init")
  external JSPromise<JSObject> init(
    JSAny webAssemblyModule,
  );

  @JS("dittoffi_make_with_transport_config_mode")
  external _JSPointer<CPDitto> dittoMakeWithTransportConfigMode(
    JSUint8Array pathBytes,
    _JSPointer<CPIdentityConfig> identityConfig,
    JSString transportConfigMode,
  );

  @JS("ditto_init_sdk_version")
  external void dittoInitSdkVersion(
    JSString platform,
    JSString framework,
    JSUint8Array versionBytes,
  );

  @JS("ditto_free")
  external void dittoFree(
    _JSPointer<CPDitto> peer,
  );

  @JS("ditto_shutdown")
  external JSPromise dittoShutdown(
    _JSPointer<CPDitto> peer,
  );

  @JS("dittoffi_get_sdk_semver")
  external _JSPointer<CPCString> dittoffiGetSdkSemver();

  @JS("ditto_set_device_name")
  external _JSPointer<CPCString> dittoSetDeviceName(
    _JSPointer<CPDitto> peer,
    JSUint8Array deviceNameBytes,
  );

  @JS("dittoffi_ditto_is_activated")
  external JSBoolean dittoffiDittoIsActivated(
    _JSPointer<CPDitto> peer,
  );

  @JS("dittoffi_try_verify_license")
  external _JSResult dittoffiTryVerifyLicense(
    _JSPointer<CPDitto> peer,
    JSUint8Array licenseTokenBytes,
  );

  @JS("ditto_c_string_free")
  external void dittoCStringFree(
    _JSPointer<CPCString> cString,
  );

  //
  // Attachments
  //

  @JS("ditto_free_attachment_handle")
  external void dittoFreeAttachmentHandle(
    _JSPointer<CPAttachmentHandle> attachmentHandle,
  );

  @JS("ditto_new_attachment_from_bytes")
  external JSPromise<JSNumber> dittoNewAttachmentFromBytes(
    _JSPointer<CPDitto> ditto,
    JSUint8Array bytes,
    JSObject outAttachment,
  );

  @JS("ditto_resolve_attachment")
  external JSPromise<_JSAttachmentResult> dittoResolveAttachment(
    _JSPointer<CPDitto> ditto,
    JSUint8Array id,
    JSFunction wrappedOnComplete,
    JSFunction wrappedOnProgress,
    JSFunction wrappedOnDelete,
  );

  @JS("ditto_cancel_resolve_attachment")
  external JSNumber dittoCancelResolveAttachment(
    _JSPointer<CPDitto> ditto,
    JSUint8Array id,
    JSNumber cancelToken,
  );

  @JS("ditto_get_complete_attachment_data")
  external JSPromise<_JSAttachmentDataResult> dittoGetCompleteAttachmentData(
    _JSPointer<CPDitto> ditto,
    _JSPointer<CPAttachmentHandle> handle,
  );

  //
  // Document
  //

  @JS("ditto_document_free")
  external void dittoDocumentFree(
    _JSPointer<CPDocument> document,
  );

  //
  // Errors
  //

  @JS("dittoffi_error_code")
  external JSString dittoffiErrorCode(
    _JSPointer<CPError> error,
  );

  /// Retrieves the thread-local error message if any.
  @JS("ditto_error_message")
  external _JSPointer<CPCString>? dittoErrorMessage();

  /// Retrieves an error message associated with an error pointer.
  @JS("dittoffi_error_description")
  external _JSPointer<CPCString> dittoffiErrorDescription(
    _JSPointer<CPError> error,
  );

  @JS("dittoffi_error_free")
  external void dittoffiErrorFree(
    _JSPointer<CPError> error,
  );

  //
  // Authentication
  //

  @JS("ditto_auth_client_make_login_provider")
  external _JSPointer<CPAuthLoginProvider> dittoAuthClientMakeLoginProvider(
    JSFunction expiringCallback,
  );

  @JS("ditto_auth_set_login_provider")
  external JSPromise dittoAuthSetLoginProvider(
    _JSPointer<CPDitto> ditto,
    _JSPointer<CPAuthLoginProvider>? provider,
  );

  @JS("ditto_auth_client_login_with_token_and_feedback")
  external JSPromise<_JSAuthResponse> dittoAuthClientLoginWithTokenAndFeedback(
    _JSPointer<CPDitto> ditto,
    JSUint8Array tokenBytes,
    JSUint8Array providerBytes,
  );

  @JS("ditto_auth_client_logout")
  external JSPromise<JSNumber> dittoAuthClientLogout(
    _JSPointer<CPDitto> ditto,
  );

  @JS("ditto_auth_client_user_id")
  external _JSPointer<CPCString>? dittoAuthClientUserId(
    _JSPointer<CPDitto> ditto,
  );

  @JS("ditto_auth_client_is_web_valid")
  external JSNumber dittoAuthClientIsWebValid(
    _JSPointer<CPDitto> ditto,
  );

  @JS("dittoffi_DITTO_DEVELOPMENT_PROVIDER")
  external _JSPointer<CPCString> dittoffiGetDevelopmentProvider();

  //
  // Store
  //

  @JS("dittoffi_try_exec_statement")
  external JSPromise<_JSResult<_JSPointer<CPQueryResult>>>
      dittoffiTryExecStatement(
    _JSPointer<CPDitto> peer,
    JSUint8Array queryBytes,
    JSUint8Array queryArgsCBOR,
  );

  @JS("dittoffi_try_experimental_register_change_observer_str_detached")
  external _JSResult<JSNumber>
      dittoffiTryExperimentalRegisterChangeObserverStrDetached(
    _JSPointer<CPDitto> peer,
    JSUint8Array queryBytes,
    JSUint8Array queryArgsCBOR,
    JSFunction wrappedCallback,
  );

  @JS("dittoffi_store_register_observer_throws")
  external _JSResult<_JSPointer<CPStoreObserver>>
      dittoffiStoreRegisterObserverThrows(
    _JSPointer<CPDitto> ditto,
    JSUint8Array queryBytes,
    JSUint8Array queryArgsCBOR,
    JSFunction wrappedCallback,
  );

  @JS("dittoffi_store_observer_is_cancelled")
  external JSBoolean dittoffiStoreObserverIsCancelled(
    _JSPointer<CPStoreObserver> storeObserver,
  );

  @JS("dittoffi_store_observer_cancel")
  external void dittoffiStoreObserverCancel(
    _JSPointer<CPStoreObserver> storeObserver,
  );

  @JS("dittoffi_store_observer_query_string")
  external _JSPointer<CPCString> dittoffiStoreObserverQueryString(
    _JSPointer<CPStoreObserver> storeObserver,
  );

  @JS("dittoffi_store_observer_query_arguments_cbor")
  external _JSSliceBoxed? dittoffiStoreObserverQueryArgumentsCbor(
    _JSPointer<CPStoreObserver> storeObserver,
  );

  @JS("dittoffi_store_observer_free")
  external void dittoffiStoreObserverFree(
    _JSPointer<CPStoreObserver> storeObserver,
  );

  @JS("ditto_live_query_start")
  external JSPromise<JSNumber> dittoLiveQueryStart(
    _JSPointer<CPDitto> peer,
    JSNumber liveQueryID,
  );

  @JS("ditto_live_query_stop")
  external void dittoLiveQueryStop(
    _JSPointer<CPDitto> peer,
    JSNumber liveQueryID,
  );

  @JS("ditto_live_query_signal_available_next")
  external void dittoLiveQuerySignalAvailableNext(
    _JSPointer<CPDitto> peer,
    JSNumber liveQueryID,
  );

  @JS("dittoffi_store_begin_transaction_async_throws")
  external void dittoffiStoreBeginTransactionAsyncThrows(
    _JSPointer<CPDitto> peer,
    _DittoffiStoreBeginTransactionOptions options,
    JSFunction continuation,
  );

  @JS("dittoffi_transaction_info")
  external _JSSliceBoxed dittoffiTransactionInfo(
    _JSPointer<CPTransaction> txn,
  );

  @JS("dittoffi_transaction_execute_async_throws")
  external void dittoffiTransactionExecuteAsyncThrows(
    _JSPointer<CPTransaction> txn,
    JSUint8Array queryBytes,
    JSUint8Array queryArgsCBOR,
    JSFunction continuation,
  );

  @JS("dittoffi_transaction_complete_async_throws")
  external void dittoffiTransactionCompleteAsyncThrows(
    _JSPointer<CPTransaction> txn,
    JSString actionString,
    JSFunction continuation,
  );

  //
  // Diffing
  //

  @JS("dittoffi_differ_new")
  external _JSPointer<CPDiffer> dittoffiDifferNew();

  @JS("dittoffi_differ_free")
  external void dittoffiDifferFree(
    _JSPointer<CPDiffer> differ,
  );

  @JS("dittoffi_differ_diff")
  external JSUint8Array dittoffiDifferDiff(
    _JSPointer<CPDiffer> differ,
    JSArray<_JSPointer<CPQueryResultItem>> items,
  );

  //
  // Query Result
  //

  @JS("dittoffi_query_result_free")
  external void dittoffiQueryResultFree(
    _JSPointer<CPQueryResult> queryResult,
  );

  @JS("dittoffi_query_result_item_free")
  external void dittoffiQueryResultItemFree(
    _JSPointer<CPQueryResultItem> queryResultItem,
  );

  @JS("dittoffi_query_result_item_count")
  external JSNumber dittoffiQueryResultItemCount(
    _JSPointer<CPQueryResult> queryResult,
  );

  @JS("dittoffi_query_result_item_at")
  external _JSPointer<CPQueryResultItem> dittoffiQueryResultItemAt(
    _JSPointer<CPQueryResult> queryResult,
    JSNumber index,
  );

  @JS("dittoffi_query_result_mutated_document_id_count")
  external JSNumber dittoffiQueryResultMutatedDocumentIdCount(
    _JSPointer<CPQueryResult> queryResult,
  );

  @JS("dittoffi_query_result_mutated_document_id_at")
  external _JSSliceBoxed dittoffiQueryResultMutatedDocumentIdAt(
    _JSPointer<CPQueryResult> queryResult,
    JSNumber index,
  );

  @JS("dittoffi_query_result_has_commit_id")
  external JSBoolean dittoffiQueryResultHasCommitId(
    _JSPointer<CPQueryResult> queryResult,
  );

  @JS("dittoffi_query_result_commit_id")
  external JSNumber dittoffiQueryResultCommitId(
    _JSPointer<CPQueryResult> queryResult,
  );

  @JS("dittoffi_query_result_item_cbor")
  external _JSSliceBoxed dittoffiQueryResultItemCBOR(
    _JSPointer<CPQueryResultItem> queryResultItem,
  );

  @JS("dittoffi_query_result_item_json")
  external _JSPointer<CPCString> dittoffiQueryResultItemJSON(
    _JSPointer<CPQueryResultItem> queryResultItem,
  );

  @JS("dittoffi_query_result_item_new")
  external _JSResult<_JSPointer<CPQueryResultItem>> dittoffiQueryResultItemNew(
    JSUint8Array queryResultItemBytes,
  );

  //
  // Small Peer Info
  //

  @JS("ditto_small_peer_info_get_is_enabled")
  external JSBoolean dittoSmallPeerInfoGetIsEnabled(
    _JSPointer<CPDitto> peer,
  );

  @JS("ditto_small_peer_info_set_enabled")
  external void dittoSmallPeerInfoSetEnabled(
    _JSPointer<CPDitto> peer,
    JSBoolean isEnabled,
  );

  @JS("ditto_small_peer_info_get_metadata")
  external _JSPointer<CPCString> dittoSmallPeerInfoGetMetadata(
    _JSPointer<CPDitto> peer,
  );

  @JS("ditto_small_peer_info_set_metadata")
  external JSNumber dittoSmallPeerInfoSetMetadata(
    _JSPointer<CPDitto> peer,
    JSUint8Array metadataBytes,
  );

  //
  // Sync
  //

  @JS("dittoffi_ditto_try_start_sync")
  external _JSResult dittoffiDittoTryStartSync(
    _JSPointer peer,
  );

  @JS("dittoffi_ditto_stop_sync")
  external void dittoffiDittoStopSync(
    _JSPointer peer,
  );

  @JS("dittoffi_ditto_is_sync_active")
  external JSBoolean dittoffiDittoIsSyncActive(
    _JSPointer peer,
  );

  @JS("dittoffi_sync_register_subscription_throws")
  external _JSResult<_JSPointer<CPSyncSubscription>>
      dittoffiSyncRegisterSubscriptionThrows(
    _JSPointer<CPDitto> ditto,
    JSUint8Array queryBytes,
    JSUint8Array queryArgsCBOR,
  );

  @JS("dittoffi_sync_subscription_is_cancelled")
  external JSBoolean dittoFfiSyncSubscriptionIsCancelled(
    _JSPointer<CPSyncSubscription> subscription,
  );

  @JS("dittoffi_sync_subscription_cancel")
  external void dittoFfiSyncSubscriptionCancel(
    _JSPointer<CPSyncSubscription> subscription,
  );

  @JS("dittoffi_sync_subscription_query_string")
  external _JSPointer<CPCString> dittoFfiSyncSubscriptionQueryString(
    _JSPointer<CPSyncSubscription> subscription,
  );

  @JS("dittoffi_sync_subscription_query_arguments")
  external _JSSliceBoxed dittoFfiSyncSubscriptionQueryArguments(
    _JSPointer<CPSyncSubscription> subscription,
  );

  @JS("dittoffi_sync_subscription_query_arguments_cbor")
  external _JSSliceBoxed dittoFfiSyncSubscriptionQueryArgumentsCbor(
    _JSPointer<CPSyncSubscription> subscription,
  );

  @JS("dittoffi_sync_subscription_query_arguments_json")
  external _JSSliceBoxed dittoFfiSyncSubscriptionQueryArgumentsJson(
    _JSPointer<CPSyncSubscription> subscription,
  );

  @JS("dittoffi_sync_subscription_id")
  external _JSSliceBoxed dittoFfiSyncSubscriptionId(
    _JSPointer<CPSyncSubscription> subscription,
  );

  @JS("dittoffi_sync_subscription_free")
  external void dittoFfiSyncSubscriptionFree(
    _JSPointer<CPSyncSubscription> subscription,
  );

  @JS("dittoffi_sync_subscriptions")
  external JSArray<_JSPointer<CPSyncSubscription>> dittoFfiSyncSubscriptions(
    _JSPointer<CPDitto> ditto,
  );

  //
  // Transports
  //

  @JS("dittoffi_ditto_transport_config")
  external _JSSliceBoxed dittoffiDittoTransportConfig(
    _JSPointer peer,
  );

  @JS("dittoffi_ditto_try_set_transport_config")
  external _JSResult dittoffiDittoTrySetTransportConfig(
    _JSPointer peer,
    JSUint8Array transportConfigBytes,
    JSBoolean shouldValidate,
  );

  @JS("dittoffi_ditto_set_cloud_sync_enabled")
  external void dittoffiDittoSetCloudSyncEnabled(
    _JSPointer<CPDitto> peer,
    JSBoolean enableDittoCloudSync,
  );

  //
  // Presence
  //

  @JS("ditto_presence_v3")
  external _JSPointer<CPCString> dittoPresenceV3(
    _JSPointer<CPDitto> peer,
  );

  @JS("dittoffi_presence_peer_metadata_json")
  external _JSSliceBoxed dittoFfiPresencePeerMetadataJson(
    _JSPointer<CPDitto> peer,
  );

  @JS("dittoffi_presence_try_set_peer_metadata_json")
  external JSPromise<_JSResult> dittoFfiPresenceTrySetPeerMetadataJson(
    _JSPointer<CPDitto> peer,
    JSUint8Array metadataBytes,
  );

  @JS("ditto_register_presence_v3_callback")
  external JSVoid dittoRegisterPresenceV3Callback(
    _JSPointer<CPDitto> peer,
    JSFunction callback,
  );

  @JS("ditto_clear_presence_v3_callback")
  external void dittoClearPresenceV3Callback(
    _JSPointer<CPDitto> peer,
  );

  @JS("ditto_register_transport_condition_changed_callback")
  external JSVoid dittoRegisterTransportConditionChangedCallback(
    _JSPointer<CPDitto> peer,
    JSFunction? callback,
  );

  @JS("dittoffi_presence_set_connection_request_handler")
  external _JSResult? dittoffiPresenceSetConnectionRequestHandler(
    _JSPointer<CPDitto> peer,
    JSFunction? connectionRequestHandler,
  );

  @JS("dittoffi_connection_request_authorize")
  external void dittoFfiConnectionRequestAuthorize(
    _JSPointer<CPConnectionRequest> connectionRequest,
    JSString authorization,
  );

  @JS("dittoffi_connection_request_connection_type")
  external JSString dittoFfiConnectionRequestConnectionType(
    _JSPointer<CPConnectionRequest> request,
  );

  @JS("dittoffi_connection_request_peer_key_string")
  external _JSPointer<CPCString>? dittoFfiConnectionRequestPeerKeyString(
    _JSPointer<CPConnectionRequest> request,
  );

  @JS("dittoffi_connection_request_identity_service_metadata_json")
  external _JSSliceBoxed dittoFfiConnectionRequestIdentityServiceMetadataJson(
    _JSPointer<CPConnectionRequest> request,
  );

  @JS("dittoffi_connection_request_peer_metadata_json")
  external _JSSliceBoxed dittoFfiConnectionRequestPeerMetadataJson(
    _JSPointer<CPConnectionRequest> request,
  );

  @JS("dittoffi_connection_request_free")
  external void dittoffiConnectionRequestFree(
    _JSPointer<CPConnectionRequest> connectionRequest,
  );

  //
  // Logger
  //

  @JS("ditto_log")
  external void dittoLog(
    JSString logLevel,
    JSUint8Array messageBytes,
  );

  @JS("ditto_logger_enabled_get")
  external JSBoolean dittoLoggerEnabledGet();

  @JS("ditto_logger_enabled")
  external void dittoLoggerEnabled(
    JSBoolean isEnabled,
  );

  @JS("ditto_logger_minimum_log_level_get")
  external JSString dittoLoggerMinimumLogLevelGet();

  @JS("ditto_logger_minimum_log_level")
  external void dittoLoggerMinimumLogLevel(
    JSString logLevel,
  );

  @JS("ditto_logger_emoji_headings_enabled_get")
  external JSBoolean dittoLoggerEmojiHeadingsEnabledGet();

  @JS("ditto_logger_emoji_headings_enabled")
  external void dittoLoggerEmojiHeadingsEnabled(
    JSBoolean isEnabled,
  );

  @JS("ditto_logger_set_custom_log_cb")
  external void dittoLoggerSetCustomLogCb(
    JSFunction? callback,
  );

  @JS("dittoffi_ditto_open_async_throws")
  external void dittoffiDittoOpenAsyncThrows(
    JSUint8Array configCbor,
    JSString transportConfigMode,
    JSUint8Array rootDir,
    _JSVoidCalback1<_JSResult<_JSPointer<CPDitto>>> continuation,
  );

  @JS("dittoffi_ditto_open_throws")
  external _JSResult<_JSPointer<CPDitto>> dittoffiDittoOpenThrows(
    JSUint8Array configCbor,
    JSString transportConfigMode,
    JSUint8Array rootDir,
  );

  @JS("dittoffi_ditto_config")
  external _JSSliceBoxed dittoffiDittoConfig(_JSPointer<CPDitto> ditto);

  @JS("dittoffi_ditto_config_default")
  external _JSSliceBoxed dittoffiDittoConfigDefault();

  @JS("dittoffi_ditto_absolute_persistence_directory")
  external _JSPointer<CPCString> dittoffiDittoAbsolutePersistenceDirectory(
    _JSPointer<CPDitto> ditto,
  );

  @JS("dittoffi_cbor_round_trip")
  external _JSResult<_JSSliceBoxed> dittoffiCborRoundTrip(
    JSUint8Array type,
    JSUint8Array bytes,
  );

  @JS("dittoffi_transport_config_new")
  external _JSSliceBoxed dittoffiTransportConfigNew();

  //
  // Type Conversion
  //

  /// Convert a C string into a JS string.
  ///
  /// May throw JS error!
  @JS("boxCStringIntoString")
  external JSString? boxCStringIntoString(
    _JSPointer<CPCString>? cStringPointer,
  );

  /// Convert a C string into a JS string.
  ///
  /// May throw JS error!
  @JS("refCStringToString")
  external JSString? refCStringToString(
    _JSPointer<CPCString>? cStringPointer,
  );

  /// Convert a C byte array into a JS buffer.
  ///
  /// May throw JS error!
  @JS("boxCBytesIntoBuffer")
  external JSUint8Array? boxCBytesIntoBuffer(
    _JSSliceBoxed? cBytesPointer,
  );

  /// Convert an optional (Rust ref) C byte array into a JS buffer.
  ///
  /// May throw JS error!
  @JS("refCBytesIntoBuffer")
  external JSUint8Array? refCBytesIntoBuffer(
    _JSSliceBoxed? cBytesPointer,
  );

  /// Convert a JS byte array into a char_p::Box JS String.
  ///
  /// May throw JS error!
  @JS("dittoffi_base64_encode")
  external _JSPointer<CPCString> base64encode(
    JSUint8Array bytes,
    JSString paddingMode,
  );

  /// Convert a  char_p::Box JS String into a JS byte array.
  ///
  /// May throw JS error!
  @JS("dittoffi_try_base64_decode")
  external _JSResult<_JSSliceBoxed> tryBase64decode(
    JSUint8Array bytes,
    JSString paddingMode,
  );
}
