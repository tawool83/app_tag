import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/qr_task.dart';
import '../../domain/usecases/clear_qr_tasks_usecase.dart';
import '../../domain/usecases/delete_qr_task_usecase.dart';
import '../../domain/usecases/list_qr_tasks_usecase.dart';
import 'qr_task_providers.dart';

/// 히스토리 화면용 QrTask 리스트.
///
/// autoDispose: 화면 재진입 시 새 인스턴스 → `_load()` 재실행으로 최신 반영.
class QrTaskListNotifier extends StateNotifier<List<QrTask>> {
  final ListQrTasksUseCase _list;
  final DeleteQrTaskUseCase _delete;
  final ClearQrTasksUseCase _clear;

  QrTaskListNotifier({
    required ListQrTasksUseCase list,
    required DeleteQrTaskUseCase delete,
    required ClearQrTasksUseCase clear,
  })  : _list = list,
        _delete = delete,
        _clear = clear,
        super(const []) {
    _load();
  }

  Future<void> _load() async {
    final result = await _list();
    state = result.fold((tasks) => tasks, (_) => const []);
  }

  Future<void> delete(String id) async {
    final result = await _delete(id);
    result.fold((_) => _load(), (_) {});
  }

  Future<void> clearAll() async {
    final result = await _clear();
    result.fold((_) => state = const [], (_) {});
  }
}

final qrTaskListNotifierProvider =
    StateNotifierProvider.autoDispose<QrTaskListNotifier, List<QrTask>>((ref) {
  return QrTaskListNotifier(
    list: ref.watch(listQrTasksUseCaseProvider),
    delete: ref.watch(deleteQrTaskUseCaseProvider),
    clear: ref.watch(clearQrTasksUseCaseProvider),
  );
});
