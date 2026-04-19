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
import '../qr_result_provider.dart'
    show QrEyeOuter, QrEyeInner, qrResultProvider, ShapePreviewMode, shapePreviewModeProvider;

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
          _editDot = state.customDotParams ??
              const DotShapeParams(vertices: 5, innerRadius: 0.5);
        case _EditorType.eye:
          _editEye = state.customEyeParams ?? const EyeShapeParams();
        case _EditorType.boundary:
          _editBoundary = state.boundaryParams;
        case _EditorType.animation:
          _editAnim = state.animationParams;
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
    final isRandom = state.randomEyeSeed != null;
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
              selectedBuiltinParams: _selectedDotPresetId == null ? state.customDotParams : null,
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
            selected: isRandom ? null : state.eyeOuter,
            onSelected: widget.onEyeOuterChanged,
          ),
          const SizedBox(height: 14),

          // ③ 눈 모양 — 내부
          _sectionLabel(l10n.labelEyeInner),
          const SizedBox(height: 10),
          _InnerShapeRow(
            selected: isRandom ? null : state.eyeInner,
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
            selected: state.boundaryParams.type,
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
            selected: state.animationParams.type,
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

enum _EditorType { dot, eye, boundary, animation }

// ── 도트 프리셋 행: [■][●] | [+][user...][...] ──────────────────────────────

class _DotPresetRow extends StatelessWidget {
  final String? selectedPresetId;
  final DotShapeParams? selectedBuiltinParams; // 빌트인 선택용 (presetId == null 일 때만)
  final List<UserShapePreset> userPresets;
  final ValueChanged<DotShapeParams> onBuiltinSelect;
  final VoidCallback onAdd;
  final ValueChanged<UserShapePreset> onUserSelect;
  final ValueChanged<UserShapePreset> onUserLongPress;
  final VoidCallback onShowAll;

  const _DotPresetRow({
    super.key,
    required this.selectedPresetId,
    this.selectedBuiltinParams,
    required this.userPresets,
    required this.onBuiltinSelect,
    required this.onAdd,
    required this.onUserSelect,
    required this.onUserLongPress,
    required this.onShowAll,
  });

  // 빌트인: 네모, 동그라미만
  static const _builtinPresets = <(String, DotShapeParams)>[
    ('■', DotShapeParams.square),
    ('●', DotShapeParams.circle),
  ];

  // 칩/버튼 크기 상수
  static const _chipSize = 48.0;
  static const _gap = 8.0;
  static const _dividerWidth = 17.0; // 1px line + left4 + right12

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          // 고정 영역: 빌트인(2칩) + 구분선 + "+" 버튼
          final fixedWidth = _builtinPresets.length * (_chipSize + _gap)
              + _dividerWidth
              + (_chipSize + _gap); // "+" 버튼
          final remaining = totalWidth - fixedWidth;
          // 사용자 슬롯 수 계산
          final maxSlots = (remaining / (_chipSize + _gap)).floor();
          final needMore = userPresets.length > maxSlots && maxSlots > 0;
          // ··· 자리를 확보해야 하면 인라인은 1칸 줄임
          final inlineCount = needMore
              ? (maxSlots - 1).clamp(0, userPresets.length)
              : maxSlots.clamp(0, userPresets.length);
          final inlinePresets = userPresets.sublist(0, inlineCount);

          return Row(
            children: [
              // 빌트인 프리셋
              ..._builtinPresets.map((entry) {
                final (label, params) = entry;
                final isSelected = selectedPresetId == null && selectedBuiltinParams == params;
                return _DotChip(
                  label: label,
                  isSelected: isSelected,
                  onTap: () => onBuiltinSelect(params),
                );
              }),
              // 구분선
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 12),
                child: Container(width: 1, height: 32, color: Colors.grey.shade300),
              ),
              // "+" 추가 버튼
              Padding(
                padding: const EdgeInsets.only(right: _gap),
                child: GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: _chipSize,
                    height: _chipSize,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.add, size: 24, color: Colors.grey),
                  ),
                ),
              ),
              // 인라인 사용자 프리셋
              ...inlinePresets.map((p) => _PresetChip(
                    preset: p,
                    isSelected: p.id == selectedPresetId,
                    onTap: () => onUserSelect(p),
                    onLongPress: () => onUserLongPress(p),
                  )),
              // ··· 더보기 버튼 (넘칠 때 마지막 슬롯 대체)
              if (needMore)
                Padding(
                  padding: const EdgeInsets.only(right: _gap),
                  child: GestureDetector(
                    onTap: onShowAll,
                    child: Container(
                      width: _chipSize,
                      height: _chipSize,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Center(
                        child: Text('···',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey)),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 도트 칩 (빌트인용)
class _DotChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DotChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 도트 격자 모달 (보기 / 편집 / 삭제 모드) ────────────────────────────────

enum _DotGridMode { view, delete }

sealed class _DotGridResult {}
class _DotGridDeleteResult extends _DotGridResult { final Set<String> deletedIds; _DotGridDeleteResult(this.deletedIds); }
class _DotGridEditResult extends _DotGridResult { final UserShapePreset preset; _DotGridEditResult(this.preset); }
class _DotGridSelectResult extends _DotGridResult { final UserShapePreset preset; _DotGridSelectResult(this.preset); }

class _DotGridModal extends StatefulWidget {
  final List<UserShapePreset> presets;
  final _DotGridMode mode;
  final String? selectedPresetId;

  const _DotGridModal({
    required this.presets,
    required this.mode,
    this.selectedPresetId,
  });

  @override
  State<_DotGridModal> createState() => _DotGridModalState();
}

class _DotGridModalState extends State<_DotGridModal> {
  final _markedForDeletion = <String>{};

  bool _isSelected(UserShapePreset preset) {
    return preset.id == widget.selectedPresetId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDelete = widget.mode == _DotGridMode.delete;
    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.6),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들바
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 격자
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: widget.presets.length,
              itemBuilder: (context, i) {
                final preset = widget.presets[i];
                final isMarked = _markedForDeletion.contains(preset.id);
                final isCurrent = _isSelected(preset);
                return GestureDetector(
                  onTap: () {
                    if (isDelete) {
                      setState(() {
                        if (isMarked) {
                          _markedForDeletion.remove(preset.id);
                        } else {
                          _markedForDeletion.add(preset.id);
                        }
                      });
                    } else {
                      Navigator.pop(context, _DotGridSelectResult(preset));
                    }
                  },
                  onLongPress: isDelete
                      ? null
                      : () => Navigator.pop(context, _DotGridEditResult(preset)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isMarked
                          ? Colors.red.shade50
                          : isCurrent
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isMarked
                            ? Colors.red
                            : isCurrent
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                        width: (isMarked || isCurrent) ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: ImageFiltered(
                            imageFilter: isMarked
                                ? dart_ui.ImageFilter.blur(
                                    sigmaX: 3, sigmaY: 3)
                                : dart_ui.ImageFilter.blur(
                                    sigmaX: 0, sigmaY: 0),
                            child: CustomPaint(
                              size: const Size(32, 32),
                              painter:
                                  _PresetIconPainter(preset: preset),
                            ),
                          ),
                        ),
                        if (isMarked)
                          const Center(
                            child: Icon(Icons.delete_outline,
                                color: Colors.red, size: 24),
                          ),
                        if (isCurrent && !isMarked)
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Icon(Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                                size: 14),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // 삭제 모드: 항상 버튼 표시, 선택 없으면 비활성화
          if (isDelete)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _markedForDeletion.isNotEmpty
                        ? Colors.red
                        : Colors.grey.shade400,
                  ),
                  onPressed: _markedForDeletion.isNotEmpty
                      ? () => Navigator.pop(context, _DotGridDeleteResult(_markedForDeletion))
                      : null,
                  icon: const Icon(Icons.delete, size: 18),
                  label: Text(l10n.actionDeleteCount(_markedForDeletion.length)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 커스텀 눈 프리셋 행 ───────────────────────────────────────────────────────

class _CustomEyeRow extends StatelessWidget {
  final List<UserShapePreset> presets;
  final VoidCallback onAdd;
  final ValueChanged<UserShapePreset> onSelect;
  final ValueChanged<UserShapePreset> onDelete;

  const _CustomEyeRow({
    required this.presets,
    required this.onAdd,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _AddButton(onTap: onAdd),
          ...presets.map((p) => _PresetChip(
                preset: p,
                onTap: () => onSelect(p),
                onLongPress: () => onDelete(p),
              )),
        ],
      ),
    );
  }
}

// ── Boundary 프리셋 행 ──────────────────────────────────────────────────────

class _BoundaryPresetRow extends StatelessWidget {
  final QrBoundaryType selected;
  final ValueChanged<QrBoundaryType> onSelected;
  final List<UserShapePreset> presets;
  final VoidCallback onAdd;
  final ValueChanged<UserShapePreset> onPresetSelect;
  final ValueChanged<UserShapePreset> onPresetDelete;

  const _BoundaryPresetRow({
    required this.selected,
    required this.onSelected,
    required this.presets,
    required this.onAdd,
    required this.onPresetSelect,
    required this.onPresetDelete,
  });

  static const _builtinTypes = [
    QrBoundaryType.square,
    QrBoundaryType.circle,
    QrBoundaryType.superellipse,
    QrBoundaryType.star,
    QrBoundaryType.heart,
    QrBoundaryType.hexagon,
  ];

  static const _icons = {
    QrBoundaryType.square: Icons.crop_square,
    QrBoundaryType.circle: Icons.circle_outlined,
    QrBoundaryType.superellipse: Icons.rounded_corner,
    QrBoundaryType.star: Icons.star_outline,
    QrBoundaryType.heart: Icons.favorite_outline,
    QrBoundaryType.hexagon: Icons.hexagon_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _AddButton(onTap: onAdd),
          ..._builtinTypes.map((type) {
            final isSelected = selected == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ShapeButton(
                isSelected: isSelected,
                dimmed: false,
                onTap: () => onSelected(type),
                tooltip: type.name,
                child: Icon(_icons[type], size: 22,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black87),
              ),
            );
          }),
          ...presets.map((p) => _PresetChip(
                preset: p,
                onTap: () => onPresetSelect(p),
                onLongPress: () => onPresetDelete(p),
              )),
        ],
      ),
    );
  }
}

