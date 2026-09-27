import "dart:ffi";

import "package:meta/meta.dart";

import "../../../exception.dart";
import "../../bridge.dart";
import "../native.dart";
import "bindings.dart";
import "generated_bindings.dart";
import "ptr.dart";

/// A pointer which frees the underlying resource when it "goes out of scope"
///
/// Basically Rust's `Box` type (except with runtime type checking due to limitations in the Dart type system)
@internal
abstract class Box<T extends NativeType> implements Finalizable {
  final Ptr<T> _ptr;

  Box(this._ptr) {
    final finalizer = _finalizer<T>();
    finalizer?.attach(this, _ptr.asPointer.cast());
  }
}

NativeFinalizer? _finalizer<T extends NativeType>() {
  // tried to construct a Box<$T>, but no finalizer for $T exists,
  final finalizer = _finalizers[T] ?? (throw privateMakeDittoError());

  if (finalizer is NativeFinalizer) return finalizer;
  if (finalizer is _NoDestructor) return null;

  // Invalid finalizer type: ${finalizer.runtimeType}
  throw privateMakeDittoError();
}

// small helper to fix formatting
NativeFinalizer _f<T extends NativeType>(Pointer<T> ptr) =>
    NativeFinalizer(ptr.cast());

final _finalizers = {
  CDitto: _f(bindings.addresses.ditto_free),
  dittoffi_query_result: _f(bindings.addresses.dittoffi_query_result_free),
  dittoffi_error: _f(bindings.addresses.dittoffi_error_free),
  CReadTransaction: _f(bindings.addresses.ditto_read_transaction_free),
  CWriteTransaction: _f(bindings.addresses.ditto_write_transaction_free),
  CIdentityConfig: _NoDestructor(),
  CDocument: _f(bindings.addresses.ditto_document_free),
  CLoginProvider: _f(bindings.addresses.ditto_auth_login_provider_free),
  AttachmentHandle: _f(bindings.addresses.ditto_free_attachment_handle),
};

class _NoDestructor {}

/// Even though `Box` is private to this library, it is part of many public types' inheritance hierarchy, so we still need to use the private extension trick
@internal
extension PrivateBoxExtension<T extends NativeType> on Box<T> {
  Ptr<T> get ptr => _ptr;

  CPPointer<S> asCP<S extends CPPointerTarget>() =>
      FfiPtr(ptr.asPointer.cast());
}
