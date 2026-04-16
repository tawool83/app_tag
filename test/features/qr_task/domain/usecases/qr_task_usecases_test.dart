import 'package:app_tag/core/error/result.dart';
import 'package:app_tag/features/qr_task/domain/entities/qr_customization.dart';
import 'package:app_tag/features/qr_task/domain/entities/qr_task.dart';
import 'package:app_tag/features/qr_task/domain/entities/qr_task_kind.dart';
import 'package:app_tag/features/qr_task/domain/entities/qr_task_meta.dart';
import 'package:app_tag/features/qr_task/domain/repositories/qr_task_repository.dart';
import 'package:app_tag/features/qr_task/domain/usecases/clear_qr_tasks_usecase.dart';
import 'package:app_tag/features/qr_task/domain/usecases/create_qr_task_usecase.dart';
import 'package:app_tag/features/qr_task/domain/usecases/delete_qr_task_usecase.dart';
import 'package:app_tag/features/qr_task/domain/usecases/get_qr_task_by_id_usecase.dart';
import 'package:app_tag/features/qr_task/domain/usecases/list_qr_tasks_usecase.dart';
import 'package:app_tag/features/qr_task/domain/usecases/update_qr_task_customization_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements QrTaskRepository {}

class _FakeMeta extends Fake implements QrTaskMeta {}

class _FakeCustomization extends Fake implements QrCustomization {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeMeta());
    registerFallbackValue(_FakeCustomization());
    registerFallbackValue(QrTaskKind.qr);
  });

  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  test('CreateQrTaskUseCase → repo.createNew 위임', () async {
    final task = QrTask(
      id: 'a',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      kind: QrTaskKind.qr,
      meta: const QrTaskMeta(appName: '', deepLink: '', platform: ''),
      customization: const QrCustomization(),
    );
    when(() => repo.createNew(kind: any(named: 'kind'), meta: any(named: 'meta')))
        .thenAnswer((_) async => Success(task));

    final result = await CreateQrTaskUseCase(repo)(
      kind: QrTaskKind.qr,
      meta: const QrTaskMeta(appName: '', deepLink: '', platform: ''),
    );

    expect(result.valueOrNull, task);
  });

  test('GetQrTaskByIdUseCase → repo.getById 위임', () async {
    when(() => repo.getById('x'))
        .thenAnswer((_) async => const Success(null));
    final r = await GetQrTaskByIdUseCase(repo)('x');
    expect(r.isSuccess, true);
  });

  test('ListQrTasksUseCase → repo.listAll 위임', () async {
    when(() => repo.listAll())
        .thenAnswer((_) async => const Success([]));
    final r = await ListQrTasksUseCase(repo)();
    expect(r.valueOrNull, isEmpty);
  });

  test('UpdateQrTaskCustomizationUseCase → repo.updateCustomization', () async {
    when(() => repo.updateCustomization(any(), any()))
        .thenAnswer((_) async => const Success(null));
    final r = await UpdateQrTaskCustomizationUseCase(repo)(
        'a', const QrCustomization());
    expect(r.isSuccess, true);
    verify(() => repo.updateCustomization('a', any())).called(1);
  });

  test('DeleteQrTaskUseCase → repo.delete', () async {
    when(() => repo.delete('a'))
        .thenAnswer((_) async => const Success(null));
    final r = await DeleteQrTaskUseCase(repo)('a');
    expect(r.isSuccess, true);
  });

  test('ClearQrTasksUseCase → repo.clearAll', () async {
    when(() => repo.clearAll())
        .thenAnswer((_) async => const Success(null));
    final r = await ClearQrTasksUseCase(repo)();
    expect(r.isSuccess, true);
  });
}
