// ignore_for_file: ditto_missing_visibility
// ./native/native.dart
// ./wasm/wasm.dart
//
// ^^^ Implementations in these files

import "dart:typed_data";

import "package:meta/meta.dart";

import "../presence/presence.dart";
import "../presence/presence_graph.dart";
import "../supported_platform.dart";
import "../store/transaction.dart";
import "../transport_conditions.dart";
import "cross_platform/freeable.dart";
import "cross_platform/types.dart";
import "cross_platform/error.dart";

Never get _$ => throw UnsupportedError("Stub implementation");

// === Ditto Initialization and Configuration ===
Future<void> init({String? wasmUrl, String? wasmShimUrl}) async => _$;

/// Set the name, language, and version for the Ditto SDK.
///
/// No-op on web where this is set during initialization with [init].
void dittoInitSdkVersion() => _$;

String dittoGetSdkSemver() => _$;
Future<void> dittoShutdown(CPPointer<CPDitto> peer) => _$;

// === Peer Management Functions ===
String dittoSetDeviceName(CPPointer<CPDitto> ditto, String deviceName) => _$;
CPResult<void> dittoFfiTryVerifyLicense(
  CPPointer<CPDitto> ditto,
  String licenseKey,
) =>
    _$;
CPPointer<CPDitto> dittoMake(
  String directory,
  CPPointer<CPIdentityConfig> identity,
) =>
    _$;
bool dittoIsActivated(CPPointer<CPDitto> ditto) => _$;

CPResult<void> dittoSdkTransportsInit() => _$;

CPBytes dittoFfiDittoTransportConfig(CPPointer<CPDitto> peer) => _$;
CPResult<void> dittoFfiDittoTrySetTransportConfig(
  CPPointer<CPDitto> peer,
  Uint8List transportConfig,
) =>
    _$;

Future<void> dittoRunGarbageCollection(CPPointer<CPDitto> peer) => _$;

// === Authentication Functions ===
Future<AuthResponse> dittoAuthClientLoginWithTokenAndFeedback(
  CPPointer<CPDitto> peer,
  String token,
  String provider,
) =>
    _$;
Future<CPResult<void>> dittoAuthClientLogout(CPPointer<CPDitto> pointer) => _$;

(CPPointer<CPAuthLoginProvider>, CPFreeable) dittoAuthClientMakeLoginProvider(
  CPPointer<CPDitto> ditto,
  void Function(int seconds) expiringCallback,
) =>
    _$;

Future<void> dittoAuthSetLoginProvider(
  CPPointer<CPDitto> ditto,
  CPPointer<CPAuthLoginProvider>? provider,
) =>
    _$;

bool dittoAuthClientIsWebValid(CPPointer<CPDitto> ditto) => _$;
String? dittoAuthClientUserId(CPPointer<CPDitto> ditto) => _$;
String dittoffiGetDevelopmentProvider() => _$;

// === Sync Functions ===
CPResult<void> dittoFfiDittoTryStartSync(CPPointer<CPDitto> ditto) => _$;
void dittoFfiDittoStopSync(CPPointer<CPDitto> ditto) => _$;
bool dittoFfiDittoIsSyncActive(CPPointer<CPDitto> ditto) => _$;
CPResult<CPPointer<CPSyncSubscription>> dittoFfiSyncRegisterSubscriptionThrows(
  CPPointer<CPDitto> peer,
  String query,
  Uint8List queryArgumentsCBOR,
) =>
    _$;
bool dittoFfiSyncSubscriptionIsCancelled(
  CPPointer<CPSyncSubscription> subscription,
) =>
    _$;
void dittoFfiSyncSubscriptionCancel(
  CPPointer<CPSyncSubscription> subscription,
) =>
    _$;
String dittoFfiSyncSubscriptionQueryString(
  CPPointer<CPSyncSubscription> subscription,
) =>
    _$;
Uint8List dittoFfiSyncSubscriptionQueryArgumentsCbor(
  CPPointer<CPSyncSubscription> subscription,
) =>
    _$;
String dittoFfiSyncSubscriptionQueryArgumentsJson(
  CPPointer<CPSyncSubscription> subscription,
) =>
    _$;
