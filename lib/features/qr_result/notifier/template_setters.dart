part of '../qr_result_provider.dart';

/// 템플릿(기본 + 사용자) 적용/해제 setter. 스타일+로고+템플릿 sub-state 동시 갱신.
mixin _TemplateSetters on StateNotifier<QrResultState> {
  void _schedulePush();

  /// 템플릿 적용: 스타일 필드 일괄 갱신 (컬러 + 도트 + 눈 + 기타 초기화)
  void applyTemplate(QrTemplate template, {Uint8List? centerIconBytes}) {
    final tStyle = template.style;
    final dotStyle = _parseDotStyle(tStyle.dataModuleShape);
    final (eyeOuter, eyeInner) = _parseEyeShape(tStyle.eyeShape);

    state = state.copyWith(
      style: state.style.copyWith(
        qrColor: tStyle.foreground.solidColor ?? const Color(0xFF000000),
        roundFactor: template.roundFactor ?? 0.0,
        dotStyle: dotStyle,
        clearCustomDotParams: true,
        eyeOuter: eyeOuter,
        eyeInner: eyeInner,
        clearRandomEyeSeed: true,
        clearCustomEyeParams: true,
        boundaryParams: const QrBoundaryParams(),
        animationParams: const QrAnimationParams(),
        clearCustomGradient: true,
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

  /// 템플릿 해제 — activeTemplateId 만 clear. 시각 스타일은 유지
  /// (favorite QR 적용 후 "템플릿 표시만 해제" 용도로 사용).
  void clearTemplate() {
    state = state.copyWith(template: const QrTemplateState());
    _schedulePush();
  }

  // ── 템플릿 shape string → enum 파싱 ─────────────────────────────────────
  QrDotStyle _parseDotStyle(String s) => switch (s) {
        'circle' => QrDotStyle.circle,
        _ => QrDotStyle.square,
      };

  (QrEyeOuter, QrEyeInner) _parseEyeShape(String s) => switch (s) {
        'circle' => (QrEyeOuter.circle, QrEyeInner.circle),
        _ => (QrEyeOuter.square, QrEyeInner.square),
      };
}
