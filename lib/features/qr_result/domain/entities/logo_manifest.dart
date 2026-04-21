/// 로고 라이브러리 manifest — assets/logos/manifest.json 의 도메인 표현.
class LogoManifest {
  final List<LogoCategory> categories;

  const LogoManifest(this.categories);

  static const empty = LogoManifest([]);

  LogoCategory? findCategory(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Composite id ("social/twitter") 로 아이콘 탐색.
  LogoAsset? findByCompositeId(String compositeId) {
    final parts = compositeId.split('/');
    if (parts.length != 2) return null;
    final cat = findCategory(parts[0]);
    if (cat == null) return null;
    for (final a in cat.icons) {
      if (a.id == parts[1]) return a;
    }
    return null;
  }
}

class LogoCategory {
  /// "social"
  final String id;

  /// 한국어 표시명 — i18n은 UI 레이어에서 별도 처리(카테고리 id → ARB 키)
  final String nameKo;

  final List<LogoAsset> icons;

  const LogoCategory({
    required this.id,
    required this.nameKo,
    required this.icons,
  });
}

class LogoAsset {
  /// "twitter"
  final String id;

  /// "assets/logos/social/twitter.svg"
  final String assetPath;

  const LogoAsset({
    required this.id,
    required this.assetPath,
  });

  /// Composite id for category id prefix.
  String compositeId(String categoryId) => '$categoryId/$id';
}
