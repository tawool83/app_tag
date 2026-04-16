import '../../../../core/error/result.dart';
import '../entities/qr_customization.dart';
import '../entities/qr_task.dart';
import '../entities/qr_task_kind.dart';
import '../entities/qr_task_meta.dart';

/// QrTask 저장소 추상 인터페이스 (Domain).
///
/// 구현체: `data/repositories/qr_task_repository_impl.dart`
abstract class QrTaskRepository {
  /// 신규 QrTask 발급 + 저장. 기본 customization 으로 초기화.
  Future<Result<QrTask>> createNew({
    required QrTaskKind kind,
    required QrTaskMeta meta,
  });

  /// id 로 단건 조회. 없으면 Success(null).
  Future<Result<QrTask?>> getById(String id);

  /// 전체 목록 (updatedAt desc 정렬).
  Future<Result<List<QrTask>>> listAll();

  /// 꾸미기만 갱신 (updatedAt 자동 갱신).
  Future<Result<void>> updateCustomization(String id, QrCustomization c);

  /// 메타만 갱신 (updatedAt 자동 갱신).
  Future<Result<void>> updateMeta(String id, QrTaskMeta meta);

  Future<Result<void>> delete(String id);
  Future<Result<void>> clearAll();
}
