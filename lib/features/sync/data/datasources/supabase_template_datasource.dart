import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseTemplateDataSource {
  final SupabaseClient _client;
  const SupabaseTemplateDataSource(this._client);

  static const _table = 'user_templates';

  /// 서버에서 사용자의 모든 템플릿 조회 (soft-delete 포함).
  Future<List<Map<String, dynamic>>> fetchAll(String userId) async {
    final response =
        await _client.from(_table).select().eq('user_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  /// updated_at > since 인 템플릿만 조회 (delta sync).
  Future<List<Map<String, dynamic>>> fetchUpdatedSince(
      String userId, DateTime since) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .gt('updated_at', since.toUtc().toIso8601String());
    return List<Map<String, dynamic>>.from(response);
  }

  /// 단일 템플릿 upsert (local_id 기준).
  Future<Map<String, dynamic>> upsert(
      String userId, Map<String, dynamic> data) async {
    final payload = {
      ...data,
      'user_id': userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final response = await _client
        .from(_table)
        .upsert(payload, onConflict: 'user_id,local_id')
        .select()
        .single();
    return response;
  }

  /// soft delete (deleted_at 설정).
  Future<void> softDelete(String userId, String localId) async {
    await _client.from(_table).update({
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    }).match({'user_id': userId, 'local_id': localId});
  }
}