// ── 애니메이션 프리셋 행 ──────────────────────────────────────────────────────

class _AnimationPresetRow extends StatelessWidget {
  final QrAnimationType selected;
  final ValueChanged<QrAnimationType> onSelected;
  final List<UserShapePreset> presets;
  final VoidCallback onAdd;
  final ValueChanged<UserShapePreset> onPresetSelect;
  final ValueChanged<UserShapePreset> onPresetDelete;

  const _AnimationPresetRow({
    required this.selected,
    required this.onSelected,
    required this.presets,
    required this.onAdd,
    required this.onPresetSelect,
    required this.onPresetDelete,
  });

  static const _labels = {
    QrAnimationType.none: 'Off',
    QrAnimationType.wave: '~',
    QrAnimationType.rainbow: '🌈',
    QrAnimationType.pulse: '♥',
    QrAnimationType.sequential: '►',
    QrAnimationType.rotationWave: '↻',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _AddButton(onTap: onAdd),
          ...QrAnimationType.values.map((type) {
            final isSelected = selected == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ShapeButton(
                isSelected: isSelected,
                dimmed: false,
                onTap: () => onSelected(type),
                tooltip: type.name,
                child: Text(_labels[type] ?? '', style: TextStyle(
                  fontSize: 16,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black87,
                )),
              ),
            );
          }),
          ...presets.map((p) => _PresetChip(
                preset: p,
                onTap: () => onPresetSelect(p),
                onLongPress: () => onPresetDelete(p),
              )),
        ],
      ),
    );
  }
}

