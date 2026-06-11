/// Result type for operations that can fail in expected ways
/// (printer offline, payment declined, sync unreachable).
///
/// Drivers return `Result` instead of throwing, so callers are forced
/// by the type system to handle the failure path.
sealed class Result<T, E> {
  const Result();

  R when<R>(
      {required R Function(T value) ok, required R Function(E error) err}) {
    final self = this;
    return switch (self) {
      Ok<T, E>(:final value) => ok(value),
      Err<T, E>(:final error) => err(error),
    };
  }

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  /// The success value, or null if this is an error.
  T? get valueOrNull => switch (this) {
        Ok<T, E>(:final value) => value,
        Err<T, E>() => null,
      };

  /// The error, or null if this is a success.
  E? get errorOrNull => switch (this) {
        Ok<T, E>() => null,
        Err<T, E>(:final error) => error,
      };
}

final class Ok<T, E> extends Result<T, E> {
  final T value;
  const Ok(this.value);

  @override
  String toString() => 'Ok($value)';
}

final class Err<T, E> extends Result<T, E> {
  final E error;
  const Err(this.error);

  @override
  String toString() => 'Err($error)';
}
