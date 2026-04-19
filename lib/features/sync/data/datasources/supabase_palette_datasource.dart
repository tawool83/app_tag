import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePaletteDataSource {
  final SupabaseClient _client;
  const SupabasePaletteDataSource(this._client);

  static const _table = 'user_color_palettes';

  Future<List<Map<String, dynamic>>> fetchAll(String userId) async {
    final response =
        await _client.from(_table).select().eq('user_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchUpdatedSince(
      String userId, DateTime since) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .gt('updated_at', since.toUtc().toIso8601String());
    return List<Map<String, dynamic>>.from(response);
  }

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

  Future<void> softDelete(String userId, String localId) async {
    await _client.from(_table).update({
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    }).match({'user_id': userId, 'local_id': localId});
  }
}
