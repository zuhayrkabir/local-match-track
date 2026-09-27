// ignore_for_file: ditto_missing_visibility, ditto_store_ditto_ptr
part of "native.dart";

final _queryResultFinalizer = NativeFinalizer(
  bindings.addresses.dittoffi_query_result_free.cast(),
);

final _queryResultItemFinalizer = NativeFinalizer(
  bindings.addresses.dittoffi_query_result_item_free.cast(),
);

typedef _ExecuteRequest = ({
  int dittoPtr,
  String query,
  Uint8List cborEncodedArgs,
});
typedef _ExecuteResponse = ({dittoffi_result_dittoffi_query_result_ptr result});

/// isolate instead of dispatching to a long-lived background worker isolate.
///
/// Defaults to `false`: the FFI call runs on a per-`Ditto` worker isolate
/// (spawned lazily on first call, torn down on `Ditto.close()`), preserving
/// the non-blocking dispatch behavior introduced in SDK 5.0 without paying
/// the per-call isolate-spawn cost of the original `compute()` wrapper
/// (SDKS-3878 / SDKS-3879). Callers issuing many small queries from a thread
/// that does no other work can still flip this to `true` to run the FFI call
/// inline and skip the per-call SendPort hop entirely.
///
/// Set via [Store.experimentalSkipExecuteIsolateOffload].
bool experimentalSkipExecuteIsolateOffload = false;

Future<CPResult<CPPointer<CPQueryResult>>> dittoffiTryExecStatement(
  CPPointer<CPDitto> ditto,
  String query,
  Uint8List cborEncodedArgs,
) async {
  final dittoPtr = ditto.asFfi();
  final dittoffi_result_dittoffi_query_result_ptr result;
  if (experimentalSkipExecuteIsolateOffload) {
    result = withQueryAndArgs(
      query: query,
      argsCbor: cborEncodedArgs,
      (queryPtr, argsSlice) => bindings.dittoffi_try_exec_statement(
        dittoPtr.inner.cast(),
        queryPtr,
        argsSlice,
      ),
    );
  } else {
    final dittoAddress = dittoPtr.address;
    final worker = _executeWorkerFor(dittoAddress);
    final response = await worker.execute(
      (
        dittoPtr: dittoAddress,
        query: query,
        cborEncodedArgs: cborEncodedArgs,
      ),
    );
    result = response.result;
  }

  return _NativeResult(
    result,
    getSuccess: (res) {
      final pointer = res.success.toCP<CPQueryResult>();
      _queryResultFinalizer.attach(pointer, res.success.cast());
      return pointer;
    },
    getError: (res) => res.error,
  );
}

_ExecuteResponse _dittoffiTryExecStatementSync(_ExecuteRequest request) {
  final result = withQueryAndArgs(
    query: request.query,
    argsCbor: request.cborEncodedArgs,
    (queryPtr, argsSlice) => bindings.dittoffi_try_exec_statement(
      Pointer.fromAddress(request.dittoPtr),
      queryPtr,
      argsSlice,
    ),
  );

  return (result: result);
}

// === Long-lived `Store.execute` worker isolate (SDKS-3879) ===
//
// The 5.0.0 `compute()` wrapper spawned a fresh isolate per `Store.execute`
// call, paying ~150-300µs of isolate-spawn overhead on every dispatch and
// regressing throughput for apps issuing many small queries (SDKS-3878).
// This worker replaces that wrapper with a single per-`Ditto` isolate that
// stays alive for the lifetime of the `Ditto` instance:
//
//   - lazy spawn on the first `execute()` call,
//   - SendPort/ReceivePort dispatch for each subsequent call,
//   - torn down by `Ditto.close()` via [disposeExecuteWorker].
//
// Per-`Ditto` (rather than process-global) so each instance's worker can be
// cleanly killed alongside its FFI handle: the worker holds the same
// `Ditto*` address the main isolate does, so freeing the underlying handle
// while the worker still has pending work would dereference a dangling
// pointer. Tying lifetime to the owning Ditto avoids that. Concurrent
// `execute()` calls on the same Ditto serialize through this one worker;
// that matches what users of "non-blocking dispatch" typically want
// (calling isolate doesn't block) and is acceptable for the IMMFLY-style
// workload (many sequential small queries) that motivated SDKS-3878.

// Sentinel sent by the worker after it processes the shutdown null and is
// about to close its ReceivePort. dispose() awaits this so Ditto.close()
// does not call ditto_free while the worker is mid-FFI (SDKS-3879).
const String _drainedAck = "ditto-execute-worker:drained";

class _ExecuteWorker {
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _replyPort;
  ReceivePort? _errorPort;
  ReceivePort? _exitPort;
  Completer<SendPort>? _starting;
  Completer<void>? _drained;
  final Map<int, Completer<_ExecuteResponse>> _pending = {};
  int _nextId = 0;
  bool _disposed = false;

