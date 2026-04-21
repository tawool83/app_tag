library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/error/result.dart';
import 'domain/entities/qr_animation_params.dart';
import 'domain/entities/qr_boundary_params.dart';
import 'domain/entities/qr_dot_style.dart';
import 'domain/entities/qr_shape_params.dart';
import 'domain/entities/logo_source.dart' show LogoType;
import 'domain/entities/qr_template.dart';
import 'domain/entities/sticker_config.dart';
import 'data/services/qr_service.dart';
import '../qr_task/domain/entities/qr_customization.dart';
import '../qr_task/presentation/providers/qr_task_providers.dart';
import 'domain/entities/user_qr_template.dart';
import 'presentation/providers/qr_result_providers.dart';
import 'domain/entities/qr_preview_mode.dart';
import 'domain/state/qr_action_state.dart';
import 'domain/state/qr_logo_state.dart';
import 'domain/state/qr_meta_state.dart';
import 'domain/state/qr_style_state.dart';
import 'domain/state/qr_template_state.dart';
import 'utils/customization_mapper.dart';

// ── 파트 분리: notifier/ 하위 mixin 들 ──────────────────────────────────────
part 'notifier/action_setters.dart';
part 'notifier/style_setters.dart';
part 'notifier/logo_setters.dart';
part 'notifier/template_setters.dart';
part 'notifier/meta_setters.dart';

final qrServiceProvider = Provider<QrService>((ref) => QrService());

/// 현재 미리보기 모드. 슬라이더 onChanged 시 dedicated*, onChangeEnd 시 fullQr.
final shapePreviewModeProvider = StateProvider<ShapePreviewMode>(
  (_) => ShapePreviewMode.fullQr,
);

class QrResultState {
  // ── Composite sub-states (single source of truth) ─────────────────────────
  final QrActionState action;
  final QrStyleState style;
  final QrLogoState logo;
  final QrTemplateState template;
  final QrMetaState meta;
  final StickerConfig sticker;

  const QrResultState({
    this.action = const QrActionState(),
    this.style = const QrStyleState(),
    this.logo = const QrLogoState(),
    this.template = const QrTemplateState(),
    this.meta = const QrMetaState(),
    this.sticker = const StickerConfig(),
  });

