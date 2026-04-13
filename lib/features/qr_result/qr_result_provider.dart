import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/qr_template.dart';
import '../../services/qr_service.dart';
import '../../services/history_service.dart';

final qrServiceProvider = Provider<QrService>((ref) => QrService());
final historyServiceProvider =
    Provider<HistoryService>((ref) => HistoryService());

enum QrActionStatus { idle, loading, success, error }

/// 꾸미기 탭 그라디언트 프리셋 팔레트 (흰 배경 기준 스캔 안전)
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

/// WCAG 대비비 ≥ 4.5:1 (흰 배경 기준) 안전 색상 팔레트
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

/// QR finder pattern(눈) 모양 프리셋
enum QrEyeStyle { square, rounded, circle, smooth }

class QrResultState {
  final Uint8List? capturedImage;
  final QrActionStatus saveStatus;
  final QrActionStatus shareStatus;
  final QrActionStatus printStatus;
  final String? errorMessage;
  final String? customLabel;               // null = 앱 이름 사용, "" = 표시 안 함
  final Color qrColor;
  final double printSizeCm;               // 인쇄 크기 (cm)
  final String? printTitle;               // null = 앱 이름 사용, "" = 표시 안 함
  final double roundFactor;               // 도트 둥글기 (0.0~1.0)
  final QrEyeStyle eyeStyle;              // 아이(finder pattern) 모양
  final QrGradient? customGradient;       // 꾸미기 탭에서 직접 선택한 그라디언트
  final bool embedIcon;
  final Uint8List? defaultIconBytes;       // 태그 타입 기본 아이콘
  final String? centerEmoji;               // 선택된 이모지 문자
  final Uint8List? emojiIconBytes;         // 렌더링된 이모지 PNG bytes
  final String? tagType;                   // 현재 태그 타입 (추천 탭 필터링용)
  // 템플릿 관련
  final String? activeTemplateId;          // 선택된 템플릿 ID (UI 하이라이트용)
  final QrGradient? templateGradient;      // non-null이면 그라디언트 렌더링
  final Uint8List? templateCenterIconBytes; // 템플릿 URL 아이콘 로드 결과

  const QrResultState({
    this.capturedImage,
    this.saveStatus = QrActionStatus.idle,
    this.shareStatus = QrActionStatus.idle,
    this.printStatus = QrActionStatus.idle,
    this.errorMessage,
    this.customLabel,
    this.qrColor = const Color(0xFF000000),
    this.printSizeCm = 5.0,
    this.printTitle,
    this.roundFactor = 0.0,
    this.eyeStyle = QrEyeStyle.square,
    this.customGradient,
    this.embedIcon = false,
    this.defaultIconBytes,
    this.centerEmoji,
    this.emojiIconBytes,
    this.tagType,
    this.activeTemplateId,
    this.templateGradient,
    this.templateCenterIconBytes,
  });

  QrResultState copyWith({
    Uint8List? capturedImage,
    QrActionStatus? saveStatus,
    QrActionStatus? shareStatus,
    QrActionStatus? printStatus,
    String? errorMessage,
    Object? customLabel = _sentinel,
    Color? qrColor,
    double? printSizeCm,
    Object? printTitle = _sentinel,
    double? roundFactor,
    QrEyeStyle? eyeStyle,
    Object? customGradient = _sentinel,
    bool? embedIcon,
    Object? defaultIconBytes = _sentinel,
    Object? centerEmoji = _sentinel,
    Object? emojiIconBytes = _sentinel,
    Object? tagType = _sentinel,
    Object? activeTemplateId = _sentinel,
    Object? templateGradient = _sentinel,
    Object? templateCenterIconBytes = _sentinel,
  }) =>
      QrResultState(
        capturedImage: capturedImage ?? this.capturedImage,
        saveStatus: saveStatus ?? this.saveStatus,
        shareStatus: shareStatus ?? this.shareStatus,
        printStatus: printStatus ?? this.printStatus,
        errorMessage: errorMessage ?? this.errorMessage,
        customLabel: customLabel == _sentinel
            ? this.customLabel
            : customLabel as String?,
        qrColor: qrColor ?? this.qrColor,
        printSizeCm: printSizeCm ?? this.printSizeCm,
        printTitle: printTitle == _sentinel
            ? this.printTitle
            : printTitle as String?,
        roundFactor: roundFactor ?? this.roundFactor,
        eyeStyle: eyeStyle ?? this.eyeStyle,
        customGradient: customGradient == _sentinel
            ? this.customGradient
            : customGradient as QrGradient?,
        embedIcon: embedIcon ?? this.embedIcon,
        defaultIconBytes: defaultIconBytes == _sentinel
            ? this.defaultIconBytes
            : defaultIconBytes as Uint8List?,
        centerEmoji: centerEmoji == _sentinel
            ? this.centerEmoji
            : centerEmoji as String?,
        emojiIconBytes: emojiIconBytes == _sentinel
            ? this.emojiIconBytes
            : emojiIconBytes as Uint8List?,
        tagType: tagType == _sentinel ? this.tagType : tagType as String?,
        activeTemplateId: activeTemplateId == _sentinel
            ? this.activeTemplateId
            : activeTemplateId as String?,
        templateGradient: templateGradient == _sentinel
            ? this.templateGradient
            : templateGradient as QrGradient?,
        templateCenterIconBytes: templateCenterIconBytes == _sentinel
            ? this.templateCenterIconBytes
            : templateCenterIconBytes as Uint8List?,
      );
}

