/// QR 미리보기 모드 — 슬라이더 드래그 중 dedicated*, 평소 fullQr.
///
/// 편집기 슬라이더의 `onChanged` 콜백에서 `dedicated*` 로 전환해
/// 단일 도트/눈/외곽을 확대 미리보기로 표시하고, `onChangeEnd` 콜백에서
/// `fullQr` 로 복귀해 전체 QR 렌더링을 재개한다.
enum ShapePreviewMode {
  fullQr,
  dedicatedDot,
  dedicatedEye,
  dedicatedBoundary,
  dedicatedAnim,
}
