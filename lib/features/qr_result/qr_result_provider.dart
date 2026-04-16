import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/error/result.dart';
import '../../models/qr_dot_style.dart';
import '../../models/qr_template.dart';
import '../../models/sticker_config.dart';
import '../../services/qr_service.dart';
import '../qr_task/domain/entities/qr_customization.dart';
import '../qr_task/presentation/providers/qr_task_providers.dart';
import 'domain/entities/user_qr_template.dart';
import 'presentation/providers/qr_result_providers.dart';
import 'utils/customization_mapper.dart';

final qrServiceProvider = Provider<QrService>((ref) => QrService());

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

/// QR finder pattern 외곽 링 모양
/// circleRound: 원형 외각 + 원형 여백(도넛 링)
enum QrEyeOuter { square, rounded, circle, circleRound, smooth }

/// QR finder pattern 내부 채움 모양
enum QrEyeInner { square, circle, diamond, star }

class QrResultState {
  final Uint8List? capturedImage;
  final QrActionStatus saveStatus;
  final QrActionStatus shareStatus;
  final QrActionStatus printStatus;
  final String? errorMessage;
  final Color qrColor;
  final double printSizeCm;               // 인쇄 크기 (cm)
  final double roundFactor;               // 도트 둥글기 (0.0~1.0)
  final QrEyeOuter eyeOuter;             // finder pattern 외곽 링 모양 (circleRound = 원형+원형여백)
  final QrEyeInner eyeInner;             // finder pattern 내부 채움 모양
  final int? randomEyeSeed;              // non-null → 시드 기반 랜덤 눈 모양
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

  // 레이어 에디터 신규 필드
  final StickerConfig sticker;             // 스티커 레이어 (최상단)
  final Color quietZoneColor;              // QR 콰이어트 존 배경색
  final QrDotStyle dotStyle;              // QR 도트 모양

  const QrResultState({
    this.capturedImage,
    this.saveStatus = QrActionStatus.idle,
    this.shareStatus = QrActionStatus.idle,
    this.printStatus = QrActionStatus.idle,
    this.errorMessage,
    this.qrColor = const Color(0xFF000000),
    this.printSizeCm = 5.0,
    this.roundFactor = 0.0,
    this.eyeOuter = QrEyeOuter.square,
    this.eyeInner = QrEyeInner.square,
    this.randomEyeSeed,
    this.customGradient,
    this.embedIcon = false,
    this.defaultIconBytes,
    this.centerEmoji,
    this.emojiIconBytes,
    this.tagType,
    this.activeTemplateId,
    this.templateGradient,
    this.templateCenterIconBytes,
    this.sticker = const StickerConfig(),
    this.quietZoneColor = Colors.white,
    this.dotStyle = QrDotStyle.square,
  });

  QrResultState copyWith({
    Uint8List? capturedImage,
    QrActionStatus? saveStatus,
    QrActionStatus? shareStatus,
    QrActionStatus? printStatus,
    String? errorMessage,
    Color? qrColor,
    double? printSizeCm,
    double? roundFactor,
    QrEyeOuter? eyeOuter,
    QrEyeInner? eyeInner,
    Object? randomEyeSeed = _sentinel,
    Object? customGradient = _sentinel,
    bool? embedIcon,
    Object? defaultIconBytes = _sentinel,
    Object? centerEmoji = _sentinel,
    Object? emojiIconBytes = _sentinel,
    Object? tagType = _sentinel,
    Object? activeTemplateId = _sentinel,
    Object? templateGradient = _sentinel,
    Object? templateCenterIconBytes = _sentinel,
    StickerConfig? sticker,
    Color? quietZoneColor,
    QrDotStyle? dotStyle,
  }) =>
      QrResultState(
        capturedImage: capturedImage ?? this.capturedImage,
        saveStatus: saveStatus ?? this.saveStatus,
        shareStatus: shareStatus ?? this.shareStatus,
        printStatus: printStatus ?? this.printStatus,
        errorMessage: errorMessage ?? this.errorMessage,
        qrColor: qrColor ?? this.qrColor,
        printSizeCm: printSizeCm ?? this.printSizeCm,
        roundFactor: roundFactor ?? this.roundFactor,
        eyeOuter: eyeOuter ?? this.eyeOuter,
        eyeInner: eyeInner ?? this.eyeInner,
        randomEyeSeed: randomEyeSeed == _sentinel
            ? this.randomEyeSeed
            : randomEyeSeed as int?,
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
        sticker: sticker ?? this.sticker,
        quietZoneColor: quietZoneColor ?? this.quietZoneColor,
        dotStyle: dotStyle ?? this.dotStyle,
      );
}

