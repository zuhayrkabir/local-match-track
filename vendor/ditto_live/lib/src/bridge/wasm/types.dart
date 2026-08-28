// ignore_for_file: cascade_invocations

part of "wasm.dart";

// We need two layers of wrapping here
//
// We need `_JSPointer` to give us type-safe bindings to JS.
// It must be an extension type, because it must not introduce a new object
// Extension types are guaranteed to have no impact on runtime object structure.
//
// We need `_WasmPointer` because we need to implement `CPPointer<T>`.
// Extension types are prohibited from implementing/extending Dart types
// (with some limited exceptions that don't apply here)

// ignore: unused_element
class _WasmPointer<T extends CPPointerTarget> implements CPPointer<T> {
  final _JSPointer<T> _inner;

  _WasmPointer._fromUntrackedPointer(this._inner);

  factory _WasmPointer(_JSPointer<T> inner) {
    final registry =
        _PointerRegistry.byType[inner._type.toDart] as _PointerRegistry<T>?;
    if (registry == null) {
      _registryDebugLog(
        "Can not track and free pointer type: ${inner._type}",
      );
      return _WasmPointer._fromUntrackedPointer(inner);
    }
    return registry._get(inner);
  }

  @override
  int get address => throw UnsupportedError("not on web :(");
}

/// Returns a count of the number of pointers tracked by the registry for each
/// type.
@visibleForTesting
@internal
Map<String, int> get pointerRegistryLengths {
  final result = <String, int>{};
  for (final entry in _PointerRegistry.byType.entries) {
    if (entry.value.length > 0) result[entry.key] = entry.value.length;
  }
  return result;
}

class _PointerRegistry<T extends CPPointerTarget> {
  final FutureOr<void> Function(_JSPointer<T> pointer) _release;

  final _objectsByAddress = _WeakMap<int, _WasmPointer<T>>();
  late Finalizer<_JSPointer> _finalizer;

  _PointerRegistry(this._release) {
    _finalizer = Finalizer<_JSPointer<T>>(_finalize);
  }

  static final byType = {
    "AttachmentHandle_t *": _PointerRegistry<CPAttachmentHandle>(
      (pointer) => _dittoCore.dittoFreeAttachmentHandle(pointer),
    ),
    "dittoffi_connection_request_t *": _PointerRegistry<CPConnectionRequest>(
      (pointer) => _dittoCore.dittoffiConnectionRequestFree(pointer),
    ),
    "CDocument_t *": _PointerRegistry<CPDocument>(
      (pointer) => _dittoCore.dittoDocumentFree(pointer),
    ),
    "dittoffi_error_t *": _PointerRegistry<CPError>(
      (pointer) => _dittoCore.dittoffiErrorFree(pointer),
    ),
    "dittoffi_query_result_t *": _PointerRegistry<CPQueryResult>(
      (pointer) => _dittoCore.dittoffiQueryResultFree(pointer),
    ),
    "dittoffi_query_result_item_t *": _PointerRegistry<CPQueryResultItem>(
      (pointer) => _dittoCore.dittoffiQueryResultItemFree(pointer),
    ),
    "dittoffi_sync_subscription_t *": _PointerRegistry<CPSyncSubscription>(
      (pointer) => _dittoCore.dittoFfiSyncSubscriptionFree(pointer),
    ),
    "dittoffi_store_observer_t *": _PointerRegistry<CPStoreObserver>(
      (pointer) => _dittoCore.dittoffiStoreObserverFree(pointer),
    ),
    "CDitto_t *": _PointerRegistry<CPDitto>(
      (pointer) => _dittoCore.dittoFree(pointer),
    ),
    //
    // Can not be freed
    //
    "CIdentityConfig_t *": _PointerRegistry<CPIdentityConfig>(
      (pointer) => Future.value(),
    ),
  };

  int get length => _objectsByAddress.length;

