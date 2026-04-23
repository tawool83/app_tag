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

  /// 템플릿 해제 (커스텀 설정 모드로 복귀)
  void clearTemplate() {
    state = state.copyWith(template: const QrTemplateState());
    _schedulePush();
  }
}