// nullable 필드 null 재설정을 위한 sentinel
const _sentinel = Object();

class QrResultNotifier extends StateNotifier<QrResultState> {
  final Ref _ref;

  /// 현재 편집 중인 QrTask 의 id. null 이면 아직 발급 전 (저장 안 함).
  String? _currentTaskId;
  Timer? _debounceTimer;

  /// `loadFromCustomization` 등 일괄 복원 시 setter 가 debounced save 를
  /// 트리거하지 않도록 막는 플래그.
  bool _suppressPush = false;

  QrResultNotifier(this._ref) : super(const QrResultState());

  String? get currentTaskId => _currentTaskId;

  /// QR 화면 진입 시 1회 호출 — 이후 setter 들이 이 task 로 저장.
  void setCurrentTaskId(String id) {
    _currentTaskId = id;
  }

  /// 히스토리에서 진입 시 사용. 모든 customization 필드를 일괄 복원하며
  /// 복원 중에는 자동저장을 막는다.
  void loadFromCustomization(QrCustomization c) {
    _suppressPush = true;
    try {
      state = state.copyWith(
        qrColor: CustomizationMapper.colorFromArgb(c.qrColorArgb),
        customGradient: CustomizationMapper.gradientFromData(c.gradient),
        roundFactor: c.roundFactor,
        eyeOuter: CustomizationMapper.eyeOuterFromName(c.eyeOuter),
        eyeInner: CustomizationMapper.eyeInnerFromName(c.eyeInner),
        randomEyeSeed: c.randomEyeSeed,
        quietZoneColor: CustomizationMapper.colorFromArgb(c.quietZoneColorArgb),
        dotStyle: CustomizationMapper.dotStyleFromName(c.dotStyle),
        embedIcon: c.embedIcon,
        centerEmoji: c.centerEmoji,
        emojiIconBytes: CustomizationMapper.bytesFromBase64(c.centerIconBase64),
        printSizeCm: c.printSizeCm,
        sticker: CustomizationMapper.stickerFromSpec(c.sticker),
        activeTemplateId: c.activeTemplateId,
        templateGradient: null,
        templateCenterIconBytes: null,
      );
    } finally {
      _suppressPush = false;
    }
  }

