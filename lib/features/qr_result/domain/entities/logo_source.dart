import 'dart:typed_data';

import 'sticker_config.dart' show StickerText;

/// 로고 소스 타입.
/// StickerConfig.logoType 필드에 저장되어 렌더링 분기를 결정한다.
///
/// - none:  로고 표시 안 함 (기존 Switch 토글 OFF 대체)
/// - logo:  번들 SVG 아이콘 라이브러리 (카테고리별)
/// - image: 사용자가 갤러리에서 선택 후 정사각 크롭한 이미지
/// - text:  사용자가 입력한 짧은 문구 (색상/폰트/크기 포함)
///
/// 주의: Hive 는 `name`(String) 로 저장되므로 enum 순서 변경 금지.
/// `none` 은 반드시 첫 번째 (index 0) 에 위치 — UI 드롭다운 상단에 노출.
enum LogoType { none, logo, image, text }

/// 로고 소스의 3가지 변종을 나타내는 sealed class.
///
/// UI 의 드롭다운 선택을 도메인 타입으로 승격시켜 패턴 매칭 + null 방어.
sealed class LogoSource {
  const LogoSource();

  LogoType get type;
}

/// 로고 라이브러리 (번들 SVG) 에서 선택한 아이콘.
class LogoSourceLibrary extends LogoSource {
  /// "social/twitter" 형식 composite id.
  final String assetId;

  /// "social"
  final String category;

  /// "twitter"
  final String iconId;

  const LogoSourceLibrary({
    required this.assetId,
    required this.category,
    required this.iconId,
  });

  @override
  LogoType get type => LogoType.logo;
}

/// 사용자가 갤러리에서 선택하고 정사각으로 크롭한 이미지.
/// 256x256 JPEG Q85 로 재인코딩된 bytes.
class LogoSourceImage extends LogoSource {
  final Uint8List croppedBytes;

  const LogoSourceImage(this.croppedBytes);

  @override
  LogoType get type => LogoType.image;
}

/// 사용자가 입력한 로고 전용 텍스트.
class LogoSourceText extends LogoSource {
  final StickerText text;

  const LogoSourceText(this.text);

  @override
  LogoType get type => LogoType.text;
}