// ── "+" 추가 버튼 ────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Icon(Icons.add, size: 24, color: Colors.grey),
        ),
      ),
    );
  }
}

// ── 프리셋 칩 (모양 미리보기 표시) ───────────────────────────────────────────

class _PresetChip extends StatelessWidget {
  final UserShapePreset preset;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PresetChip({
    required this.preset,
    this.isSelected = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: CustomPaint(
                  size: const Size(32, 32),
                  painter: _PresetIconPainter(preset: preset),
                ),
              ),
              if (isSelected)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Icon(Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 프리셋의 모양을 작은 아이콘으로 렌더링.
class _PresetIconPainter extends CustomPainter {
  final UserShapePreset preset;
  const _PresetIconPainter({required this.preset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    if (preset.dotParams != null) {
      final path = PolarPolygon.buildPath(center, radius, preset.dotParams!);
      canvas.drawPath(path, paint);
    } else if (preset.eyeParams != null) {
      final bounds = Rect.fromCenter(center: center, width: size.width * 0.8, height: size.height * 0.8);
      SuperellipsePath.paintEye(canvas, bounds, preset.eyeParams!, paint);
    } else if (preset.boundaryParams != null) {
      final clipPath = QrBoundaryClipper.buildClipPath(size, preset.boundaryParams!);
      if (clipPath != null) {
        canvas.drawPath(clipPath, paint..style = PaintingStyle.stroke..strokeWidth = 1.5);
      } else {
        canvas.drawRect(Offset.zero & size, paint..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
    } else if (preset.animParams != null) {
      // 애니메이션: 타입 아이콘 텍스트
      final tp = TextPainter(
        text: TextSpan(
          text: switch (preset.animParams!.type) {
            QrAnimationType.none => 'Off',
            QrAnimationType.wave => '~',
            QrAnimationType.rainbow => '🌈',
            QrAnimationType.pulse => '♥',
            QrAnimationType.sequential => '►',
            QrAnimationType.rotationWave => '↻',
          },
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
    }
  }

  @override
  bool shouldRepaint(_PresetIconPainter old) => preset != old.preset;
}

// ── 도트 편집기 (듀얼 모드: 대칭/비대칭) ──────────────────────────────────────

class _DotEditor extends StatelessWidget {
  final DotShapeParams params;
  final ValueChanged<DotShapeParams> onChanged;
  final VoidCallback onDragStart;
  final ValueChanged<DotShapeParams> onDragEnd;

  const _DotEditor({
    required this.params,
    required this.onChanged,
    required this.onDragStart,
    required this.onDragEnd,
  });

  // Superformula 프리셋 목록
  static const _sfPresets = <(String, DotShapeParams)>[
    ('●', DotShapeParams.sfCircle),
    ('■', DotShapeParams.sfSquare),
    ('★', DotShapeParams.sfStar),
    ('✿', DotShapeParams.sfFlower),
    ('♥', DotShapeParams.sfHeart),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSymmetric = params.mode == DotShapeMode.symmetric;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── [대칭] / [비대칭] 토글 ──
        Row(
          children: [
            Expanded(
              child: _ModeToggleButton(
                label: l10n.labelSymmetric,
                isSelected: isSymmetric,
                onTap: () => _switchMode(DotShapeMode.symmetric),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ModeToggleButton(
                label: l10n.labelAsymmetric,
                isSelected: !isSymmetric,
                onTap: () => _switchMode(DotShapeMode.asymmetric),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── 모드별 슬라이더 ──
        if (isSymmetric) ..._buildSymmetricSliders(l10n)
        else ..._buildAsymmetricSliders(l10n),

        // ── 공통: 회전 ──
        _SliderRow(
          label: l10n.sliderRotation,
          value: params.rotation,
          min: 0, max: 360,
          valueLabel: '${params.rotation.round()}°',
          onChanged: (v) {
            onDragStart();
            onChanged(params.copyWith(rotation: v));
          },
          onChangeEnd: (v) => onDragEnd(params.copyWith(rotation: v)),
        ),

        // ── 공통: 크기 (QR 인식 범위 내 미세 조정) ──
        _SliderRow(
          label: l10n.sliderDotScale,
          value: params.scale,
          min: 0.8, max: 1.15,
          valueLabel: '${(params.scale * 100).round()}%',
          onChanged: (v) {
            onDragStart();
            onChanged(params.copyWith(scale: v));
          },
          onChangeEnd: (v) => onDragEnd(params.copyWith(scale: v)),
        ),
      ],
    );
  }

  void _switchMode(DotShapeMode mode) {
    if (params.mode == mode) return;
    final newParams = mode == DotShapeMode.symmetric
        ? DotShapeParams(mode: mode, rotation: params.rotation, scale: params.scale)
        : DotShapeParams(
            mode: mode, rotation: params.rotation, scale: params.scale,
            sfM: 5, sfN1: 0.3, sfN2: 0.3, sfN3: 0.3, // 별 기본값
          );
    onChanged(newParams);
    onDragEnd(newParams);
  }

  List<Widget> _buildSymmetricSliders(AppLocalizations l10n) => [
    _SliderRow(
      label: l10n.sliderVertices,
      value: params.vertices.toDouble(),
      min: 3, max: 12, divisions: 9,
      valueLabel: '${params.vertices}',
      onChanged: (v) {
        onDragStart();
        onChanged(params.copyWith(vertices: v.round()));
      },
      onChangeEnd: (v) => onDragEnd(params.copyWith(vertices: v.round())),
    ),
    _SliderRow(
      label: l10n.sliderInnerRadius,
      value: params.innerRadius,
      min: 0, max: 1,
      valueLabel: params.innerRadius.toStringAsFixed(2),
      onChanged: (v) {
        onDragStart();
        onChanged(params.copyWith(innerRadius: v));
      },
      onChangeEnd: (v) => onDragEnd(params.copyWith(innerRadius: v)),
    ),
    _SliderRow(
      label: l10n.sliderRoundness,
      value: params.roundness,
      min: 0, max: 1,
      valueLabel: params.roundness.toStringAsFixed(2),
      onChanged: (v) {
        onDragStart();
        onChanged(params.copyWith(roundness: v));
      },
      onChangeEnd: (v) => onDragEnd(params.copyWith(roundness: v)),
    ),
  ];

  List<Widget> _buildAsymmetricSliders(AppLocalizations l10n) => [
    // Superformula 프리셋 행
    SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _sfPresets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final (label, preset) = _sfPresets[i];
          return GestureDetector(
            onTap: () {
              final p = preset.copyWith(rotation: params.rotation);
              onChanged(p);
              onDragEnd(p);
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(label, style: const TextStyle(fontSize: 20)),
              ),
            ),
          );
        },
      ),
    ),
    const SizedBox(height: 12),
    _SliderRow(
      label: l10n.sliderSfM,
      value: params.sfM,
      min: 0, max: 20,
      valueLabel: params.sfM.toStringAsFixed(1),
      onChanged: (v) {
        onDragStart();
        onChanged(params.copyWith(sfM: v));
      },
      onChangeEnd: (v) => onDragEnd(params.copyWith(sfM: v)),
    ),
    _SliderRow(
      label: l10n.sliderSfN1,
      value: params.sfN1.clamp(0.1, 40),
      min: 0.1, max: 40,
      valueLabel: params.sfN1.toStringAsFixed(1),
      onChanged: (v) {
        onDragStart();
        onChanged(params.copyWith(sfN1: v));
      },
      onChangeEnd: (v) => onDragEnd(params.copyWith(sfN1: v)),
    ),
    _SliderRow(
      label: l10n.sliderSfN2,
      value: params.sfN2.clamp(0.1, 40),
      min: 0.1, max: 40,
      valueLabel: params.sfN2.toStringAsFixed(1),
      onChanged: (v) {
        onDragStart();
        onChanged(params.copyWith(sfN2: v));
      },
      onChangeEnd: (v) => onDragEnd(params.copyWith(sfN2: v)),
    ),
    _SliderRow(
      label: l10n.sliderSfN3,
      value: params.sfN3.clamp(-5, 40),
      min: -5, max: 40,
      valueLabel: params.sfN3.toStringAsFixed(1),
      onChanged: (v) {
        onDragStart();
        onChanged(params.copyWith(sfN3: v));
      },
      onChangeEnd: (v) => onDragEnd(params.copyWith(sfN3: v)),
    ),
    _SliderRow(
      label: l10n.sliderSfA,
      value: params.sfA.clamp(0.5, 2),
      min: 0.5, max: 2,
      valueLabel: params.sfA.toStringAsFixed(2),
      onChanged: (v) {
        onDragStart();
        onChanged(params.copyWith(sfA: v));
      },
      onChangeEnd: (v) => onDragEnd(params.copyWith(sfA: v)),
    ),
    _SliderRow(
      label: l10n.sliderSfB,
      value: params.sfB.clamp(0.5, 2),
      min: 0.5, max: 2,
      valueLabel: params.sfB.toStringAsFixed(2),
      onChanged: (v) {
        onDragStart();
        onChanged(params.copyWith(sfB: v));
      },
      onChangeEnd: (v) => onDragEnd(params.copyWith(sfB: v)),
    ),
  ];
}

/// 대칭/비대칭 토글 버튼.
class _ModeToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

// ── 눈 편집기 (4 슬라이더) ──────────────────────────────────────────────────

class _EyeEditor extends StatelessWidget {
  final EyeShapeParams params;
  final ValueChanged<EyeShapeParams> onChanged;
  final VoidCallback onDragStart;
  final ValueChanged<EyeShapeParams> onDragEnd;

  const _EyeEditor({
    required this.params,
    required this.onChanged,
    required this.onDragStart,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SliderRow(
          label: l10n.sliderOuterN,
          value: params.outerN,
          min: 2, max: 20,
          valueLabel: params.outerN.toStringAsFixed(1),
          onChanged: (v) {
            onDragStart();
            onChanged(params.copyWith(outerN: v));
          },
          onChangeEnd: (v) => onDragEnd(params.copyWith(outerN: v)),
        ),
        _SliderRow(
          label: l10n.sliderInnerN,
          value: params.innerN,
          min: 2, max: 20,
          valueLabel: params.innerN.toStringAsFixed(1),
          onChanged: (v) {
            onDragStart();
            onChanged(params.copyWith(innerN: v));
          },
          onChangeEnd: (v) => onDragEnd(params.copyWith(innerN: v)),
        ),
        _SliderRow(
          label: l10n.sliderRotation,
          value: params.rotation,
          min: 0, max: 360,
          valueLabel: '${params.rotation.round()}°',
          onChanged: (v) {
            onDragStart();
            onChanged(params.copyWith(rotation: v));
          },
          onChangeEnd: (v) => onDragEnd(params.copyWith(rotation: v)),
        ),
        _SliderRow(
          label: l10n.sliderInnerScale,
          value: params.innerScale,
          min: 0.3, max: 0.8,
          valueLabel: params.innerScale.toStringAsFixed(2),
          onChanged: (v) {
            onDragStart();
            onChanged(params.copyWith(innerScale: v));
          },
          onChangeEnd: (v) => onDragEnd(params.copyWith(innerScale: v)),
        ),
      ],
    );
  }
}

// ── Boundary 편집기 ────────────────────────────────────────────────────────

class _BoundaryEditor extends StatelessWidget {
  final QrBoundaryParams params;
  final ValueChanged<QrBoundaryParams> onChanged;
  final VoidCallback onDragStart;
  final ValueChanged<QrBoundaryParams> onDragEnd;

  const _BoundaryEditor({
    required this.params,
    required this.onChanged,
    required this.onDragStart,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타입 선택
        _sectionLabel(l10n.labelBoundaryType),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: QrBoundaryType.values
              .where((t) => t != QrBoundaryType.custom)
              .map((type) => ChoiceChip(
                    label: Text(type.name),
                    selected: params.type == type,
                    onSelected: (_) {
                      onChanged(params.copyWith(type: type));
                      onDragEnd(params.copyWith(type: type));
                    },
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        // Superellipse N (superellipse/custom 타입)
        if (params.type == QrBoundaryType.superellipse ||
            params.type == QrBoundaryType.custom)
          _SliderRow(
            label: l10n.sliderSuperellipseN,
            value: params.superellipseN,
            min: 2, max: 20,
            valueLabel: params.superellipseN.toStringAsFixed(1),
            onChanged: (v) {
              onDragStart();
              onChanged(params.copyWith(superellipseN: v));
            },
            onChangeEnd: (v) => onDragEnd(params.copyWith(superellipseN: v)),
          ),
        // Star 전용 슬라이더
        if (params.type == QrBoundaryType.star) ...[
          _SliderRow(
            label: l10n.sliderStarVertices,
            value: params.starVertices.toDouble(),
            min: 5, max: 12, divisions: 7,
            valueLabel: '${params.starVertices}',
            onChanged: (v) {
              onDragStart();
              onChanged(params.copyWith(starVertices: v.round()));
            },
            onChangeEnd: (v) => onDragEnd(params.copyWith(starVertices: v.round())),
          ),
          _SliderRow(
            label: l10n.sliderStarInnerRadius,
            value: params.starInnerRadius,
            min: 0.3, max: 0.8,
            valueLabel: params.starInnerRadius.toStringAsFixed(2),
            onChanged: (v) {
              onDragStart();
              onChanged(params.copyWith(starInnerRadius: v));
            },
            onChangeEnd: (v) => onDragEnd(params.copyWith(starInnerRadius: v)),
          ),
        ],
        // 공통: 회전
        _SliderRow(
          label: l10n.sliderRotation,
          value: params.rotation,
          min: 0, max: 360,
          valueLabel: '${params.rotation.round()}°',
          onChanged: (v) {
            onDragStart();
            onChanged(params.copyWith(rotation: v));
          },
          onChangeEnd: (v) => onDragEnd(params.copyWith(rotation: v)),
        ),
        // Star/Hexagon: 둥글기
        if (params.type == QrBoundaryType.star ||
            params.type == QrBoundaryType.hexagon)
          _SliderRow(
            label: l10n.sliderRoundness,
            value: params.roundness,
            min: 0, max: 1,
            valueLabel: params.roundness.toStringAsFixed(2),
            onChanged: (v) {
              onDragStart();
              onChanged(params.copyWith(roundness: v));
            },
            onChangeEnd: (v) => onDragEnd(params.copyWith(roundness: v)),
          ),
        // 패딩
        _SliderRow(
          label: l10n.sliderPadding,
          value: params.padding,
          min: 0, max: 0.15,
          valueLabel: '${(params.padding * 100).round()}%',
          onChanged: (v) {
            onDragStart();
            onChanged(params.copyWith(padding: v));
          },
          onChangeEnd: (v) => onDragEnd(params.copyWith(padding: v)),
        ),
      ],
    );
  }

  static Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500));
}

// ── 애니메이션 편집기 ────────────────────────────────────────────────────────

class _AnimationEditor extends StatelessWidget {
  final QrAnimationParams params;
  final ValueChanged<QrAnimationParams> onChanged;

  const _AnimationEditor({
    required this.params,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타입 선택
        Wrap(
          spacing: 8,
          children: QrAnimationType.values.map((type) => ChoiceChip(
                label: Text(type.name),
                selected: params.type == type,
                onSelected: (_) => onChanged(params.copyWith(type: type)),
              )).toList(),
        ),
        const SizedBox(height: 12),
        if (params.isAnimated) ...[
          _SliderRow(
            label: l10n.sliderSpeed,
            value: params.speed,
            min: 0.1, max: 2,
            valueLabel: params.speed.toStringAsFixed(1),
            onChanged: (v) => onChanged(params.copyWith(speed: v)),
          ),
          _SliderRow(
            label: l10n.sliderAmplitude,
            value: params.amplitude,
            min: 0, max: 1,
            valueLabel: params.amplitude.toStringAsFixed(2),
            onChanged: (v) => onChanged(params.copyWith(amplitude: v)),
          ),
          _SliderRow(
            label: l10n.sliderFrequency,
            value: params.frequency,
            min: 0.1, max: 2,
            valueLabel: params.frequency.toStringAsFixed(1),
            onChanged: (v) => onChanged(params.copyWith(frequency: v)),
          ),
        ],
      ],
    );
  }
}

// ── 공용 슬라이더 행 ──────────────────────────────────────────────────────────

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.valueLabel,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(valueLabel,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

// ── 눈 외곽 모양 행 (기존) ──────────────────────────────────────────────────

Map<QrEyeOuter, String> _outerLabels(AppLocalizations l10n) => {
  QrEyeOuter.square:      l10n.shapeSquare,
  QrEyeOuter.rounded:     l10n.shapeRounded,
  QrEyeOuter.circle:      l10n.shapeCircle,
  QrEyeOuter.circleRound: l10n.shapeCircleRound,
  QrEyeOuter.smooth:      l10n.shapeSmooth,
};

class _OuterShapeRow extends StatelessWidget {
  final QrEyeOuter? selected;
  final ValueChanged<QrEyeOuter> onSelected;

  const _OuterShapeRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final labels = _outerLabels(AppLocalizations.of(context)!);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: QrEyeOuter.values.map((outer) {
        final isSelected = selected == outer;
        return _ShapeButton(
          isSelected: isSelected,
          dimmed: selected == null,
          onTap: () => onSelected(outer),
          tooltip: labels[outer] ?? '',
          child: CustomPaint(
            size: const Size(26, 26),
            painter: _OuterIconPainter(outer, isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.black87),
          ),
        );
      }).toList(),
    );
  }
}

// ── 눈 내부 모양 행 (기존) ──────────────────────────────────────────────────

Map<QrEyeInner, String> _innerLabels(AppLocalizations l10n) => {
  QrEyeInner.square:  l10n.shapeSquare,
  QrEyeInner.circle:  l10n.shapeCircle,
  QrEyeInner.diamond: l10n.shapeDiamond,
  QrEyeInner.star:    l10n.shapeStar,
};

class _InnerShapeRow extends StatelessWidget {
  final QrEyeInner? selected;
  final ValueChanged<QrEyeInner> onSelected;

  const _InnerShapeRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final labels = _innerLabels(AppLocalizations.of(context)!);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: QrEyeInner.values.map((inner) {
        final isSelected = selected == inner;
        return _ShapeButton(
          isSelected: isSelected,
          dimmed: selected == null,
          onTap: () => onSelected(inner),
          tooltip: labels[inner] ?? '',
          child: CustomPaint(
            size: const Size(26, 26),
            painter: _InnerIconPainter(inner, isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.black87),
          ),
        );
      }).toList(),
    );
  }
}

// ── 공용 Shape 버튼 ───────────────────────────────────────────────────────────

class _ShapeButton extends StatelessWidget {
  final bool isSelected;
  final bool dimmed;
  final VoidCallback onTap;
  final Widget child;
  final String tooltip;