  // Set when the worker dies for any non-disposal reason (FFI panic,
  // unhandled error, unexpected exit). Subsequent execute() calls fail
  // immediately with this error rather than hanging on a dead SendPort.
  StateError? _terminalError;

  Future<_ExecuteResponse> execute(_ExecuteRequest req) async {
    if (_disposed) {
      throw StateError(
        "Execute worker isolate has been disposed; this Ditto is closed",
      );
    }
    if (_terminalError != null) throw _terminalError!;

    final send = _sendPort ?? await _spawn();

    // Re-check after every async hop. dispose() or a worker crash may have
    // landed during `await _spawn()`. The insert below MUST be synchronous
    // with this check so no microtask can interleave dispose() between the
    // gate and `_pending[id] = completer` (SDKS-3879 REL-002).
    if (_disposed) {
      throw StateError(
        "Execute worker isolate was disposed while spawning",
      );
    }
    if (_terminalError != null) throw _terminalError!;

    // Correlation IDs (not per-call ReceivePorts) so we don't allocate a
    // fresh OS-level port and StreamSubscription for every Store.execute
    // call. An earlier per-call-port design showed p99 spikes ~12× the
    // direct-FFI baseline on empty-SELECT workloads; amortizing the reply
    // port across all calls keeps tail latency within the bench's 2×
    // acceptance bound.
    final id = _nextId++;
    final completer = Completer<_ExecuteResponse>();
    _pending[id] = completer;

    send.send((id, req));
    return completer.future;
  }

  Future<SendPort> _spawn() async {
    final existing = _starting;
    if (existing != null) return existing.future;

    final starting = Completer<SendPort>();
    _starting = starting;

    final replyPort = ReceivePort();
    _replyPort = replyPort;
    replyPort.listen(_onReply);

    // onError catches uncaught throws inside the worker (e.g., FFI panic
    // propagated as a Dart exception). onExit catches all isolate exits,
    // expected or otherwise. Without these, a dead worker is invisible
    // and every pending Completer hangs forever (SDKS-3879 REL-001).
    final errorPort = ReceivePort();
    _errorPort = errorPort;
    errorPort.listen(_onWorkerError);

    final exitPort = ReceivePort();
    _exitPort = exitPort;
    exitPort.listen(_onWorkerExit);

    try {
      _isolate = await Isolate.spawn(
        _executeWorkerEntryPoint,
        replyPort.sendPort,
        debugName: "ditto-execute-worker",
        onError: errorPort.sendPort,
        onExit: exitPort.sendPort,
      );
    } catch (e) {
      _closePorts();
      _starting = null;
      if (!starting.isCompleted) starting.completeError(e);
      rethrow;
    }

    // dispose() may have run while we were awaiting Isolate.spawn. The
    // newly spawned isolate is otherwise orphaned (nothing kills it after
    // assignment, because dispose already passed its kill call). Detect
    // and clean up here (SDKS-3879 A-2).
    if (_disposed) {
      _isolate?.kill();
      _isolate = null;
      _closePorts();
      final err = StateError("Ditto closed during execute worker spawn");
      if (!starting.isCompleted) starting.completeError(err);
      _starting = null;
      throw err;
    }

    return starting.future;
  }

  void _onReply(dynamic msg) {
    // First message from the worker after spawn is its SendPort (handshake).
    // Then either correlation-keyed responses, or the drained ack.
    if (msg is SendPort) {
      _sendPort = msg;
      final starting = _starting;
      if (starting != null && !starting.isCompleted) starting.complete(msg);
      return;
    }
    if (msg == _drainedAck) {
      final drained = _drained;
      if (drained != null && !drained.isCompleted) drained.complete();
      return;
    }
    // (id, _ExecuteResponse). Defensive: a malformed message (out-of-order
    // or post-disposal noise) should not crash the reply pump.
    if (msg is! (int, _ExecuteResponse)) return;
    final (id, response) = msg;
    final completer = _pending.remove(id);
    if (completer != null && !completer.isCompleted) {
      completer.complete(response);
    }
  }

  void _onWorkerError(dynamic msg) {
    // Dart sends `[error.toString(), stackTrace.toString()]` to onError.
    final summary =
        msg is List && msg.isNotEmpty ? msg[0].toString() : "unknown error";
    _setTerminal(
      StateError("Execute worker isolate threw: $summary"),
    );
  }

  void _onWorkerExit(dynamic _) {
    // Always release any awaited drained ack so dispose() can proceed past
    // its timeout-or-drained race. If the exit is expected (we set
    // _disposed first) this is the normal completion path; if it is
    // unexpected, _setTerminal will also fire below.
    final drained = _drained;
    if (drained != null && !drained.isCompleted) drained.complete();

    if (_disposed) return;
    _setTerminal(
      StateError("Execute worker isolate exited unexpectedly"),
    );
  }

