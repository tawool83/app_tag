/// QR 사양 경계(quiet-zone) 테두리선의 stroke pattern.
///
/// 외각 모양(boundaryParams.type) 과 무관 — 항상 직사각형으로 그려짐.
/// QR 코드 사양상 quiet-zone 까지가 스캐너 인식 영역이므로 그 경계를 시각화한다.
enum QuietZoneBorderStyle {
  solid,    // ──────────────
  dashed,   // ─ ─ ─ ─ ─ ─
  dotted,   // · · · · · · ·
}