  /// 500ms debounce 후 현재 state 를 JSON payload 로 저장.
  /// taskId 가 없거나 복원 중이면 no-op.
  void _schedulePush() {
    if (_suppressPush) return;
    if (_currentTaskId == null) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _pushNow);
  }

  Future<void> _pushNow() async {
    final id = _currentTaskId;
    if (id == null) return;
    try {
      final c = CustomizationMapper.fromState(state);
      await _ref.read(updateQrTaskCustomizationUseCaseProvider)(id, c);
    } catch (_) {
      // best-effort: 다음 변경 시 재시도됨
    }
  }

  @override
  void dispose() {
    if (_debounceTimer?.isActive == true) {
      _debounceTimer?.cancel();
      // 마지막 변경분 best-effort flush (ref 가 유효할 때만 동작)
      // ignore: discarded_futures
      _pushNow();
    }
    super.dispose();
  }

  void setCapturedImage(Uint8List bytes) {
    state = state.copyWith(capturedImage: bytes);
  }

  void setQrColor(Color color) {
    // 색상 직접 변경 시 템플릿 그라디언트 해제 (마지막 선택 우선)
    state = state.copyWith(
      qrColor: color,
      templateGradient: null,
      activeTemplateId: null,
    );
    _schedulePush();
  }

  void setPrintSizeCm(double sizeCm) {
    state = state.copyWith(printSizeCm: sizeCm);
    _schedulePush();
  }

  void setRoundFactor(double factor) {
    state = state.copyWith(roundFactor: factor);
    _schedulePush();
  }

  void setEyeOuter(QrEyeOuter outer) {
    state = state.copyWith(eyeOuter: outer, randomEyeSeed: null);
    _schedulePush();
  }

  void setEyeInner(QrEyeInner inner) {
    state = state.copyWith(eyeInner: inner, randomEyeSeed: null);
    _schedulePush();
  }

  void regenerateEyeSeed() {
    state = state.copyWith(randomEyeSeed: math.Random().nextInt(0xFFFFFF) + 1);
    _schedulePush();
  }

  void clearRandomEye() {
    state = state.copyWith(randomEyeSeed: null);
    _schedulePush();
  }

  void setCustomGradient(QrGradient? gradient) {
    if (gradient != null) {
      // 그라디언트 직접 선택 시 템플릿 그라디언트 해제 (마지막 선택 우선)
      state = state.copyWith(
        customGradient: gradient,
        templateGradient: null,
        activeTemplateId: null,
      );
    } else {
      state = state.copyWith(customGradient: null);
    }
    _schedulePush();
  }

  void setTagType(String? tagType) {
    state = state.copyWith(tagType: tagType);
  }

  void setEmbedIcon(bool embed) {
    state = state.copyWith(embedIcon: embed);
    _schedulePush();
  }

  void setDefaultIconBytes(Uint8List bytes) {
    // defaultIconBytes 는 재생성 가능 (tagType 기반 머티리얼 아이콘)
    // → JSON 저장 대상 아님, _schedulePush 호출 안 함
    state = state.copyWith(defaultIconBytes: bytes);
  }

  void setCenterEmoji(String emoji, Uint8List rendered) {
    state = state.copyWith(centerEmoji: emoji, emojiIconBytes: rendered);
    _schedulePush();
  }

  void clearEmoji() {
    state = state.copyWith(centerEmoji: null, emojiIconBytes: null);
    _schedulePush();
  }

  /// 템플릿 적용: 스타일 필드 일괄 갱신
  void applyTemplate(QrTemplate template, {Uint8List? centerIconBytes}) {
    final style = template.style;
    state = state.copyWith(
      activeTemplateId: template.id,
      roundFactor: template.roundFactor ?? 0.0,
      qrColor: style.foreground.solidColor ?? const Color(0xFF000000),
      templateGradient: style.foreground.gradient,
      // 기존 커스텀 그라디언트 초기화 (템플릿이 우선)
      customGradient: null,
      embedIcon: style.centerIcon.type != 'none',
      templateCenterIconBytes: centerIconBytes,
      centerEmoji: null,
      emojiIconBytes: null,
    );
    _schedulePush();
  }

  // ── 레이어 에디터 setter ───────────────────────────────────────────────────

  void setQuietZoneColor(Color color) {
    state = state.copyWith(quietZoneColor: color);
    _schedulePush();
  }

  void setSticker(StickerConfig config) {
    state = state.copyWith(sticker: config);
    _schedulePush();
  }

  void setDotStyle(QrDotStyle style) {
    state = state.copyWith(dotStyle: style);
    _schedulePush();
  }

  /// 나의 템플릿 일괄 적용 (모든 레이어 설정 복원)
  void applyUserTemplate(UserQrTemplate t) {
    QrGradient? gradient;
    if (t.gradientJson != null) {
      try {
        gradient = QrGradient.fromJson(jsonDecode(t.gradientJson!));
      } catch (_) {}
    }
    state = state.copyWith(
      qrColor: Color(t.qrColorValue),
      customGradient: gradient,
      roundFactor: t.roundFactor,
      dotStyle: QrDotStyle.values[t.dotStyleIndex.clamp(0, QrDotStyle.values.length - 1)],
      eyeOuter: QrEyeOuter.values[t.eyeOuterIndex.clamp(0, QrEyeOuter.values.length - 1)],
      eyeInner: QrEyeInner.values[t.eyeInnerIndex.clamp(0, QrEyeInner.values.length - 1)],
      randomEyeSeed: t.randomEyeSeed,
      quietZoneColor: Color(t.quietZoneColorValue),
      sticker: StickerConfig(
        logoPosition: LogoPosition.values[t.logoPositionIndex],
        logoBackground: LogoBackground.values[t.logoBackgroundIndex],
        topText: t.topTextContent != null
            ? StickerText(
                content: t.topTextContent!,
                color: Color(t.topTextColorValue ?? 0xFF000000),
                fontFamily: t.topTextFont ?? 'sans-serif',
                fontSize: t.topTextSize ?? 14,
              )
            : null,
        bottomText: t.bottomTextContent != null
            ? StickerText(
                content: t.bottomTextContent!,
                color: Color(t.bottomTextColorValue ?? 0xFF000000),
                fontFamily: t.bottomTextFont ?? 'sans-serif',
                fontSize: t.bottomTextSize ?? 14,
              )
            : null,
      ),
      activeTemplateId: null,
      templateGradient: null,
      templateCenterIconBytes: null,
    );
    _schedulePush();
  }

  /// 템플릿 해제 (커스텀 설정 모드로 복귀)
  void clearTemplate() {
    state = state.copyWith(
      activeTemplateId: null,
      templateGradient: null,
      templateCenterIconBytes: null,
    );
    _schedulePush();
  }

  Future<void> saveToGallery(String appName) async {
    if (state.capturedImage == null) return;
    state = state.copyWith(saveStatus: QrActionStatus.loading);
    final result = await _ref
        .read(saveQrToGalleryUseCaseProvider)(state.capturedImage!, appName);
    result.fold(
      (success) => state = state.copyWith(
        saveStatus: success ? QrActionStatus.success : QrActionStatus.error,
        errorMessage: success ? null : '이미지 저장에 실패했습니다.',
      ),
      (_) => state = state.copyWith(
        saveStatus: QrActionStatus.error,
        errorMessage: '이미지 저장에 실패했습니다.',
      ),
    );
  }

  Future<void> shareImage(String appName) async {
    if (state.capturedImage == null) return;
    state = state.copyWith(shareStatus: QrActionStatus.loading);
    final result = await _ref
        .read(shareQrImageUseCaseProvider)(state.capturedImage!, appName);
    result.fold(
      (_) => state = state.copyWith(shareStatus: QrActionStatus.success),
      (_) => state = state.copyWith(shareStatus: QrActionStatus.error),
    );
  }

  Future<void> printQrCode(String appName, {double? sizeCm}) async {
    if (state.capturedImage == null) return;
    state = state.copyWith(printStatus: QrActionStatus.loading);
    final result = await _ref.read(printQrCodeUseCaseProvider)(
      imageBytes: state.capturedImage!,
      appName: appName,
      sizeCm: sizeCm ?? state.printSizeCm,
    );
    result.fold(
      (_) => state = state.copyWith(printStatus: QrActionStatus.success),
      (_) => state = state.copyWith(
        printStatus: QrActionStatus.error,
        errorMessage: '인쇄에 실패했습니다. 프린터 연결을 확인해주세요.',
      ),
    );
  }
}

final qrResultProvider =
    StateNotifierProvider.autoDispose<QrResultNotifier, QrResultState>(
  (ref) => QrResultNotifier(ref),
);
