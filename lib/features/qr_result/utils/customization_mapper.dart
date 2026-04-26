import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/utils/enum_from_name.dart';
import '../domain/entities/logo_source.dart' show LogoType;
import '../domain/entities/qr_animation_params.dart';
import '../domain/entities/qr_boundary_params.dart';
import '../domain/entities/qr_dot_style.dart';
import '../domain/entities/qr_eye_shapes.dart';
import '../domain/entities/qr_shape_params.dart';
import '../domain/entities/qr_template.dart';
import '../domain/entities/sticker_config.dart';
import '../../qr_task/domain/entities/qr_customization.dart';
import '../../qr_task/domain/entities/qr_gradient_data.dart';
import '../../qr_task/domain/entities/sticker_spec.dart';
import '../qr_result_provider.dart';

/// Presentation 의 [QrResultState] / 도메인 [QrCustomization] 변환 매퍼.
///
/// - 도메인은 ARGB int + enum name(String) 만 사용
/// - presentation 은 Flutter Color/Enum 사용
/// - centerIconBase64: emojiIconBytes (렌더링된 PNG) 만 직렬화. defaultIconBytes 와
///   templateCenterIconBytes 는 재생성 가능하므로 직렬화 안 함.
class CustomizationMapper {
  CustomizationMapper._();

  // ── State → Customization (저장용) ─────────────────────────────────

  static QrCustomization fromState(QrResultState state) {
    return QrCustomization(
      qrColorArgb: state.style.qrColor.toARGB32(),
      gradient: _gradientToData(state.style.customGradient),
      roundFactor: state.style.roundFactor,
      eyeOuter: state.style.eyeOuter.name,
      eyeInner: state.style.eyeInner.name,
      randomEyeSeed: state.style.randomEyeSeed,
      quietZoneColorArgb: state.style.quietZoneColor.toARGB32(),
      dotStyle: state.style.dotStyle.name,
      embedIcon: state.logo.embedIcon,
      centerEmoji: state.logo.centerEmoji,
      centerIconBase64: state.logo.emojiIconBytes != null
          ? base64Encode(state.logo.emojiIconBytes!)
          : null,
      printSizeCm: state.meta.printSizeCm,
      sticker: _stickerToSpec(state.sticker),
      activeTemplateId: state.template.activeTemplateId,
      customDotParams: state.style.customDotParams?.toJson(),
      customEyeParams: state.style.customEyeParams?.toJson(),
      boundaryParams: state.style.boundaryParams.isDefault
          ? null
          : state.style.boundaryParams.toJson(),
      animationParams: state.style.animationParams.isAnimated
          ? state.style.animationParams.toJson()
          : null,
      bgColorArgb: state.style.bgColor?.toARGB32(),
      bgGradient: _gradientToData(state.style.bgGradient),
    );
  }

  // ── Customization → 일부 State 필드 (복원용) ───────────────────────
  // 복원은 Notifier 에서 copyWith 로 적용 — 여기서는 변환만 제공.

  static Color colorFromArgb(int argb) => Color(argb);

  static QrGradient? gradientFromData(QrGradientData? d) {
    if (d == null) return null;
    return QrGradient(
      type: d.type,
      colors: d.colorsArgb.map(Color.new).toList(),
      stops: d.stops,
      angleDegrees: d.angleDegrees,
      center: d.center,
    );
  }

  static QrEyeOuter eyeOuterFromName(String name) =>
      enumFromName(QrEyeOuter.values, name, QrEyeOuter.square);

  static QrEyeInner eyeInnerFromName(String name) =>
      enumFromName(QrEyeInner.values, name, QrEyeInner.square);

  static QrDotStyle dotStyleFromName(String name) =>
      enumFromName(QrDotStyle.values, name, QrDotStyle.square);

  static StickerConfig stickerFromSpec(StickerSpec spec) {
    return StickerConfig(
      logoPosition: _logoPositionFromName(spec.logoPosition),
      logoBackground: _logoBackgroundFromName(spec.logoBackground),
      topText: spec.topText != null ? _stickerTextFromSpec(spec.topText!) : null,
      bottomText:
          spec.bottomText != null ? _stickerTextFromSpec(spec.bottomText!) : null,
      logoType: _logoTypeFromName(spec.logoType),
      logoAssetId: spec.logoAssetId,
      logoImageBytes: bytesFromBase64(spec.logoImageBase64),
      logoText:
          spec.logoText != null ? _stickerTextFromSpec(spec.logoText!) : null,
      logoBackgroundColor: spec.logoBackgroundColorArgb != null
          ? Color(spec.logoBackgroundColorArgb!)
          : null,
      bandMode: _bandModeFromName(spec.bandMode),
      centerTextEvenSpacing: spec.centerTextEvenSpacing,
      // logoAssetPngBytes 는 영속화 안 됨 — 복원 시 repository.rasterize 로 재생성
    );
  }

