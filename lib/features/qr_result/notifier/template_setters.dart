part of '../qr_result_provider.dart';

/// 템플릿(기본 + 사용자) 적용/해제 setter. 스타일+로고+템플릿 sub-state 동시 갱신.
mixin _TemplateSetters on StateNotifier<QrResultState> {
  void _schedulePush();

  /// 템플릿 적용: 스타일 필드 일괄 갱신
  void applyTemplate(QrTemplate template, {Uint8List? centerIconBytes}) {
    final tStyle = template.style;
    state = state.copyWith(
      style: state.style.copyWith(
        roundFactor: template.roundFactor ?? 0.0,
        qrColor: tStyle.foreground.solidColor ?? const Color(0xFF000000),
        clearCustomGradient: true, // 템플릿이 우선 — 기존 커스텀 그라디언트 초기화
      ),
      template: QrTemplateState(
        activeTemplateId: template.id,
        templateGradient: tStyle.foreground.gradient,
        templateCenterIconBytes: centerIconBytes,
      ),
      logo: state.logo.copyWith(
        embedIcon: tStyle.centerIcon.type != 'none',
        clearCenterEmoji: true,
        clearEmojiIconBytes: true,
      ),
    );
    _schedulePush();
  }

  /// 나의 템플릿 일괄 적용 (모든 레이어 설정 복원)
  void applyUserTemplate(UserQrTemplate t) {
    QrGradient? gradient;
    if (t.gradientJson != null) {
      try {
        gradient = QrGradient.fromJson(jsonDecode(t.gradientJson!));
      } catch (_) {}
    }

    // v2: 커스텀 파라미터 복원
    DotShapeParams? dotParams;
    if (t.customDotParamsJson != null) {
      try {
        dotParams = DotShapeParams.fromJson(
            jsonDecode(t.customDotParamsJson!) as Map<String, dynamic>);
      } catch (_) {}
    }

    EyeShapeParams? eyeParams;
    if (t.customEyeParamsJson != null) {
      try {
        eyeParams = EyeShapeParams.fromJson(
            jsonDecode(t.customEyeParamsJson!) as Map<String, dynamic>);
      } catch (_) {}
    }

    QrBoundaryParams? boundary;
    if (t.boundaryParamsJson != null) {
      try {
        boundary = QrBoundaryParams.fromJson(
            jsonDecode(t.boundaryParamsJson!) as Map<String, dynamic>);
      } catch (_) {}
    }

    state = state.copyWith(
      style: state.style.copyWith(
        qrColor: Color(t.qrColorValue),
        customGradient: gradient,
        clearCustomGradient: gradient == null,
        roundFactor: t.roundFactor,
        dotStyle: QrDotStyle.values[t.dotStyleIndex.clamp(0, QrDotStyle.values.length - 1)],
        eyeOuter: QrEyeOuter.values[t.eyeOuterIndex.clamp(0, QrEyeOuter.values.length - 1)],
        eyeInner: QrEyeInner.values[t.eyeInnerIndex.clamp(0, QrEyeInner.values.length - 1)],
        randomEyeSeed: t.randomEyeSeed,
        clearRandomEyeSeed: t.randomEyeSeed == null,
        quietZoneColor: Color(t.quietZoneColorValue),
        customDotParams: dotParams,
        clearCustomDotParams: dotParams == null,
        customEyeParams: eyeParams,
        clearCustomEyeParams: eyeParams == null,
        boundaryParams: boundary ?? const QrBoundaryParams(),
      ),
      sticker: StickerConfig(
        logoPosition: LogoPosition.values[t.logoPositionIndex],
        logoBackground: LogoBackground.values[t.logoBackgroundIndex],
        topText: t.topTextContent != null
            ? StickerText(
                content: t.topTextContent!,
                color: Color(t.topTextColorValue ?? 0xFF000000),
                fontFamily: t.topTextFont ?? 'sans-serif',
                fontSize: t.topTextSize ?? 14,
              )
            : null,
        bottomText: t.bottomTextContent != null
            ? StickerText(
                content: t.bottomTextContent!,
                color: Color(t.bottomTextColorValue ?? 0xFF000000),
                fontFamily: t.bottomTextFont ?? 'sans-serif',
                fontSize: t.bottomTextSize ?? 14,
              )
            : null,
      ),
      template: const QrTemplateState(),
    );
    _schedulePush();
  }

  /// 템플릿 해제 (커스텀 설정 모드로 복귀)
  void clearTemplate() {
    state = state.copyWith(template: const QrTemplateState());
    _schedulePush();
  }
}
