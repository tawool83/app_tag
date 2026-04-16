import '../../../../core/error/result.dart';
import '../entities/qr_customization.dart';
import '../repositories/qr_task_repository.dart';

/// 꾸미기 상태만 갱신 (debounced autosave 에서 호출).
class UpdateQrTaskCustomizationUseCase {
  final QrTaskRepository _repository;
  const UpdateQrTaskCustomizationUseCase(this._repository);

  Future<Result<void>> call(String id, QrCustomization customization) =>
      _repository.updateCustomization(id, customization);
}
