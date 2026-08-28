import "dart:ffi";

import "package:ffi/ffi.dart";
import "package:meta/meta.dart";

import "../../../exception.dart";
import "bindings.dart";
import "box.dart";
import "generated_bindings.dart";
import "ptr.dart";
import "strings.dart";

// currently, in the interest of compatibility, this type isn't publicly exposed until we can get a stable error API
@internal
class FfiError extends Box<dittoffi_error> {
  FfiError._(super._ptr);

  String get description => bindings
      .dittoffi_error_description(ptr.asPointer)
      .cast<Utf8>()
      .toDartString();

  int get code => bindings.dittoffi_error_code1(ptr.asPointer);

  @override
  String toString() => "FfiError(code: $code, description: $description)";
}

// This temporarily returns `DittoError` so it can be compatible
@internal
DittoError? privateMakeNullableFfiError(Ptr<dittoffi_error>? ptr) {
  if (ptr == null) return null;
  final ffiError = FfiError._(ptr);
  return privateMakeDittoError(ffiError.toString());
}

@internal
DittoError privateMakeFfiError(Pointer<dittoffi_error> ptr) {
  return privateMakeNullableFfiError(Ptr.fromPointer(ptr))!;
}

@internal
String? takeErrorMessage() =>
    nullableStringFromCharStar(bindings.ditto_error_message());
