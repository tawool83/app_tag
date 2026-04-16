import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../models/qr_dot_style.dart';
import '../../../models/qr_template.dart';
import '../../../models/sticker_config.dart';
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
      qrColorArgb: state.qrColor.toARGB32(),
      gradient: _gradientToData(state.customGradient),
      roundFactor: state.roundFactor,
      eyeOuter: state.eyeOuter.name,
      eyeInner: state.eyeInner.name,
      randomEyeSeed: state.randomEyeSeed,
      quietZoneColorArgb: state.quietZoneColor.toARGB32(),
      dotStyle: state.dotStyle.name,
      embedIcon: state.embedIcon,
      centerEmoji: state.centerEmoji,
      centerIconBase64: state.emojiIconBytes != null
          ? base64Encode(state.emojiIconBytes!)
          : null,
      printSizeCm: state.printSizeCm,
      sticker: _stickerToSpec(state.sticker),
      activeTemplateId: state.activeTemplateId,
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
    );
  }

  static QrEyeOuter eyeOuterFromName(String name) {
    for (final v in QrEyeOuter.values) {
      if (v.name == name) return v;
    }
    return QrEyeOuter.square;
  }

  static QrEyeInner eyeInnerFromName(String name) {
    for (final v in QrEyeInner.values) {
      if (v.name == name) return v;
    }
    return QrEyeInner.square;
  }

  static QrDotStyle dotStyleFromName(String name) {
    for (final v in QrDotStyle.values) {
      if (v.name == name) return v;
    }
    return QrDotStyle.square;
  }

  static StickerConfig stickerFromSpec(StickerSpec spec) {
    return StickerConfig(
      logoPosition: _logoPositionFromName(spec.logoPosition),
      logoBackground: _logoBackgroundFromName(spec.logoBackground),
      topText: spec.topText != null ? _stickerTextFromSpec(spec.topText!) : null,
      bottomText:
          spec.bottomText != null ? _stickerTextFromSpec(spec.bottomText!) : null,
    );
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
    );
  }

  static StickerSpec _stickerToSpec(StickerConfig s) {
    return StickerSpec(
      logoPosition: s.logoPosition.name,
      logoBackground: s.logoBackground.name,
      topText: s.topText != null ? _stickerTextToSpec(s.topText!) : null,
      bottomText:
          s.bottomText != null ? _stickerTextToSpec(s.bottomText!) : null,
    );
  }

  static StickerTextSpec _stickerTextToSpec(StickerText t) => StickerTextSpec(
        content: t.content,
        colorArgb: t.color.toARGB32(),
        fontFamily: t.fontFamily,
        fontSize: t.fontSize,
      );

  static StickerText _stickerTextFromSpec(StickerTextSpec s) => StickerText(
        content: s.content,
        color: Color(s.colorArgb),
        fontFamily: s.fontFamily,
        fontSize: s.fontSize,
      );

  static LogoPosition _logoPositionFromName(String name) {
    for (final v in LogoPosition.values) {
      if (v.name == name) return v;
    }
    return LogoPosition.center;
  }

  static LogoBackground _logoBackgroundFromName(String name) {
    for (final v in LogoBackground.values) {
      if (v.name == name) return v;
    }
    return LogoBackground.none;
  }
}
