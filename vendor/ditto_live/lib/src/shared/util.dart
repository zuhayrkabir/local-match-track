import "package:meta/meta.dart";

import "../exception.dart";

@internal
String convertKey(Object? object) {
  if (object is String) return object;
  throw privateMakeDittoError(
    "Map contained non-string key: ${object.runtimeType} - $object",
  );
}

// Recursively converts all Map<Object?, Object?> to Map<String, dynamic>,
// the latter being accepted by `json_serializable`.
@internal
Map<String, dynamic> convertMap(Map<Object?, Object?> map) =>
    map.map((key, value) {
      final newKey = convertKey(key);
      final newValue = value is Map ? convertMap(value) : value;
      return MapEntry(newKey, newValue);
    });