  void _setTerminal(StateError error) {
    if (_terminalError != null || _disposed) return;
    _terminalError = error;

    final pending = List.of(_pending.values);
    _pending.clear();
    for (final c in pending) {
      if (!c.isCompleted) c.completeError(error);
    }
    final starting = _starting;
    if (starting != null && !starting.isCompleted) {
      starting.completeError(error);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    // Reject any in-flight execute() Futures and the in-flight spawn
    // Completer so callers don't hang past Ditto.close() (SDKS-3879
    // REL-002, REL-003, A-1). _setTerminal would have done the same, but
    // we use direct rejection here so the StateError text reflects close
    // rather than crash.
    final closedError = StateError("Ditto closed before execute() completed");
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(closedError);
    }
    _pending.clear();
    final starting = _starting;
    if (starting != null && !starting.isCompleted) {
      starting.completeError(closedError);
    }

    // Wait for the worker to drain its current FFI call and ack before we
    // kill the isolate and let Ditto.close() free the underlying pointer.
    // Without this wait, ditto_free can race the worker's in-flight call
    // and dereference freed memory (SDKS-3879 C-02 / A-3). The bounded
    // timeout caps the wait in case the worker is stuck.
    final sendPort = _sendPort;
    if (sendPort != null) {
      final drained = Completer<void>();
      _drained = drained;
      try {
        sendPort.send(null);
        await drained.future.timeout(const Duration(seconds: 5));
      } catch (_) {
        // Timeout or send-on-closed-port: fall through to kill anyway.
        // The pending Completers are already rejected above.
      }
    }

    _isolate?.kill();
    _isolate = null;
    _sendPort = null;
    _closePorts();
    _starting = null;
    _drained = null;
  }

  void _closePorts() {
    _replyPort?.close();
    _replyPort = null;
    _errorPort?.close();
    _errorPort = null;
    _exitPort?.close();
    _exitPort = null;
  }
}

void _executeWorkerEntryPoint(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  receivePort.listen((msg) {
    if (msg == null) {
      // Shutdown sentinel. Ack so dispose() knows the queue has been
      // drained (any prior FFI call completed) before it kills the
      // isolate and lets ditto_free run.
      mainSendPort.send(_drainedAck);
      receivePort.close();
      return;
    }
    final (id, req) = msg as (int, _ExecuteRequest);
    // Don't catch — let throws propagate to the isolate's error port so
    // the main side can fail pending Completers via _onWorkerError. The
    // alternative (catch + send error-tagged response) would require a
    // wider response protocol; the error-port path is simpler.
    final response = _dittoffiTryExecStatementSync(req);
    mainSendPort.send((id, response));
  });
}

// Keyed on the raw Ditto pointer address so we don't need to plumb a
// `_ExecuteWorker` reference through every layer between
// `Store.execute` and `bridge/native/store.dart`. The corresponding
// teardown happens in [disposeExecuteWorker] from `Ditto.close()`.
final Map<int, _ExecuteWorker> _executeWorkers = {};

_ExecuteWorker _executeWorkerFor(int dittoAddress) =>
    _executeWorkers.putIfAbsent(dittoAddress, _ExecuteWorker.new);

/// Tears down the per-`Ditto` execute worker isolate, if one has been spawned.
///
/// Called from `Ditto.close()` after sync has been stopped and before the
/// underlying FFI handle is freed, so the worker doesn't hold a dangling
/// pointer past the call to `ditto_free`.
Future<void> disposeExecuteWorker(CPPointer<CPDitto> ditto) async {
  final dittoPtr = ditto.asFfi();
  final worker = _executeWorkers.remove(dittoPtr.address);
  if (worker != null) {
    await worker.dispose();
  }
}

int dittoffiQueryResultItemCount(CPPointer<CPQueryResult> qr) {
  final qrPtr = qr.asFfi();
  return bindings.dittoffi_query_result_item_count(qrPtr.inner.cast());
}

CPPointer<CPQueryResultItem> dittoffiQueryResultItemAt(
  CPPointer<CPQueryResult> qr,
  int index,
) {
  final qrPtr = qr.asFfi();

  // does this need a finalizer?
  final ptr = bindings.dittoffi_query_result_item_at(qrPtr.inner.cast(), index);
  final cpPtr = ptr.toCP<CPQueryResultItem>();

  // yes, yes it does...
  _queryResultItemFinalizer.attach(cpPtr, ptr.cast());

  return cpPtr;
}

