import 'dart:typed_data';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../models/qr_template.dart';
import '../../domain/repositories/default_template_repository.dart';
import '../datasources/default_template_datasource.dart';

class DefaultTemplateRepositoryImpl implements DefaultTemplateRepository {
  final DefaultTemplateDataSource _dataSource;
  const DefaultTemplateRepositoryImpl(this._dataSource);

  @override
  Future<Result<QrTemplateManifest>> getTemplates() async {
    try {
      final local = await _dataSource.getLocal();
      // 백그라운드 동기화 (fire-and-forget)
      _syncRemote(local);
      return Success(local);
    } catch (e, st) {
      return Err(UnexpectedFailure('기본 템플릿 로드 실패: $e',
          cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<Uint8List?>> loadImageBytes(String url) async {
    try {
      final bytes = await _dataSource.loadImageBytes(url);
      return Success(bytes);
    } catch (e, st) {
      return Err(UnexpectedFailure('이미지 로드 실패: $e', cause: e, stackTrace: st));
    }
  }

  // ── private ────────────────────────────────────────────────────────────────

  Future<void> _syncRemote(QrTemplateManifest local) async {
    try {
      final cacheTs = await _dataSource.getCacheTimestamp();
      final remote = await _dataSource.fetchRemote(cacheTs);
      if (remote != null) {
        await _dataSource.saveCache(remote);
      }
    } catch (_) {
      // 동기화 실패는 무시
    }
  }
}
