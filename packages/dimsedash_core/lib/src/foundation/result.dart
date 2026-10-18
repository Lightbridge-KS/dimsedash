sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final AppFailure error;
}

enum FailureKind { validation, conflict, storage, newerSchema, alreadyOpen }

final class AppFailure {
  const AppFailure(this.kind, this.message);
  final FailureKind kind;

  /// Safe operator-facing text, never a raw OS/peer exception.
  final String message;
}