String dittoffiQueryResultItemJson(CPPointer<CPQueryResultItem> item) {
  final itemPtr = item.asFfi();
  final pointer = bindings.dittoffi_query_result_item_json(
    itemPtr.inner.cast(),
  );
  return stringFromCharStar(pointer, free: true);
}

Uint8List dittoffiQueryResultItemCbor(CPPointer<CPQueryResultItem> item) {
  final itemPtr = item.asFfi();
  final bytes = bindings.dittoffi_query_result_item_cbor(itemPtr.inner.cast());
  return bytesFromNative(bytes, free: true);
}

CPResult<CPPointer<CPQueryResultItem>> dittoffiQueryResultItemNew(
  Uint8List json,
) {
  final jsonSlice = bytesToSlice(json);
  final result = bindings.dittoffi_query_result_item_new(jsonSlice.ref);

  return _NativeResult(
    result,
    getSuccess: (res) {
      final pointer = res.success.toCP<CPQueryResultItem>();
      _queryResultItemFinalizer.attach(pointer, res.success.cast());
      return pointer;
    },
    getError: (res) => res.error,
  );
}

int dittoffiQueryResultMutatedDocumentIdCount(CPPointer<CPQueryResult> qr) {
  final qrPtr = qr.asFfi();
  return bindings.dittoffi_query_result_mutated_document_id_count(
    qrPtr.inner.cast(),
  );
}

Uint8List dittoffiQueryResultMutatedDocumentIdAt(
  CPPointer<CPQueryResult> qr,
  int index,
) {
  final qrPtr = qr.asFfi();
  final result = bindings.dittoffi_query_result_mutated_document_id_at(
    qrPtr.inner.cast(),
    index,
  );

  return bytesFromNative(result, free: true);
}

bool dittoffiQueryResultHasCommitId(CPPointer<CPQueryResult> qr) {
  final qrPtr = qr.asFfi();
  return bindings.dittoffi_query_result_has_commit_id(qrPtr.inner.cast());
}

int dittoffiQueryResultCommitId(CPPointer<CPQueryResult> qr) {
  final qrPtr = qr.asFfi();
  return bindings.dittoffi_query_result_commit_id(qrPtr.inner.cast());
}

CPResult<(int, CPFreeable)> dittoffiTryExperimentalRegisterChangeObserverStr(
  CPPointer<CPDitto> ditto,
  String query,
  Uint8List cborEncodedArgs,
  void Function(CPChangeHandlerWithQueryResult) callback,
) {
  final dittoPtr = ditto.asFfi();
  void cb(Pointer<Void> ctx, ChangeHandlerWithQueryResult result) {
    if (result.query_result == nullptr) return;
    final ptr = result.query_result.toCP<CPQueryResult>();
    _queryResultFinalizer.attach(ptr, result.query_result.cast());
    final struct = CPChangeHandlerWithQueryResult(queryResult: ptr);

    callback(struct);
  }

  final nativeCb = NativeCallable<
      Void Function(Pointer<Void>, ChangeHandlerWithQueryResult)>.listener(cb);

  final freeable = NativeCallableFreeable(nativeCb);

  final result = withQueryAndArgs(
    query: query,
    argsCbor: cborEncodedArgs,
    (
      queryPtr,
      argsSlice,
    ) =>
        bindings.dittoffi_try_experimental_register_change_observer_str(
      dittoPtr.inner.cast(),
      queryPtr,
      argsSlice,
      LiveQueryAvailability.LIVE_QUERY_AVAILABILITY_ALWAYS,
      dummyNonNullPointer,
      // See doc_internal/src/architecture/core_api.md "Ref Count and Ownership"
      bindings.dittoffi_get_noop_void_ptr_fn(), // retain
      bindings.dittoffi_get_noop_void_ptr_fn(), // release
      nativeCb.nativeFunction,
    ),
  );

  return _NativeResult(
    result,
    getSuccess: (res) {
      return (res.success, freeable);
    },
    getError: (res) => res.error,
  );
}

final _storeObserverFinalizer = NativeFinalizer(
  bindings.addresses.dittoffi_store_observer_free.cast(),
);

