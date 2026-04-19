import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProfileDataSource {
  final SupabaseClient _client;
  const SupabaseProfileDataSource(this._client);

  Future<Map<String, dynamic>> getProfile(String userId) async {
    final response =
        await _client.from('profiles').select().eq('id', userId).single();
    return response;
  }

  Future<void> updateProfile(String userId,
      {String? nickname, String? avatarUrl}) async {
    final data = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (nickname != null) data['nickname'] = nickname;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    await _client.from('profiles').update(data).eq('id', userId);
  }
}
