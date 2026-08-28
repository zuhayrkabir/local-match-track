import "package:cbor/simple.dart";
import "package:meta/meta.dart";

import "../exception.dart";

@internal
dynamic decodeTrivialCbor(List<int> bytes) {
  final decoded = cbor.decode(bytes);
  return _fix(decoded);
}

dynamic _fix(dynamic decoded) => switch (decoded) {
      null || bool _ || int _ || double _ || String _ => decoded,
      final List<dynamic> list => list.map(_fix).toList(),
      final Map<dynamic, dynamic> map =>
        map.map((key, value) => MapEntry(key! as String, _fix(value))),
      _ => throw privateMakeDittoError("invalid CBOR"),
    };