  const _ShapeButton({
    required this.isSelected,
    required this.dimmed,
    required this.onTap,
    required this.child,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: dimmed ? 0.4 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

// ── 랜덤 눈 버튼 ──────────────────────────────────────────────────────────────

class _RandomEyeButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onGenerate;
  final VoidCallback onClear;

  const _RandomEyeButton({
    required this.isActive,
    required this.onGenerate,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.casino_outlined, size: 18),
            label: Text(isActive ? l10n.actionRandomRegenerate : l10n.actionRandomEye),
            style: FilledButton.styleFrom(
              backgroundColor: isActive
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (isActive) ...[
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            child: Text(l10n.actionClear),
          ),
        ],
      ],
    );
  }
}

// ── 아이콘 Painter ─────────────────────────────────────────────────────────────

class _OuterIconPainter extends CustomPainter {
  final QrEyeOuter outer;
  final Color color;
  const _OuterIconPainter(this.outer, this.color);

  void _addOuter(Path path, Rect r) {
    switch (outer) {
      case QrEyeOuter.square:
        path.addRect(r);
      case QrEyeOuter.rounded:
        path.addRRect(RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.18)));
      case QrEyeOuter.circle:
        path.addOval(r);
      case QrEyeOuter.circleRound:
        path.addOval(r);
      case QrEyeOuter.smooth:
        path.addRRect(RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.32)));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    final hole = r.deflate(size.width / 5);

    final path = Path()..fillType = PathFillType.evenOdd;
    _addOuter(path, r);
    if (outer == QrEyeOuter.circleRound) {
      path.addOval(hole);
    } else {
      path.addRect(hole);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OuterIconPainter old) => old.outer != outer || old.color != color;
}

