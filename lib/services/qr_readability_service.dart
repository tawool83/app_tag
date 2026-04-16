import 'dart:math';
import 'package:flutter/material.dart';
import '../models/qr_dot_style.dart';
import '../models/sticker_config.dart' show LogoPosition;
import '../features/qr_result/qr_result_provider.dart' show QrResultState;

/// QR 스캔 인식률 추정 점수.
class ReadabilityScore {
  final int total;         // 0~100 합산 점수
  final int contrastScore; // 0~40 색상 대비
  final int densityScore;  // 0~25 데이터 밀도
  final int logoScore;     // 0~20 로고 점유
  final int dotScore;      // 0~15 도트 모양
  final String mainIssue;  // 주요 원인 텍스트

  const ReadabilityScore({
    required this.total,
    required this.contrastScore,
    required this.densityScore,
    required this.logoScore,
    required this.dotScore,
    required this.mainIssue,
  });

  bool get isGood    => total >= 80;
  bool get isWarning => total >= 60 && total < 80;
  bool get isDanger  => total < 60;

  /// 80% 미만이면 저장 전 경고 필요
  bool get shouldWarnOnSave => total < 80;

  Color get color {
    if (isGood)    return Colors.green.shade600;
    if (isWarning) return Colors.orange.shade700;
    return Colors.red.shade600;
  }
}

/// 휴리스틱 기반 QR 인식률 계산 서비스 (순수 계산, UI 없음).
///
/// 점수 구성:
///   색상 대비 40점 + 데이터 밀도 25점 + 로고 점유 20점 + 도트 모양 15점
class QrReadabilityService {
  const QrReadabilityService._();

  static ReadabilityScore calculate(QrResultState state, String deepLink) {
    final contrast = _contrastScore(state);
    final density  = _densityScore(deepLink);
    final logo     = _logoScore(state);
    final dot      = _dotScore(state);
    final total    = (contrast + density + logo + dot).clamp(0, 100);

    // 각 항목의 달성률 중 가장 낮은 것을 주요 원인으로 표시
    final rates = {
      '색상 대비 부족':  contrast / 40.0,
      '데이터 밀도 높음': density  / 25.0,
      '로고 점유':       logo     / 20.0,
      '도트 모양':       dot      / 15.0,
    };
    final worst = rates.entries.reduce((a, b) => a.value < b.value ? a : b);
    final mainIssue = worst.value < 0.85 ? worst.key : '정상 범위';

    return ReadabilityScore(
      total: total,
      contrastScore: contrast,
      densityScore:  density,
      logoScore:     logo,
      dotScore:      dot,
      mainIssue:     mainIssue,
    );
  }

  // ── 색상 대비 점수 (0~40) ─────────────────────────────────────────────────

  static int _contrastScore(QrResultState state) {
    final bgColor = state.quietZoneColor;
    final activeGradient = state.templateGradient ?? state.customGradient;

    if (activeGradient != null) {
      // 그라디언트: 시작색·끝색 중 낮은 대비 사용
      final r1 = _contrastRatio(activeGradient.colors.first, bgColor);
      final r2 = _contrastRatio(activeGradient.colors.last, bgColor);
      return _ratioToScore(min(r1, r2));
    }

    return _ratioToScore(_contrastRatio(state.qrColor, bgColor));
  }

  static double _contrastRatio(Color fg, Color bg) {
    final l1 = _relativeLuminance(fg);
    final l2 = _relativeLuminance(bg);
    return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05);
  }

  static double _relativeLuminance(Color c) {
    // toARGB32()로 추출하면 모든 Flutter 버전에서 0-255 범위 보장
    final argb = c.toARGB32();
    double r = ((argb >> 16) & 0xFF) / 255.0;
    double g = ((argb >> 8)  & 0xFF) / 255.0;
    double b = ( argb        & 0xFF) / 255.0;
    r = r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4).toDouble();
    g = g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4).toDouble();
    b = b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static int _ratioToScore(double ratio) {
    if (ratio >= 7.0) return 40;
    if (ratio >= 4.5) return 34;
    if (ratio >= 3.0) return 26;
    if (ratio >= 2.0) return 16;
    return 8;
  }

  // ── 데이터 밀도 점수 (0~25) ──────────────────────────────────────────────

  static int _densityScore(String deepLink) {
    final len = deepLink.length;
    if (len <= 50)  return 25;
    if (len <= 100) return 21;
    if (len <= 200) return 16;
    if (len <= 300) return 11;
    return 6;
  }

  // ── 로고 점유 점수 (0~20) ────────────────────────────────────────────────

  static int _logoScore(QrResultState state) {
    if (!state.embedIcon) return 20;
    switch (state.sticker.logoPosition) {
      case LogoPosition.center:
        // ECC H 자동 적용: 30% 복원 가능 → 패널티 소폭
        return 17;
      case LogoPosition.bottomRight:
        // QR 모듈 영역 미점유 → 패널티 없음
        return 20;
    }
  }

  // ── 도트 모양 점수 (0~15) ────────────────────────────────────────────────

  static int _dotScore(QrResultState state) {
    switch (state.dotStyle) {
      case QrDotStyle.square:
        return 15;
      case QrDotStyle.circle:
        return 14;
      case QrDotStyle.diamond:
      case QrDotStyle.heart:
      case QrDotStyle.star:
        return 11;
    }
  }
}
