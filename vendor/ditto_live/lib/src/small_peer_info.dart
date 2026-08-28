import "dart:convert";

import "package:meta/meta.dart";

import "analysis/annotations.dart";
import "ditto.dart";

import "bridge/bridge.dart" as core;

@internal
SmallPeerInfo makeSpi(Ditto ditto) => SmallPeerInfo._(ditto);

/// An object that provides access to Ditto's small peer info APIs.
///
/// An instance of [SmallPeerInfo] can be obtained from [Ditto.smallPeerInfo]:
/// ```dart
/// final ditto = await Ditto.open(/* ... */);
/// final smallPeerInfo = ditto.smallPeerInfo;
/// ```
/// This class is not user-constructible.
@external
final class SmallPeerInfo {
  final Ditto _ditto;

  SmallPeerInfo._(this._ditto);

  bool get isEnabled => core.dittoSmallPeerInfoGetIsEnabled(_ditto.ptr);

  set isEnabled(bool value) =>
      core.dittoFfiSmallPeerInfoSetEnabled(_ditto.ptr, isEnabled: value);

  Map<String, dynamic> get metadata =>
      jsonDecode(metadataJsonString) as Map<String, dynamic>;

  set metadata(Map<String, dynamic> value) =>
      metadataJsonString = jsonEncode(value);

  String get metadataJsonString =>
      core.dittoFfiSmallPeerInfoGetMetadata(_ditto.ptr);

  set metadataJsonString(String value) =>
      core.dittoSmallPeerInfoSetMetadata(_ditto.ptr, value).extract();
}
