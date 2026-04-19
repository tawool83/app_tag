import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../qr_result/data/datasources/user_template_local_datasource.dart';
import '../../../qr_result/data/models/user_qr_template_model.dart';
import '../datasources/supabase_template_datasource.dart';

/// 동기화 결과.
class SyncResult {
  final int pulled;
  final int pushed;
  final int deleted;
  final int conflicts;
  final List<String> errors;

  const SyncResult({
    this.pulled = 0,
    this.pushed = 0,
    this.deleted = 0,
    this.conflicts = 0,
    this.errors = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
}

/// Offline-First 양방향 동기화 엔진 (Last-Write-Wins).
class TemplateSyncEngine {
  final UserTemplateLocalDataSource _local;
  final SupabaseTemplateDataSource _remote;

  static const _lastSyncKey = 'last_sync_templates';

  const TemplateSyncEngine(this._local, this._remote);

  Future<SyncResult> sync(String userId) async {
    int pulled = 0, pushed = 0, deleted = 0, conflicts = 0;
    final errors = <String>[];

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_lastSyncKey);
      final lastSync = lastSyncStr != null
          ? DateTime.parse(lastSyncStr)
          : DateTime.fromMillisecondsSinceEpoch(0);

      // ── Step 1: Pull (서버 → 로컬) ──
      final remoteRecords = lastSyncStr == null
          ? await _remote.fetchAll(userId)
          : await _remote.fetchUpdatedSince(userId, lastSync);

      for (final remote in remoteRecords) {
        final localId = remote['local_id'] as String;
        final deletedAt = remote['deleted_at'];

        if (deletedAt != null) {
          // 서버에서 삭제된 항목 → 로컬도 삭제
          final existing = _local.readById(localId);
          if (existing != null) {
            await _local.delete(localId);
            deleted++;
          }
          continue;
        }

        final remoteUpdated = DateTime.parse(remote['updated_at'] as String);
        final existing = _local.readById(localId);

        if (existing == null) {
          // 로컬에 없음 → 삽입
          final model = _remoteToModel(remote);
          await _local.write(model);
          pulled++;
        } else {
          final localUpdated = existing.updatedAt ?? existing.createdAt;
          if (remoteUpdated.isAfter(localUpdated)) {
            // 서버가 더 최신 → 로컬 덮어쓰기
            final model = _remoteToModel(remote);
            await _local.write(model);
            pulled++;
            conflicts++;
          }
          // else: 로컬이 더 최신 → push에서 처리
        }
      }

      // ── Step 2: Push (로컬 → 서버) ──
      final allLocal = _local.readAll();
      for (final local in allLocal) {
        if (!local.syncedToCloud) {
          try {
            final data = _modelToRemote(local);
            final result = await _remote.upsert(userId, data);
            // remoteId 및 syncedToCloud 업데이트
            local.remoteId = result['id'] as String?;
            local.syncedToCloud = true;
            await _local.write(local);
            pushed++;
          } catch (e) {
            errors.add('Push failed for ${local.id}: $e');
          }
        }
      }

      // ── Step 3: lastSyncedAt 갱신 ──
      await prefs.setString(
          _lastSyncKey, DateTime.now().toUtc().toIso8601String());
    } catch (e) {
      errors.add('Sync error: $e');
    }

    return SyncResult(
      pulled: pulled,
      pushed: pushed,
      deleted: deleted,
      conflicts: conflicts,
      errors: errors,
    );
  }

  /// 단일 템플릿 즉시 push.
  Future<void> pushSingle(String userId, UserQrTemplateModel model) async {
    try {
      final data = _modelToRemote(model);
      final result = await _remote.upsert(userId, data);
      model.remoteId = result['id'] as String?;
      model.syncedToCloud = true;
      model.updatedAt = DateTime.now().toUtc();
      await _local.write(model);
    } catch (_) {
      // best-effort — 다음 full sync에서 재시도
    }
  }

  // ── 변환 헬퍼 ──────────────────────────────────────────────────────────