CPResult<(CPPointer<CPStoreObserver>, CPFreeable)>
    dittoFfiStoreRegisterObserverThrows(
  CPPointer<CPDitto> ditto,
  String query,
  Uint8List queryArgumentsCBOR,
  void Function(CPChangeHandlerWithQueryResultAndSignalNext) callback,
) {
  final dittoPtr = ditto.asFfi();

  void cb(
    Pointer<Void> /* env */ _,
    Pointer<dittoffi_query_result_t> queryResultPtr,
    ArcDynFn0_void_t ffiSignalNext,
  ) {
    final cpQueryResultPtr = queryResultPtr.toCP<CPQueryResult>();
    _queryResultFinalizer.attach(cpQueryResultPtr, queryResultPtr.cast());

    void signalNextDart() {
      final callFn =
          ffiSignalNext.call.asFunction<void Function(Pointer<Void>)>();
      callFn(ffiSignalNext.env_ptr);
    }

    callback(
      CPChangeHandlerWithQueryResultAndSignalNext(
        queryResult: cpQueryResultPtr,
        signalNext: signalNextDart,
      ),
    );
  }

  late final NativeCallable<
      Void Function(
        Pointer<Void>,
        Pointer<dittoffi_query_result_t>,
        ArcDynFn0_void_t,
      )> nativeCb;
  late final NativeCallable<Void Function(Pointer<Void>)> freeCallable;

  // Invoked by Rust when it drops the `Box<dyn FnMut>` — i.e., once the
  // observer is fully cancelled and no more callbacks will fire. Only then
  // is it safe to close the NativeCallables; closing them earlier races
  // with inflight callbacks and aborts the Dart VM with
  // "Callback invoked after it has been deleted." (SDKS-2389)
  void freeCb(Pointer<Void> _) {
    // Defer to avoid closing `freeCallable` from within its own invocation.
    scheduleMicrotask(() {
      nativeCb.close();
      freeCallable.close();
    });
  }

  nativeCb = NativeCallable<
      Void Function(
        Pointer<Void>,
        Pointer<dittoffi_query_result_t>,
        ArcDynFn0_void_t,
      )>.listener(cb);
  freeCallable = NativeCallable<Void Function(Pointer<Void>)>.listener(freeCb);

  final ffiHandler =
      calloc<BoxDynFnMut2_void_dittoffi_query_result_ptr_ArcDynFn0_void>();
  ffiHandler.ref.env_ptr = dummyNonNullPointer;
  ffiHandler.ref.free = freeCallable.nativeFunction;
  ffiHandler.ref.call = nativeCb.nativeFunction;

  final result = withQueryAndArgs(
    query: query,
    argsCbor: queryArgumentsCBOR,
    (queryPtr, argsSlice) => bindings.dittoffi_store_register_observer_throws(
      dittoPtr.inner.cast(),
      queryPtr,
      argsSlice,
      ffiHandler.ref,
    ),
  );

  // The struct is passed by value to Rust; free our allocation now.
  malloc.free(ffiHandler);

  // On registration failure, Rust never took ownership of the handler and
  // won't invoke `free`, so clean up the NativeCallables here.
  if (result.error != nullptr) {
    nativeCb.close();
    freeCallable.close();
  }

  return _NativeResult(
    result,
    getSuccess: (res) {
      final ptr = res.success.toCP<CPStoreObserver>();
      _storeObserverFinalizer.attach(ptr, res.success.cast());
      // Cleanup is driven by Rust invoking our `free` callback when it
      // drops the handler; nothing for the caller to free.
      return (ptr, CPFreeable.noop());
    },
    getError: (res) => res.error,
  );
}

bool dittoFfiStoreObserverIsCancelled(
  CPPointer<CPStoreObserver> storeObserver,
) {
  final ptr = storeObserver.asFfi();
  return bindings.dittoffi_store_observer_is_cancelled(ptr.inner.cast());
}

void dittoFfiStoreObserverCancel(CPPointer<CPStoreObserver> storeObserver) {
  final ptr = storeObserver.asFfi();
  bindings.dittoffi_store_observer_cancel(ptr.inner.cast());
}

String dittoFfiStoreObserverQueryString(
  CPPointer<CPStoreObserver> storeObserver,
) {
  final ptr = storeObserver.asFfi();
  final queryStringPtr = bindings.dittoffi_store_observer_query_string(
    ptr.inner.cast(),
  );
  return stringFromCharStar(queryStringPtr, free: true);
}

Uint8List dittoFfiStoreObserverQueryArgumentsCbor(
  CPPointer<CPStoreObserver> storeObserver,
) {
  final ptr = storeObserver.asFfi();
  final queryArgsBytes = bindings.dittoffi_store_observer_query_arguments_cbor(
    ptr.inner.cast(),
  );
  return bytesFromNative(queryArgsBytes, free: true);
}

String dittoFfiStoreObserverQueryArgumentsJson(
  CPPointer<CPStoreObserver> storeObserver,
) {
  final ptr = storeObserver.asFfi();
  final queryArgsJsonBytes =
      bindings.dittoffi_store_observer_query_arguments_json(
    ptr.inner.cast(),
  );
  return utf8.decode(bytesFromNative(queryArgsJsonBytes, free: true));
}

Uint8List dittoFfiStoreObserverId(
  CPPointer<CPStoreObserver> storeObserver,
) {
  final ptr = storeObserver.asFfi();
  final idBytes = bindings.dittoffi_store_observer_id(ptr.inner.cast());
  return bytesFromNative(idBytes, free: true);
}