Uint8List dittoFfiSyncSubscriptionId(
  CPPointer<CPSyncSubscription> subscription,
) =>
    _$;
List<CPPointer<CPSyncSubscription>> dittoFfiSyncSubscriptions(
  CPPointer<CPDitto> ditto,
) =>
    _$;

// === Diffing ===

CPPointer<CPDiffer> dittoFfiDifferNew() => _$;
Uint8List dittoFfiDifferDiff(
  CPPointer<CPDiffer> differ,
  List<CPPointer<CPQueryResultItem>> items,
) =>
    _$;

// === Error Handling Functions ===
int dittoFfiErrorCode() => _$;
String dittoErrorMessagePeek() => _$;
String dittoErrorMessage() => _$;

// === Presence  ===
/// Registers a presence observer via the modern observer-handle FFI.
/// The callback receives the presence graph as a UTF-8 JSON string.
CPFreeable dittoRegisterPresenceObserver(
  CPPointer<CPDitto> ditto,
  void Function(String json) callback,
) =>
    _$;
String dittoPresenceV3(CPPointer<CPDitto> ditto) => _$;
String dittoFfiPresencePeerMetadataJson(CPPointer<CPDitto> peer) => _$;
Future<CPResult<void>> dittoFfiPresenceTrySetPeerMetadataJson(
  CPPointer<CPDitto> peer,
  String metadata,
) =>
    _$;

// === Transport Conditions ===
CPFreeable dittoRegisterTransportConditionChangedCallback(
  CPPointer<CPDitto> ditto,
  void Function(TransportConditionEvent event) callback,
) =>
    _$;

// Test-only stubs paired with the native/wasm debug accessors so the
// cross-platform conditional export in `bridge.dart` resolves on every
// platform. See SDKS-3847.
@visibleForTesting
TransportConditionSource debugDecodeUnknownConditionSource() => _$;
@visibleForTesting
TransportCondition debugDecodeUnknownTransportCondition() => _$;

// === Connection Handling ===
CPFreeable dittoFfiPresenceSetConnectionRequestHandler(
  CPPointer<CPDitto> peer,
  Future<ConnectionRequestAuthorization> Function(
    CPPointer<CPConnectionRequest>,
  ) handler,
) =>
    _$;
void dittoFfiConnectionRequestAuthorize(
  CPPointer<CPConnectionRequest> request,
  ConnectionRequestAuthorization authorization,
) =>
    _$;
ConnectionType dittoFfiConnectionRequestConnectionType(
  CPPointer<CPConnectionRequest> request,
) =>
    _$;
String dittoFfiConnectionRequestPeerKeyString(
  CPPointer<CPConnectionRequest> request,
) =>
    _$;
String dittoFfiConnectionRequestIdentityServiceMetadataJson(
  CPPointer<CPConnectionRequest> request,
) =>
    _$;
String dittoFfiConnectionRequestPeerMetadataJson(
  CPPointer<CPConnectionRequest> request,
) =>
    _$;
void dittoffiConnectionRequestFree(CPPointer<CPConnectionRequest> request) =>
    _$;

// === Small Peer Info ===

bool dittoSmallPeerInfoGetIsEnabled(CPPointer<CPDitto> ditto) => _$;

void dittoFfiSmallPeerInfoSetEnabled(
  CPPointer<CPDitto> ditto, {
  required bool isEnabled,
}) =>
    _$;

String dittoFfiSmallPeerInfoGetMetadata(CPPointer<CPDitto> ditto) => _$;

CPResult<void> dittoSmallPeerInfoSetMetadata(
  CPPointer<CPDitto> ditto,
  String metadata,
) =>
    _$;

// === Logger Functions ===
bool dittoLoggerEnabledGet() => _$;
void dittoLoggerEnabled({required bool isEnabled}) => _$;
LogLevel dittoLoggerMinimumLogLevelGet() => _$;
void dittoLoggerMinimumLogLevel(LogLevel logLevel) => _$;
bool dittoLoggerEmojiHeadingsEnabledGet() => _$;
void dittoLoggerEmojiHeadingsEnabled({required bool isEnabled}) => _$;
void dittoLog(LogLevel level, String message) => _$;
Future<CPResult<int>> dittoFfiLoggerTryExportToFileAsync(String filePath) => _$;
CPFreeable? dittoLoggerSetCustomLogCb([
  void Function(LogLevel level, String message)? callback,
]) =>
    _$;

