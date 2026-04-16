/// 도메인 실패 타입. Repository 는 exception 을 throw 하지 않고
/// [Result] (성공=[Success], 실패=[Err]) 로 변환해서 반환한다.
sealed class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType($message)';
}

/// 로컬 저장소(Hive, SharedPreferences 등) 실패.
class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

/// 네트워크/원격 서비스(HTTP, Supabase 등) 실패.
class NetworkFailure extends Failure {
  final int? statusCode;
  const NetworkFailure(super.message, {this.statusCode});
}

/// 플랫폼 채널(NFC, 카메라, 위치 등) 실패.
class PlatformFailure extends Failure {
  const PlatformFailure(super.message);
}

/// 입력 검증 실패. fields 는 필드명 → 에러 메시지.
class ValidationFailure extends Failure {
  final Map<String, String> fields;
  const ValidationFailure(super.message, {this.fields = const {}});
}

/// 예기치 못한 실패. 가능하면 구체 타입으로 대체.
class UnexpectedFailure extends Failure {
  final Object? cause;
  final StackTrace? stackTrace;
  const UnexpectedFailure(super.message, {this.cause, this.stackTrace});
}
