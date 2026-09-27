import "package:meta/meta.dart";

import "ditto.dart";

import "bridge/bridge.dart" as core;

@internal
class PrivateSyncController {
  final Ditto _ditto;
  PrivateSyncController(this._ditto);

  bool get syncing => core.dittoFfiDittoIsSyncActive(_ditto.ptr);

  void start() => core.dittoFfiDittoTryStartSync(_ditto.ptr).extract();

  void stop() => core.dittoFfiDittoStopSync(_ditto.ptr);
}
