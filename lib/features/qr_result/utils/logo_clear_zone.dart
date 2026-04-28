import 'dart:ui';

import '../domain/entities/logo_source.dart' show LogoType;
import '../domain/entities/sticker_config.dart';

/// QR 렌더 시 도트를 비울 영역을 나타내는 record.
/// - [rect]: Painter 좌표계(quiet zone 제외)의 영역
/// - [isCircular]: true 면 rect.center 기준 반지름 rect.width/2 원, false 면 rect 사각
///
/// Dart record 는 ==/hashCode 를 필드 기반으로 자동 생성 →
/// CustomQrPainter.shouldRepaint 에서 직접 값 비교가 가능하다.
typedef ClearZone = ({Rect rect, bool isCircular});

/// QR 도트 clear-zone 계산.
///
/// 리턴 null (clearing 대상 아님) 조건:
///  - [embedIcon] == false
///  - [StickerConfig.logoPosition] != [LogoPosition.center]
///    (bottomRight 는 QR 밖 배치이므로 clearing 불필요)
///  - [StickerConfig.logoType] == none 또는 null
///  - [StickerConfig.logoType] == text 이고 logoBackground 가 none 인 경우
///    (🚫 모드 텍스트는 bandClearZone 경로로 처리)
///
/// v0.7: text 타입도 square/circle 배경이면 clearing 적용.
///
/// 모양은 [StickerConfig.logoBackground] 에 따라 결정:
///  - none             → iconSize × iconSize                  원형 (컨텐츠가 ClipOval 적용)
///  - circle           → (iconSize+8) × (iconSize+8)          원형
///  - square           → (iconSize+8) × (iconSize+8)          사각
///  - rectangle        → (iconSize+20) × (iconSize+12)        사각 (레거시 대응)
///  - roundedRectangle → (iconSize+20) × (iconSize+12)        사각
///
/// 이미지 타입에서 rectangle/roundedRectangle 는 UI 정규화로 선택할 수 없지만,
/// 레거시 저장 데이터 복원 시 state 에 남아 있을 수 있으므로 대응한다.
///
/// [qrSize]  : CustomQrPainter 가 그리는 영역(quiet zone 제외) 의 크기.
/// [iconSize]: `QrLayerStack.widget.size * 0.22` — _LogoWidget 기본 아이콘 크기.
ClearZone? computeLogoClearZone({
  required Size qrSize,
  required double iconSize,
  required StickerConfig sticker,
  required bool embedIcon,
}) {
  if (!embedIcon) return null;
  if (sticker.logoPosition != LogoPosition.center) return null;
  final type = sticker.logoType;
  if (type == null || type == LogoType.none) return null;
  // text 타입: square/circle 배경 + 텍스트 있을 때만 clearing
  if (type == LogoType.text) {
    final bg = sticker.logoBackground;
    if (bg != LogoBackground.square && bg != LogoBackground.circle) return null;
    // 텍스트가 비어있으면 clearing 불필요
    final t = sticker.logoText;
    if (t == null || t.isEmpty) return null;
  }

  final (double w, double h, bool circular) = switch (sticker.logoBackground) {
    LogoBackground.none     => (iconSize,      iconSize,      true),
    LogoBackground.circle   => (iconSize + 8,  iconSize + 8,  true),
    LogoBackground.square   => (iconSize + 8,  iconSize + 8,  false),
    LogoBackground.rectangle ||
    LogoBackground.roundedRectangle => (iconSize + 20, iconSize + 12, false),
  };

  final rect = Rect.fromCenter(
    center: Offset(qrSize.width / 2, qrSize.height / 2),
    width: w,
    height: h,
  );
  return (rect: rect, isCircular: circular);
}

/// 중앙 텍스트 "띠(band)" 모드용 ClearZone 계산.
///
/// [bandMode]: horizontal → 가로 전폭 스트립, vertical → 세로 전높이 스트립.
/// [qrSize]: CustomQrPainter 가 그리는 영역(quiet zone 제외) 크기.
/// [fontSize]: logoText.fontSize * scale (미리보기 크기 비례).
///
/// 띠 크기(높이 또는 너비)는 QR 크기의 12% 이하로 제한.
/// (이전 15% → 12%: burst error 실효 정정 capacity 안쪽으로 진입,
///  finder/timing pattern 침범 위험 감소)
ClearZone computeBandClearZone({
  required Size qrSize,
  required BandMode bandMode,
  required double fontSize,
}) {
  final maxDimension = qrSize.width * 0.12;

  if (bandMode == BandMode.vertical) {
    final bandWidth = (fontSize * 1.4).clamp(0.0, maxDimension);
    final rect = Rect.fromCenter(
      center: Offset(qrSize.width / 2, qrSize.height / 2),
      width: bandWidth,
      height: qrSize.height,
    );
    return (rect: rect, isCircular: false);
  }

  // horizontal
  final bandHeight = (fontSize * 1.4).clamp(0.0, maxDimension);
  final rect = Rect.fromCenter(
    center: Offset(qrSize.width / 2, qrSize.height / 2),
    width: qrSize.width,
    height: bandHeight,
  );
  return (rect: rect, isCircular: false);
}
