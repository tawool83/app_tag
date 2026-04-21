import 'package:flutter/material.dart';

import 'qr_template.dart' show QrGradient;

/// 꾸미기 탭 그라디언트 프리셋 팔레트 (흰 배경 기준 스캔 안전).
const kQrPresetGradients = [
  QrGradient(type: 'linear', angleDegrees: 45,
      colors: [Color(0xFF0066CC), Color(0xFF6A0DAD)]),  // 블루-퍼플
  QrGradient(type: 'linear', angleDegrees: 45,
      colors: [Color(0xFFCC3300), Color(0xFFCC8800)]),  // 선셋
  QrGradient(type: 'linear', angleDegrees: 135,
      colors: [Color(0xFF006644), Color(0xFF003388)]),  // 에메랄드-네이비
  QrGradient(type: 'linear', angleDegrees: 45,
      colors: [Color(0xFFCC0055), Color(0xFF660099)]),  // 로즈-퍼플
  QrGradient(type: 'linear', angleDegrees: 135,
      colors: [Color(0xFF0077B6), Color(0xFF023E8A)]),  // 오션
  QrGradient(type: 'linear', angleDegrees: 45,
      colors: [Color(0xFF1B5E20), Color(0xFF1A237E)]),  // 포레스트
  QrGradient(type: 'linear', angleDegrees: 135,
      colors: [Color(0xFF1A237E), Color(0xFF006064)]),  // 미드나잇
  QrGradient(type: 'radial',
      colors: [Color(0xFF880000), Color(0xFF4A0080)]),  // 라디얼 다크
];

/// WCAG 대비비 ≥ 4.5:1 (흰 배경 기준) 안전 색상 팔레트.
const qrSafeColors = [
  Color(0xFF000000), // 검정
  Color(0xFF003366), // 남색
  Color(0xFF0000CD), // 진파랑
  Color(0xFF006400), // 진초록
  Color(0xFF8B0000), // 진빨강
  Color(0xFF4B0082), // 진보라
  Color(0xFF006666), // 청록
  Color(0xFF5C3317), // 진갈색
  Color(0xFFCC4400), // 진주황
  Color(0xFF1B0060), // 인디고
];
