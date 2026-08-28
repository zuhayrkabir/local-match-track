import "../ditto_live.dart";
import "analysis/annotations.dart";

/// An enum covering platforms supported by the Ditto Flutter SDK
///
/// You can use [Ditto.currentPlatform] to detect the current platform.
@external
@DartSpecific(
  "Dart benefits from a cross-platform way to detect the current platform "
  "without importing platform-specific libraries",
)
enum SupportedPlatform {
  android,
  ios,
  linux,
  macos,
  web,
  windows,
  ;

  /// Whether this platform is a mobile platform
  bool get isMobile =>
      this == SupportedPlatform.android || this == SupportedPlatform.ios;
}