// nullable 필드 null 재설정을 위한 sentinel
const _sentinel = Object();

class QrResultNotifier extends StateNotifier<QrResultState> {
  final QrService _qrService;

  QrResultNotifier(this._qrService) : super(const QrResultState());

  void setCapturedImage(Uint8List bytes) {
    state = state.copyWith(capturedImage: bytes);
  }

  void setCustomLabel(String? label) {
    state = state.copyWith(customLabel: label);
  }

  void setQrColor(Color color) {
    state = state.copyWith(qrColor: color);
  }

  void setPrintSizeCm(double sizeCm) {
    state = state.copyWith(printSizeCm: sizeCm);
  }

  void setPrintTitle(String? title) {
    state = state.copyWith(printTitle: title);
  }

  void setRoundFactor(double factor) {
    state = state.copyWith(roundFactor: factor);
  }

  void setEyeStyle(QrEyeStyle style) {
    state = state.copyWith(eyeStyle: style);
  }

  void setCustomGradient(QrGradient? gradient) {
    state = state.copyWith(customGradient: gradient);
  }

  void setTagType(String? tagType) {
    state = state.copyWith(tagType: tagType);
  }

  void setEmbedIcon(bool embed) {
    state = state.copyWith(embedIcon: embed);
  }

  void setDefaultIconBytes(Uint8List bytes) {
    state = state.copyWith(defaultIconBytes: bytes);
  }

  void setCenterEmoji(String emoji, Uint8List rendered) {
    state = state.copyWith(centerEmoji: emoji, emojiIconBytes: rendered);
  }

  void clearEmoji() {
    state = state.copyWith(centerEmoji: null, emojiIconBytes: null);
  }

  /// 템플릿 적용: 스타일 필드 일괄 갱신
  void applyTemplate(QrTemplate template, {Uint8List? centerIconBytes}) {
    final style = template.style;
    state = state.copyWith(
      activeTemplateId: template.id,
      roundFactor: template.roundFactor ?? 0.0,
      qrColor: style.foreground.solidColor ?? const Color(0xFF000000),
      templateGradient: style.foreground.gradient,
      embedIcon: style.centerIcon.type != 'none',
      templateCenterIconBytes: centerIconBytes,
      centerEmoji: null,
      emojiIconBytes: null,
    );
  }

  /// 템플릿 해제 (커스텀 설정 모드로 복귀)
  void clearTemplate() {
    state = state.copyWith(
      activeTemplateId: null,
      templateGradient: null,
      templateCenterIconBytes: null,
    );
  }

  Future<void> saveToGallery(String appName) async {
    if (state.capturedImage == null) return;
    state = state.copyWith(saveStatus: QrActionStatus.loading);
    try {
      final success =
          await _qrService.saveToGallery(state.capturedImage!, appName);
      state = state.copyWith(
        saveStatus: success ? QrActionStatus.success : QrActionStatus.error,
        errorMessage: success ? null : '이미지 저장에 실패했습니다.',
      );
    } catch (_) {
      state = state.copyWith(
        saveStatus: QrActionStatus.error,
        errorMessage: '이미지 저장에 실패했습니다.',
      );
    }
  }

  Future<void> shareImage(String appName) async {
    if (state.capturedImage == null) return;
    state = state.copyWith(shareStatus: QrActionStatus.loading);
    try {
      await _qrService.shareImage(state.capturedImage!, appName);
      state = state.copyWith(shareStatus: QrActionStatus.success);
    } catch (_) {
      state = state.copyWith(shareStatus: QrActionStatus.error);
    }
  }

  Future<void> printQrCode(String appName,
      {double? sizeCm, String? printTitle}) async {
    if (state.capturedImage == null) return;
    state = state.copyWith(printStatus: QrActionStatus.loading);
    try {
      await _qrService.printQrCode(
        imageBytes: state.capturedImage!,
        appName: appName,
        sizeCm: sizeCm ?? state.printSizeCm,
        printTitle: printTitle ?? state.printTitle,
      );
      state = state.copyWith(printStatus: QrActionStatus.success);
    } catch (_) {
      state = state.copyWith(
        printStatus: QrActionStatus.error,
        errorMessage: '인쇄에 실패했습니다. 프린터 연결을 확인해주세요.',
      );
    }
  }
}

final qrResultProvider =
    StateNotifierProvider.autoDispose<QrResultNotifier, QrResultState>(
  (ref) => QrResultNotifier(ref.read(qrServiceProvider)),
);