// === Attachments ===

/// Returns a (cancel_token, guard)
Future<CPResult<(int, CPFreeable)>> dittoResolveAttachment(
  CPPointer<CPDitto> ditto,
  Uint8List token,
  void Function(CPPointer<CPAttachmentHandle>) onComplete,
  void Function(int downloadedBytes, int totalBytes) onProgress,
  void Function() onDelete,
) =>
    _$;

CPResult<void> dittoCancelResolveAttachment(
  CPPointer<CPDitto> ditto,
  Uint8List token,
  int cancelToken,
) =>
    _$;

Future<CPResult<Uint8List>> dittoGetCompleteAttachmentData(
  CPPointer<CPDitto> ditto,
  CPPointer<CPAttachmentHandle> attachment,
) =>
    _$;

String dittoGetCompleteAttachmentPath(
  CPPointer<CPDitto> ditto,
  CPPointer<CPAttachmentHandle> attachment,
) =>
    _$;
void dittoFreeAttachmentHandle(CPPointer<CPAttachmentHandle> handle) => _$;

// === Type Utilities ===
String dittoFfiBase64Encode(Uint8List bytes, CPBase64PaddingMode mode) => _$;
CPResult<Uint8List> dittoFfiTryBase64Decode(
  String base64String,
  CPBase64PaddingMode mode,
) =>
    _$;

// === Finalizers ===
void dittoCStringFree(CPPointer<CPCString> cString) => _$;
void dittoDocumentFree(CPPointer<CPDocument> document) => _$;
void dittoFfiDifferFree(CPPointer<CPDiffer> differ) => _$;
void dittoFfiErrorFree(CPPointer<CPError> error) => _$;
void dittoFfiQueryResultFree(CPPointer<CPQueryResult> queryResult) => _$;
void dittoFree(CPPointer<CPDitto> pointer) => _$;

/// See native/store.dart for semantics. Stub only; the native bridge is the
/// platform that actually honors this flag. Web has no per-call dispatch
/// isolate to skip in the first place.
bool experimentalSkipExecuteIsolateOffload = false;

Future<CPResult<CPPointer<CPQueryResult>>> dittoffiTryExecStatement(
  CPPointer<CPDitto> ditto,
  String query,
  Uint8List cborEncodedArgs,
) =>
    _$;

/// Stub for the per-`Ditto` execute worker isolate teardown. The web bridge
/// has no worker isolate, so this is a no-op there; the native bridge
/// overrides it to kill the worker spawned by `dittoffiTryExecStatement`.
Future<void> disposeExecuteWorker(CPPointer<CPDitto> ditto) => _$;

int dittoffiQueryResultItemCount(CPPointer<CPQueryResult> qr) => _$;

CPPointer<CPQueryResultItem> dittoffiQueryResultItemAt(
  CPPointer<CPQueryResult> qr,
  int index,
) =>
    _$;

String dittoffiQueryResultItemJson(CPPointer<CPQueryResultItem> item) => _$;

Uint8List dittoffiQueryResultItemCbor(CPPointer<CPQueryResultItem> item) => _$;

CPResult<CPPointer<CPQueryResultItem>> dittoffiQueryResultItemNew(
  Uint8List json,
) =>
    _$;

int dittoffiQueryResultMutatedDocumentIdCount(CPPointer<CPQueryResult> qr) =>
    _$;

Uint8List dittoffiQueryResultMutatedDocumentIdAt(
  CPPointer<CPQueryResult> qr,
  int index,
) =>
    _$;

bool dittoffiQueryResultHasCommitId(CPPointer<CPQueryResult> qr) => _$;

int dittoffiQueryResultCommitId(CPPointer<CPQueryResult> qr) => _$;

CPResult<(int, CPFreeable)> dittoffiTryExperimentalRegisterChangeObserverStr(
  CPPointer<CPDitto> ditto,
  String query,
  Uint8List cborEncodedArgs,
  void Function(CPChangeHandlerWithQueryResult) callback,
) =>
    _$;

