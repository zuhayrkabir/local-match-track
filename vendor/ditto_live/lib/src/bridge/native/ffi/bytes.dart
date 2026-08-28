import "dart:ffi";
import "dart:typed_data";

import "package:ffi/ffi.dart";
import "package:meta/meta.dart";

import "../../../error.dart";
import "../../cross_platform/types.dart";
import "bindings.dart";
import "generated_bindings.dart";
import "manually_free.dart";

/// memcpy the bytes in a [Uint8List] into [dest]
///
/// UB if [dest] points to an allocation that's too short
@internal
void memcpyDartToNative(Pointer<Uint8> dest, Uint8List src) {
  dest.asTypedList(src.lengthInBytes).setRange(0, src.lengthInBytes, src);
}

@ManuallyFree(free: freeSliceRef)
@internal
Pointer<slice_ref_uint8> bytesToSlice(Uint8List bytes) {
  final ptr = malloc<Uint8>(bytes.length);
  memcpyDartToNative(ptr, bytes);

  final slice = malloc<slice_ref_uint8>();
  slice.ref.ptr = ptr;
  slice.ref.len = bytes.length;

  return slice;
}

// This function is very performance-sensitive. Before editing, dump it into
// godbolt.org to make sure nothing funky is happening with the generated
// assembly. Seemingly small changes can have dramatic (10x) perf impacts.
//
// Notably, we can get significant performance gains by copying 64-bit
// integers, rather than going through the default `Uint8List`.
//
// All benchmarking was done on my x86_64 pc on Dart 3.7. Results are likely
// different on mobile/ARM. We'll very likely eventually want platform-specific
// implementations of this. In the future, (native assets) we'll be able to
// call `Uint8List.address` and call our own (leaf) FFI function which calls an
// optimized memcpy from Rust.
//
// This code is not platform-specific *from a correctness point-of-view*, but
// platform-specific implementations may be valuable from a performance
// perspective.
//
// Adding `@pragma("vm:unsafe:no-bounds-checks")` makes this loop ~20% slower
// in my testing...
@internal
Uint8List bytesFromNative(slice_boxed_uint8 bytes, {required bool free}) {
  final paddingBytesRequired = bytes.len % 8;
  final lengthInFullU64s = bytes.len ~/ 8;

  final buffer = ByteData(bytes.len);
  final srcPtrU64 = bytes.ptr.cast<Uint64>();

  for (var i = 0; i < lengthInFullU64s; i++) {
    final temp = srcPtrU64[i];
    buffer.setUint64(i * 8, temp, Endian.host);
  }

  // now we may have padding bytes
  for (var i = bytes.len - paddingBytesRequired; i < bytes.len; i++) {
    buffer.setUint8(i, bytes.ptr[i]);
  }

  if (free) bindings.ditto_c_bytes_free(bytes);

  return Uint8List.view(buffer.buffer, 0, bytes.len);
}

@internal
extension BytesStringExtension on String {
  Uint8List toUtf8Bytes() => Uint8List.fromList(codeUnits);
}

/// A Dart handle into bytes owned by Rust
///
/// These bytes are `'static` in the Rust sense - in other words, they are
/// "fully owned" and do not have any lifetimes that would prematurely
/// invalidate this object.
///
/// This means that, as long as you have a reference to a [NativeBytes], it
/// is safe to access.
@internal
final class NativeBytes implements Finalizable, CPBytes {
  static final _finalizer = NativeFinalizer(
    bindings.addresses.dittoffi_bytes_double_boxed_byte_slice_free.cast(),
  );

  /// A pointer to a pointer/len pair
  final Pointer<slice_boxed_uint8> _inner;

  /// We can't update this during finalization, but that doesn't matter,
  /// because finalization only happens when the object is GC-ed, so the state
  /// of variables is irrelevant.
  bool _freedEarly = false;

  NativeBytes(slice_boxed_uint8 slice)
      : _inner = bindings.dittoffi_bytes_double_box_byte_slice(slice) {
    // use the thin pointer as the finalization token, since we use the
    // double-boxed free function.
    _finalizer.attach(this, _inner.cast(), detach: this);
  }

  @override
  bool get isFreedEarly => _freedEarly;

  @override
  void freeEarly() {
    _freedEarly = true;
    _finalizer.detach(this);
    bindings.dittoffi_bytes_double_boxed_byte_slice_free(_inner);
  }

  /// Get a borrowed view of the bytes owned by this [NativeBytes]. Note that
  /// the lifetime of these bytes depends on the lifetime of the [NativeBytes]
  /// from which it was derived. If this were a Rust function, the type
  /// signature (with elided lifetimes included for clarity) would be:
  /// ```rust
  /// fn bytes<'a>(&'a self) -> &'a [u8] { /* ... */ }
  /// ```
  ///
  /// If [freeEarly] has been called, this will throw.
  ///
  /// Put another way, the following is UB:
  /// ```dart
  /// final nativeBytes = NativeBytes(slice);
  /// final bytes = nativeBytes.bytes;
  /// nativeBytes.freeEarly();
  /// print(bytes[0]);
  /// ```
  /// However, the following *is* guaranteed to be safe (due to the semantics
  /// of [Finalizable]):
  /// ```dart
  /// final nativeBytes = NativeBytes(slice);
  /// final bytes = nativeBytes.bytes;
  /// print(bytes[0]);
  /// // nativeBytes never used again
  /// ```
  /// This requires that the [NativeBytes] local variable remain in *lexical
  /// scope* while `bytes` is used. A class member is **not sufficient**.
  @override
  Uint8List get bytes {
    if (_freedEarly) {
      throw privateMakeDittoError(
        "Attempting to deref a `NativeBytes` instance that has been "
        "pre-emptively freed",
      );
    }
    return _inner.ref.ptr.asTypedList(_inner.ref.len);
  }
}
