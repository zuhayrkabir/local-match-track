import "dart:ffi";

import "package:meta/meta.dart";

/// A non-null pointer to an instance of `T`
///
/// This exists for a couple of reasons:
///  - it is non-nullable - if you have a `Ptr<T>`, the address is not `0`. Null values are represented by `null` (i.e. a `Ptr<T>?`)
///  - it is `Send` (in Rust terms). Dart prevents sending `Pointer<T>` between isolates, which is why this type wraps an `int`
@internal
extension type Ptr<T extends NativeType>._(int addr) {
  static Ptr<T>? fromPointer<T extends NativeType>(Pointer<T> pointer) {
    if (pointer == nullptr) return null;
    return Ptr._(pointer.address);
  }

  static Ptr<T> nonNull<T extends NativeType>(Pointer<T> pointer) =>
      fromPointer(pointer)!;

  Ptr<S> cast<S extends NativeType>() => Ptr._(addr);

  int get address => addr;
}

@internal
extension PtrExtension<T extends NativeType> on Ptr<T>? {
  Pointer<T> get asPointer =>
      this == null ? nullptr : Pointer.fromAddress(this!.addr);
}

@internal
extension PointerExtension<T extends NativeType> on Pointer<T> {
  Ptr<T>? get asPtr => Ptr.fromPointer(this);
}

/// Apply a function to a pointer if the pointer is non-null, otherwise return Dart `null`
@internal
T? withNullablePtr<T, N extends NativeType>(
  Pointer<N> ptr,
  T Function(Pointer<N>) map,
) {
  if (ptr.address == nullptr.address) return null;
  return map(ptr);
}