CPResult<(CPPointer<CPStoreObserver>, CPFreeable)>
    dittoFfiStoreRegisterObserverThrows(
  CPPointer<CPDitto> ditto,
  String query,
  Uint8List queryArgumentsCBOR,
  void Function(CPChangeHandlerWithQueryResultAndSignalNext) callback,
) =>
        _$;

bool dittoFfiStoreObserverIsCancelled(
  CPPointer<CPStoreObserver> storeObserver,
) =>
    _$;

void dittoFfiStoreObserverCancel(CPPointer<CPStoreObserver> storeObserver) =>
    _$;

String dittoFfiStoreObserverQueryString(
  CPPointer<CPStoreObserver> storeObserver,
) =>
    _$;

Uint8List dittoFfiStoreObserverQueryArgumentsCbor(
  CPPointer<CPStoreObserver> storeObserver,
) =>
    _$;

CPResult<CPAttachment> dittoNewAttachmentFromFile(
  CPPointer<CPDitto> ditto,
  String path,
  CPAttachmentFileOperation op,
) =>
    _$;

Future<CPResult<CPAttachment>> dittoNewAttachmentFromBytes(
  CPPointer<CPDitto> ditto,
  Uint8List bytes,
) =>
    _$;

/// Extracts the attachment handle, id, and length from an attachment
CPResult<(CPPointer<CPAttachmentHandle>, String, int)>
    utilExtractAndFreeAttachment(CPAttachment attachment) => _$;

// === Utility Functions (not in Ditto FFI) ===

/// Creates a directory if it doesn't exist
///
/// On web, validate that the given path is not empty.
void utilValidatePersistenceDirectory(String path) => _$;

/// Create a persistence directory that is writable on native, and just return the string as-is on web
Future<String> utilsMakePersistenceDirectory(
  String path, {
  bool createIfMissing = true,
}) =>
    _$;

/// Get the default device name for the current platform.
///
/// On mobile, this is the model name. On web, it's the browser's user agent.
Future<String> utilDefaultDeviceName() => _$;

void dittoLiveQueryStart(CPPointer<CPDitto> ditto, int liveQueryId) => _$;
void dittoLiveQueryStop(CPPointer<CPDitto> ditto, int liveQueryId) => _$;

Future<CPResult<CPPointer<CPTransaction>>>
    dittoffiStoreBeginTransactionAsyncThrows(
  CPPointer<CPStore> store,
  String? hint, {
  required bool isReadOnly,
}) =>
        _$;

Uint8List dittoffiTransactionInfo(CPPointer<CPTransaction> txn) => _$;

Future<CPResult<CPPointer<CPQueryResult>>> dittoffiTransactionExecute(
  CPPointer<CPTransaction> txn,
  String query,
  Uint8List cborEncodedArgs,
) =>
    _$;

Future<CPResult<TransactionCompletionAction>> dittoffiTransactionComplete(
  CPPointer<CPTransaction> txn,
  TransactionCompletionAction action,
) =>
    _$;

Future<String?> utilApplicationDocumentsDir() => _$;
SupportedPlatform utilGetCurrentPlatform() => _$;

CPErrorCode dittoffiErrorCode(CPPointer<CPError> error) => _$;
String dittoffiErrorDescription(CPPointer<CPError> error) => _$;

Future<void> utilFileCopy(String source, String destination) => _$;

Future<CPResult<CPPointer<CPDitto>>> dittoffiDittoOpenAsyncThrows(
  Uint8List configCbor,
  CPTransportConfigMode mode,
  String defaultRootDirectory,
) =>
    _$;

CPResult<CPPointer<CPDitto>> dittoffiDittoOpenThrows(
  Uint8List configCbor,
  CPTransportConfigMode mode,
  String defaultRootDirectory,
) =>
    _$;

Uint8List dittoffiDittoConfig(CPPointer<CPDitto> ditto) => _$;
String dittoffiDittoAbsolutePersistenceDirectory(CPPointer<CPDitto> ditto) =>
    _$;
Uint8List dittffiDittoConfigDefault() => _$;

CPResult<Uint8List> dittoffiCborRoundTrip(String type, Uint8List bytes) => _$;
Uint8List dittoffiTransportConfigNew() => _$;
