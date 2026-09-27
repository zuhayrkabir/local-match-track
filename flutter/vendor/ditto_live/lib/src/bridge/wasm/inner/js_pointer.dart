import "dart:js_interop";

import "package:meta/meta.dart";

import "../../bridge.dart";

/// Representation of C pointers as JavaScript objects with a `type` and `addr`
/// field. Null pointers are represented as JS `null` values.
@internal
extension type JSPointer<T extends CPPointerTarget>._(JSObject _)
    implements JSObject {
  @JS("type")
  external JSString get type;

  @JS("addr")
  external JSAny get _addr;

  factory JSPointer(JSObject value) {
    final self = JSPointer<T>._(value);

    assert(self.type == self.type);
    assert(self._addr == self._addr);

    return self;
  }

  /// Returns a unique hash code for this pointer.
  ///
  /// This is not an @override because those are not allowed in extension types.
  int get hashCode_ => Object.hashAll([type, _addr]);

  String get debugRepresentation => "Pointer $type $_addr";
}
