import "dart:ffi";

import "package:meta/meta.dart";

import "../../../exception.dart";

/// A wrapper for [Pointer] that ensures that the pointer is not null
@internal
class NonNull<T extends NativeType> {
  final Pointer<T> _ptr;

  NonNull._(this._ptr);

  factory NonNull(Pointer<T> ptr) {
    if (ptr.address == 0) {
      throw privateMakeDittoError();
    }

    return NonNull._(ptr);
  }

  Pointer<T> get toRaw => _ptr;
}
