import 'qr_border_style.dart';
import 'qr_margin_pattern.dart';

enum QrBoundaryType { square, circle, superellipse, star, heart, hexagon, custom }

/// QR 외곽 파라미터.
///
/// [frameScale] <= 1.0 이면 기존 clipPath 모드 (QR 자체 변형).
/// [frameScale] > 1.0 이면 프레임 모드 (QR 정사각형 유지, 장식 프레임).
class QrBoundaryParams {
  final QrBoundaryType type;
  final double superellipseN; // type=superellipse 전용: 2.0(원)~20.0(사각)
  final int starVertices; // type=star 전용: 5~12
  final double starInnerRadius; // type=star 전용: 0.3~0.8
  final double rotation; // 회전: 0.0~360.0
  final double padding; // quiet zone 패딩: 0.0~0.15 (기본 0.05)
  final double roundness; // 꼭짓점 둥글기: 0.0~1.0 (star/hexagon 전용)

  // ── 프레임 모드 필드 ──
  final double frameScale; // 프레임 크기 비율: 1.0~3.0 (≤1.0 = clipPath 모드, >1.0 = 프레임 모드)
  final QrMarginPattern marginPattern; // 마진 장식 패턴
  final double patternDensity; // 패턴 밀도: 0.5~2.0

  // ── 외곽선 스타일 ──
  final QrBorderStyle borderStyle; // 외곽선 종류: solid(기본)/dashed/dotted/...
  final int borderColorArgb; // 외곽선 색상 ARGB: 0xFF000000(검정)
  final double borderWidth; // 외곽선 두께: 1.0~6.0 (기본 2.0)

  // ── 마진 패턴 색상 ──
  final int? patternColorArgb; // null = 자동 (qrColor * 0.4)

  const QrBoundaryParams({
    this.type = QrBoundaryType.square,
    this.superellipseN = 20.0,
    this.starVertices = 5,
    this.starInnerRadius = 0.5,
    this.rotation = 0.0,
    this.padding = 0.05,
    this.roundness = 0.0,
    this.frameScale = 1.0,
    this.marginPattern = QrMarginPattern.none,
    this.patternDensity = 1.0,
    this.borderStyle = QrBorderStyle.solid,
    this.borderColorArgb = 0xFF000000,
    this.borderWidth = 2.0,
    this.patternColorArgb,
  });

  // ── 기본 프리셋 (clipPath 모드 — 기존 호환) ──
  static const square = QrBoundaryParams();
  static const circle = QrBoundaryParams(type: QrBoundaryType.circle);
  static const squircle = QrBoundaryParams(
    type: QrBoundaryType.superellipse,
    superellipseN: 4.0,
  );
  static const roundedRect = QrBoundaryParams(
    type: QrBoundaryType.superellipse,
    superellipseN: 6.0,
  );
  static const star5 = QrBoundaryParams(
    type: QrBoundaryType.star,
    starVertices: 5,
    starInnerRadius: 0.5,
  );
  static const heart = QrBoundaryParams(type: QrBoundaryType.heart);
  static const hexagon = QrBoundaryParams(type: QrBoundaryType.hexagon);

  // ── 프레임 프리셋 (프레임 모드 — QR 정사각형 유지) ──
  static const circleFrame = QrBoundaryParams(
    type: QrBoundaryType.circle,
    frameScale: 1.4,
    marginPattern: QrMarginPattern.qrDots,
  );
  static const hexagonFrame = QrBoundaryParams(
    type: QrBoundaryType.hexagon,
    frameScale: 1.4,
    marginPattern: QrMarginPattern.zigzag,
  );
  static const heartFrame = QrBoundaryParams(
    type: QrBoundaryType.heart,
    frameScale: 1.5,
    marginPattern: QrMarginPattern.wave,
  );
  static const starFrame = QrBoundaryParams(
    type: QrBoundaryType.star,
    frameScale: 1.5,
    marginPattern: QrMarginPattern.grid,
    starVertices: 5,
    starInnerRadius: 0.5,
  );

  bool get isDefault => type == QrBoundaryType.square && frameScale <= 1.0;

  /// 프레임 모드: type != square && frameScale > 1.0
  bool get isFrameMode => type != QrBoundaryType.square && frameScale > 1.0;

