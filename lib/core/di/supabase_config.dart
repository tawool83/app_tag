import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_config.dart';

/// Supabase 초기화. SUPABASE_URL/ANON_KEY 가 비어있으면 no-op.
Future<void> initSupabase() async {
  if (kSupabaseUrl.isEmpty || kSupabaseAnonKey.isEmpty) return;
  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey: kSupabaseAnonKey,
  );
}

/// Supabase 가 dart-define 으로 구성되었는지 여부.
bool get isSupabaseConfigured =>
    kSupabaseUrl.isNotEmpty && kSupabaseAnonKey.isNotEmpty;
