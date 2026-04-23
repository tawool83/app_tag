import 'package:app_tag/core/error/failure.dart';
import 'package:app_tag/core/error/result.dart';
import 'package:app_tag/features/qr_task/data/datasources/qr_task_local_datasource.dart';
import 'package:app_tag/features/qr_task/data/models/qr_task_model.dart';
import 'package:app_tag/features/qr_task/data/repositories/qr_task_repository_impl.dart';
import 'package:app_tag/features/qr_task/domain/entities/qr_customization.dart';
import 'package:app_tag/features/qr_task/domain/entities/qr_task.dart';
import 'package:app_tag/features/qr_task/domain/entities/qr_task_kind.dart';
import 'package:app_tag/features/qr_task/domain/entities/qr_task_meta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class _MockDataSource extends Mock implements QrTaskLocalDataSource {}

class _FakeQrTaskModel extends Fake implements QrTaskModel {}

QrTask _entity({
  required String id,
  DateTime? createdAt,
  DateTime? updatedAt,
  QrTaskKind kind = QrTaskKind.qr,
}) =>
    QrTask(
      id: id,
      createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
      updatedAt: updatedAt ?? createdAt ?? DateTime.utc(2026, 1, 1),
      kind: kind,
      name: 'task-$id',
      meta: QrTaskMeta(appName: 'app-$id', deepLink: 'link-$id', platform: 'android'),
      customization: const QrCustomization(),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeQrTaskModel());
  });

  late _MockDataSource ds;
  late QrTaskRepositoryImpl repo;
  final fixedNow = DateTime.utc(2026, 4, 15, 12, 0);

  setUp(() {
    ds = _MockDataSource();
    repo = QrTaskRepositoryImpl(
      ds,
      uuid: const Uuid(),
      now: () => fixedNow,
    );
  });

  group('createNew', () {
    test('새 Task 생성 + put 호출 + Success 반환', () async {
      when(() => ds.put(any())).thenAnswer((_) async {});

      final result = await repo.createNew(
        kind: QrTaskKind.qr,
        meta: const QrTaskMeta(
            appName: 'A', deepLink: 'L', platform: 'android'),
      );

      expect(result.isSuccess, true);
      final task = result.valueOrNull!;
      expect(task.kind, QrTaskKind.qr);
      expect(task.createdAt, fixedNow);
      expect(task.updatedAt, fixedNow);
      verify(() => ds.put(any())).called(1);
    });

    test('DataSource throw 시 StorageFailure', () async {
      when(() => ds.put(any())).thenThrow(Exception('disk'));

      final result = await repo.createNew(
        kind: QrTaskKind.qr,
        meta: const QrTaskMeta(appName: '', deepLink: '', platform: ''),
      );

      expect(result.failureOrNull, isA<StorageFailure>());
    });
  });

  group('getById', () {
    test('존재하지 않으면 Success(null)', () async {
      when(() => ds.readById('x')).thenReturn(null);

      final result = await repo.getById('x');

      expect(result.isSuccess, true);
      expect(result.valueOrNull, isNull);
    });

    test('존재하면 toEntity 결과 반환', () async {
      final entity = _entity(id: 'x');
      when(() => ds.readById('x'))
          .thenReturn(QrTaskModel.fromEntity(entity));

      final result = await repo.getById('x');

      expect(result.valueOrNull!.id, 'x');
    });
  });

  group('listAll', () {
    test('updatedAt desc 정렬', () async {
      final older = QrTaskModel.fromEntity(_entity(
        id: 'a',
        updatedAt: DateTime.utc(2026, 1, 1),
      ));
      final newer = QrTaskModel.fromEntity(_entity(
        id: 'b',
        updatedAt: DateTime.utc(2026, 6, 1),
      ));
      when(() => ds.readAll()).thenReturn([older, newer]);

      final result = await repo.listAll();

      expect(result.valueOrNull!.map((e) => e.id).toList(), ['b', 'a']);
    });
  });

  group('updateCustomization', () {
    test('존재하지 않는 id → StorageFailure', () async {
      when(() => ds.readById('missing')).thenReturn(null);

      final result =
          await repo.updateCustomization('missing', const QrCustomization());

      expect(result.failureOrNull, isA<StorageFailure>());
    });

    test('존재하면 customization 갱신 + updatedAt = now', () async {
      final original =
          _entity(id: 'a', updatedAt: DateTime.utc(2026, 1, 1));
      when(() => ds.readById('a'))
          .thenReturn(QrTaskModel.fromEntity(original));
      when(() => ds.put(any())).thenAnswer((_) async {});

      final result = await repo.updateCustomization(
          'a', const QrCustomization(qrColorArgb: 0xFFFF00FF));

      expect(result.isSuccess, true);
      final captured = verify(() => ds.put(captureAny())).captured.single
          as QrTaskModel;
      final entity = captured.toEntity();
      expect(entity.updatedAt, fixedNow);
      expect(entity.customization.qrColorArgb, 0xFFFF00FF);
    });
  });

  group('delete / clearAll', () {
    test('delete 정상', () async {
      when(() => ds.delete('a')).thenAnswer((_) async {});

      final result = await repo.delete('a');

      expect(result.isSuccess, true);
      verify(() => ds.delete('a')).called(1);
    });

    test('clearAll 정상', () async {
      when(() => ds.clearAll()).thenAnswer((_) async {});

      final result = await repo.clearAll();

      expect(result.isSuccess, true);
      verify(() => ds.clearAll()).called(1);
    });
  });
}
