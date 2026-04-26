import 'package:flutter/material.dart';

import '../entities/qr_animation_params.dart';
import '../entities/qr_boundary_params.dart';
import '../entities/qr_dot_style.dart';
import '../entities/qr_eye_shapes.dart';
import '../entities/qr_shape_params.dart';
import '../entities/qr_template.dart' show QrGradient;

export '../entities/qr_eye_shapes.dart' show QrEyeOuter, QrEyeInner;

/// QR 시각적 스타일 상태 (도트/눈/외곽/애니메이션/그라디언트).
///
/// 12개 필드. 가장 자주 변경되는 핵심 스타일 sub-state로,
/// 위젯은 `ref.watch(provider.select((s) => s.style))` 로 구독하면
/// 다른 sub-state 변경에 의한 불필요 리빌드를 제거할 수 있다.
class QrStyleState {
  final Color qrColor;
  final double roundFactor;
  final QrEyeOuter eyeOuter;
  final QrEyeInner eyeInner;
  final int? randomEyeSeed;
  final QrGradient? customGradient;
  final QrDotStyle dotStyle;
  final DotShapeParams? customDotParams;
  final EyeShapeParams? customEyeParams;
  final QrBoundaryParams boundaryParams;
  final QrAnimationParams animationParams;
  final Color quietZoneColor;

  // ── 배경 전용 색상 (null = qrColor/customGradient 따라감) ──
  final Color? bgColor;
  final QrGradient? bgGradient;

  const QrStyleState({
    this.qrColor = const Color(0xFF000000),
    this.roundFactor = 0.0,
    this.eyeOuter = QrEyeOuter.square,
    this.eyeInner = QrEyeInner.square,
    this.randomEyeSeed,
    this.customGradient,
    this.dotStyle = QrDotStyle.square,
    this.customDotParams,
    this.customEyeParams,
    this.boundaryParams = const QrBoundaryParams(),
    this.animationParams = const QrAnimationParams(),
    this.quietZoneColor = Colors.white,
    this.bgColor,
    this.bgGradient,
  });

  QrStyleState copyWith({
    Color? qrColor,
    double? roundFactor,
    QrEyeOuter? eyeOuter,
    QrEyeInner? eyeInner,
    int? randomEyeSeed,
    bool clearRandomEyeSeed = false,
    QrGradient? customGradient,
    bool clearCustomGradient = false,
    QrDotStyle? dotStyle,
    DotShapeParams? customDotParams,
    bool clearCustomDotParams = false,
    EyeShapeParams? customEyeParams,
    bool clearCustomEyeParams = false,
    QrBoundaryParams? boundaryParams,
    QrAnimationParams? animationParams,
    Color? quietZoneColor,
    Color? bgColor,
    bool clearBgColor = false,
    QrGradient? bgGradient,
    bool clearBgGradient = false,
  }) =>
      QrStyleState(
        qrColor: qrColor ?? this.qrColor,
        roundFactor: roundFactor ?? this.roundFactor,
        eyeOuter: eyeOuter ?? this.eyeOuter,
        eyeInner: eyeInner ?? this.eyeInner,
        randomEyeSeed:
            clearRandomEyeSeed ? null : (randomEyeSeed ?? this.randomEyeSeed),
        customGradient: clearCustomGradient
            ? null
            : (customGradient ?? this.customGradient),
        dotStyle: dotStyle ?? this.dotStyle,
        customDotParams: clearCustomDotParams
            ? null
            : (customDotParams ?? this.customDotParams),
        customEyeParams: clearCustomEyeParams
            ? null
            : (customEyeParams ?? this.customEyeParams),
        boundaryParams: boundaryParams ?? this.boundaryParams,
        animationParams: animationParams ?? this.animationParams,
        quietZoneColor: quietZoneColor ?? this.quietZoneColor,
        bgColor: clearBgColor ? null : (bgColor ?? this.bgColor),
        bgGradient:
            clearBgGradient ? null : (bgGradient ?? this.bgGradient),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrStyleState &&
          other.qrColor == qrColor &&
          other.roundFactor == roundFactor &&
          other.eyeOuter == eyeOuter &&
          other.eyeInner == eyeInner &&
          other.randomEyeSeed == randomEyeSeed &&
          other.customGradient == customGradient &&
          other.dotStyle == dotStyle &&
          other.customDotParams == customDotParams &&
          other.customEyeParams == customEyeParams &&
          other.boundaryParams == boundaryParams &&
          other.animationParams == animationParams &&
          other.quietZoneColor == quietZoneColor &&
          other.bgColor == bgColor &&
          other.bgGradient == bgGradient;

  @override
  int get hashCode => Object.hash(
        qrColor,
        roundFactor,
        eyeOuter,
        eyeInner,
        randomEyeSeed,
        customGradient,
        dotStyle,
        customDotParams,
        customEyeParams,
        boundaryParams,
        animationParams,
        quietZoneColor,
        bgColor,
        bgGradient,
      );
}
