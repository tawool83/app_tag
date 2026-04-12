import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/qr_service.dart';
import '../../services/history_service.dart';

final qrServiceProvider = Provider<QrService>((ref) => QrService());
final historyServiceProvider =
    Provider<HistoryService>((ref) => HistoryService());

enum QrActionStatus { idle, loading, success, error }

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

class QrResultState {
  final Uint8List? capturedImage;
  final QrActionStatus saveStatus;
  final QrActionStatus shareStatus;
  final QrActionStatus printStatus;
  final String? errorMessage;
  final String? customLabel;       // null = 앱 이름 사용, "" = 표시 안 함
  final Color qrColor;
  final double printSizeCm;        // 인쇄 크기 (cm)
  final String? printTitle;        // null = 앱 이름 사용, "" = 표시 안 함
  final QrEyeShape eyeShape;
  final QrDataModuleShape dataModuleShape;
  final bool embedIcon;

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
    this.eyeShape = QrEyeShape.square,
    this.dataModuleShape = QrDataModuleShape.square,
    this.embedIcon = false,
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
    QrEyeShape? eyeShape,
    QrDataModuleShape? dataModuleShape,
    bool? embedIcon,
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
        eyeShape: eyeShape ?? this.eyeShape,
        dataModuleShape: dataModuleShape ?? this.dataModuleShape,
        embedIcon: embedIcon ?? this.embedIcon,
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

  void setEyeShape(QrEyeShape shape) {
    state = state.copyWith(eyeShape: shape);
  }

  void setDataModuleShape(QrDataModuleShape shape) {
    state = state.copyWith(dataModuleShape: shape);
  }

  void setEmbedIcon(bool embed) {
    state = state.copyWith(embedIcon: embed);
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
