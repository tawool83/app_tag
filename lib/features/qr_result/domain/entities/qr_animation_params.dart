enum QrAnimationType { none, wave, rainbow, pulse, sequential, rotationWave }

/// 데이터 영역 전용 애니메이션 파라미터.
class QrAnimationParams {
  final QrAnimationType type;
  final double speed; // 1.0 = 2초 주기, 0.5 = 4초
  final double amplitude; // 효과 강도: 0.0~1.0
  final double frequency; // 위상 차이 주파수: 0.1~2.0

  const QrAnimationParams({
    this.type = QrAnimationType.none,
    this.speed = 1.0,
    this.amplitude = 0.5,
    this.frequency = 0.3,
  });

  // ── 기본 프리셋 ──
  static const none = QrAnimationParams();
  static const wave = QrAnimationParams(
    type: QrAnimationType.wave,
    amplitude: 0.5,
    frequency: 0.3,
  );
  static const rainbow = QrAnimationParams(
    type: QrAnimationType.rainbow,
    speed: 0.8,
    frequency: 1.0,
  );
  static const pulse = QrAnimationParams(
    type: QrAnimationType.pulse,
    amplitude: 0.3,
  );
  static const sequential = QrAnimationParams(
    type: QrAnimationType.sequential,
    speed: 0.5,
  );
  static const rotationWave = QrAnimationParams(
    type: QrAnimationType.rotationWave,
    amplitude: 0.4,
    frequency: 0.5,
  );

  bool get isAnimated => type != QrAnimationType.none;

  QrAnimationParams copyWith({
    QrAnimationType? type,
    double? speed,
    double? amplitude,
    double? frequency,
  }) =>
      QrAnimationParams(
        type: type ?? this.type,
        speed: speed ?? this.speed,
        amplitude: amplitude ?? this.amplitude,
        frequency: frequency ?? this.frequency,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'speed': speed,
        'amplitude': amplitude,
        'frequency': frequency,
      };

  factory QrAnimationParams.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'none';
    return QrAnimationParams(
      type: QrAnimationType.values.firstWhere(
        (e) => e.name == typeName,
        orElse: () => QrAnimationType.none,
      ),
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      amplitude: (json['amplitude'] as num?)?.toDouble() ?? 0.5,
      frequency: (json['frequency'] as num?)?.toDouble() ?? 0.3,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrAnimationParams &&
          type == other.type &&
          speed == other.speed &&
          amplitude == other.amplitude &&
          frequency == other.frequency;

  @override
  int get hashCode => Object.hash(type, speed, amplitude, frequency);

  @override
  String toString() =>
      'QrAnimationParams(${type.name}, spd:$speed, amp:$amplitude, freq:$frequency)';
}

/// 단일 도트의 애니메이션 프레임 값.
class DotAnimFrame {
  final double scale; // 0.6~1.2
  final double hueShift; // 0.0~1.0 (HSV hue offset)
  final double opacity; // 0.5~1.0
  final double rotationRad; // 회전 (라디안)

  const DotAnimFrame({
    this.scale = 1.0,
    this.hueShift = 0.0,
    this.opacity = 1.0,
    this.rotationRad = 0.0,
  });

  static const identity = DotAnimFrame();
}
