import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_config.dart';

bool _supabaseInitialized = false;

/// Supabase 초기화. SUPABASE_URL/ANON_KEY 가 비어있으면 no-op.
Future<void> initSupabase() async {
  if (kSupabaseUrl.isEmpty || kSupabaseAnonKey.isEmpty) return;
  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey: kSupabaseAnonKey,
  );
  _supabaseInitialized = true;
}

/// Supabase 가 실제로 초기화 완료되었는지 여부.
bool get isSupabaseConfigured => _supabaseInitialized;