  QrBoundaryParams copyWith({
    QrBoundaryType? type,
    double? superellipseN,
    int? starVertices,
    double? starInnerRadius,
    double? rotation,
    double? padding,
    double? roundness,
    double? frameScale,
    QrMarginPattern? marginPattern,
    double? patternDensity,
    QrBorderStyle? borderStyle,
    int? borderColorArgb,
    double? borderWidth,
    int? patternColorArgb,
    bool clearPatternColor = false,
  }) =>
      QrBoundaryParams(
        type: type ?? this.type,
        superellipseN: superellipseN ?? this.superellipseN,
        starVertices: starVertices ?? this.starVertices,
        starInnerRadius: starInnerRadius ?? this.starInnerRadius,
        rotation: rotation ?? this.rotation,
        padding: padding ?? this.padding,
        roundness: roundness ?? this.roundness,
        frameScale: frameScale ?? this.frameScale,
        marginPattern: marginPattern ?? this.marginPattern,
        patternDensity: patternDensity ?? this.patternDensity,
        borderStyle: borderStyle ?? this.borderStyle,
        borderColorArgb: borderColorArgb ?? this.borderColorArgb,
        borderWidth: borderWidth ?? this.borderWidth,
        patternColorArgb: clearPatternColor
            ? null
            : (patternColorArgb ?? this.patternColorArgb),
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'superellipseN': superellipseN,
        'starVertices': starVertices,
        'starInnerRadius': starInnerRadius,
        'rotation': rotation,
        'padding': padding,
        'roundness': roundness,
        'frameScale': frameScale,
        'marginPattern': marginPattern.name,
        'patternDensity': patternDensity,
        'borderStyle': borderStyle.name,
        'borderColorArgb': borderColorArgb,
        'borderWidth': borderWidth,
        if (patternColorArgb != null) 'patternColorArgb': patternColorArgb,
      };

  factory QrBoundaryParams.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'square';
    final patternName = json['marginPattern'] as String?;
    final borderStyleName = json['borderStyle'] as String?;
    return QrBoundaryParams(
      type: QrBoundaryType.values.firstWhere(
        (e) => e.name == typeName,
        orElse: () => QrBoundaryType.square,
      ),
      superellipseN: (json['superellipseN'] as num?)?.toDouble() ?? 20.0,
      starVertices: json['starVertices'] as int? ?? 5,
      starInnerRadius:
          (json['starInnerRadius'] as num?)?.toDouble() ?? 0.5,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      padding: (json['padding'] as num?)?.toDouble() ?? 0.05,
      roundness: (json['roundness'] as num?)?.toDouble() ?? 0.0,
      frameScale: (json['frameScale'] as num?)?.toDouble() ?? 1.0,
      marginPattern: patternName == null
          ? QrMarginPattern.none
          : QrMarginPattern.values.firstWhere(
              (e) => e.name == patternName,
              orElse: () => QrMarginPattern.none,
            ),
      patternDensity: (json['patternDensity'] as num?)?.toDouble() ?? 1.0,
      borderStyle: borderStyleName == null
          ? QrBorderStyle.solid
          : QrBorderStyle.values.firstWhere(
              (e) => e.name == borderStyleName,
              orElse: () => QrBorderStyle.solid,
            ),
      borderColorArgb: json['borderColorArgb'] as int? ?? 0xFF000000,
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 2.0,
      patternColorArgb: json['patternColorArgb'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrBoundaryParams &&
          type == other.type &&
          superellipseN == other.superellipseN &&
          starVertices == other.starVertices &&
          starInnerRadius == other.starInnerRadius &&
          rotation == other.rotation &&
          padding == other.padding &&
          roundness == other.roundness &&
          frameScale == other.frameScale &&
          marginPattern == other.marginPattern &&
          patternDensity == other.patternDensity &&
          borderStyle == other.borderStyle &&
          borderColorArgb == other.borderColorArgb &&
          borderWidth == other.borderWidth &&
          patternColorArgb == other.patternColorArgb;

  @override
  int get hashCode => Object.hash(
        type, superellipseN, starVertices, starInnerRadius,
        rotation, padding, roundness,
        frameScale, marginPattern, patternDensity,
        borderStyle, borderColorArgb, borderWidth, patternColorArgb,
      );

  @override
  String toString() =>
      'QrBoundaryParams(${type.name}, n:$superellipseN, rot:$rotation, frame:$frameScale, pattern:${marginPattern.name}, border:${borderStyle.name})';
}
