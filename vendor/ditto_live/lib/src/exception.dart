import "package:meta/meta.dart";

import "analysis/annotations.dart";
import "bridge/bridge.dart" as core;

@external
final class DittoException implements Exception {
  final String? _message;
  DittoException._(this._message);

  @override
  String toString() => "DittoException(${_message ?? ''})";
}

@external
final class DittoClosedException extends DittoException {
  DittoClosedException()
      : super._("This ditto instance is closed, so all operations are invalid");
}

@external
DittoException privateMakeDittoException([String? message]) =>
    DittoException._(message);

@external
final class DittoError extends Error {
  final String? _message;
  final StackTrace _trace;
  DittoError._(this._message, this._trace);

  @override
  String toString() => "DittoError(${_message ?? ''})";

  @visibleForTesting
  StackTrace get trace => _trace;
}

@internal
DittoError privateMakeDittoError([
  String? message,
  StackTrace? trace,
]) =>
    DittoError._(message, trace ?? StackTrace.current);

@internal
Never throwFfi(core.CPFfiError error) => switch (error.code.shouldBeError) {
      true => throw privateMakeDittoError(error.description),
      false => throw privateMakeDittoException(error.description),
    };
