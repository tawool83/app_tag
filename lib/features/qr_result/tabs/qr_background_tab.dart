library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/entities/qr_border_style.dart';
import '../domain/entities/qr_boundary_params.dart';
import '../domain/entities/qr_margin_pattern.dart';
import '../domain/entities/user_shape_preset.dart';
import '../data/datasources/local_user_shape_preset_datasource.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/qr_boundary_clipper.dart';
import '../domain/entities/qr_preview_mode.dart';
import '../qr_result_provider.dart' show qrResultProvider, shapePreviewModeProvider;

part 'qr_shape_tab/boundary_preset_row.dart';
part 'qr_shape_tab/boundary_editor.dart';

/// [배경] 탭: QR 전체 외곽(boundary) 프리셋 + 편집기.
class QrBackgroundTab extends ConsumerStatefulWidget {
  final ValueChanged<bool>? onEditorModeChanged;

  const QrBackgroundTab({
    super.key,
    this.onEditorModeChanged,
  });

  @override
  ConsumerState<QrBackgroundTab> createState() => QrBackgroundTabState();
}

class QrBackgroundTabState extends ConsumerState<QrBackgroundTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isEditorOpen = false;
  QrBoundaryParams _editBoundary = const QrBoundaryParams();
  String? _editingPresetId;
  String? _selectedBoundaryPresetId;

  LocalUserShapePresetDatasource? _datasource;
  List<UserShapePreset> _boundaryPresets = [];

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
      _boundaryPresets = _datasource!.readAll(ShapePresetType.boundary);
    });
  }

  void _openEditor({String? editingId}) {
    final state = ref.read(qrResultProvider);
    var bp = state.style.boundaryParams;
    // square(=효과 없음)로 편집기 진입 시 circle 로 초기화
    if (bp.type == QrBoundaryType.square) {
      bp = bp.copyWith(type: QrBoundaryType.circle, frameScale: 1.4);
    }
    setState(() {
      _isEditorOpen = true;
      _editingPresetId = editingId;
      _editBoundary = bp;
    });
    ref.read(qrResultProvider.notifier).setBoundaryParams(bp);
    widget.onEditorModeChanged?.call(true);
  }

  String? activeEditorLabel(AppLocalizations l10n) =>
      _isEditorOpen ? l10n.labelCustomBoundary : null;

  Future<void> confirmAndCloseEditor() async {
    if (!_isEditorOpen) return;
    if (_editingPresetId != null) {
      await _updateExistingPreset();
    } else {
      await _saveCurrentAsPreset();
    }
    _confirmEditor();
  }

  Future<bool> cancelAndCloseEditor() async {
    if (!_isEditorOpen) return true;
    if (_editingPresetId != null) {
      await _updateExistingPreset();
    } else {
      await _saveCurrentAsPreset();
    }
    _confirmEditor();
    return true;
  }

  void _confirmEditor() {
    ref.read(qrResultProvider.notifier).setBoundaryParams(_editBoundary);
    ref.read(shapePreviewModeProvider.notifier).state = ShapePreviewMode.fullQr;
    setState(() { _isEditorOpen = false; _editingPresetId = null; });
    widget.onEditorModeChanged?.call(false);
  }

  Future<void> _saveCurrentAsPreset() async {
    if (_datasource == null || !_isEditorOpen) return;

    final id = const Uuid().v4();
    final preset = UserShapePreset(
      id: id, name: id.substring(0, 8), type: ShapePresetType.boundary,
      createdAt: DateTime.now(), boundaryParams: _editBoundary,
    );
    await _datasource!.save(preset);
    _loadPresets();
  }

  /// 선택 하이라이트를 먼저 보여주고, 잠시 뒤에 재정렬.
  void _delayedReloadPresets() {
    _reorderTimer?.cancel();
    _reorderTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) _loadPresets();
    });
  }

  Future<void> _showBoundaryGridModal(BuildContext context, {required _BoundaryGridMode mode}) async {
    if (_boundaryPresets.isEmpty) return;
    final result = await showModalBottomSheet<_BoundaryGridResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _BoundaryGridModal(
        presets: _boundaryPresets,
        mode: mode,
      ),
    );
    if (result == null) return;
    switch (result) {
      case _BoundaryGridDeleteResult(:final deletedIds):
        if (deletedIds.contains(_selectedBoundaryPresetId)) {
          setState(() => _selectedBoundaryPresetId = null);
        }
        for (final id in deletedIds) {
          await _datasource?.delete(ShapePresetType.boundary, id);
        }
        _loadPresets();
      case _BoundaryGridEditResult(:final preset):
        ref.read(qrResultProvider.notifier).setBoundaryParams(preset.boundaryParams!);
        setState(() => _selectedBoundaryPresetId = preset.id);
        await _datasource?.touchLastUsed(ShapePresetType.boundary, preset.id);
        _loadPresets();
        _openEditor(editingId: preset.id);
      case _BoundaryGridSelectResult(:final preset):
        ref.read(qrResultProvider.notifier).setBoundaryParams(preset.boundaryParams!);
        setState(() => _selectedBoundaryPresetId = preset.id);
        await _datasource?.touchLastUsed(ShapePresetType.boundary, preset.id);
        _loadPresets();
    }
  }

  /// 기존 프리셋을 현재 편집 값으로 덮어쓰기 (수정 모드용).
  Future<void> _updateExistingPreset() async {
    if (_datasource == null || _editingPresetId == null) return;
    final existing = _boundaryPresets.where((p) => p.id == _editingPresetId).firstOrNull;
    if (existing != null) {
      final updated = UserShapePreset(
        id: existing.id, name: existing.name, type: existing.type,
        createdAt: existing.createdAt, lastUsedAt: DateTime.now(),
        version: existing.version, boundaryParams: _editBoundary,
      );
      await _datasource!.save(updated);
      setState(() => _selectedBoundaryPresetId = existing.id);
      _loadPresets();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(qrResultProvider);
    final l10n = AppLocalizations.of(context)!;

    if (_isEditorOpen) {
      return _buildEditor(l10n);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 라벨 + 삭제 아이콘
          Row(
            children: [
              Expanded(child: _sectionLabel(l10n.labelBoundaryShape)),
              if (_boundaryPresets.isNotEmpty)
                GestureDetector(
                  onTap: () => _showBoundaryGridModal(context, mode: _BoundaryGridMode.delete),
                  child: Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade600),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _BoundaryBuiltinRow(
            isSelected: _selectedBoundaryPresetId == null
                && state.style.boundaryParams.type == QrBoundaryType.square
                && !state.style.boundaryParams.isFrameMode,
            onReset: () {
              setState(() => _selectedBoundaryPresetId = null);
              ref.read(qrResultProvider.notifier).setBoundaryParams(QrBoundaryParams.square);
            },
          ),
          const SizedBox(height: 8),
          _BoundaryUserPresetRow(
            selectedPresetId: _selectedBoundaryPresetId,
            userPresets: _boundaryPresets,
            onAdd: () => _openEditor(),
            onUserSelect: (p) async {
              setState(() => _selectedBoundaryPresetId = p.id);
              ref.read(qrResultProvider.notifier).setBoundaryParams(p.boundaryParams!);
              await _datasource?.touchLastUsed(ShapePresetType.boundary, p.id);
              _delayedReloadPresets();
            },
            onUserLongPress: (p) async {
              ref.read(qrResultProvider.notifier).setBoundaryParams(p.boundaryParams!);
              setState(() => _selectedBoundaryPresetId = p.id);
              await _datasource?.touchLastUsed(ShapePresetType.boundary, p.id);
              _loadPresets();
              _openEditor(editingId: p.id);
            },
            onShowAll: () => _showBoundaryGridModal(context, mode: _BoundaryGridMode.view),
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
          Text(
            l10n.labelCustomBoundary,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _BoundaryEditor(
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

// ── 공용 위젯 (배경 탭 전용) ──────────────────────────────────────────────────

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

class _PresetIconPainter extends CustomPainter {
  final UserShapePreset preset;
  const _PresetIconPainter({required this.preset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    if (preset.boundaryParams != null) {
      final clipPath = QrBoundaryClipper.buildClipPath(size, preset.boundaryParams!);
      if (clipPath != null) {
        canvas.drawPath(clipPath, paint..style = PaintingStyle.stroke..strokeWidth = 1.5);
      } else {
        canvas.drawRect(Offset.zero & size, paint..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
    }
  }

  @override
  bool shouldRepaint(_PresetIconPainter old) => preset != old.preset;
}

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
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

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
