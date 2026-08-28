// ignore_for_file: ditto_missing_visibility, ditto_store_ditto_ptr

@NativeFfiLibrary()
library;

import "dart:async";
import "dart:convert";
import "dart:ffi";
import "dart:io";
import "dart:isolate";

import "package:ffi/ffi.dart";
import "package:flutter/foundation.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";

import "../../../ditto_live.dart";
import "../../analysis/annotations.dart";
import "../../exception.dart";
import "../cross_platform/connection_request_lifecycle.dart";
import "../cross_platform/constants.dart";
import "../cross_platform/error.dart";
import "../cross_platform/freeable.dart";
import "../cross_platform/types.dart";

import "ffi/bindings.dart";
import "ffi/bytes.dart";
import "ffi/error.dart";
import "ffi/func.dart";
import "ffi/generated_bindings.dart"
    hide Platform, TransportCondition, ConditionSource;
import "ffi/generated_bindings.dart" as generated_bindings;
import "ffi/manually_free.dart";
import "ffi/strings.dart";
import "freeable.dart";

part "auth.dart";
part "differ.dart";
part "error.dart";
part "identity.dart";
part "logger.dart";
part "open.dart";
part "presence.dart";
part "small_peer_info.dart";
part "store.dart";
part "sync.dart";
part "transport_conditions.dart";
part "types.dart";
part "util.dart";

Never get _$ => throw UnsupportedError("Native is currently not supported");

Future<void> init({String? wasmUrl, String? wasmShimUrl}) async {}
void dittoInitSdkVersion() {
  final platform = switch (Platform.isAndroid) {
    true => generated_bindings.Platform.PLATFORM_ANDROID,
    false => generated_bindings.Platform.PLATFORM_IOS,
  };

  withStringAsPtr(
    privateSdkVersion,
    (versionPtr) => bindings.ditto_init_sdk_version(
      platform,
      Language.LANGUAGE_FLUTTER,
      versionPtr,
    ),
  );
}

String dittoGetSdkSemver() =>
    stringFromCharStar(bindings.ditto_get_sdk_version(), free: true);
// Future<void> dittoShutdown(CPPointer<CPDitto> peer) => _$;

// === Peer Management Functions ===
String dittoSetDeviceName(CPPointer<CPDitto> ditto, String deviceName) {
  final dittoPtr = ditto.asFfi();
  final actualPtr = withStringAsPtr(
    deviceName,
    (namePtr) => bindings.ditto_set_device_name(dittoPtr.inner.cast(), namePtr),
  );

  return stringFromCharStar(actualPtr, free: true);
}

CPResult<void> dittoFfiTryVerifyLicense(
  CPPointer<CPDitto> ditto,
  String licenseKey,
) {
  final dittoPtr = ditto.asFfi();
  final result = withStringAsPtr(
    licenseKey,
    (keyPtr) =>
        bindings.dittoffi_try_verify_license(dittoPtr.inner.cast(), keyPtr),
  );

  return _NativeResult(
    result,
    getSuccess: (_) {},
    getError: (result) => result.error,
  );
}

bool dittoIsActivated(CPPointer<CPDitto> ditto) {
  final dittoPtr = ditto.asFfi();
  return bindings.dittoffi_ditto_is_activated(dittoPtr.inner.cast());
}

final _dittoFinalizer = NativeFinalizer(bindings.addresses.ditto_free.cast());

CPPointer<CPDitto> dittoMake(
  String directory,
  CPPointer<CPIdentityConfig> identity,
) {
  final identityPtr = identity.asFfi();
  final dittoPtr = withStringAsPtr(
    directory,
    (dirPtr) => bindings.ditto_make(
      dirPtr,
      identityPtr.inner.cast(),
    ),
  );

  final cpPointer = dittoPtr.toCP<CPDitto>();
  _dittoFinalizer.attach(cpPointer, dittoPtr.cast());
  return cpPointer;
}

CPResult<void> dittoSdkTransportsInit() {
  final err = malloc<Int32>()..value = 0;
  bindings.ditto_sdk_transports_init(err);
  final errValue = err.value;
  malloc.free(err);

  if (errValue != 0) {
    return CPResult.legacyError(
      privateMakeDittoError("Failed to init transports"),
    );
  }

  return CPResult.legacyOk(null);
}

CPBytes dittoFfiDittoTransportConfig(CPPointer<CPDitto> ditto) {
  final dittoPtr = ditto.asFfi();
  final result =
      bindings.dittoffi_ditto_transport_config(dittoPtr.inner.cast());
  return NativeBytes(result);
}

