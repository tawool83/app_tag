/// 도트 모양 모드: 대칭(극좌표 다각형) vs 비대칭(Superformula)
enum DotShapeMode { symmetric, asymmetric }

/// 극좌표 다각형 + Superformula 기반 도트 파라미터. 불변 객체.
///
/// [대칭 모드]: vertices, innerRadius, roundness
/// [비대칭 모드]: Superformula (sfM, sfN1, sfN2, sfN3, sfA, sfB)
/// [공통]: rotation
class DotShapeParams {
  final DotShapeMode mode;

  // ── 대칭 전용 ──
  final int vertices; // 꼭짓점 수: 3~12 (4=사각, 12≈원)
  final double innerRadius; // 별 깊이: 0.0(첨예)~1.0(볼록)
  final double roundness; // 둥글기: 0.0(날카로운)~1.0(곡선)

  // ── 비대칭 전용: Superformula (Gielis, 1999) ──
  // r(θ) = ( |cos(mθ/4)/a|^n2 + |sin(mθ/4)/b|^n3 )^(-1/n1)
  final double sfM; // 대칭 차수: 0~20
  final double sfN1; // 곡률 1: 0.1~40
  final double sfN2; // 곡률 2: 0.1~40
  final double sfN3; // 곡률 3: -5~40
  final double sfA; // X 스케일: 0.5~2.0
  final double sfB; // Y 스케일: 0.5~2.0

  // ── 공통 ──
  final double rotation; // 회전: 0.0~360.0 (도)
  final double scale; // 크기: 0.5~2.0 (슬라이더 -100%~+100%, 중앙 1.0, QR 인식 한계는 테스트 후 조정)

  const DotShapeParams({
    this.mode = DotShapeMode.symmetric,
    this.vertices = 4,
    this.innerRadius = 1.0,
    this.roundness = 0.0,
    this.sfM = 0.0,
    this.sfN1 = 1.0,
    this.sfN2 = 1.0,
    this.sfN3 = 1.0,
    this.sfA = 1.0,
    this.sfB = 1.0,
    this.rotation = 0.0,
    this.scale = 1.0,
  });

  // ── 대칭 프리셋 ──
  // vertices=4, rotation=0 → PolarPolygon이 꼭짓점을 상/우/하/좌에 배치(마름모).
  // 사각형을 원하면 rotation=45로 꼭짓점을 모서리로 이동시킨다.
  // scale=√2: 4개 꼭짓점이 셀 외접원이 아닌 셀 코너에 도달 → 셀을 꽉 채움 (PrettyQrSmoothSymbol 과 동일 출력).
  static const square = DotShapeParams(
    vertices: 4,
    innerRadius: 1.0,
    roundness: 0.0,
    rotation: 45.0,
    scale: 1.4142135623730951,
  );
  static const circle = DotShapeParams(
    vertices: 12,
    innerRadius: 1.0,
    roundness: 1.0,
  );
  static const diamond = DotShapeParams(
    vertices: 4,
    innerRadius: 1.0,
    roundness: 0.0,
  );
  static const star = DotShapeParams(
    vertices: 5,
    innerRadius: 0.45,
    roundness: 0.0,
  );

  // ── 비대칭 프리셋 (Superformula 파라미터 조합) ──
  static const sfCircle = DotShapeParams(
    mode: DotShapeMode.asymmetric,
    sfM: 0, sfN1: 1, sfN2: 1, sfN3: 1,
  );
  static const sfSquare = DotShapeParams(
    mode: DotShapeMode.asymmetric,
    sfM: 4, sfN1: 100, sfN2: 100, sfN3: 100,
  );
  static const sfStar = DotShapeParams(
    mode: DotShapeMode.asymmetric,
    sfM: 5, sfN1: 4.5, sfN2: 12, sfN3: 10,
    sfA: 1.10, sfB: 1.10, rotation: 240,
  );
  static const sfFlower = DotShapeParams(
    mode: DotShapeMode.asymmetric,
    sfM: 10, sfN1: 7.6, sfN2: 21.8, sfN3: 6.6,
    sfA: 0.89, sfB: 2, rotation: 230,
  );
  static const sfHeart = DotShapeParams(
    mode: DotShapeMode.asymmetric,
    sfM: 2, sfN1: 1.5, sfN2: 0.2, sfN3: -1.9,
    sfA: 1.2, sfB: 0.98, rotation: 244,
  );

