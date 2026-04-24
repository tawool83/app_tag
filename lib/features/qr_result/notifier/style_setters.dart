part of '../qr_result_provider.dart';

/// QR 시각적 스타일(color/dot/eye/boundary/animation/quiet-zone) setter.
mixin _StyleSetters on StateNotifier<QrResultState> {
  void _schedulePush();

  void setQrColor(Color color) {
    // 색상 직접 변경 시 템플릿 그라디언트 해제 (마지막 선택 우선)
    state = state.copyWith(
      style: state.style.copyWith(qrColor: color),
      template: state.template.copyWith(
        clearTemplateGradient: true,
        clearActiveTemplateId: true,
      ),
    );
    _schedulePush();
  }

  void setRoundFactor(double factor) {
    state = state.copyWith(
      style: state.style.copyWith(roundFactor: factor),
      template: state.template.copyWith(clearActiveTemplateId: true),
    );
    _schedulePush();
  }

  void setEyeOuter(QrEyeOuter outer) {
    state = state.copyWith(
      style: state.style.copyWith(eyeOuter: outer, clearRandomEyeSeed: true),
      template: state.template.copyWith(clearActiveTemplateId: true),
    );
    _schedulePush();
  }

  void setEyeInner(QrEyeInner inner) {
    state = state.copyWith(
      style: state.style.copyWith(eyeInner: inner, clearRandomEyeSeed: true),
      template: state.template.copyWith(clearActiveTemplateId: true),
    );
    _schedulePush();
  }

  void regenerateEyeSeed() {
    state = state.copyWith(
      style: state.style.copyWith(randomEyeSeed: math.Random().nextInt(0xFFFFFF) + 1),
      template: state.template.copyWith(clearActiveTemplateId: true),
    );
    _schedulePush();
  }

  void clearRandomEye() {
    state = state.copyWith(
      style: state.style.copyWith(clearRandomEyeSeed: true),
    );
    _schedulePush();
  }

  void setCustomGradient(QrGradient? gradient) {
    if (gradient != null) {
      // 그라디언트 직접 선택 시 템플릿 그라디언트 해제 (마지막 선택 우선)
      state = state.copyWith(
        style: state.style.copyWith(customGradient: gradient),
        template: state.template.copyWith(
          clearTemplateGradient: true,
          clearActiveTemplateId: true,
        ),
      );
    } else {
      state = state.copyWith(
        style: state.style.copyWith(clearCustomGradient: true),
      );
    }
    _schedulePush();
  }

  void setQuietZoneColor(Color color) {
    state = state.copyWith(
      style: state.style.copyWith(quietZoneColor: color),
      template: state.template.copyWith(clearActiveTemplateId: true),
    );
    _schedulePush();
  }

  void setDotStyle(QrDotStyle style) {
    state = state.copyWith(
      style: state.style.copyWith(dotStyle: style, clearCustomDotParams: true),
      template: state.template.copyWith(clearActiveTemplateId: true),
    );
    _schedulePush();
  }

  void setCustomDotParams(DotShapeParams? params) {
    state = state.copyWith(
      style: params == null
          ? state.style.copyWith(clearCustomDotParams: true)
          : state.style.copyWith(customDotParams: params),
      template: state.template.copyWith(clearActiveTemplateId: true),
    );
    _schedulePush();
  }

  void setCustomEyeParams(EyeShapeParams? params) {
    state = state.copyWith(
      style: params == null
          ? state.style.copyWith(clearCustomEyeParams: true)
          : state.style.copyWith(customEyeParams: params, clearRandomEyeSeed: true),
      template: state.template.copyWith(clearActiveTemplateId: true),
    );
    _schedulePush();
  }

  void setBoundaryParams(QrBoundaryParams params) {
    state = state.copyWith(
      style: state.style.copyWith(boundaryParams: params),
      template: state.template.copyWith(clearActiveTemplateId: true),
    );
    _schedulePush();
  }

  void setAnimationParams(QrAnimationParams params) {
    state = state.copyWith(
      style: state.style.copyWith(animationParams: params),
      template: state.template.copyWith(clearActiveTemplateId: true),
    );
    _schedulePush();
  }
}
