// ignore_for_file: ditto_missing_visibility
part of "wasm.dart";

/// Cross-platform parity with the native bridge. Has no effect on web (there
/// is no per-call dispatch isolate in the wasm path; `dittoffiTryExecStatement`
/// already runs on the calling isolate). See native/store.dart for semantics.
bool experimentalSkipExecuteIsolateOffload = false;

/// Cross-platform parity with the native bridge. No-op on web — there is no
/// worker isolate to tear down. See native/store.dart for semantics.
Future<void> disposeExecuteWorker(CPPointer<CPDitto> ditto) async {}

Future<CPResult<CPPointer<CPQueryResult>>> dittoffiTryExecStatement(
  CPPointer<CPDitto> ditto,
  String query,
  Uint8List cborEncodedArgs,
) async {
  final queryBytes = bytesFromString(query);

  final resultJS = await _dittoCore
      .dittoffiTryExecStatement(
        (ditto as _WasmPointer<CPDitto>).asWasm(),
        queryBytes.toJS,
        cborEncodedArgs.toJS,
      )
      .toDart;

  return resultJS.toCP().map((ptr) => ptr!.toCP());
}

int dittoffiQueryResultItemCount(CPPointer<CPQueryResult> queryResult) =>
    _dittoCore.dittoffiQueryResultItemCount(queryResult.asWasm()).toDartInt;

CPPointer<CPQueryResultItem> dittoffiQueryResultItemAt(
  CPPointer<CPQueryResult> queryResult,
  int index,
) {
  final pointer = _dittoCore.dittoffiQueryResultItemAt(
    queryResult.asWasm(),
    index.toJS,
  );
  return _WasmPointer(pointer);
}

String dittoffiQueryResultItemJson(CPPointer<CPQueryResultItem> item) {
  final jsonPointer = _dittoCore.dittoffiQueryResultItemJSON(item.asWasm());
  return _dittoCore.boxCStringIntoString(jsonPointer)!.toDart;
}

Uint8List dittoffiQueryResultItemCbor(CPPointer<CPQueryResultItem> item) {
  final bytes = _dittoCore.dittoffiQueryResultItemCBOR(item.asWasm());
  return _dittoCore.boxCBytesIntoBuffer(bytes)!.toDart;
}

CPResult<CPPointer<CPQueryResultItem>> dittoffiQueryResultItemNew(
  Uint8List json,
) {
  final jsResult = _dittoCore.dittoffiQueryResultItemNew(json.toJS);
  return jsResult.toCP().map((pointer) => pointer!.toCP());
}

int dittoffiQueryResultMutatedDocumentIdCount(
  CPPointer<CPQueryResult> queryResult,
) =>
    _dittoCore
        .dittoffiQueryResultMutatedDocumentIdCount(queryResult.asWasm())
        .toDartInt;

Uint8List dittoffiQueryResultMutatedDocumentIdAt(
  CPPointer<CPQueryResult> queryResult,
  int index,
) {
  final cBytes = _dittoCore.dittoffiQueryResultMutatedDocumentIdAt(
    queryResult.asWasm(),
    index.toJS,
  );
  return _dittoCore.boxCBytesIntoBuffer(cBytes)!.toDart;
}

bool dittoffiQueryResultHasCommitId(CPPointer<CPQueryResult> queryResult) =>
    _dittoCore.dittoffiQueryResultHasCommitId(queryResult.asWasm()).toDart;

int dittoffiQueryResultCommitId(CPPointer<CPQueryResult> queryResult) =>
    _dittoCore.dittoffiQueryResultCommitId(queryResult.asWasm()).toDartInt;

CPResult<(int, CPFreeable)> dittoffiTryExperimentalRegisterChangeObserverStr(
  CPPointer<CPDitto> peer,
  String query,
  Uint8List cborEncodedArgs,
  void Function(CPChangeHandlerWithQueryResult) callback,
) {
  final queryBytes = bytesFromString(query);
  int? liveQueryID;

  // In Wasm, store observers are always registered with
  // `LiveQueryAvailability::WhenSignalled`. This means, that a callback always
  // needs to be followed up by signalling to core that the observer is ready to
  // receive the next change.

  final wrappedCallback = wrapBackgroundCbForFFI(
    onBackgroundError: (err, stackTrace) {
      dittoLog(
        LogLevel.error,
        "The registered store observer failed: $err\n$stackTrace",
      );
    },
    (_ChangeHandlerWithQueryResult changeHandlerWithQueryResultJS) {
      if (liveQueryID == null) {
        throw privateMakeDittoError(
          // zalgo
          "Store observer callback invoked before registration completed (liveQueryID is null)",
        );
      }
      final changeHandlerWithQueryResult =
          changeHandlerWithQueryResultJS.toCP();

      if (changeHandlerWithQueryResult == null) {
        return;
      }

      try {
        callback(changeHandlerWithQueryResult);
      } finally {
        _dittoCore.dittoLiveQuerySignalAvailableNext(
          peer.asWasm(),
          liveQueryID.toJS,
        );
      }
    },
  );

  liveQueryID = _dittoCore
      .dittoffiTryExperimentalRegisterChangeObserverStrDetached(
        peer.asWasm(),
        queryBytes.toJS,
        cborEncodedArgs.toJS,
        wrappedCallback,
      )
      .toCP()
      .extract()!
      .toDartInt;

  return CPResult.legacyOk((liveQueryID, CPFreeable.noop()));
}

