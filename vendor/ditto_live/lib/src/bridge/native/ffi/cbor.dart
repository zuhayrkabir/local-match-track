import "dart:typed_data";

import "package:cbor/simple.dart";
import "package:meta/meta.dart";

@internal
Uint8List toCborBytes(dynamic object) => Uint8List.fromList(
      cbor.encode(object),
    );

@internal
dynamic fromCborBytes(Uint8List bytes) => cbor.decode(bytes.toList());
