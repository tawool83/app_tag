library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/entities/qr_dot_style.dart';
import '../domain/entities/qr_shape_params.dart';
import '../domain/entities/user_shape_preset.dart';
import '../data/datasources/local_user_shape_preset_datasource.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/polar_polygon.dart';
import '../utils/superellipse.dart';
import '../domain/entities/qr_eye_shapes.dart';
import '../domain/entities/qr_preview_mode.dart';
import '../qr_result_provider.dart' show qrResultProvider, shapePreviewModeProvider;

// ── 파트 분리: qr_shape_tab/ 하위로 이동한 내부 위젯/헬퍼들 ─────────────────
part 'qr_shape_tab/editor_type.dart';
part 'qr_shape_tab/shared.dart';
part 'qr_shape_tab/dot_preset_row.dart';
part 'qr_shape_tab/eye_row.dart';
part 'qr_shape_tab/dot_editor.dart';
part 'qr_shape_tab/eye_editor.dart';

/// [모양] 탭: 도트 + 눈 프리셋 행 + "+" 편집기.
class QrShapeTab extends ConsumerStatefulWidget {
  final ValueChanged<QrEyeOuter> onEyeOuterChanged;
  final ValueChanged<QrEyeInner> onEyeInnerChanged;
  final ValueChanged<bool>? onEditorModeChanged;

  const QrShapeTab({
    super.key,
    required this.onEyeOuterChanged,
    required this.onEyeInnerChanged,
    this.onEditorModeChanged,
  });

  @override
  ConsumerState<QrShapeTab> createState() => QrShapeTabState();
}

