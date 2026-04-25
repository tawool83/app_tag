// 앱 전역 설정 상수

/// Supabase 프로젝트 URL / anon key (dart-define으로 주입)
const String kSupabaseUrl =
    String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const String kSupabaseAnonKey =
    String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

/// QR 코드 데이터 최대 길이 — 문자 유형별 (QR Version 40 기준)
const int kQrMaxNumeric = 7089;
const int kQrMaxAlphanumeric = 4296;
const int kQrMaxMultibyte = 1817; // 한글·한자 등 멀티바이트

/// 원격 템플릿 캐시 유효 시간 (Supabase diff 동기화로 명시적 제어)
const Duration kTemplateCacheTtl = Duration(hours: 24);

/// QR 데이터 유효성 검사. 문자 유형별 제한 적용.
/// 초과 시 에러 메시지, 유효하면 null.
String? validateQrData(String data) {
  final limit = _qrCharLimit(data);
  if (data.length > limit) {
    return 'QR 코드 최대 $limit자를 초과했습니다 (현재 ${data.length}자).';
  }
  return null;
}

/// 데이터 내용에 따라 적절한 글자 수 제한을 반환.
int _qrCharLimit(String data) {
  // 멀티바이트 문자(한글·한자 등)가 하나라도 있으면 Kanji 모드 제한
  if (data.runes.any((r) => r > 0x7F)) return kQrMaxMultibyte;
  // 숫자만으로 구성
  if (RegExp(r'^[0-9]+$').hasMatch(data)) return kQrMaxNumeric;
  // 그 외 영숫자·ASCII
  return kQrMaxAlphanumeric;
}
