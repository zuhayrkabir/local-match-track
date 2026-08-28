/// This file just contains a bunch of private extension types that are used to
/// test our lints
///
/// If an `expect_lint` comment is found, but the suggested lint *isn't*
/// triggered, it will itself trigger a lint.

// ignore_for_file: unused_element

library;

import "dart:js_interop";

// expect_lint: ditto_js_extension_type_check
extension type _MissingConstructor(JSObject _) implements JSObject {
  @JS("prop")
  external JSString get prop;
}

extension type _MissingJSAnnotation._(JSObject _) implements JSObject {
  // expect_lint: ditto_js_extension_type_external_member_js_annotation
  external JSString get prop;

  // expect_lint: ditto_js_extension_type_external_member_js_annotation
  external JSString function();

  factory _MissingJSAnnotation(JSObject value) {
    final self = _MissingJSAnnotation._(value);

    assert(self.prop == self.prop);

    return self;
  }
}

extension type _FieldNotGetter._(JSObject _) implements JSObject {
  // expect_lint: ditto_js_extension_type_getters
  @JS("field")
  external final JSString field;

  factory _FieldNotGetter(JSObject value) {
    final self = _FieldNotGetter._(value);

    assert(self.field == self.field);

    return self;
  }
}

extension type _AccidentalRecursion._(JSObject _) implements JSObject {
  factory _AccidentalRecursion(JSObject value) {
    // expect_lint: ditto_js_extension_type_recursive_factory
    final self = _AccidentalRecursion(value);

    return self;
  }
}
