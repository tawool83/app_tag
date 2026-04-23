import 'dart:typed_data';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../repositories/qr_task_repository.dart';

class UpdateQrTaskThumbnailUseCase {
  final QrTaskRepository _repository;
  const UpdateQrTaskThumbnailUseCase(this._repository);

  Future<Result<void>> call(String taskId, Uint8List thumbnailBytes) async {
    final result = await _repository.getById(taskId);
    final task = result.valueOrNull;
    if (task == null) return Err(StorageFailure('QrTask 미존재: $taskId'));
    final updated = task.copyWith(
      thumbnailBytes: thumbnailBytes,
      updatedAt: DateTime.now(),
    );
    return _repository.update(updated);
  }
}