class QrShapeTabState extends ConsumerState<QrShapeTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// 현재 열린 편집기 (null = 닫힘).
  _EditorType? _activeEditor;

  // 편집기 임시 파라미터
  DotShapeParams _editDot = const DotShapeParams();
  EyeShapeParams _editEye = const EyeShapeParams();

  // 사용자 프리셋
  LocalUserShapePresetDatasource? _datasource;
  List<UserShapePreset> _dotPresets = [];
  List<UserShapePreset> _eyePresets = [];

  // 현재 선택된 사용자 프리셋 ID (null = 빌트인 또는 미선택)
  String? _selectedDotPresetId;
  String? _selectedEyePresetId;

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
      }
    });
    widget.onEditorModeChanged?.call(true);
  }

  /// 현재 열린 편집기의 l10n 라벨 키를 반환 (null = 편집기 닫힘).
  String? activeEditorLabel(AppLocalizations l10n) => switch (_activeEditor) {
    _EditorType.dot => l10n.labelCustomDot,
    _EditorType.eye => l10n.labelCustomEye,
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

  /// 외부(부모)에서 호출 — AppBar 뒤로가기 시: 현재 편집 값을 항상 자동 저장 후 닫기.
  /// (기존 프리셋 수정/새 프리셋 생성 구분 없이 동일하게 "사용자 모양"에 반영)
  Future<bool> cancelAndCloseEditor() async {
    if (_activeEditor == null) return true;
    if (_editingPresetId != null) {
      await _updateExistingPreset();
    } else {
      await _saveCurrentAsPreset();
    }
    _confirmEditor();
    return true;
  }

  void _confirmEditor() {
    // 편집기 값을 상태에 적용
    final notifier = ref.read(qrResultProvider.notifier);
    switch (_activeEditor!) {
      case _EditorType.dot:
        notifier.setCustomDotParams(_editDot);
      case _EditorType.eye:
        notifier.setCustomEyeParams(_editEye);
    }
    ref.read(shapePreviewModeProvider.notifier).state = ShapePreviewMode.fullQr;
    setState(() { _activeEditor = null; _editingPresetId = null; });
    widget.onEditorModeChanged?.call(false);
  }

  Future<void> _showEyeGridModal(BuildContext context, {required _EyeGridMode mode}) async {
    if (_eyePresets.isEmpty) return;
    final result = await showModalBottomSheet<_EyeGridResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EyeGridModal(
        presets: _eyePresets,
        mode: mode,
        selectedPresetId: _selectedEyePresetId,
      ),
    );
    if (result == null) return;
    switch (result) {
      case _EyeGridDeleteResult(:final deletedIds):
        if (deletedIds.contains(_selectedEyePresetId)) {
          setState(() => _selectedEyePresetId = null);
          ref.read(qrResultProvider.notifier).setCustomEyeParams(null);
        }
        for (final id in deletedIds) {
          await _datasource?.delete(ShapePresetType.eye, id);
        }
        _loadPresets();
      case _EyeGridEditResult(:final preset):
        ref.read(qrResultProvider.notifier).setCustomEyeParams(preset.eyeParams!);
        setState(() => _selectedEyePresetId = preset.id);
        await _datasource?.touchLastUsed(ShapePresetType.eye, preset.id);
        _loadPresets();
        _openEditor(_EditorType.eye, editingId: preset.id);
      case _EyeGridSelectResult(:final preset):
        ref.read(qrResultProvider.notifier).setCustomEyeParams(preset.eyeParams!);
        setState(() => _selectedEyePresetId = preset.id);
        await _datasource?.touchLastUsed(ShapePresetType.eye, preset.id);
        _loadPresets();
    }
  }

  /// 빌트인 눈 모양 선택: customEye 해제 + 프리셋 선택 상태 해제 후 부모 콜백 호출.
  void _onEyeOuterSelected(QrEyeOuter outer) {
    if (_selectedEyePresetId != null || ref.read(qrResultProvider).style.customEyeParams != null) {
      ref.read(qrResultProvider.notifier).setCustomEyeParams(null);
      setState(() => _selectedEyePresetId = null);
    }
    widget.onEyeOuterChanged(outer);
  }

  void _onEyeInnerSelected(QrEyeInner inner) {
    if (_selectedEyePresetId != null || ref.read(qrResultProvider).style.customEyeParams != null) {
      ref.read(qrResultProvider.notifier).setCustomEyeParams(null);
      setState(() => _selectedEyePresetId = null);
    }
    widget.onEyeInnerChanged(inner);
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
        final existing = _eyePresets.where((p) => p.id == _editingPresetId).firstOrNull;
        if (existing != null) {
          final updated = UserShapePreset(
            id: existing.id, name: existing.name, type: existing.type,
            createdAt: existing.createdAt, lastUsedAt: DateTime.now(),
            version: existing.version, eyeParams: _editEye,
          );
          await _datasource!.save(updated);
          setState(() => _selectedEyePresetId = existing.id);
          _loadPresets();
        }
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

    // 눈: 동일 파라미터가 이미 있으면 기존 프리셋 선택
    if (_activeEditor == _EditorType.eye) {
      final existing = _eyePresets.where((p) => p.eyeParams == _editEye).firstOrNull;
      if (existing != null) {
        setState(() => _selectedEyePresetId = existing.id);
        await _datasource!.touchLastUsed(ShapePresetType.eye, existing.id);
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
        setState(() => _selectedEyePresetId = id);
    }
    await _datasource!.save(preset);
    _loadPresets();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 요구
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
          _DotBuiltinRow(
            selectedBuiltinStyle: (_selectedDotPresetId == null && state.style.customDotParams == null)
                ? state.style.dotStyle
                : null,
            onBuiltinSelect: (style) {
              setState(() => _selectedDotPresetId = null);
              ref.read(qrResultProvider.notifier).setDotStyle(style);
            },
          ),
          const SizedBox(height: 8),
          _DotUserPresetRow(
            selectedPresetId: _selectedDotPresetId,
            userPresets: _dotPresets,
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
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // ② 눈 모양 — 외곽 (사용자 눈/랜덤이 활성화되면 dim)
          _sectionLabel(l10n.labelEyeOuter),
          const SizedBox(height: 10),
          _OuterShapeRow(
            selected: state.style.eyeOuter,
            dimmed: isRandom || state.style.customEyeParams != null,
            onSelected: _onEyeOuterSelected,
          ),
          const SizedBox(height: 14),

          // ③ 눈 모양 — 내부 (사용자 눈/랜덤이 활성화되면 dim)
          _sectionLabel(l10n.labelEyeInner),
          const SizedBox(height: 10),
          _InnerShapeRow(
            selected: state.style.eyeInner,
            dimmed: isRandom || state.style.customEyeParams != null,
            onSelected: _onEyeInnerSelected,
          ),
          const SizedBox(height: 14),

          // ④ 사용자 눈 모양 (빌트인/랜덤이 활성화되면 dim)
          Row(
            children: [
              Expanded(child: _sectionLabel(l10n.labelCustomEye)),
              if (_eyePresets.isNotEmpty)
                GestureDetector(
                  onTap: () => _showEyeGridModal(context, mode: _EyeGridMode.delete),
                  child: Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade600),
                ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: _CustomEyeRow(
              key: ValueKey(_eyePresets.map((p) => p.id).join(',')),
              selectedPresetId: _selectedEyePresetId,
              dimmed: isRandom || state.style.customEyeParams == null,
              presets: _eyePresets,
              onAdd: () => _openEditor(_EditorType.eye),
              onUserSelect: (p) async {
                setState(() => _selectedEyePresetId = p.id);
                ref.read(qrResultProvider.notifier).setCustomEyeParams(p.eyeParams!);
                await _datasource?.touchLastUsed(ShapePresetType.eye, p.id);
                _delayedReloadPresets();
              },
              onUserLongPress: (p) async {
                ref.read(qrResultProvider.notifier).setCustomEyeParams(p.eyeParams!);
                setState(() => _selectedEyePresetId = p.id);
                await _datasource?.touchLastUsed(ShapePresetType.eye, p.id);
                _loadPresets();
                _openEditor(_EditorType.eye, editingId: p.id);
              },
              onShowAll: () => _showEyeGridModal(context, mode: _EyeGridMode.view),
            ),
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
