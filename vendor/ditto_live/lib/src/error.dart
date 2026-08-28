import "package:meta/meta.dart";

import "analysis/annotations.dart";

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
