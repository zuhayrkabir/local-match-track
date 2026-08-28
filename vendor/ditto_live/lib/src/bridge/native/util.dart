// ignore_for_file: ditto_missing_visibility
part of "native.dart";

String dittoFfiBase64Encode(Uint8List bytes, CPBase64PaddingMode mode) {
  final ffiMode = switch (mode) {
    CPBase64PaddingMode.padded => Base64PaddingMode.BASE64_PADDING_MODE_PADDED,
    CPBase64PaddingMode.unpadded =>
      Base64PaddingMode.BASE64_PADDING_MODE_UNPADDED,
  };
  final slice = bytesToSlice(bytes);

  final ptr = bindings.dittoffi_base64_encode(slice.ref, ffiMode);
  final string = stringFromCharStar(ptr, free: true);
  freeSliceRef(slice);
  return string;
}

CPResult<Uint8List> dittoFfiTryBase64Decode(
  String base64String,
  CPBase64PaddingMode mode,
) =>
    withStringAsPtr(base64String, (ptr) {
      final result = bindings.dittoffi_try_base64_decode(
        ptr,
        Base64PaddingMode.BASE64_PADDING_MODE_UNPADDED,
      );

      return _NativeResult(
        result,
        getSuccess: (res) => bytesFromNative(result.success, free: true),
        getError: (res) => res.error,
      );
    });

Future<String> utilsMakePersistenceDirectory(
  String path, {
  bool createIfMissing = true,
}) async {
  if (isAbsolute(path)) {
    if (createIfMissing) Directory(path).createSync(recursive: true);
    return path;
  }

  final dataDir = await getApplicationDocumentsDirectory();
  final actualDir = join(dataDir.path, path);
  if (createIfMissing) Directory(actualDir).createSync(recursive: true);
  return actualDir;
}

Future<String> utilDefaultDeviceName() async => Platform.localHostname;
