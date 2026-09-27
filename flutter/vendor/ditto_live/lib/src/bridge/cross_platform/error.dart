import "package:meta/meta.dart";

import "../../exception.dart";
import "../bridge.dart";

@internal
final class CPFfiError {
  final CPPointer<CPError> _ptr;

  CPFfiError(this._ptr);

  CPErrorCode get code => dittoffiErrorCode(_ptr);
  String get description => dittoffiErrorDescription(_ptr);
}

@internal
abstract class CPResult<T> {
  /// Basically `unwrap()` except with a different name to avoid the negative
  /// connotations associated with unwrap (since they are not applicable in
  /// dart)
  T extract() {
    final e = error;
    if (e != null) throwFfi(e);
    return successUnchecked;
  }

  // we can't use a `T?` to indicate "not successful" here because `null` is
  // often an acceptable value for `T`
  /// @nodoc
  @protected
  T get successUnchecked;

  /// @nodoc
  @protected
  CPFfiError? get error;

  /// An ok result from an FFI representation that isn't backed by a pointer to
  /// an error
  static CPResult<S> legacyOk<S>(S value) => LegacyCPResultOk(value);

  /// An error result from an FFI representation that isn't backed by a pointer to
  /// an error
  static CPResult<S> legacyError<S>(DittoError error) =>
      LegacyCPResultError(error);

  /// An exception result from an FFI representation that isn't backed by a pointer to
  /// an error
  static CPResult<S> legacyException<S>(DittoException ex) =>
      LegacyCPResultException(ex);

  CPResult<S> map<S>(S Function(T) f) => _MappedCPResult(this, f);
}

@internal
extension CPResultExtension<T> on Future<CPResult<T>> {
  Future<T> extract() async => (await this).extract();
}

/// A [CPResult] that isn't backed by a pointer to an error (and so cannot use
/// `_JSResult` or `_NativeResult`)
@internal
sealed class LegacyCPResult<T> implements CPResult<T> {
  const LegacyCPResult();

  @override
  T extract() => switch (this) {
        LegacyCPResultOk(:final value) => value,
        LegacyCPResultException(:final exception) => throw exception,
        LegacyCPResultError(:final err) => throw err,
      };

  @override
  T get successUnchecked =>
      throw privateMakeDittoError("invalid use of @protected member");

  @override
  CPFfiError? get error =>
      throw privateMakeDittoError("invalid use of @protected member");

  @override
  CPResult<S> map<S>(S Function(T) f) => _MappedCPResult(this, f);
}

@internal
final class LegacyCPResultOk<T> extends LegacyCPResult<T> {
  final T value;
  const LegacyCPResultOk(this.value);
}

@internal
final class LegacyCPResultException extends LegacyCPResult<Never> {
  final DittoException exception;
  const LegacyCPResultException(this.exception);
}

@internal
final class LegacyCPResultError extends LegacyCPResult<Never> {
  final DittoError err;
  const LegacyCPResultError(this.err);
}

final class _MappedCPResult<T, S> implements CPResult<T> {
  final CPResult<S> _inner;
  final T Function(S) _map;

  _MappedCPResult(this._inner, this._map);

  @override
  T extract() => _map(_inner.extract());

  @override
  T get successUnchecked =>
      throw privateMakeDittoError("invalid use of @protected member");

  @override
  CPFfiError? get error =>
      throw privateMakeDittoError("invalid use of @protected member");

  @override
  CPResult<X> map<X>(X Function(T) f) => _MappedCPResult(this, f);
}