CPResult<CPAttachment> dittoNewAttachmentFromFile(
  CPPointer<CPDitto> ditto,
  String path,
  CPAttachmentFileOperation op,
) {
  final dittoPtr = ditto.asFfi();
  final opInt = switch (op) {
    CPAttachmentFileOperation.copy =>
      AttachmentFileOperation.ATTACHMENT_FILE_OPERATION_COPY,
    CPAttachmentFileOperation.move =>
      AttachmentFileOperation.ATTACHMENT_FILE_OPERATION_MOVE,
  };

  final outAttachment = malloc<CAttachment>();

  final errorCode = withStringAsPtr(
    path,
    (pathPtr) => bindings.ditto_new_attachment_from_file(
      dittoPtr.inner.cast(),
      pathPtr,
      opInt,
      outAttachment,
    ),
  );

  if (errorCode != 0) {
    malloc.free(outAttachment);
    return CPResult.legacyException(
      privateMakeDittoException(
        "Failed to create attachment with error code: $errorCode",
      ),
    );
  }

  final id = bytesFromNative(outAttachment.ref.id, free: true);
  final len = outAttachment.ref.len;
  final handle = outAttachment.ref.handle.toCP<CPAttachmentHandle>();
  malloc.free(outAttachment);
  final attachment = CPAttachment(id: id, len: len, handle: handle);

  return CPResult.legacyOk(attachment);
}

CPResult<CPAttachment> dittoNewAttachmentFromBytes(
  CPPointer<CPDitto> ditto,
  Uint8List bytes,
) {
  final dittoPtr = ditto.asFfi();
  final outAttachment = malloc<CAttachment>();

  final cborSlice = bytesToSlice(bytes);
  final errorCode = bindings.ditto_new_attachment_from_bytes(
    dittoPtr.inner.cast(),
    cborSlice.ref,
    outAttachment,
  );
  freeSliceRef(cborSlice);

  if (errorCode != 0) {
    malloc.free(outAttachment);
    return CPResult.legacyException(
      privateMakeDittoException(
        "Failed to create attachment with error code: $errorCode",
      ),
    );
  }

  final id = bytesFromNative(outAttachment.ref.id, free: true);
  final len = outAttachment.ref.len;
  final handle = outAttachment.ref.handle.toCP<CPAttachmentHandle>();
  malloc.free(outAttachment);
  final attachment = CPAttachment(id: id, len: len, handle: handle);

  return CPResult.legacyOk(attachment);
}

final _attachmentHandleFinalizer = NativeFinalizer(
  bindings.addresses.ditto_free_attachment_handle.cast(),
);

CPResult<(CPPointer<CPAttachmentHandle>, String, int)>
    utilExtractAndFreeAttachment(CPAttachment attachment) {
  final sliceRef = bytesToSlice(attachment.id);
  final idStar = bindings.dittoffi_base64_encode(
    sliceRef.ref,
    Base64PaddingMode.BASE64_PADDING_MODE_UNPADDED,
  );
  final id = stringFromCharStar(idStar, free: true);
  final len = attachment.len;
  final handle = attachment.handle;

  malloc.free(sliceRef);

  final cpHandle = handle.asFfi();
  _attachmentHandleFinalizer.attach(cpHandle, cpHandle.inner.cast());

  return CPResult.legacyOk((handle, id, len));
}

Future<CPResult<(int, CPFreeable)>> dittoResolveAttachment(
  CPPointer<CPDitto> ditto,
  Uint8List token,
  void Function(CPPointer<CPAttachmentHandle>) onComplete,
  void Function(int downloadedBytes, int totalBytes) onProgress,
  void Function() onDelete,
) {
  final dittoPtr = ditto.asFfi();
  void wrappedOnComplete(
    Pointer<Void> ctx,
    Pointer<AttachmentHandle> attachmentHandlePointer,
  ) {
    // Rust guarantees that the pointer not be null.
    onComplete(attachmentHandlePointer.toCP());
  }

  void wrappedOnProgress(Pointer<Void> ctx, int downloaded, int toDownload) {
    onProgress(downloaded, toDownload);
  }

  void wrappedOnDelete(Pointer<Void> ctx) {
    onDelete();
  }

  final onCompleteCb = NativeCallable<
      Void Function(
        Pointer<Void>,
        Pointer<AttachmentHandle>,
      )>.listener(
    wrappedOnComplete,
  );

  final onProgressCb =
      NativeCallable<Void Function(Pointer<Void>, Uint64, Uint64)>.listener(
    wrappedOnProgress,
  );

  final onDeleteCb = NativeCallable<Void Function(Pointer<Void>)>.listener(
    wrappedOnDelete,
  );

  final cborSlice = bytesToSlice(token);
  final result = bindings.ditto_resolve_attachment(
    dittoPtr.inner.cast(),
    cborSlice.ref,
    nullptr,
    nullptr,
    nullptr,
    onCompleteCb.nativeFunction,
    onProgressCb.nativeFunction,
    onDeleteCb.nativeFunction,
  );

  if (result.status_code != 0) {
    return Future.value(
      CPResult.legacyError(
        privateMakeDittoError(
          "Internal error: Couldn't retrieve cancel token for attachment",
        ),
      ),
    );
  }

  final guard = CPMultiFreeable([
    NativeCallableFreeable(onCompleteCb),
    NativeCallableFreeable(onProgressCb),
    NativeCallableFreeable(onDeleteCb),
  ]);

  freeSliceRef(cborSlice);

  return Future.value(CPResult.legacyOk((result.cancel_token, guard)));
}