  /// Get a CPPointer given a JSPointer, either by creating and tracking a new
  /// one or returning an existing one.
  _WasmPointer<T> _get(_JSPointer<T> inner) {
    final existing = _objectsByAddress.get(inner._hashCode);
    if (existing != null) {
      _registryDebugLog(
        "Already tracked ${existing._inner._debugRepresentation}",
      );
      return existing;
    }

    _registryDebugLog(
      "Now tracking ${inner._debugRepresentation}",
    );
    final pointer = _WasmPointer._fromUntrackedPointer(inner);
    _register(pointer);
    return pointer;
  }

  /// Track a CPPointer with the registry.
  bool _register(_WasmPointer<T> pointer) {
    if (_objectsByAddress.get(pointer._inner._hashCode) != null) {
      return false;
    }
    _objectsByAddress.set(pointer._inner._hashCode, pointer);
    _finalizer.attach(
      pointer,
      pointer._inner,
      detach: pointer,
    );
    return true;
  }

  /// Remove a CPPointer from the registry before it is garbage collected. This
  /// may be needed when ownership of a pointer is transferred back to Ditto
  /// core.
  // void _unregister(_WasmPointer<T> pointer) {
  //   _objectsByAddress.remove(pointer._inner._addr.toDart);
  //   this._finalizer.detach(pointer);
  // }

  Future<void> _finalize(_JSPointer<T> pointer) async {
    _registryDebugLog(
      "Releasing ${pointer._debugRepresentation}",
    );
    _objectsByAddress.remove(pointer._hashCode);
    await _release(pointer);
  }
}

/// Representation of C pointers as JavaScript objects with a `type` and `addr`
/// field. Null pointers are represented as JS `null` values.
extension type _JSPointer<T extends CPPointerTarget>._(JSObject _)
    implements JSObject {
  @JS("type")
  external JSString get _type;

  @JS("addr")
  external JSNumber get _addr;

  factory _JSPointer(JSObject _) {
    final self = _JSPointer<T>._(_);

    assert(self._type == self._type);
    assert(self._addr == self._addr);

    return self;
  }

  _WasmPointer<T> toCP() => _WasmPointer(this);

  /// Returns a unique hash code for this pointer.
  ///
  /// This is not an @override because those are not allowed in extension types.
  int get _hashCode => Object.hashAll([_type, _addr]);

  String get _debugRepresentation => "Pointer $_type $_addr";

  /// This is sometimes needed when the same underlying type has multiple names
  /// in the FFI representation (e.g. `CDitto_t` and `dittoffi_store_t`)
  _JSPointer<T> withType(String newType) {
    final dartMap = {"addr": _addr, "type": newType};
    final jsObject = dartMap.jsify()!;
    return _JSPointer(jsObject as JSObject);
  }
}

/// JS representation of fat pointer to a slice (`Box<[T]>` /
/// `slice_boxed_uint8_t`).
extension type _JSSliceBoxed(JSObject _) implements JSObject {
  // @JS("len")
  // external JSNumber get _len;

  // @JS("ptr")
  // external _JSPointer<CPPointerTarget> get _ptr;
}

extension _CPPointerExt<T extends CPPointerTarget> on CPPointer<T> {
  _JSPointer<T> asWasm() => (this as _WasmPointer<T>)._inner;
}

extension type _JSResult<T extends JSAny>._(JSObject _jsObject)
    implements JSObject {
  static const _successFieldName = "success";
  static const _errorFieldName = "error";

  // These types must be nullable here - it doesn't matter if `T` itself is
  // nullable (e.g. if `T` is `JSAny?`). If there is no `?` written on this
  // getter, then it will throw (only when compiling with `--wasm`). Probably a
  // compiler bug, don't have time to investigate
  @JS(_successFieldName)
  external T? get _success;

  @JS(_errorFieldName)
  external _JSPointer<CPError>? get _error;

  factory _JSResult(JSObject value) {
    final self = _JSResult<T>._(value);

    assert(self._success == self._success);
    assert(self._error == self._error);

    return self;
  }

  bool get isError => _error != null;

  /// Convert to a cross-platform result, retrieving error code and message if
  /// the result is an error.
  CPResult<T?> toCP() {
    if (isError) {
      final errorCode = _dittoCore.dittoffiErrorCode(_error!).toDart;
      final errorMessage = _dittoCore
          .boxCStringIntoString(_dittoCore.dittoffiErrorDescription(_error!))
          ?.toDart;

      _dittoCore.dittoffiErrorFree(_error!);
      if (errorCode == "Unknown") {
        return CPResult.legacyError(
          privateMakeDittoError(errorMessage ?? errorCode),
        );
      } else {
        return CPResult.legacyException(
          privateMakeDittoException(errorMessage ?? errorCode),
        );
      }
    }

    return CPResult.legacyOk(_success);
  }
}

