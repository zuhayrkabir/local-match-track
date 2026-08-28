import "dart:ffi";
import "dart:typed_data";

import "package:convert/convert.dart";
import "package:meta/meta.dart";

import "bindings.dart";
import "bytes.dart";
import "generated_bindings.dart";
import "manually_free.dart";
import "ptr.dart";
import "package:ffi/ffi.dart";

@internal
final class StringFromCharStarError extends Error {
  final Pointer<Char> pointer;
  final String hexBytes;
  final int length;
  final Object originalError;

  StringFromCharStarError._({
    required this.pointer,
    required this.hexBytes,
    required this.length,
    required this.originalError,
  });

  @override
  String toString() => """
Error creating `String` from `char *`:
  pointer: ${pointer.address},
  hexBytes: $hexBytes,
  length: $length,
  original error: $originalError,
""";
}

@internal
String stringFromCharStar(
  Pointer<Char> ptr, {
  required bool free,
}) {
  try {
    final string = ptr.cast<Utf8>().toDartString();
    if (free) bindings.ditto_c_string_free(ptr);
    return string;
  } catch (e) {
    final codeUnits = ptr.cast<Uint8>();

    var length = 0;
    while (codeUnits[length] != 0) {
      length++;
    }

    final bytes = codeUnits.asTypedList(length);
    final hexBytes = hex.encode(bytes);

    throw StringFromCharStarError._(
      pointer: ptr,
      hexBytes: hexBytes,
      length: length,
      originalError: e,
    );
  }
}

@internal
String? nullableStringFromCharStar(Pointer<Char> ptr) => withNullablePtr(
      ptr,
      (ptr) => stringFromCharStar(ptr, free: true),
    );

/// A helper to run a callback with a pointer to a dart string, freeing the string when the closure finishes
@internal
T withStringAsPtr<T>(
  String? s,
  T Function(Pointer<Char> ptr) function,
) =>
    withStringsAsPtrs(
      [s],
      (ptrs) {
        final [ptr] = ptrs;
        return function(ptr.cast());
      },
    );

/// A helper to run a callback with a list of pointers to dart strings, freeing the strings when the closure finishes
@internal
T withStringsAsPtrs<T>(
  List<String?> strings,
  T Function(List<Pointer<Utf8>> ptrs) function,
) {
  final pointers = strings.map((s) => s?.toNativeUtf8() ?? nullptr).toList();
  final t = function(pointers);
  pointers.forEach(malloc.free);
  return t;
}

@internal
String stringFromSliceUint8(slice_ref_uint8 slice) =>
    slice.ptr.cast<Utf8>().toDartString(length: slice.len);

@internal
String stringFromUtf8Bytes(Pointer<Uint8> ptr, int len) =>
    ptr.cast<Utf8>().toDartString(length: len);

/// Like [withStringAsPtr] but specialized for query/args pairs
@internal
T withQueryAndArgs<T>(
  T Function(Pointer<Char>, slice_ref_uint8) f, {
  required String query,
  required Uint8List argsCbor,
}) =>
    withStringAsPtr(
      query,
      (queryPtr) {
        final cborSlice = bytesToSlice(argsCbor);
        final result = f(queryPtr, cborSlice.ref);
        freeSliceRef(cborSlice);
        return result;
      },
    );