  QrResultState copyWith({
    QrActionState? action,
    QrStyleState? style,
    QrLogoState? logo,
    QrTemplateState? template,
    QrMetaState? meta,
    StickerConfig? sticker,
  }) =>
      QrResultState(
        action: action ?? this.action,
        style: style ?? this.style,
        logo: logo ?? this.logo,
        template: template ?? this.template,
        meta: meta ?? this.meta,
        sticker: sticker ?? this.sticker,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrResultState &&
          other.action == action &&
          other.style == style &&
          other.logo == logo &&
          other.template == template &&
          other.meta == meta &&
          other.sticker == sticker;

  @override
  int get hashCode => Object.hash(action, style, logo, template, meta, sticker);
}

/// QR 결과 화면의 상태 Notifier.
///
/// 라이프사이클 / 영속(loadFromCustomization, debounced push, dispose)만 본체에
/// 유지하고, 40+ setter 는 관심사별 5개 mixin 으로 분리:
/// - [_ActionSetters] — capture/save/share/print
/// - [_StyleSetters]  — color/dot/eye/boundary/animation/quietZone
/// - [_LogoSetters]   — embed/emoji/logo-image/logo-text/assetId
/// - [_TemplateSetters] — apply/clear template
/// - [_MetaSetters]   — printSize/tagType/editorMode/sticker
class QrResultNotifier extends StateNotifier<QrResultState>
    with
        _ActionSetters,
        _StyleSetters,
        _LogoSetters,
        _TemplateSetters,
        _MetaSetters {
  @override
  final Ref _ref;

  /// 현재 편집 중인 QrTask 의 id. null 이면 아직 발급 전 (저장 안 함).
  String? _currentTaskId;
  Timer? _debounceTimer;

  /// `loadFromCustomization` 등 일괄 복원 시 setter 가 debounced save 를
  /// 트리거하지 않도록 막는 플래그.
  bool _suppressPush = false;
  bool _disposed = false;

  QrResultNotifier(this._ref) : super(const QrResultState());

  String? get currentTaskId => _currentTaskId;

  /// QR 화면 진입 시 1회 호출 — 이후 setter 들이 이 task 로 저장.
  void setCurrentTaskId(String id) {
    _currentTaskId = id;
  }

  /// 히스토리에서 진입 시 사용. 모든 customization 필드를 일괄 복원하며
  /// 복원 중에는 자동저장을 막는다.
  ///
  /// I3 fix: 복원된 sticker 에 logoAssetId 는 있지만 logoAssetPngBytes 가 null 인 경우
  /// (라이브러리 로고는 메모리 전용 캐시이므로 영속화되지 않음) → 비동기로
  /// `SelectLogoAssetUseCase` 를 재호출하여 PNG 를 재래스터화한다.
  void loadFromCustomization(QrCustomization c) {
    _suppressPush = true;
    try {
      state = state.copyWith(
        style: state.style.copyWith(
          qrColor: CustomizationMapper.colorFromArgb(c.qrColorArgb),
          customGradient: CustomizationMapper.gradientFromData(c.gradient),
          roundFactor: c.roundFactor,
          eyeOuter: CustomizationMapper.eyeOuterFromName(c.eyeOuter),
          eyeInner: CustomizationMapper.eyeInnerFromName(c.eyeInner),
          randomEyeSeed: c.randomEyeSeed,
          quietZoneColor: CustomizationMapper.colorFromArgb(c.quietZoneColorArgb),
          dotStyle: CustomizationMapper.dotStyleFromName(c.dotStyle),
          customDotParams: CustomizationMapper.dotParamsFromJson(c.customDotParams),
          customEyeParams: CustomizationMapper.eyeParamsFromJson(c.customEyeParams),
          boundaryParams: CustomizationMapper.boundaryParamsFromJson(c.boundaryParams),
          animationParams: CustomizationMapper.animationParamsFromJson(c.animationParams),
        ),
        logo: state.logo.copyWith(
          embedIcon: c.embedIcon,
          centerEmoji: c.centerEmoji,
          emojiIconBytes: CustomizationMapper.bytesFromBase64(c.centerIconBase64),
        ),
        meta: state.meta.copyWith(printSizeCm: c.printSizeCm),
        sticker: CustomizationMapper.stickerFromSpec(c.sticker),
        template: QrTemplateState(activeTemplateId: c.activeTemplateId),
      );
    } finally {
      _suppressPush = false;
    }
    // I3: 라이브러리 로고 PNG 는 영속 대상 아님 — assetId 로부터 재래스터화
    _rehydrateLogoAssetIfNeeded();
  }

  /// 복원된 sticker.logoAssetId 로부터 PNG 를 재래스터화하여 메모리 캐시에 주입.
  /// 이미 bytes 가 있거나 assetId 가 없으면 no-op.
  Future<void> _rehydrateLogoAssetIfNeeded() async {
    final sticker = state.sticker;
    if (sticker.logoAssetId == null) return;
    if (sticker.logoAssetPngBytes != null) return;

    final parts = sticker.logoAssetId!.split('/');
    if (parts.length != 2) return;

    final useCase = _ref.read(selectLogoAssetUseCaseProvider);
    final res = await useCase(category: parts[0], iconId: parts[1]);
    if (res is Success) {
      final pngBytes = (res as Success).value.pngBytes as Uint8List;
      // 저장 트리거 없이 메모리 캐시만 주입
      _suppressPush = true;
      try {
        state = state.copyWith(
          sticker: state.sticker.copyWith(logoAssetPngBytes: pngBytes),
        );
      } finally {
        _suppressPush = false;
      }
    }
  }

  /// 500ms debounce 후 현재 state 를 JSON payload 로 저장.
  /// taskId 가 없거나 복원 중이면 no-op.
  @override
  void _schedulePush() {
    if (_suppressPush) return;
    if (_currentTaskId == null) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _pushNow);
  }

  Future<void> _pushNow() async {
    if (_disposed) return;
    final id = _currentTaskId;
    if (id == null) return;
    try {
      final c = CustomizationMapper.fromState(state);
      // 사용자 취소로 이미 dispose 된 경우 ref 접근 금지
      if (_disposed) return;
      await _ref.read(updateQrTaskCustomizationUseCaseProvider)(id, c);
    } catch (_) {
      // best-effort: 다음 변경 시 재시도됨
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    // pending flush 는 의도적으로 포기 — dispose 후 async ref 접근은 안전하지 않음.
    // 이후 재진입 시 복원된 state 가 500ms debounce 로 재push 하므로 데이터 손실 없음.
    _disposed = true;
    super.dispose();
  }
}

final qrResultProvider =
    StateNotifierProvider.autoDispose<QrResultNotifier, QrResultState>(
  (ref) => QrResultNotifier(ref),
);
