import 'dart:typed_data';
import 'dart:ui' show Color;

import 'logo_source.dart' show LogoType;

const _stickerSentinel = Object();

enum LogoPosition { center, bottomRight }

/// 로고 배경 도형.
/// - none: 배경 없음
/// - square: 정사각 (이미지/로고 타입 권장)
/// - circle: 원형 (이미지/로고 타입 권장)
/// - rectangle: 직사각형 — 콘텐츠(특히 텍스트) 가로 폭에 맞춤
/// - roundedRectangle: 직사각형 + 모서리 라운드
///
/// ※ Hive 에는 index(int) 로 저장되므로 새 값은 반드시 enum **끝**에 추가.
enum LogoBackground { none, square, circle, rectangle, roundedRectangle }

/// 스티커 텍스트 (상단 또는 하단 또는 로고 텍스트).
class StickerText {
  final String content;
  final Color color;
  final String fontFamily; // 'sans-serif' | 'serif' | 'monospace'
  final double fontSize;   // 10 ~ 64

  const StickerText({
    required this.content,
    this.color = const Color(0xFF000000),
    this.fontFamily = 'sans-serif',
    this.fontSize = 14,
  });

  bool get isEmpty => content.trim().isEmpty;

  StickerText copyWith({
    String? content,
    Color? color,
    String? fontFamily,
    double? fontSize,
  }) =>
      StickerText(
        content: content ?? this.content,
        color: color ?? this.color,
        fontFamily: fontFamily ?? this.fontFamily,
        fontSize: fontSize ?? this.fontSize,
      );
}

/// QR 스티커 레이어 설정 (최상단 레이어).
/// 로고 위치/배경 + 상/하단 텍스트 + 로고 타입(logo/image/text) 을 관리.
///
/// 로고 타입 필드(logoType, logoAssetId, logoImageBytes, logoText,
/// logoAssetPngBytes, logoBackgroundColor) 는 모두 nullable 이며,
/// logoType == null 인 경우 기존 렌더링 경로(templateCenterIconBytes >
/// emojiIconBytes > defaultIconBytes) 를 그대로 사용한다.
class StickerConfig {
  final LogoPosition logoPosition;
  final LogoBackground logoBackground;
  final StickerText? topText;
  final StickerText? bottomText;

  // ── 신규 (로고 타입 확장) — 모두 nullable ───────────────────────────────
  /// 사용자가 드롭다운에서 선택한 로고 타입. null = 레거시 경로.
  final LogoType? logoType;

  /// LogoType.logo 일 때 — "social/twitter" 형식.
  final String? logoAssetId;

  /// LogoType.image 일 때 — 256×256 JPEG Q85 bytes.
  final Uint8List? logoImageBytes;

  /// LogoType.text 일 때 — 로고 전용 텍스트 (상/하단 텍스트와 독립).
  final StickerText? logoText;

  /// LogoType.logo 선택 후 래스터화된 PNG 96×96 bytes (메모리 전용 캐시).
  /// 영속화 대상 아님. 복원 시 logoAssetId 로부터 재래스터화.
  final Uint8List? logoAssetPngBytes;

  /// 로고 배경(square/circle)의 fill 색상. null = 기본 흰색.
  /// logoBackground == none 인 경우에는 의미 없음 (UI 에서도 disabled).
  final Color? logoBackgroundColor;

  const StickerConfig({
    this.logoPosition = LogoPosition.center,
    this.logoBackground = LogoBackground.none,
    this.topText,
    this.bottomText,
    this.logoType,
    this.logoAssetId,
    this.logoImageBytes,
    this.logoText,
    this.logoAssetPngBytes,
    this.logoBackgroundColor,
  });

  bool get hasTopText => topText != null && !topText!.isEmpty;
  bool get hasBottomText => bottomText != null && !bottomText!.isEmpty;

  StickerConfig copyWith({
    LogoPosition? logoPosition,
    LogoBackground? logoBackground,
    Object? topText = _stickerSentinel,
    Object? bottomText = _stickerSentinel,
    Object? logoType = _stickerSentinel,
    Object? logoAssetId = _stickerSentinel,
    Object? logoImageBytes = _stickerSentinel,
    Object? logoText = _stickerSentinel,
    Object? logoAssetPngBytes = _stickerSentinel,
    Object? logoBackgroundColor = _stickerSentinel,
  }) =>
      StickerConfig(
        logoPosition: logoPosition ?? this.logoPosition,
        logoBackground: logoBackground ?? this.logoBackground,
        topText: topText == _stickerSentinel ? this.topText : topText as StickerText?,
        bottomText:
            bottomText == _stickerSentinel ? this.bottomText : bottomText as StickerText?,
        logoType:
            logoType == _stickerSentinel ? this.logoType : logoType as LogoType?,
        logoAssetId:
            logoAssetId == _stickerSentinel ? this.logoAssetId : logoAssetId as String?,
        logoImageBytes: logoImageBytes == _stickerSentinel
            ? this.logoImageBytes
            : logoImageBytes as Uint8List?,
        logoText:
            logoText == _stickerSentinel ? this.logoText : logoText as StickerText?,
        logoAssetPngBytes: logoAssetPngBytes == _stickerSentinel
            ? this.logoAssetPngBytes
            : logoAssetPngBytes as Uint8List?,
        logoBackgroundColor: logoBackgroundColor == _stickerSentinel
            ? this.logoBackgroundColor
            : logoBackgroundColor as Color?,
      );
}
