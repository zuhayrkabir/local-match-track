import "dart:io" as io;
import "dart:ffi";

import "generated_bindings.dart";

DynamicLibrary get _dylib {
  if (io.Platform.isMacOS || io.Platform.isIOS) {
    final path = io.Platform.environment["LIBDITTOFFI_PATH"];
    if (path != null) return DynamicLibrary.open(path);
    return DynamicLibrary.executable();
  } else if (io.Platform.isAndroid) {
    return DynamicLibrary.open("libdittoffi.so");
  } else if (io.Platform.isLinux) {
    final path =
        io.Platform.environment["LIBDITTOFFI_PATH"] ?? "libdittoffi.so";
    return DynamicLibrary.open(path);
  } else if (io.Platform.isWindows) {
    final path = io.Platform.environment["LIBDITTOFFI_PATH"] ?? "dittoffi.dll";
    return DynamicLibrary.open(path);
  } else {
    throw UnsupportedError("Unknown platform: ${io.Platform.operatingSystem}");
  }
}

final bindings = DittoBindings(_dylib);