class _InnerIconPainter extends CustomPainter {
  final QrEyeInner inner;
  final Color color;
  const _InnerIconPainter(this.inner, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final r = Rect.fromLTWH(
      size.width * 0.15, size.height * 0.15,
      size.width * 0.70, size.height * 0.70,
    );
    canvas.drawPath(_innerPath(r), paint);
  }

  Path _innerPath(Rect r) {
    switch (inner) {
      case QrEyeInner.square:
        return Path()..addRect(r);
      case QrEyeInner.circle:
        return Path()..addOval(r);
      case QrEyeInner.diamond:
        return Path()
          ..moveTo(r.center.dx, r.top)
          ..lineTo(r.right, r.center.dy)
          ..lineTo(r.center.dx, r.bottom)
          ..lineTo(r.left, r.center.dy)
          ..close();
      case QrEyeInner.star:
        return _starPath(r.center, r.width / 2, r.width * 0.22, 4);
    }
  }

  Path _starPath(Offset center, double outer, double innerR, int points) {
    final path = Path();
    final total = points * 2;
    for (int i = 0; i < total; i++) {
      final rr = i.isEven ? outer : innerR;
      final angle = (i * math.pi / points) - math.pi / 2;
      final pt = Offset(center.dx + rr * math.cos(angle), center.dy + rr * math.sin(angle));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_InnerIconPainter old) => old.inner != inner || old.color != color;
}
