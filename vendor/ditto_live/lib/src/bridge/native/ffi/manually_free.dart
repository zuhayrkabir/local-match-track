import "dart:ffi";

import "package:ffi/ffi.dart";
import "package:meta/meta.dart";

import "generated_bindings.dart";

/// Annotation to indicate that a function returns an object that must be manually freed
@internal
class ManuallyFree<T extends NativeType> {
  final void Function(Pointer<T>)? free;
  const ManuallyFree({this.free});
}

@internal
void freeSliceRef(Pointer<slice_ref_uint8> slice) {
  malloc
    ..free(slice.ref.ptr)
    ..free(slice);
}
