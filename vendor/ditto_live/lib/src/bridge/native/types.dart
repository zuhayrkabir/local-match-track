// ignore_for_file: ditto_missing_visibility
part of "native.dart";

// temporarily make this public to allow interop between old-style and new-style APIs
typedef FfiPtr<T extends CPPointerTarget> = _FfiPtr<T>;

class _FfiPtr<T extends CPPointerTarget> implements CPPointer<T>, Finalizable {
  final Pointer<Void> inner;
  _FfiPtr(this.inner);

  CPPointer<S> cast<S extends CPPointerTarget>() => _FfiPtr(inner);

  @override
  int get address => inner.address;
}

extension _PointerExt<T extends NativeType> on Pointer<T> {
  _FfiPtr<S> toCP<S extends CPPointerTarget>() => _FfiPtr(cast());
}

extension _CPPointerExt<T extends CPPointerTarget> on CPPointer<T> {
  _FfiPtr<T> asFfi() => this as _FfiPtr<T>;
}
