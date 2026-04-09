class DeepLinkConstants {
  DeepLinkConstants._();

  /// Android: package: 딥링크
  static String androidPackageLink(String packageName) =>
      'package:$packageName';

  /// iOS: Shortcuts URL 스킴 (한글/공백 URL 인코딩 포함)
  static String iosShortcutLink(String shortcutName) =>
      'shortcuts://run-shortcut?name=${Uri.encodeFull(shortcutName)}';
}
