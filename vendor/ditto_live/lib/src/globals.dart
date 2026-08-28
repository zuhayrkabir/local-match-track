import "package:meta/meta.dart";

import "../ditto_live.dart";
import "bridge/bridge.dart" as core;
import "exception.dart";

/// Global state needed by the ditto constructor. The state requires an async
/// call, which we perform in [Ditto.init]
@internal
final class Globals {
  static Globals? _instance;
  static Globals get instance {
    final g = _instance;

    if (g == null) {
      // error not exception becuase there should be an earlier check that
      // throws exception
      throw privateMakeDittoError("`Globals.load()` has not been called");
    }

    return g;
  }

  final String deviceName;
  final String? documentsDirectory;

  Globals._({
    required this.deviceName,
    required this.documentsDirectory,
  });

  static Future<void> load() async {
    if (_instance != null) {
      throw privateMakeDittoError("Called `Globals.load()` twice");
    }
    _instance = Globals._(
      deviceName: await core.utilDefaultDeviceName(),
      documentsDirectory: await core.utilApplicationDocumentsDir(),
    );
  }
}