  DotShapeParams copyWith({
    DotShapeMode? mode,
    int? vertices,
    double? innerRadius,
    double? roundness,
    double? sfM,
    double? sfN1,
    double? sfN2,
    double? sfN3,
    double? sfA,
    double? sfB,
    double? rotation,
    double? scale,
  }) =>
      DotShapeParams(
        mode: mode ?? this.mode,
        vertices: vertices ?? this.vertices,
        innerRadius: innerRadius ?? this.innerRadius,
        roundness: roundness ?? this.roundness,
        sfM: sfM ?? this.sfM,
        sfN1: sfN1 ?? this.sfN1,
        sfN2: sfN2 ?? this.sfN2,
        sfN3: sfN3 ?? this.sfN3,
        sfA: sfA ?? this.sfA,
        sfB: sfB ?? this.sfB,
        rotation: rotation ?? this.rotation,
        scale: scale ?? this.scale,
      );

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'vertices': vertices,
        'innerRadius': innerRadius,
        'roundness': roundness,
        'sfM': sfM,
        'sfN1': sfN1,
        'sfN2': sfN2,
        'sfN3': sfN3,
        'sfA': sfA,
        'sfB': sfB,
        'rotation': rotation,
        'scale': scale,
      };

  factory DotShapeParams.fromJson(Map<String, dynamic> json) {
    // 하위 호환: squareness 필드 무시, mode 필드 없으면 symmetric
    final modeStr = json['mode'] as String? ?? 'symmetric';
    return DotShapeParams(
      mode: modeStr == 'asymmetric'
          ? DotShapeMode.asymmetric
          : DotShapeMode.symmetric,
      vertices: json['vertices'] as int? ?? 4,
      innerRadius: (json['innerRadius'] as num?)?.toDouble() ?? 1.0,
      roundness: (json['roundness'] as num?)?.toDouble() ?? 0.0,
      sfM: (json['sfM'] as num?)?.toDouble() ?? 0.0,
      sfN1: (json['sfN1'] as num?)?.toDouble() ?? 1.0,
      sfN2: (json['sfN2'] as num?)?.toDouble() ?? 1.0,
      sfN3: (json['sfN3'] as num?)?.toDouble() ?? 1.0,
      sfA: (json['sfA'] as num?)?.toDouble() ?? 1.0,
      sfB: (json['sfB'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DotShapeParams &&
          mode == other.mode &&
          vertices == other.vertices &&
          innerRadius == other.innerRadius &&
          roundness == other.roundness &&
          sfM == other.sfM &&
          sfN1 == other.sfN1 &&
          sfN2 == other.sfN2 &&
          sfN3 == other.sfN3 &&
          sfA == other.sfA &&
          sfB == other.sfB &&
          rotation == other.rotation &&
          scale == other.scale;

  @override
  int get hashCode => Object.hash(
      mode, vertices, innerRadius, roundness, sfM, sfN1, sfN2, sfN3, sfA, sfB,
      rotation, scale);

  @override
  String toString() => mode == DotShapeMode.symmetric
      ? 'DotShapeParams.sym(v:$vertices, ir:$innerRadius, r:$roundness, rot:$rotation, s:$scale)'
      : 'DotShapeParams.asym(m:$sfM, n1:$sfN1, n2:$sfN2, n3:$sfN3, a:$sfA, b:$sfB, rot:$rotation, s:$scale)';
}

/// Eye (finder pattern) 모양 파라미터.
///
/// 외곽 ring 은 4 모서리 독립 corner radius (0.0 = 둥근, 1.0 = 각진).
/// 내부 fill 은 uniform superellipse (2.0 원 ~ 20.0 사각).
///
/// 좌표계는 local eye (회전 전). 렌더러에서 finder 위치에 따라 ±90° 회전 적용.
///   - Q1 corner = top-right
///   - Q2 corner = top-left
///   - Q3 corner = bottom-left
///   - Q4 corner = bottom-right (회전 후 QR 중심 방향)
class EyeShapeParams {
  /// 0.0 = 완전 둥근(원형) 모서리, 1.0 = 완전 각진(직각) 모서리.
  final double cornerQ1;
  final double cornerQ2;
  final double cornerQ3;
  final double cornerQ4;

  /// 내부 fill superellipse n: 2.0(원) ~ 20.0(사각). uniform.
  final double innerN;

  const EyeShapeParams({
    this.cornerQ1 = 0.0,
    this.cornerQ2 = 0.0,
    this.cornerQ3 = 0.0,
    this.cornerQ4 = 0.0,
    this.innerN = 2.0,
  });

  // ── 내장 프리셋 매핑 (참조용) ──
  static const square   = EyeShapeParams(cornerQ1: 1, cornerQ2: 1, cornerQ3: 1, cornerQ4: 1, innerN: 20);
  static const rounded  = EyeShapeParams(cornerQ1: 0.7, cornerQ2: 0.7, cornerQ3: 0.7, cornerQ4: 0.7, innerN: 20);
  static const circle   = EyeShapeParams(cornerQ1: 0, cornerQ2: 0, cornerQ3: 0, cornerQ4: 0, innerN: 2);
  static const squircle = EyeShapeParams(cornerQ1: 0.4, cornerQ2: 0.4, cornerQ3: 0.4, cornerQ4: 0.4, innerN: 4);
  static const smooth   = EyeShapeParams(cornerQ1: 0.2, cornerQ2: 0.2, cornerQ3: 0.2, cornerQ4: 0.2, innerN: 3);

  EyeShapeParams copyWith({
    double? cornerQ1,
    double? cornerQ2,
    double? cornerQ3,
    double? cornerQ4,
    double? innerN,
  }) =>
      EyeShapeParams(
        cornerQ1: cornerQ1 ?? this.cornerQ1,
        cornerQ2: cornerQ2 ?? this.cornerQ2,
        cornerQ3: cornerQ3 ?? this.cornerQ3,
        cornerQ4: cornerQ4 ?? this.cornerQ4,
        innerN: innerN ?? this.innerN,
      );

  Map<String, dynamic> toJson() => {
        'cornerQ1': cornerQ1,
        'cornerQ2': cornerQ2,
        'cornerQ3': cornerQ3,
        'cornerQ4': cornerQ4,
        'innerN': innerN,
      };

  /// legacy(outerN 키만 있고 cornerQ* 없음) 는 null 리턴 — 호출자가 skip.
  static EyeShapeParams? fromJsonOrNull(Map<String, dynamic> json) {
    final hasCorner = json.containsKey('cornerQ1');
    final hasLegacyOuter = json.containsKey('outerN') && !hasCorner;
    if (hasLegacyOuter) return null;
    return EyeShapeParams(
      cornerQ1: (json['cornerQ1'] as num?)?.toDouble() ?? 0.0,
      cornerQ2: (json['cornerQ2'] as num?)?.toDouble() ?? 0.0,
      cornerQ3: (json['cornerQ3'] as num?)?.toDouble() ?? 0.0,
      cornerQ4: (json['cornerQ4'] as num?)?.toDouble() ?? 0.0,
      innerN: (json['innerN'] as num?)?.toDouble() ?? 2.0,
    );
  }

  /// 기본 fromJson — legacy 인 경우 default 값 반환.
  factory EyeShapeParams.fromJson(Map<String, dynamic> json) =>
      fromJsonOrNull(json) ?? const EyeShapeParams();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EyeShapeParams &&
          cornerQ1 == other.cornerQ1 &&
          cornerQ2 == other.cornerQ2 &&
          cornerQ3 == other.cornerQ3 &&
          cornerQ4 == other.cornerQ4 &&
          innerN == other.innerN;

  @override
  int get hashCode => Object.hash(cornerQ1, cornerQ2, cornerQ3, cornerQ4, innerN);

  @override
  String toString() =>
      'EyeShapeParams(Q1:$cornerQ1, Q2:$cornerQ2, Q3:$cornerQ3, Q4:$cornerQ4, innerN:$innerN)';
}
