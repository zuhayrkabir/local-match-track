import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "analysis/annotations.dart";
import "supported_platform.dart";
import "bridge/bridge.dart" as core;

/// A utility class for identifying and requesting missing platform permissions.
///
/// On Android, this class helps identify which permissions are required for Ditto sync
/// and which ones are missing or not granted. On iOS and other platforms, all methods
/// return empty lists since permissions are handled differently.
///
/// ## Usage
///
/// ```dart
/// final permissions = DittoSyncPermissions();
///
/// // Get all required permissions for the current Android version
/// final required = await permissions.requiredPermissions();
///
/// // Check which permissions are missing
/// final missing = await permissions.missingPermissions();
///
/// if (missing.isNotEmpty) {
///   // Request permissions using permission_handler or similar package
///   // For example:
///   // await [
///   //   Permission.bluetoothConnect,
///   //   Permission.bluetoothScan,
///   //   // ... etc
///   // ].request();
/// }
/// ```
@external
final class DittoSyncPermissions {
  /// Creates a new permissions handler using the current runtime platform.
  DittoSyncPermissions() : _platformOverride = null;

  /// Creates a permissions handler with an explicit platform override.
  ///
  /// Intended for tests so the Android MethodChannel code path can be
  /// exercised on a Linux/macOS CI host.
  @visibleForTesting
  DittoSyncPermissions.forPlatform(SupportedPlatform platform)
      : _platformOverride = platform;

  /// Name of the platform method channel registered by the Kotlin
  /// `DittoPlugin`.
  ///
  /// Intentionally NOT annotated `@visibleForTesting`: production code in
  /// `transports.dart` also imports this constant (for `setAndroidContext`),
  /// so the annotation would make the analyzer flag legitimate production
  /// call sites. The two method-name constants below keep
  /// `@visibleForTesting` because only tests reference them by name —
  /// production calls them via `_channel.invokeMethod(...)`.
  ///
  /// Renaming this in production source must break compile at every Dart
  /// call site, not just at runtime on Android.
  static const String channelName = "ditto_plugin";

  /// Method name invoked to query the required-permissions list. The Kotlin
  /// side handles this method on the [channelName] channel.
  @visibleForTesting
  static const String getRequiredPermissionsMethod = "getRequiredPermissions";

  /// Method name invoked to query the missing-permissions list. The Kotlin
  /// side handles this method on the [channelName] channel.
  @visibleForTesting
  static const String getMissingPermissionsMethod = "getMissingPermissions";

  static const MethodChannel _channel = MethodChannel(channelName);

  final SupportedPlatform? _platformOverride;

  SupportedPlatform get _platform =>
      _platformOverride ?? core.utilGetCurrentPlatform();

  /// Returns a list of all required permissions for Ditto sync on the current platform.
  ///
  /// On Android, the returned list is the de-duplicated union of permissions
  /// required by four permission groups, each sensitive to the runtime API
  /// level and the app's manifest:
  ///
  /// **Bluetooth LE client (scanning):**
  /// - Android 12+ (API 31+): `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN`, plus
  ///   `ACCESS_FINE_LOCATION` unless the app asserts `neverForLocation` on
  ///   `BLUETOOTH_SCAN` in the manifest.
  /// - Android 10-11 (API 29-30): `ACCESS_FINE_LOCATION`.
  /// - Android 9 and below (API ≤ 28): `ACCESS_COARSE_LOCATION`.
  ///
  /// **Bluetooth LE server (advertising):**
  /// - Android 12+ (API 31+): `BLUETOOTH_ADVERTISE`, `BLUETOOTH_CONNECT`.
  /// - Android 11 and below (API ≤ 30): `BLUETOOTH`, `BLUETOOTH_ADMIN`.
  ///
  /// **Wi-Fi Aware (all API levels):**
  /// - Always: `INTERNET`, `ACCESS_NETWORK_STATE`, `CHANGE_NETWORK_STATE`,
  ///   `ACCESS_WIFI_STATE`, `CHANGE_WIFI_STATE`.
  /// - Android 13+ (API 33+): additionally `NEARBY_WIFI_DEVICES`, plus
  ///   `ACCESS_FINE_LOCATION` unless the app asserts `neverForLocation` on
  ///   `NEARBY_WIFI_DEVICES` in the manifest.
  /// - Android 12 and below (API ≤ 32): additionally `ACCESS_FINE_LOCATION`.
  ///
  /// **Reliable UDP multicast:**
  /// - Always: `CHANGE_WIFI_MULTICAST_STATE`.
  /// - Android 17+ (API 37+) when the app targets API 37 or newer:
  ///   additionally `ACCESS_LOCAL_NETWORK`.
  ///
  /// **Foreground service:**
  /// - Android 13+ (API 33+), only when a Ditto foreground service class is
  ///   present in the app: `POST_NOTIFICATIONS`.
  ///
  /// On iOS, web, and other platforms, this returns an empty list — those
  /// platforms grant permissions via `Info.plist` prompts or have no
  /// analogous concept.
  ///
  /// The canonical list is computed by the Kotlin
  /// `com.ditto.internal.transports.DittoSyncPermissions.requiredPermissions()`;
  /// this method delegates to it across the platform channel.
  Future<List<String>> requiredPermissions() async {
    if (_platform != SupportedPlatform.android) {
      return [];
    }

    try {
      final result = await _channel
          .invokeMethod<List<Object?>>(getRequiredPermissionsMethod);
      if (result == null) return [];
      return result.cast<String>();
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Error getting required permissions: ${e.message}");
      }
      return [];
    }
  }

  /// Calculates the list of missing permissions.
  ///
  /// If [permissions] is provided, checks only those specific permissions.
  /// Otherwise, checks all required permissions (same as [requiredPermissions]).
  ///
  /// A permission is considered "missing" if either:
  /// - It is not granted by the user, OR
  /// - It is not declared in the app's AndroidManifest.xml
  ///
  /// The returned list can be passed to permission request APIs like
  /// `permission_handler` or `ActivityCompat.requestPermissions()`.
  ///
  /// On iOS, web, and other platforms, this returns an empty list.
  Future<List<String>> missingPermissions([List<String>? permissions]) async {
    if (_platform != SupportedPlatform.android) {
      return [];
    }

    try {
      final args = permissions != null
          ? {"permissions": permissions}
          : <String, dynamic>{};
      final result = await _channel.invokeMethod<List<Object?>>(
        getMissingPermissionsMethod,
        args,
      );
      if (result == null) return [];
      return result.cast<String>();
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Error getting missing permissions: ${e.message}");
      }
      return [];
    }
  }
}
