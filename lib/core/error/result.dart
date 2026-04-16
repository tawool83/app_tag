import 'failure.dart';

/// 성공/실패 2-state sealed union. Repository/UseCase 반환 타입.
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}

extension ResultExt<T> on Result<T> {
  /// 성공/실패 분기 매핑.
  R fold<R>(R Function(T value) onSuccess, R Function(Failure failure) onErr) =>
      switch (this) {
        Success<T>(:final value) => onSuccess(value),
        Err<T>(:final failure) => onErr(failure),
      };

  /// 성공 값 변환. 실패는 그대로 전파.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success<T>(:final value) => Success<R>(transform(value)),
        Err<T>(:final failure) => Err<R>(failure),
      };

  /// 성공일 때 다음 Result 로 연결. 실패는 그대로 전파.
  Result<R> flatMap<R>(Result<R> Function(T value) next) => switch (this) {
        Success<T>(:final value) => next(value),
        Err<T>(:final failure) => Err<R>(failure),
      };

  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Err<T>() => null,
      };

  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Err<T>(:final failure) => failure,
      };

  bool get isSuccess => this is Success<T>;
  bool get isErr => this is Err<T>;
}
