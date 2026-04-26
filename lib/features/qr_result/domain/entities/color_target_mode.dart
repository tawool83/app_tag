/// 색상 탭에서 색상 변경 대상.
enum ColorTargetMode {
  /// QR 도트 + 배경 패턴/테두리 동시 변경 (기본값).
  both,

  /// QR 도트만 변경.
  qrOnly,

  /// 배경 패턴/테두리만 변경.
  bgOnly,
}
