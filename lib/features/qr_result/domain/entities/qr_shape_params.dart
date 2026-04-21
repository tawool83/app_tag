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
  static const square = DotShapeParams(
    vertices: 4,
    innerRadius: 1.0,
    roundness: 0.0,
    rotation: 45.0,
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

/// Superellipse 기반 눈 파라미터.
///
/// |x/a|^n + |y/b|^n = 1 에서 n 값으로 형태 결정:
/// n=2 → 원, n≈4 → squircle (iOS), n→∞ → 사각형.
///
/// 회전·내부 크기 필드는 QR 인식률 저하 원인이 되어 제거됨 (2026-04-21).
/// 내부 finder 패턴은 항상 QR 스펙 3/7 비율 고정 렌더.
class EyeShapeParams {
  final double outerN; // 외곽 superellipse n: 2.0(원)~20.0(사각)
  final double innerN; // 내부 superellipse n: 2.0(원)~20.0(사각)

  const EyeShapeParams({
    this.outerN = 20.0,
    this.innerN = 20.0,
  });

  // ── 기존 프리셋 매핑 ──
  static const square = EyeShapeParams(outerN: 20.0, innerN: 20.0);
  static const rounded = EyeShapeParams(outerN: 5.0, innerN: 20.0);
  static const circle = EyeShapeParams(outerN: 2.0, innerN: 2.0);
  static const squircle = EyeShapeParams(outerN: 4.0, innerN: 4.0);
  static const smooth = EyeShapeParams(outerN: 3.0, innerN: 3.0);

  EyeShapeParams copyWith({
    double? outerN,
    double? innerN,
  }) =>
      EyeShapeParams(
        outerN: outerN ?? this.outerN,
        innerN: innerN ?? this.innerN,
      );

  Map<String, dynamic> toJson() => {
        'outerN': outerN,
        'innerN': innerN,
      };

  factory EyeShapeParams.fromJson(Map<String, dynamic> json) => EyeShapeParams(
        outerN: (json['outerN'] as num?)?.toDouble() ?? 20.0,
        innerN: (json['innerN'] as num?)?.toDouble() ?? 20.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EyeShapeParams &&
          outerN == other.outerN &&
          innerN == other.innerN;

  @override
  int get hashCode => Object.hash(outerN, innerN);

  @override
  String toString() => 'EyeShapeParams(outerN:$outerN, innerN:$innerN)';
}
