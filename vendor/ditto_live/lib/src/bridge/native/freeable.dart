import "dart:ffi";

import "package:ffi/ffi.dart";
import "package:meta/meta.dart";

import "../cross_platform/freeable.dart";

@internal
final class NativeCallableFreeable implements CPFreeable {
  NativeCallableFreeable(this._callable);
  final NativeCallable _callable;

  @override
  void free() => _callable.close();
}

@internal
final class NativeMallocFreeable implements CPFreeable {
  NativeMallocFreeable(this._pointer);
  final Pointer<NativeType> _pointer;

  @override
  void free() => malloc.free(_pointer.cast());
}
