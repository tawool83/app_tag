library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/entities/qr_animation_params.dart';
import '../domain/entities/qr_boundary_params.dart';
import '../domain/entities/qr_shape_params.dart';
import '../domain/entities/user_shape_preset.dart';
import '../data/datasources/local_user_shape_preset_datasource.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/polar_polygon.dart';
import '../utils/superellipse.dart';
import '../utils/qr_boundary_clipper.dart';
import '../domain/entities/qr_eye_shapes.dart';
import '../domain/entities/qr_preview_mode.dart';
import '../qr_result_provider.dart' show qrResultProvider, shapePreviewModeProvider;

// ── 파트 분리: qr_shape_tab/ 하위로 이동한 내부 위젯/헬퍼들 ─────────────────
part 'qr_shape_tab/editor_type.dart';
part 'qr_shape_tab/shared.dart';
part 'qr_shape_tab/dot_preset_row.dart';
part 'qr_shape_tab/eye_row.dart';
part 'qr_shape_tab/boundary_preset_row.dart';
part 'qr_shape_tab/animation_preset_row.dart';
part 'qr_shape_tab/dot_editor.dart';
part 'qr_shape_tab/eye_editor.dart';
part 'qr_shape_tab/boundary_editor.dart';
part 'qr_shape_tab/animation_editor.dart';

/// [모양] 탭: 도트 + 눈 + 외곽 + 애니메이션 프리셋 행 + "+" 편집기.
class QrShapeTab extends ConsumerStatefulWidget {
  final ValueChanged<QrEyeOuter> onEyeOuterChanged;
  final ValueChanged<QrEyeInner> onEyeInnerChanged;
  final VoidCallback onRandomEyeRequested;
  final VoidCallback onRandomEyeCleared;
  final ValueChanged<bool>? onEditorModeChanged;

  const QrShapeTab({
    super.key,
    required this.onEyeOuterChanged,
    required this.onEyeInnerChanged,
    required this.onRandomEyeRequested,
    required this.onRandomEyeCleared,
    this.onEditorModeChanged,
  });

  @override
  ConsumerState<QrShapeTab> createState() => QrShapeTabState();
}

class QrShapeTabState extends ConsumerState<QrShapeTab> {
  /// 현재 열린 편집기 (null = 닫힘).
  _EditorType? _activeEditor;

  // 편집기 임시 파라미터
  DotShapeParams _editDot = const DotShapeParams();
  EyeShapeParams _editEye = const EyeShapeParams();
  QrBoundaryParams _editBoundary = const QrBoundaryParams();
  QrAnimationParams _editAnim = const QrAnimationParams();

  // 사용자 프리셋
  LocalUserShapePresetDatasource? _datasource;
  List<UserShapePreset> _dotPresets = [];
  List<UserShapePreset> _eyePresets = [];
  List<UserShapePreset> _boundaryPresets = [];
  List<UserShapePreset> _animPresets = [];

  // 현재 선택된 사용자 프리셋 ID (null = 빌트인 또는 미선택)
  String? _selectedDotPresetId;

  // 편집 중인 기존 프리셋 ID (null = 새로 만들기, non-null = 기존 수정)
  String? _editingPresetId;

  // 프리셋 재정렬 지연 타이머
  Timer? _reorderTimer;

  @override
  void initState() {
    super.initState();
    _initDatasource();
  }

  @override
  void dispose() {
    _reorderTimer?.cancel();
    super.dispose();
  }

  Future<void> _initDatasource() async {
    _datasource = await LocalUserShapePresetDatasource.init();
    _loadPresets();
  }

  void _loadPresets() {
    if (_datasource == null) return;
    setState(() {
      _dotPresets = _datasource!.readAll(ShapePresetType.dot);
      _eyePresets = _datasource!.readAll(ShapePresetType.eye);
      _boundaryPresets = _datasource!.readAll(ShapePresetType.boundary);
      _animPresets = _datasource!.readAll(ShapePresetType.animation);
    });
  }