CPResult<void> dittoFfiDittoTrySetTransportConfig(
  CPPointer<CPDitto> ditto,
  Uint8List transportConfig,
) {
  final dittoPtr = ditto.asFfi();
  final slice = bytesToSlice(transportConfig);

  final result = bindings.dittoffi_ditto_try_set_transport_config(
    dittoPtr.inner.cast(),
    slice.ref,
    true,
  );

  freeSliceRef(slice);

  return _NativeResult(
    result,
    getSuccess: (_) {},
    getError: (result) => result.error,
  );
}

CPResult<void> dittoRunGarbageCollection(CPPointer<CPDitto> ditto) {
  final dittoPtr = ditto.asFfi();
  return switch (bindings.ditto_run_garbage_collection(dittoPtr.inner.cast())) {
    0 => CPResult.legacyOk(null),
    1 => CPResult.legacyError(privateMakeDittoError(takeErrorMessage())),
    final other => CPResult.legacyError(
        privateMakeDittoError("unknown error code: $other"),
      ),
  };
}

// === Finalizers ===
// ignore: ditto_ffi_wrapper_local_variables
void dittoCStringFree(CPPointer<CPCString> cString) => _$;
// ignore: ditto_ffi_wrapper_local_variables
void dittoDocumentFree(CPPointer<CPDocument> document) => _$;
// ignore: ditto_ffi_wrapper_local_variables
void dittoFfiErrorFree(CPPointer<CPError> error) => _$;
// ignore: ditto_ffi_wrapper_local_variables
void dittoFfiQueryResultFree(CPPointer<CPQueryResult> queryResult) => _$;
void dittoFree(CPPointer<CPDitto> pointer) {
  final ptr = pointer.asFfi();
  bindings.ditto_free(ptr.inner.cast());
}

void utilValidatePersistenceDirectory(String path) {
  Directory(path).createSync(recursive: true);
}

bool utilIsAndroid() => Platform.isAndroid;

Future<void> dittoShutdown(CPPointer<CPDitto> ditto) async {
  final ptr = ditto.asFfi();
  bindings.ditto_shutdown(ptr.inner.cast());
}

Future<String?> utilApplicationDocumentsDir() async {
  Never fail() => throw privateMakeDittoException(
        "Failed to get application documents directory",
      );

  try {
    // On linux, this sometimes fails to get the directory because it uses
    // `xdg-user-dir` rather than just reading the binaries. We'd like to fall
    // back to just reading `XDG_DOCUMENTS_DIR`
    return (await getApplicationDocumentsDirectory()).path;
  } catch (_) {
    if (Platform.isLinux || Platform.isMacOS) {
      // $XDG_DOCUMENTS_DIR is slightly meaningless on macos, but consistency
      // with linux makes some setups a bit easier in a linux/macos team
      return Platform.environment["XDG_DOCUMENTS_DIR"] ?? fail();
    }

    if (Platform.isWindows) {
      // Windows fallback for test environments where path_provider plugin
      // is not registered (TestWidgetsFlutterBinding doesn't register native plugins).
      // Use USERPROFILE\Documents or TEMP/TMP or Windows\Temp.
      final userProfile = Platform.environment["USERPROFILE"];
      if (userProfile != null) {
        return "$userProfile\\Documents";
      }
      return Platform.environment["TEMP"] ??
          Platform.environment["TMP"] ??
          r"C:\Windows\Temp";
    }

    rethrow;
  }
}

SupportedPlatform utilGetCurrentPlatform() {
  if (Platform.isAndroid) return SupportedPlatform.android;
  if (Platform.isIOS) return SupportedPlatform.ios;
  if (Platform.isMacOS) return SupportedPlatform.macos;
  if (Platform.isLinux) return SupportedPlatform.linux;
  if (Platform.isWindows) return SupportedPlatform.windows;
  throw privateMakeDittoError("Unsupported Platform");
}

Future<void> utilFileCopy(String source, String destination) =>
    File(source).copy(destination);

CPResult<Uint8List> dittoffiCborRoundTrip(String type, Uint8List bytes) =>
    withStringAsPtr(type, (typePtr) {
      final slice = bytesToSlice(bytes);
      final result = bindings.dittoffi_cbor_round_trip(typePtr, slice.ref);
      freeSliceRef(slice);
      return _NativeResult(
        result,
        getSuccess: (result) => bytesFromNative(result.success, free: true),
        getError: (result) => result.error,
      );
    });

Uint8List dittoffiTransportConfigNew() {
  final slice = bindings.dittoffi_transport_config_new();
  return bytesFromNative(slice, free: true);
}