// === StoreObserverV2 ===

CPResult<(CPPointer<CPStoreObserver>, CPFreeable)>
    dittoFfiStoreRegisterObserverThrows(
  CPPointer<CPDitto> ditto,
  String query,
  Uint8List queryArgumentsCBOR,
  void Function(CPChangeHandlerWithQueryResultAndSignalNext) callback,
) {
  final queryBytes = bytesFromString(query);

  final wrappedCallback = wrapBackgroundCbForFFI(
    onBackgroundError: (err, stackTrace) {
      dittoLog(
        LogLevel.error,
        "The registered store observer failed: $err\n$stackTrace",
      );
    },
    (_JSPointer<CPQueryResult> queryResultJS, JSFunction signalNextJS) {
      callback(
        CPChangeHandlerWithQueryResultAndSignalNext(
          queryResult: queryResultJS.toCP(),
          signalNext: () => signalNextJS.callAsFunction(),
        ),
      );
    },
  );

  return _dittoCore
      .dittoffiStoreRegisterObserverThrows(
        (ditto as _WasmPointer<CPDitto>).asWasm(),
        queryBytes.toJS,
        queryArgumentsCBOR.toJS,
        wrappedCallback,
      )
      .toCP()
      .map((pointer) => (pointer!.toCP(), CPFreeable.noop()));
}

bool dittoFfiStoreObserverIsCancelled(
  CPPointer<CPStoreObserver> storeObserver,
) =>
    _dittoCore.dittoffiStoreObserverIsCancelled(storeObserver.asWasm()).toDart;

void dittoFfiStoreObserverCancel(CPPointer<CPStoreObserver> storeObserver) =>
    _dittoCore.dittoffiStoreObserverCancel(storeObserver.asWasm());

String dittoFfiStoreObserverQueryString(
  CPPointer<CPStoreObserver> storeObserver,
) {
  final queryStringPtr = _dittoCore.dittoffiStoreObserverQueryString(
    storeObserver.asWasm(),
  );
  return _dittoCore.boxCStringIntoString(queryStringPtr)!.toDart;
}

Uint8List dittoFfiStoreObserverQueryArgumentsCbor(
  CPPointer<CPStoreObserver> storeObserver,
) {
  final bytes = _dittoCore.dittoffiStoreObserverQueryArgumentsCbor(
    storeObserver.asWasm(),
  );
  // Rust returns Option<Box<[u8]>>; fall back to an empty CBOR map (0xa0)
  // so the downstream `fromCborBytes(...) as Map` in Store.queryArguments
  // stays well-defined if dittoffi ever returns None for the slice.
  return _dittoCore.boxCBytesIntoBuffer(bytes)?.toDart ??
      Uint8List.fromList([0xa0]);
}

// === Attachments ===

CPResult<CPAttachment> dittoNewAttachmentFromFile(
  CPPointer<CPDitto> ditto,
  String path,
  CPAttachmentFileOperation op,
) =>
    throw privateMakeDittoException(
      _errorMessageThreadLocal() ??
          "Creating attachments from files is not supported on Flutter Web.",
    );

Future<CPResult<CPAttachment>> dittoNewAttachmentFromBytes(
  CPPointer<CPDitto> ditto,
  Uint8List bytes,
) async {
  // The call to `dittoNewAttachmentFromBytes` is populating `outAttachment`
  // with a pointer to the attachment.
  final outAttachment = JSObject();
  final errorCodeJS = await _dittoCore
      .dittoNewAttachmentFromBytes(ditto.asWasm(), bytes.toJS, outAttachment)
      .toDart;
  final errorCode = errorCodeJS.toDartInt;
  if (errorCode != 0) {
    throw privateMakeDittoError(
      _errorMessageThreadLocal() ??
          "ditto_new_attachment_from_bytes() failed with error code: ${errorCodeJS.toDartInt}",
    );
  }

  final jsAttachment = _JSAttachment(outAttachment);
  final attachment = CPAttachment(
    id: jsAttachment.id.toDart,
    len: jsAttachment.len,
    handle: _WasmPointer<CPAttachmentHandle>(jsAttachment.handle),
  );
  return CPResult.legacyOk(attachment);
}

