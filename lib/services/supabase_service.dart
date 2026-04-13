import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/constants/app_config.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  /// main.dart에서 앱 시작 시 호출.
  /// SUPABASE_URL이 비어 있으면 초기화를 건너뜁니다.
  static Future<void> initialize() async {
    if (kSupabaseUrl.isEmpty || kSupabaseAnonKey.isEmpty) return;
    await Supabase.initialize(
      url: kSupabaseUrl,
      anonKey: kSupabaseAnonKey,
    );
  }

  /// Supabase가 설정되어 있는지 여부
  static bool get isConfigured =>
      kSupabaseUrl.isNotEmpty && kSupabaseAnonKey.isNotEmpty;
}
