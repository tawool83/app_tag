import 'package:uuid/uuid.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/qr_customization.dart';
import '../../domain/entities/qr_task.dart';
import '../../domain/entities/qr_task_kind.dart';
import '../../domain/entities/qr_task_meta.dart';
import '../../domain/repositories/qr_task_repository.dart';
import '../datasources/qr_task_local_datasource.dart';
import '../models/qr_task_model.dart';

class QrTaskRepositoryImpl implements QrTaskRepository {
  final QrTaskLocalDataSource _local;
  final Uuid _uuid;

  /// 테스트에서 결정적 시간을 주입할 수 있도록 분리.
  final DateTime Function() _now;

  QrTaskRepositoryImpl(
    this._local, {
    Uuid? uuid,
    DateTime Function()? now,
  })  : _uuid = uuid ?? const Uuid(),
        _now = now ?? DateTime.now;

  @override
  Future<Result<QrTask>> createNew({
    required QrTaskKind kind,
    required QrTaskMeta meta,
  }) async {
    try {
      final now = _now();
      final task = QrTask(
        id: _uuid.v4(),
        createdAt: now,
        updatedAt: now,
        kind: kind,
        meta: meta,
        customization: const QrCustomization(),
      );
      await _local.put(QrTaskModel.fromEntity(task));
      return Success(task);
    } catch (e) {
      return Err(StorageFailure('QrTask 생성 실패: $e'));
    }
  }

  @override
  Future<Result<QrTask?>> getById(String id) async {
    try {
      final model = _local.readById(id);
      return Success(model?.toEntity());
    } catch (e, st) {
      return Err(UnexpectedFailure('QrTask 조회 실패: $e',
          cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<List<QrTask>>> listAll() async {
    try {
      final entities = _local.readAll().map((m) => m.toEntity()).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Success(entities);
    } catch (e, st) {
      return Err(UnexpectedFailure('QrTask 목록 조회 실패: $e',
          cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<void>> updateCustomization(
      String id, QrCustomization c) async {
    try {
      final existing = _local.readById(id);
      if (existing == null) {
        return Err(StorageFailure('QrTask 미존재: $id'));
      }
      final entity = existing.toEntity();
      final updated = entity.copyWith(updatedAt: _now(), customization: c);
      await _local.put(QrTaskModel.fromEntity(updated));
      return const Success(null);
    } catch (e) {
      return Err(StorageFailure('QrTask customization 갱신 실패: $e'));
    }
  }

  @override
  Future<Result<void>> updateMeta(String id, QrTaskMeta meta) async {
    try {
      final existing = _local.readById(id);
      if (existing == null) {
        return Err(StorageFailure('QrTask 미존재: $id'));
      }
      final entity = existing.toEntity();
      final updated = entity.copyWith(updatedAt: _now(), meta: meta);
      await _local.put(QrTaskModel.fromEntity(updated));
      return const Success(null);
    } catch (e) {
      return Err(StorageFailure('QrTask meta 갱신 실패: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _local.delete(id);
      return const Success(null);
    } catch (e) {
      return Err(StorageFailure('QrTask 삭제 실패: $e'));
    }
  }

  @override
  Future<Result<void>> clearAll() async {
    try {
      await _local.clearAll();
      return const Success(null);
    } catch (e) {
      return Err(StorageFailure('QrTask 전체 삭제 실패: $e'));
    }
  }
}
