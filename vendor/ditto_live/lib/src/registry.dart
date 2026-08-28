import "dart:collection";

import "package:meta/meta.dart";

import "../ditto_live.dart";

/// A registry of Ditto instances, mainly used by the devtools extension
@internal
final class Registry {
  static final instance = Registry._();
  Registry._();

  /// A monotonically increasing key
  var _nextKey = 0;
  final _allDittos = <int, Ditto>{};
  late final _removeFromMapFinalizer = Finalizer(_allDittos.remove);

  int registerDitto(Ditto ditto) {
    _removeFromMapFinalizer.attach(ditto, _nextKey);
    _allDittos[_nextKey] = ditto;
    // god please don't make me remember postfix vs. prefix increment at 2:00 AM
    // ignore: join_return_with_assignment
    _nextKey++;
    return _nextKey;
  }

  Map<int, Ditto> get allDittos => UnmodifiableMapView(_allDittos);
}
