class DeepLinkConstants {
  DeepLinkConstants._();

  /// Android: Play Store 앱 페이지 링크
  /// 앱이 설치돼 있으면 Play Store에서 열기, 미설치 시 설치 페이지 이동
  static String androidIntentLink(String packageName) =>
      'https://play.google.com/store/apps/details?id=$packageName';

  /// iOS: Shortcuts URL 스킴 (한글/공백 URL 인코딩 포함)
  static String iosShortcutLink(String shortcutName) =>
      'shortcuts://run-shortcut?name=${Uri.encodeFull(shortcutName)}';
}