  Map<String, dynamic> _modelToRemote(UserQrTemplateModel m) {
    final templateData = <String, dynamic>{
      'qrColorValue': m.qrColorValue,
      'gradientJson': m.gradientJson,
      'roundFactor': m.roundFactor,
      'dotStyleIndex': m.dotStyleIndex,
      'eyeOuterIndex': m.eyeOuterIndex,
      'eyeInnerIndex': m.eyeInnerIndex,
      'eyeStyleIndex': m.eyeStyleIndex,
      'randomEyeSeed': m.randomEyeSeed,
      'quietZoneColorValue': m.quietZoneColorValue,
      'logoPositionIndex': m.logoPositionIndex,
      'logoBackgroundIndex': m.logoBackgroundIndex,
      'topTextContent': m.topTextContent,
      'topTextColorValue': m.topTextColorValue,
      'topTextFont': m.topTextFont,
      'topTextSize': m.topTextSize,
      'bottomTextContent': m.bottomTextContent,
      'bottomTextColorValue': m.bottomTextColorValue,
      'bottomTextFont': m.bottomTextFont,
      'bottomTextSize': m.bottomTextSize,
      'backgroundScale': m.backgroundScale,
      'backgroundAlignX': m.backgroundAlignX,
      'backgroundAlignY': m.backgroundAlignY,
    };

    String? thumbnailBase64;
    if (m.thumbnailBytes != null) {
      thumbnailBase64 = base64Encode(m.thumbnailBytes!);
    }

    return {
      'local_id': m.id,
      'name': m.name,
      'template_data': templateData,
      'thumbnail_base64': thumbnailBase64,
      'created_at': m.createdAt.toUtc().toIso8601String(),
    };
  }

  UserQrTemplateModel _remoteToModel(Map<String, dynamic> remote) {
    final data = remote['template_data'] as Map<String, dynamic>? ?? {};
    final thumbB64 = remote['thumbnail_base64'] as String?;

    return UserQrTemplateModel(
      id: remote['local_id'] as String,
      name: remote['name'] as String? ?? '',
      createdAt: DateTime.parse(remote['created_at'] as String),
      updatedAt: DateTime.parse(remote['updated_at'] as String),
      qrColorValue: (data['qrColorValue'] as num?)?.toInt() ?? 0xFF000000,
      gradientJson: data['gradientJson'] as String?,
      roundFactor: (data['roundFactor'] as num?)?.toDouble() ?? 0.0,
      dotStyleIndex: (data['dotStyleIndex'] as num?)?.toInt() ?? 0,
      eyeOuterIndex: (data['eyeOuterIndex'] as num?)?.toInt() ?? 0,
      eyeInnerIndex: (data['eyeInnerIndex'] as num?)?.toInt() ?? 0,
      eyeStyleIndex: (data['eyeStyleIndex'] as num?)?.toInt() ?? 0,
      randomEyeSeed: (data['randomEyeSeed'] as num?)?.toInt(),
      quietZoneColorValue:
          (data['quietZoneColorValue'] as num?)?.toInt() ?? 0xFFFFFFFF,
      logoPositionIndex: (data['logoPositionIndex'] as num?)?.toInt() ?? 0,
      logoBackgroundIndex: (data['logoBackgroundIndex'] as num?)?.toInt() ?? 0,
      topTextContent: data['topTextContent'] as String?,
      topTextColorValue: (data['topTextColorValue'] as num?)?.toInt(),
      topTextFont: data['topTextFont'] as String?,
      topTextSize: (data['topTextSize'] as num?)?.toDouble(),
      bottomTextContent: data['bottomTextContent'] as String?,
      bottomTextColorValue: (data['bottomTextColorValue'] as num?)?.toInt(),
      bottomTextFont: data['bottomTextFont'] as String?,
      bottomTextSize: (data['bottomTextSize'] as num?)?.toDouble(),
      backgroundScale:
          (data['backgroundScale'] as num?)?.toDouble() ?? 1.0,
      backgroundAlignX:
          (data['backgroundAlignX'] as num?)?.toDouble() ?? 0.0,
      backgroundAlignY:
          (data['backgroundAlignY'] as num?)?.toDouble() ?? 0.0,
      thumbnailBytes: thumbB64 != null ? base64Decode(thumbB64) : null,
      remoteId: remote['id'] as String?,
      syncedToCloud: true,
    );
  }
}