  static DotShapeParams? dotParamsFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return DotShapeParams.fromJson(json);
  }

  static EyeShapeParams? eyeParamsFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    // legacy(outerN만 존재) → null 반환 → customEye 해제, 빌트인 eye 로 fallback.
    return EyeShapeParams.fromJsonOrNull(json);
  }

  static QrBoundaryParams boundaryParamsFromJson(Map<String, dynamic>? json) {
    if (json == null) return const QrBoundaryParams();
    return QrBoundaryParams.fromJson(json);
  }

  static QrAnimationParams animationParamsFromJson(Map<String, dynamic>? json) {
    if (json == null) return const QrAnimationParams();
    return QrAnimationParams.fromJson(json);
  }

  static Uint8List? bytesFromBase64(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  // ── 내부 헬퍼 ─────────────────────────────────────────────────────

  static QrGradientData? _gradientToData(QrGradient? g) {
    if (g == null) return null;
    return QrGradientData(
      type: g.type,
      colorsArgb: g.colors.map((c) => c.toARGB32()).toList(),
      stops: g.stops,
      angleDegrees: g.angleDegrees,
      center: g.center,
    );
  }

  static StickerSpec _stickerToSpec(StickerConfig s) {
    return StickerSpec(
      logoPosition: s.logoPosition.name,
      logoBackground: s.logoBackground.name,
      topText: s.topText != null ? _stickerTextToSpec(s.topText!) : null,
      bottomText:
          s.bottomText != null ? _stickerTextToSpec(s.bottomText!) : null,
      logoType: s.logoType?.name,
      logoAssetId: s.logoAssetId,
      logoImageBase64: s.logoImageBytes != null
          ? base64Encode(s.logoImageBytes!)
          : null,
      logoText:
          s.logoText != null ? _stickerTextToSpec(s.logoText!) : null,
      logoBackgroundColorArgb:
          s.logoBackgroundColor?.toARGB32(),
      bandMode: s.bandMode.name,
      centerTextEvenSpacing: s.centerTextEvenSpacing,
    );
  }

  /// JSON 의 `logoType` 문자열을 `LogoType` 으로 역매핑.
  ///
  /// **null vs LogoType.none 의 의미 차이 (중요)**:
  /// - **return null** — `name` 이 null 또는 알 수 없는 값. 레거시 저장 데이터 경로를
  ///   의미한다. `centerImageProvider` 의 `case null:` 분기에서
  ///   `templateCenterIconBytes > emojiIconBytes > defaultIconBytes` fallback 체인으로
  ///   **기존 아이콘이 렌더**된다.
  /// - **return LogoType.none** — 사용자가 드롭다운에서 명시적으로 "없음" 선택한 상태.
  ///   `centerImageProvider` 의 `case LogoType.none: return null` 로 **아이콘 미표시**.
  ///
  /// 두 경로의 렌더 결과는 서로 다르다. enumFromName 의 fallback-to-default 모델과 달리
  /// 이 헬퍼는 null 을 정상 반환값으로 사용해 레거시 호환을 유지한다.
  static LogoType? _logoTypeFromName(String? name) {
    if (name == null) return null;
    for (final v in LogoType.values) {
      if (v.name == name) return v;
    }
    return null;
  }

  static StickerTextSpec _stickerTextToSpec(StickerText t) => StickerTextSpec(
        content: t.content,
        colorArgb: t.color.toARGB32(),
        fontFamily: t.fontFamily,
        fontSize: t.fontSize,
        showBackground: t.showBackground,
        backgroundColorArgb:
            t.showBackground ? t.backgroundColor.toARGB32() : null,
      );

  static StickerText _stickerTextFromSpec(StickerTextSpec s) => StickerText(
        content: s.content,
        color: Color(s.colorArgb),
        fontFamily: s.fontFamily,
        fontSize: s.fontSize,
        showBackground: s.showBackground,
        backgroundColor: s.backgroundColorArgb != null
            ? Color(s.backgroundColorArgb!)
            : const Color(0xFFFFFFFF),
      );

  static LogoPosition _logoPositionFromName(String name) =>
      enumFromName(LogoPosition.values, name, LogoPosition.center);

  static LogoBackground _logoBackgroundFromName(String name) =>
      enumFromName(LogoBackground.values, name, LogoBackground.none);

  static BandMode _bandModeFromName(String name) =>
      enumFromName(BandMode.values, name, BandMode.none);
}
