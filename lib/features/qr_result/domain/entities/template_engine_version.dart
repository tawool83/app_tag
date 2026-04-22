/// 현재 앱이 처리할 수 있는 템플릿 엔진 버전.
/// 템플릿의 minEngineVersion > kTemplateEngineVersion 이면 적용 불가.
const int kTemplateEngineVersion = 2;

/// 새 템플릿 저장 시 기재되는 스키마 버전.
const int kTemplateSchemaVersion = 2;

/// 현재 엔진에서 호환 가능한지 판정.
bool isTemplateCompatible(int? minEngineVersion) =>
    (minEngineVersion ?? 1) <= kTemplateEngineVersion;

/// 현재 스타일 상태로부터 최소 엔진 버전 자동 결정.
int computeMinEngineVersion({
  required bool hasCustomDotParams,
  required bool hasCustomEyeParams,
  required bool hasNonDefaultBoundary,
}) {
  if (hasCustomDotParams || hasCustomEyeParams || hasNonDefaultBoundary) {
    return 2;
  }
  return 1;
}