CPResult<(CPPointer<CPAttachmentHandle>, String, int)>
    utilExtractAndFreeAttachment(CPAttachment attachment) {
  final id = dittoFfiBase64Encode(attachment.id, CPBase64PaddingMode.unpadded);
  final len = attachment.len;
  final handle = attachment.handle;
  return CPResult.legacyOk((handle, id, len));
}

Future<CPResult<(CPCancelToken, CPFreeable)>> dittoResolveAttachment(
  CPPointer<CPDitto> ditto,
  Uint8List token,
  void Function(CPPointer<CPAttachmentHandle>) onComplete,
  void Function(int downloadedBytes, int totalBytes) onProgress,
  void Function() onDelete,
) async {
  final wrappedOnComplete = wrapBackgroundCbForFFI(
    onBackgroundError: (err, stackTrace) {
      dittoLog(
        LogLevel.error,
        "dittoResolveAttachment.onComplete failed: $err\n$stackTrace",
      );
    },
    (_JSPointer<CPAttachmentHandle> handleJS) {
      final handle = _WasmPointer<CPAttachmentHandle>(handleJS);
      onComplete(handle);
    },
  );

  final wrappedOnProgress = wrapBackgroundCbForFFI(
    onBackgroundError: (err, stackTrace) {
      dittoLog(
        LogLevel.error,
        "dittoResolveAttachment.onProgress failed: $err\n$stackTrace",
      );
    },
    (JSNumber downloadedBytes, JSNumber totalBytes) {
      final downloaded = downloadedBytes.toDartInt;
      final toDownload = totalBytes.toDartInt;
      onProgress(downloaded, toDownload);
    },
  );

  final wrappedOnDelete = wrapBackgroundCbForFFI(
    onBackgroundError: (err, stackTrace) {
      dittoLog(
        LogLevel.error,
        "dittoResolveAttachment.onDelete failed: $err\n$stackTrace",
      );
    },
    () {
      onDelete();
    },
  );

  final resultJS = await _dittoCore
      .dittoResolveAttachment(
        ditto.asWasm(),
        token.toJS,
        wrappedOnComplete,
        wrappedOnProgress,
        wrappedOnDelete,
      )
      .toDart;

  if (resultJS.statusCode != 0) {
    return CPResult.legacyError(
      privateMakeDittoError(
        _errorMessageThreadLocal() ??
            "Internal error: ditto_resolve_attachment() returned $resultJS.statusCode",
      ),
    );
  }

  return CPResult.legacyOk((resultJS.cancelToken, CPFreeable.noop()));
}

CPResult<void> dittoCancelResolveAttachment(
  CPPointer<CPDitto> ditto,
  Uint8List token,
  int cancelToken,
) {
  final statusCode = _dittoCore
      .dittoCancelResolveAttachment(
        ditto.asWasm(),
        token.toJS,
        cancelToken.toJS,
      )
      .toDartInt;
  if (statusCode != 0) {
    return CPResult.legacyError(
      privateMakeDittoError(
        _errorMessageThreadLocal() ??
            "Internal error: ditto_resolve_attachment() returned $statusCode",
      ),
    );
  }
  return CPResult.legacyOk(null);
}

Future<CPResult<Uint8List>> dittoGetCompleteAttachmentData(
  CPPointer<CPDitto> ditto,
  CPPointer<CPAttachmentHandle> attachment,
) async {
  final resultJS = await _dittoCore
      .dittoGetCompleteAttachmentData(ditto.asWasm(), attachment.asWasm())
      .toDart;

  if (resultJS.statusCode == 0) {
    final dataJS = resultJS.data;
    final data = _dittoCore.boxCBytesIntoBuffer(dataJS)!;
    return CPResult.legacyOk(data.toDart);
  } else {
    return CPResult.legacyError(
      privateMakeDittoError(
        _errorMessageThreadLocal() ??
            "Failed to get complete attachment data for handle: $attachment",
      ),
    );
  }
}

String dittoGetCompleteAttachmentPath(
  CPPointer<CPDitto> ditto,
  CPPointer<CPAttachmentHandle> attachment,
) {
  throw privateMakeDittoException(
    _errorMessageThreadLocal() ??
        "Retrieving a filesystem path for attachments is not supported on the Web.",
  );
}

void dittoFreeAttachmentHandle(CPPointer<CPAttachmentHandle> handle) {
  _dittoCore.dittoFreeAttachmentHandle(handle.asWasm());
}

