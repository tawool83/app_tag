/// 앱 전역 설정 상수
///
/// CDN URL 변경(v2 Supabase 마이그레이션 등)은 이 파일만 수정하면 됩니다.

/// CDN 기본 URL
const String kTemplateCdnBaseUrl = 'https://apptagcdn.pages.dev/app-config/v1';

/// QR 템플릿 JSON URL
const String kQrTemplatesUrl = '$kTemplateCdnBaseUrl/qr-templates.json';

/// 현재 앱이 렌더링 가능한 최대 템플릿 엔진 버전.
/// 새 스타일 기능(v2: 프레임/배경, v3: 애니메이션) 추가 시 앱 업데이트와 함께 증가.
const int kTemplateEngineVersion = 1;

/// 원격 템플릿 캐시 유효 시간
const Duration kTemplateCacheTtl = Duration(hours: 1);
