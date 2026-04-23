/// 법적 문서·정책 외부 URL 상수.
///
/// 호스팅 위치: GitHub Pages (placeholder — 실제 도메인 결정 시 이 파일만 수정).
/// 모든 앱 내 정책 링크는 이 상수를 참조하여 일관성 유지.
class LegalUrls {
  LegalUrls._();

  /// 개인정보처리방침. 양대 스토어 Console 에서도 동일 URL 사용.
  static const privacyPolicy =
      'https://tawool83.github.io/apptag-legal/privacy-policy.html';

  /// 이용약관.
  static const termsOfService =
      'https://tawool83.github.io/apptag-legal/terms.html';

  /// 계정 삭제 안내 — Google Play 2024 필수 외부 URL.
  /// 앱 미설치 상태에서도 접근 가능해야 함.
  static const accountDeletion =
      'https://tawool83.github.io/apptag-legal/account-deletion.html';

  /// 지원·문의 채널. mailto: 스킴 사용.
  static const support = 'mailto:tawooltag@gmail.com';
}