Future<void> dittoLiveQueryStart(
  CPPointer<CPDitto> ditto,
  int liveQueryId,
) async {
  final errorCodeJS = await _dittoCore
      .dittoLiveQueryStart(ditto.asWasm(), liveQueryId.toJS)
      .toDart;
  if (errorCodeJS.toDartInt != 0) {
    throw privateMakeDittoError(
      _errorMessageThreadLocal() ??
          "ditto_live_query_start() failed with error code: ${errorCodeJS.toDartInt}",
    );
  }
}

void dittoLiveQueryStop(CPPointer<CPDitto> ditto, int liveQueryId) =>
    _dittoCore.dittoLiveQueryStop(ditto.asWasm(), liveQueryId.toJS);

// TODO(cameron): we should allow fields, not just getters, but only on "value types"
// perhaps a `@struct` annotation
extension type _DittoffiStoreBeginTransactionOptions._(JSObject _)
    implements JSObject {
  // ignore: ditto_js_extension_type_getters
  @JS("is_read_only")
  external JSBoolean isReadOnly;

  // ignore: ditto_js_extension_type_getters
  @JS("hint")
  external JSUint8Array? hint;

  factory _DittoffiStoreBeginTransactionOptions(JSObject value) {
    final self = _DittoffiStoreBeginTransactionOptions._(value);

    assert(self.isReadOnly == self.isReadOnly);
    assert(self.hint == self.hint);

    return self;
  }

  factory _DittoffiStoreBeginTransactionOptions.create({
    required String? hint,
    required bool isReadOnly,
  }) {
    return _DittoffiStoreBeginTransactionOptions(
      {
        "hint": hint == null ? null : bytesFromString(hint).toJS,
        "is_read_only": isReadOnly.toJS,
      }.jsify()! as JSObject,
    );
  }
}

Future<CPResult<CPPointer<CPTransaction>>>
    dittoffiStoreBeginTransactionAsyncThrows(
  CPPointer<CPStore> store,
  String? hint, {
  required bool isReadOnly,
}) async {
  final options = _DittoffiStoreBeginTransactionOptions.create(
    hint: hint,
    isReadOnly: isReadOnly,
  );

  final completer = Completer<_JSResult<_JSPointer<CPTransaction>>>();
  void continuation(_JSResult<_JSPointer<CPTransaction>>? result) {
    completer.complete(result);
  }

  _dittoCore.dittoffiStoreBeginTransactionAsyncThrows(
    store.asWasm().withType("dittoffi_store_t const *"),
    options,
    wrapBackgroundCbForFFI(onBackgroundError: null, continuation),
  );

  final result = await completer.future;
  return result.toCP().map((jsPointer) => jsPointer!.toCP());
}

Uint8List dittoffiTransactionInfo(CPPointer<CPTransaction> txn) => _dittoCore
    .boxCBytesIntoBuffer(_dittoCore.dittoffiTransactionInfo(txn.asWasm()))!
    .toDart;

Future<CPResult<CPPointer<CPQueryResult>>> dittoffiTransactionExecute(
  CPPointer<CPTransaction> txn,
  String query,
  Uint8List cborEncodedArgs,
) async {
  final queryBytes = bytesFromString(query);

  final completer = Completer<_JSResult<_JSPointer<CPQueryResult>>>();
  void continuation(_JSResult<_JSPointer<CPQueryResult>> result) =>
      completer.complete(result);

  _dittoCore.dittoffiTransactionExecuteAsyncThrows(
    txn.asWasm(),
    queryBytes.toJS,
    cborEncodedArgs.toJS,
    wrapBackgroundCbForFFI(onBackgroundError: null, continuation),
  );

  final result = await completer.future;
  return result.toCP().map((ptr) => ptr!.toCP());
}

Future<CPResult<TransactionCompletionAction>> dittoffiTransactionComplete(
  CPPointer<CPTransaction> txn,
  TransactionCompletionAction action,
) async {
  final actionString = switch (action) {
    TransactionCompletionAction.commit => "Commit".toJS,
    TransactionCompletionAction.rollback => "Rollback".toJS,
  };

  final completer = Completer<_JSResult<JSString>>();
  void continuation(_JSResult<JSString> result) => completer.complete(result);

  _dittoCore.dittoffiTransactionCompleteAsyncThrows(
    txn.asWasm(),
    actionString,
    wrapBackgroundCbForFFI(onBackgroundError: null, continuation),
  );

  final result = await completer.future;
  return result.toCP().map(
        (action) => switch (action!.toDart) {
          "Commit" => TransactionCompletionAction.commit,
          "Rollback" => TransactionCompletionAction.rollback,
          final other => throw privateMakeDittoError("unknown code: $other"),
        },
      );
}
