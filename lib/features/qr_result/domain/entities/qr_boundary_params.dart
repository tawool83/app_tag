enum QrBoundaryType { square, circle, superellipse, star, heart, hexagon, custom }

/// QR 전체 외곽 클리핑 파라미터.
class QrBoundaryParams {
  final QrBoundaryType type;
  final double superellipseN; // type=superellipse 전용: 2.0(원)~20.0(사각)
  final int starVertices; // type=star 전용: 5~12
  final double starInnerRadius; // type=star 전용: 0.3~0.8
  final double rotation; // 회전: 0.0~360.0
  final double padding; // quiet zone 패딩: 0.0~0.15 (기본 0.05)
  final double roundness; // 꼭짓점 둥글기: 0.0~1.0 (star/hexagon 전용)

  const QrBoundaryParams({
    this.type = QrBoundaryType.square,
    this.superellipseN = 20.0,
    this.starVertices = 5,
    this.starInnerRadius = 0.5,
    this.rotation = 0.0,
    this.padding = 0.05,
    this.roundness = 0.0,
  });

  // ── 기본 프리셋 ──
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

  bool get isDefault => type == QrBoundaryType.square;

  QrBoundaryParams copyWith({
    QrBoundaryType? type,
    double? superellipseN,
    int? starVertices,
    double? starInnerRadius,
    double? rotation,
    double? padding,
    double? roundness,
  }) =>
      QrBoundaryParams(
        type: type ?? this.type,
        superellipseN: superellipseN ?? this.superellipseN,
        starVertices: starVertices ?? this.starVertices,
        starInnerRadius: starInnerRadius ?? this.starInnerRadius,
        rotation: rotation ?? this.rotation,
        padding: padding ?? this.padding,
        roundness: roundness ?? this.roundness,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'superellipseN': superellipseN,
        'starVertices': starVertices,
        'starInnerRadius': starInnerRadius,
        'rotation': rotation,
        'padding': padding,
        'roundness': roundness,
      };

  factory QrBoundaryParams.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'square';
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
          roundness == other.roundness;

  @override
  int get hashCode => Object.hash(
        type, superellipseN, starVertices, starInnerRadius,
        rotation, padding, roundness,
      );

  @override
  String toString() =>
      'QrBoundaryParams(${type.name}, n:$superellipseN, rot:$rotation)';
}