extension type _ChangeHandlerWithQueryResult._(JSObject _) implements JSObject {
  @JS("query_result")
  external _JSPointer<CPQueryResult>? get _queryResult;

  factory _ChangeHandlerWithQueryResult(JSObject value) {
    final self = _ChangeHandlerWithQueryResult._(value);

    assert(self._queryResult == self._queryResult);

    return self;
  }

  CPChangeHandlerWithQueryResult? toCP() {
    if (_queryResult == null) return null;
    return CPChangeHandlerWithQueryResult(
      queryResult: _queryResult!.toCP(),
    );
  }
}

/// Logs information about pointer tracking and releasing if env var
/// `DITTO_DEBUG_REGISTRY` is set to `true`.
void _registryDebugLog(String message) {
  const shouldDebugPointerRegistry = bool.fromEnvironment(
    "DITTO_DEBUG_REGISTRY",
    // ignore: avoid_redundant_argument_values
    defaultValue: false,
  );

  if (shouldDebugPointerRegistry) {
    dittoLog(
      LogLevel.info,
      "[REGISTRY] $message",
    );
  }
}

@JS()
@staticInterop
extension type _JSAttachment._(JSObject _jsObject) implements JSObject {
  @JS("id")
  external JSUint8Array get id;

  @JS("len")
  external int get len;

  @JS("handle")
  external _JSPointer<CPAttachmentHandle> get handle;

  factory _JSAttachment(JSObject value) {
    final self = _JSAttachment._(value);

    assert(self.id == self.id);
    assert(self.len == self.len);
    assert(self.handle == self.handle);

    return self;
  }
}

@JS()
@staticInterop
extension type _JSAttachmentResult._(JSObject _jsObject) implements JSObject {
  @JS("status_code")
  external int get statusCode;

  @JS("cancel_token")
  external int get cancelToken;

  factory _JSAttachmentResult(JSObject value) {
    final self = _JSAttachmentResult._(value);

    assert(self.statusCode == self.statusCode);
    assert(self.cancelToken == self.cancelToken);

    return self;
  }
}

@JS()
@staticInterop
extension type _JSAttachmentDataResult._(JSObject _jsObject)
    implements JSObject {
  @JS("status")
  external int get statusCode;

  @JS("data")
  external _JSSliceBoxed get data;

  factory _JSAttachmentDataResult(JSObject value) {
    final self = _JSAttachmentDataResult._(value);

    assert(self.statusCode == self.statusCode);
    assert(self.data == self.data);

    return self;
  }
}

/// A non-background JS-compatible unary void callback
///
/// A `_JSVoidCallback1<Foo>` is morally equivalent to a `void Function(Foo)`.
/// This type will handle marshalling.
extension type _JSVoidCalback1<A extends JSAny>._(JSFunction _inner)
    implements JSFunction {
  _JSVoidCalback1.fromDart(void Function(A) f)
      : _inner = ((JSFunction _, A a) => f(a)).toJS;
}

class _WasmBytes implements CPBytes {
  final Uint8List _bytes;

  /// We don't strictly need this - we implement it so that [_WasmBytes] can
  /// share the same API contract as `NativeBytes`.
  var _freedEarly = false;

  _WasmBytes(this._bytes);

  @override
  Uint8List get bytes {
    if (isFreedEarly) {
      throw privateMakeDittoError(
        "attempting to access bytes that have been freed early",
      );
    }
    return _bytes;
  }

  @override
  void freeEarly() {
    _freedEarly = true;
  }

  @override
  bool get isFreedEarly => _freedEarly;
}