CPResult<void> dittoCancelResolveAttachment(
  CPPointer<CPDitto> ditto,
  Uint8List token,
  int cancelToken,
) {
  final dittoPtr = ditto.asFfi();
  final cborSlice = bytesToSlice(token);
  final statusCode = bindings.ditto_cancel_resolve_attachment(
    dittoPtr.inner.cast(),
    cborSlice.ref,
    cancelToken,
  );

  if (statusCode != 0) {
    return CPResult.legacyError(
      privateMakeDittoError(
        "Internal error: Couldn't retrieve cancel token for attachment",
      ),
    );
  }
  freeSliceRef(cborSlice);
  return CPResult.legacyOk(null);
}

CPResult<Uint8List> dittoGetCompleteAttachmentData(
  CPPointer<CPDitto> ditto,
  CPPointer<CPAttachmentHandle> attachment,
) {
  final dittoPtr = ditto.asFfi();
  final attachmentPtr = attachment.asFfi();

  final result = bindings.ditto_get_complete_attachment_data(
    dittoPtr.inner.cast(),
    attachmentPtr.inner.cast(),
  );

  return switch (result.status) {
    0 => CPResult.legacyOk(bytesFromNative(result.data, free: true)),
    -1 => CPResult.legacyError(privateMakeDittoError(takeErrorMessage())),
    final other => CPResult.legacyError(
        privateMakeDittoError("unknown error code: $other"),
      ),
  };
}

String dittoGetCompleteAttachmentPath(
  CPPointer<CPDitto> ditto,
  CPPointer<CPAttachmentHandle> attachment,
) {
  final dittoPtr = ditto.asFfi();
  final attachmentPtr = attachment.asFfi();

  final pathStar = bindings.ditto_get_complete_attachment_path(
    dittoPtr.inner.cast(),
    attachmentPtr.inner.cast(),
  );

  return stringFromCharStar(pathStar, free: true);
}

// ignore: ditto_ffi_wrapper_local_variables
void dittoFreeAttachmentHandle(CPPointer<CPAttachmentHandle> handle) => _$;

void dittoLiveQueryStart(CPPointer<CPDitto> ditto, int liveQueryId) {
  final dittoPtr = ditto.asFfi();
  bindings.ditto_live_query_start(dittoPtr.inner.cast(), liveQueryId);
}

void dittoLiveQueryStop(CPPointer<CPDitto> ditto, int liveQueryId) {
  final dittoPtr = ditto.asFfi();
  bindings.ditto_live_query_stop(dittoPtr.inner.cast(), liveQueryId);
}

typedef _CreateTransactionCompletion = Void Function(
  Pointer<Void>,
  dittoffi_result_dittoffi_transaction_ptr,
);

final _transactionFinalizer = NativeFinalizer(
  bindings.addresses.dittoffi_transaction_free.cast(),
);

Future<CPResult<CPPointer<CPTransaction>>>
    dittoffiStoreBeginTransactionAsyncThrows(
  CPPointer<CPStore> store,
  String? hint, {
  required bool isReadOnly,
}) {
  final storePtr = store.asFfi();
  return withStringAsPtr(hint, (hintPtr) async {
    final completer = Completer<CPResult<CPPointer<CPTransaction>>>();

    final continuation =
        malloc<BoxDynFnMut1_void_dittoffi_result_dittoffi_transaction_ptr>();

    void cb(
      Pointer<Void> /* env */ _,
      dittoffi_result_dittoffi_transaction_ptr result,
    ) {
      final nativeResult = _NativeResult(
        result,
        getSuccess: (res) {
          final ptr = result.success.toCP<CPTransaction>();
          _transactionFinalizer.attach(ptr, result.success.cast());
          return ptr;
        },
        getError: (res) => res.error,
      );
      completer.complete(nativeResult);
    }

    final nativeCallable =
        NativeCallable<_CreateTransactionCompletion>.listener(cb);

    continuation.ref.env_ptr = dummyNonNullPointer;
    // See doc_internal/src/architecture/core_api.md "Ref Count and Ownership"
    continuation.ref.free = bindings.dittoffi_get_noop_void_ptr_fn();
    continuation.ref.call = nativeCallable.nativeFunction;

    final options = malloc<dittoffi_store_begin_transaction_options_t>();
    options.ref.hint = hintPtr;
    options.ref.is_read_only = isReadOnly;

    bindings.dittoffi_store_begin_transaction_async_throws(
      storePtr.inner.cast(),
      options.ref,
      continuation.ref,
    );

    final result = await completer.future;

    malloc
      ..free(options)
      ..free(continuation);

    nativeCallable.close();

    return result;
  });
}