  /// 선택 하이라이트를 먼저 보여주고, 500ms 뒤에 재정렬.
  void _delayedReloadPresets() {
    _reorderTimer?.cancel();
    _reorderTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) _loadPresets();
    });
  }

  void _openEditor(_EditorType type, {String? editingId}) {
    final state = ref.read(qrResultProvider);
    setState(() {
      _activeEditor = type;
      _editingPresetId = editingId;
      switch (type) {
        case _EditorType.dot:
          _editDot = state.style.customDotParams ??
              const DotShapeParams(vertices: 5, innerRadius: 0.5);
        case _EditorType.eye:
          _editEye = state.style.customEyeParams ?? const EyeShapeParams();
        case _EditorType.boundary:
          _editBoundary = state.style.boundaryParams;
        case _EditorType.animation:
          _editAnim = state.style.animationParams;
      }
    });
    widget.onEditorModeChanged?.call(true);
  }

  /// 현재 열린 편집기의 l10n 라벨 키를 반환 (null = 편집기 닫힘).
  String? activeEditorLabel(AppLocalizations l10n) => switch (_activeEditor) {
    _EditorType.dot => l10n.labelCustomDot,
    _EditorType.eye => l10n.labelCustomEye,
    _EditorType.boundary => l10n.labelCustomBoundary,
    _EditorType.animation => l10n.labelCustomAnimation,
    null => null,
  };

  /// 외부(부모)에서 호출 — 저장 버튼 또는 탭 전환 시 확인 처리용.
  Future<void> confirmAndCloseEditor() async {
    if (_activeEditor == null) return;
    if (_editingPresetId != null) {
      await _updateExistingPreset();
    } else {
      await _saveCurrentAsPreset();
    }
    _confirmEditor();
  }

  /// 외부(부모)에서 호출 — AppBar 뒤로가기 시:
  /// - 기존 프리셋 수정 중: 자동 저장 후 닫기
  /// - 새 프리셋 생성 중: 저장/취소 다이얼로그 표시
  /// Returns true if editor was closed, false if user chose to stay.
  Future<bool> cancelAndCloseEditor() async {
    if (_activeEditor == null) return true;

    // 기존 프리셋 수정 모드: 자동 저장
    if (_editingPresetId != null) {
      await _updateExistingPreset();
      _confirmEditor();
      return true;
    }

    // 새 프리셋 생성 모드: 저장/취소 확인
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.actionSave),
        content: Text(l10n.dialogSaveTemplateTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );

    if (result == true) {
      await _saveCurrentAsPreset();
      _confirmEditor();
      return true;
    } else if (result == false) {
      _cancelEditor();
      return true;
    }
    // result == null (dismiss): 에디터 유지
    return false;
  }

  void _confirmEditor() {
    // 편집기 값을 상태에 적용
    final notifier = ref.read(qrResultProvider.notifier);
    switch (_activeEditor!) {
      case _EditorType.dot:
        notifier.setCustomDotParams(_editDot);
      case _EditorType.eye:
        notifier.setCustomEyeParams(_editEye);
      case _EditorType.boundary:
        notifier.setBoundaryParams(_editBoundary);
      case _EditorType.animation:
        notifier.setAnimationParams(_editAnim);
    }
    ref.read(shapePreviewModeProvider.notifier).state = ShapePreviewMode.fullQr;
    setState(() { _activeEditor = null; _editingPresetId = null; });
    widget.onEditorModeChanged?.call(false);
  }

  void _cancelEditor() {
    ref.read(shapePreviewModeProvider.notifier).state = ShapePreviewMode.fullQr;
    setState(() { _activeEditor = null; _editingPresetId = null; });
    widget.onEditorModeChanged?.call(false);
  }

  Future<void> _showDotGridModal(BuildContext context, {required _DotGridMode mode}) async {
    if (_dotPresets.isEmpty) return;
    final result = await showModalBottomSheet<_DotGridResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _DotGridModal(
        presets: _dotPresets,
        mode: mode,
        selectedPresetId: _selectedDotPresetId,
      ),
    );
    if (result == null) return;
    switch (result) {
      case _DotGridDeleteResult(:final deletedIds):
        if (deletedIds.contains(_selectedDotPresetId)) {
          setState(() => _selectedDotPresetId = null);
        }
        for (final id in deletedIds) {
          await _datasource?.delete(ShapePresetType.dot, id);
        }
        _loadPresets();
      case _DotGridEditResult(:final preset):
        // 선택한 프리셋의 파라미터로 편집기 진입 (기존 수정 모드)
        ref.read(qrResultProvider.notifier).setCustomDotParams(preset.dotParams!);
        setState(() => _selectedDotPresetId = preset.id);
        await _datasource?.touchLastUsed(ShapePresetType.dot, preset.id);
        _loadPresets();
        _openEditor(_EditorType.dot, editingId: preset.id);
      case _DotGridSelectResult(:final preset):
        ref.read(qrResultProvider.notifier).setCustomDotParams(preset.dotParams!);
        setState(() => _selectedDotPresetId = preset.id);
        await _datasource?.touchLastUsed(ShapePresetType.dot, preset.id);
        _loadPresets();
    }
  }

  /// 기존 프리셋을 현재 편집 값으로 덮어쓰기 (수정 모드용).
  Future<void> _updateExistingPreset() async {
    if (_datasource == null || _editingPresetId == null) return;

    switch (_activeEditor!) {
      case _EditorType.dot:
        final existing = _dotPresets.where((p) => p.id == _editingPresetId).firstOrNull;
        if (existing != null) {
          final updated = UserShapePreset(
            id: existing.id, name: existing.name, type: existing.type,
            createdAt: existing.createdAt, lastUsedAt: DateTime.now(),
            version: existing.version, dotParams: _editDot,
          );
          await _datasource!.save(updated);
          setState(() => _selectedDotPresetId = existing.id);
          _loadPresets();
        }
      case _EditorType.eye:
      case _EditorType.boundary:
      case _EditorType.animation:
        break; // 다른 타입은 아직 미지원
    }
  }

  Future<void> _saveCurrentAsPreset() async {
    if (_datasource == null || _activeEditor == null) return;

    // 도트: 동일 파라미터가 이미 있으면 새로 만들지 않고 기존 프리셋 선택
    if (_activeEditor == _EditorType.dot) {
      final existing = _dotPresets.where((p) => p.dotParams == _editDot).firstOrNull;
      if (existing != null) {
        setState(() => _selectedDotPresetId = existing.id);
        await _datasource!.touchLastUsed(ShapePresetType.dot, existing.id);
        _loadPresets();
        return;
      }
    }

    final id = const Uuid().v4();
    final now = DateTime.now();
    UserShapePreset preset;
    switch (_activeEditor!) {
      case _EditorType.dot:
        preset = UserShapePreset(
          id: id, name: id.substring(0, 8), type: ShapePresetType.dot,
          createdAt: now, dotParams: _editDot,
        );
        setState(() => _selectedDotPresetId = id);
      case _EditorType.eye:
        preset = UserShapePreset(
          id: id, name: id.substring(0, 8), type: ShapePresetType.eye,
          createdAt: now, eyeParams: _editEye,
        );
      case _EditorType.boundary:
        preset = UserShapePreset(
          id: id, name: id.substring(0, 8), type: ShapePresetType.boundary,
          createdAt: now, boundaryParams: _editBoundary,
        );
      case _EditorType.animation:
        preset = UserShapePreset(
          id: id, name: id.substring(0, 8), type: ShapePresetType.animation,
          createdAt: now, animParams: _editAnim,
        );
    }
    await _datasource!.save(preset);
    _loadPresets();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qrResultProvider);
    final isRandom = state.style.randomEyeSeed != null;
    final l10n = AppLocalizations.of(context)!;

    if (_activeEditor != null) {
      return _buildEditor(l10n);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ① 도트 모양: [■][●] | [+][사용자...][...] [삭제]
          Row(
            children: [
              Expanded(child: _sectionLabel(l10n.labelDotShape)),
              if (_dotPresets.isNotEmpty)
                GestureDetector(
                  onTap: () => _showDotGridModal(context, mode: _DotGridMode.delete),
                  child: Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade600),
                ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: _DotPresetRow(
              key: ValueKey(_dotPresets.map((p) => p.id).join(',')),
              selectedPresetId: _selectedDotPresetId,
              selectedBuiltinParams: _selectedDotPresetId == null ? state.style.customDotParams : null,
              userPresets: _dotPresets,
              onBuiltinSelect: (params) {
                setState(() => _selectedDotPresetId = null);
                ref.read(qrResultProvider.notifier).setCustomDotParams(params);
              },
              onAdd: () => _openEditor(_EditorType.dot),
              onUserSelect: (p) async {
                setState(() => _selectedDotPresetId = p.id);
                ref.read(qrResultProvider.notifier).setCustomDotParams(p.dotParams!);
                await _datasource?.touchLastUsed(ShapePresetType.dot, p.id);
                _delayedReloadPresets();
              },
              onUserLongPress: (p) async {
                ref.read(qrResultProvider.notifier).setCustomDotParams(p.dotParams!);
                setState(() => _selectedDotPresetId = p.id);
                await _datasource?.touchLastUsed(ShapePresetType.dot, p.id);
                _loadPresets();
                _openEditor(_EditorType.dot, editingId: p.id);
              },
              onShowAll: () => _showDotGridModal(context, mode: _DotGridMode.view),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // ② 눈 모양 — 외곽
          _sectionLabel(l10n.labelEyeOuter),
          const SizedBox(height: 10),
          _OuterShapeRow(
            selected: isRandom ? null : state.style.eyeOuter,
            onSelected: widget.onEyeOuterChanged,
          ),
          const SizedBox(height: 14),

          // ③ 눈 모양 — 내부
          _sectionLabel(l10n.labelEyeInner),
          const SizedBox(height: 10),
          _InnerShapeRow(
            selected: isRandom ? null : state.style.eyeInner,
            onSelected: widget.onEyeInnerChanged,
          ),
          const SizedBox(height: 8),
          _CustomEyeRow(
            presets: _eyePresets,
            onAdd: () => _openEditor(_EditorType.eye),
            onSelect: (p) {
              ref.read(qrResultProvider.notifier).setCustomEyeParams(p.eyeParams!);
            },
            onDelete: (p) async {
              await _datasource?.delete(ShapePresetType.eye, p.id);
              _loadPresets();
            },
          ),
          const SizedBox(height: 16),

          // ④ 랜덤 눈 버튼
          _RandomEyeButton(
            isActive: isRandom,
            onGenerate: widget.onRandomEyeRequested,
            onClear: widget.onRandomEyeCleared,
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // ⑤ QR 전체 외곽 (Boundary)
          _sectionLabel(l10n.labelBoundaryShape),
          const SizedBox(height: 10),
          _BoundaryPresetRow(
            selected: state.style.boundaryParams.type,
            onSelected: (type) {
              final preset = switch (type) {
                QrBoundaryType.square => const QrBoundaryParams(),
                QrBoundaryType.circle => QrBoundaryParams.circle,
                QrBoundaryType.superellipse => QrBoundaryParams.squircle,
                QrBoundaryType.star => QrBoundaryParams.star5,
                QrBoundaryType.heart => QrBoundaryParams.heart,
                QrBoundaryType.hexagon => QrBoundaryParams.hexagon,
                QrBoundaryType.custom => QrBoundaryParams.squircle,
              };
              ref.read(qrResultProvider.notifier).setBoundaryParams(preset);
            },
            presets: _boundaryPresets,
            onAdd: () => _openEditor(_EditorType.boundary),
            onPresetSelect: (p) {
              ref.read(qrResultProvider.notifier).setBoundaryParams(p.boundaryParams!);
            },
            onPresetDelete: (p) async {
              await _datasource?.delete(ShapePresetType.boundary, p.id);
              _loadPresets();
            },
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // ⑥ 애니메이션
          _sectionLabel(l10n.labelAnimation),
          const SizedBox(height: 10),
          _AnimationPresetRow(
            selected: state.style.animationParams.type,
            onSelected: (type) {
              final preset = switch (type) {
                QrAnimationType.none => const QrAnimationParams(),
                QrAnimationType.wave => QrAnimationParams.wave,
                QrAnimationType.rainbow => QrAnimationParams.rainbow,
                QrAnimationType.pulse => QrAnimationParams.pulse,
                QrAnimationType.sequential => QrAnimationParams.sequential,
                QrAnimationType.rotationWave => QrAnimationParams.rotationWave,
              };
              ref.read(qrResultProvider.notifier).setAnimationParams(preset);
            },
            presets: _animPresets,
            onAdd: () => _openEditor(_EditorType.animation),
            onPresetSelect: (p) {
              ref.read(qrResultProvider.notifier).setAnimationParams(p.animParams!);
            },
            onPresetDelete: (p) async {
              await _datasource?.delete(ShapePresetType.animation, p.id);
              _loadPresets();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEditor(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 제목 (도트 편집기는 제목 없음)
          if (_activeEditor != _EditorType.dot) ...[
            Text(
              switch (_activeEditor!) {
                _EditorType.dot => '',
                _EditorType.eye => l10n.labelCustomEye,
                _EditorType.boundary => l10n.labelCustomBoundary,
                _EditorType.animation => l10n.labelCustomAnimation,
              },
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
          ],
          switch (_activeEditor!) {
            _EditorType.dot => _DotEditor(
              params: _editDot,
              onChanged: (p) {
                setState(() => _editDot = p);
                ref.read(qrResultProvider.notifier).setCustomDotParams(p);
              },
              onDragStart: () => ref.read(shapePreviewModeProvider.notifier).state = ShapePreviewMode.dedicatedDot,
              onDragEnd: (p) {
                ref.read(qrResultProvider.notifier).setCustomDotParams(p);
                ref.read(shapePreviewModeProvider.notifier).state = ShapePreviewMode.fullQr;
              },
            ),
            _EditorType.eye => _EyeEditor(
              params: _editEye,
              onChanged: (p) {
                setState(() => _editEye = p);
                ref.read(qrResultProvider.notifier).setCustomEyeParams(p);
              },
              onDragStart: () => ref.read(shapePreviewModeProvider.notifier).state = ShapePreviewMode.dedicatedEye,
              onDragEnd: (p) {
                ref.read(qrResultProvider.notifier).setCustomEyeParams(p);
                ref.read(shapePreviewModeProvider.notifier).state = ShapePreviewMode.fullQr;
              },
            ),
            _EditorType.boundary => _BoundaryEditor(
              params: _editBoundary,
              onChanged: (p) {
                setState(() => _editBoundary = p);
                ref.read(qrResultProvider.notifier).setBoundaryParams(p);
              },
              onDragStart: () => ref.read(shapePreviewModeProvider.notifier).state = ShapePreviewMode.dedicatedBoundary,
              onDragEnd: (p) {
                ref.read(qrResultProvider.notifier).setBoundaryParams(p);
                ref.read(shapePreviewModeProvider.notifier).state = ShapePreviewMode.fullQr;
              },
            ),
            _EditorType.animation => _AnimationEditor(
              params: _editAnim,
              onChanged: (p) {
                setState(() => _editAnim = p);
                // 애니메이션은 항상 전체 QR에서 미리보기
                ref.read(qrResultProvider.notifier).setAnimationParams(p);
              },
            ),
          },
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      );
}
