// 앱 전역 설정 상수

/// Supabase 프로젝트 URL / anon key (dart-define으로 주입)
const String kSupabaseUrl =
    String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const String kSupabaseAnonKey =
    String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

/// QR 코드 데이터 최대 길이 (raw 문자열 기준)
const int kQrMaxLength = 150;

/// 현재 앱이 렌더링 가능한 최대 템플릿 엔진 버전.
const int kTemplateEngineVersion = 1;

/// 원격 템플릿 캐시 유효 시간 (Supabase diff 동기화로 명시적 제어)
const Duration kTemplateCacheTtl = Duration(hours: 24);

/// QR 데이터 유효성 검사. 초과 시 에러 메시지, 유효하면 null.
String? validateQrData(String data) {
  if (data.length > kQrMaxLength) {
    return 'QR 코드 최대 $kQrMaxLength자를 초과했습니다 (현재 ${data.length}자).';
  }
  return null;
}