Uint8List dittoffiTransactionInfo(CPPointer<CPTransaction> txn) {
  final txnPtr = txn.asFfi();
  final slice = bindings.dittoffi_transaction_info(txnPtr.inner.cast());
  return bytesFromNative(slice, free: true);
}

typedef _TransactionExecuteCallback = Void Function(
  Pointer<Void>,
  dittoffi_result_dittoffi_query_result_ptr,
);

Future<CPResult<CPPointer<CPQueryResult>>> dittoffiTransactionExecute(
  CPPointer<CPTransaction> txn,
  String query,
  Uint8List cborEncodedArgs,
) async {
  final txnPtr = txn.asFfi();
  final completer = Completer<CPResult<CPPointer<CPQueryResult>>>();

  void cb(
    Pointer<Void> /* env */ _,
    dittoffi_result_dittoffi_query_result_ptr result,
  ) {
    final nativeResult = _NativeResult(
      result,
      getSuccess: (res) {
        final ptr = res.success.toCP<CPQueryResult>();
        _queryResultFinalizer.attach(ptr, res.success.cast());
        return ptr;
      },
      getError: (res) => res.error,
    );
    completer.complete(nativeResult);
  }

  final nativeCallable = NativeCallable<_TransactionExecuteCallback>.listener(
    cb,
  );

  final continuation =
      malloc<BoxDynFnMut1_void_dittoffi_result_dittoffi_query_result_ptr>();

  continuation.ref.env_ptr = dummyNonNullPointer;
  // See doc_internal/src/architecture/core_api.md "Ref Count and Ownership"
  continuation.ref.free = bindings.dittoffi_get_noop_void_ptr_fn();
  continuation.ref.call = nativeCallable.nativeFunction;

  withQueryAndArgs(query: query, argsCbor: cborEncodedArgs, (
    queryPtr,
    argsPtr,
  ) {
    bindings.dittoffi_transaction_execute_async_throws(
      txnPtr.inner.cast(),
      queryPtr,
      argsPtr,
      continuation.ref,
    );
  });

  final result = await completer.future;

  malloc.free(continuation);
  nativeCallable.close();

  return result;
}

typedef _TransactionCompleteCallback = Void Function(
  Pointer<Void>,
  dittoffi_result_dittoffi_transaction_completion_action,
);

Future<CPResult<TransactionCompletionAction>> dittoffiTransactionComplete(
  CPPointer<CPTransaction> txn,
  TransactionCompletionAction action,
) async {
  final txnPtr = txn.asFfi();
  final completer = Completer<CPResult<TransactionCompletionAction>>();

  final actionInt = switch (action) {
    TransactionCompletionAction.commit => 0,
    TransactionCompletionAction.rollback => 1,
  };

  final continuation = malloc<
      BoxDynFnMut1_void_dittoffi_result_dittoffi_transaction_completion_action>();

  void cb(
    Pointer<Void> /* env */ _,
    dittoffi_result_dittoffi_transaction_completion_action result,
  ) {
    final nativeResult = _NativeResult(
      result,
      getSuccess: (res) => switch (res.success) {
        0 => TransactionCompletionAction.commit,
        1 => TransactionCompletionAction.rollback,
        final x => throw privateMakeDittoError("Unknown value: $x"),
      },
      getError: (res) => res.error,
    );
    completer.complete(nativeResult);
  }

  final callable = NativeCallable<_TransactionCompleteCallback>.listener(cb);

  continuation.ref.env_ptr = dummyNonNullPointer;
  // See doc_internal/src/architecture/core_api.md "Ref Count and Ownership"
  continuation.ref.free = bindings.dittoffi_get_noop_void_ptr_fn();
  continuation.ref.call = callable.nativeFunction;

  bindings.dittoffi_transaction_complete_async_throws(
    txnPtr.inner.cast(),
    actionInt,
    continuation.ref,
  );

  final result = await completer.future;

  malloc.free(continuation);
  callable.close();

  return result;
}
