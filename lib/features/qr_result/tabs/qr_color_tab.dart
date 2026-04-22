library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart' hide PaletteType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/color_hex.dart' as app_color_hex;
import '../../../l10n/app_localizations.dart';
import '../../color_palette/data/datasources/hive_color_palette_datasource.dart';
import '../../color_palette/data/models/user_color_palette_model.dart';
import '../../color_palette/domain/entities/user_color_palette.dart';
import '../domain/entities/qr_color_presets.dart';
import '../domain/entities/qr_template.dart' show QrGradient;
import '../qr_result_provider.dart' show qrResultProvider;

part 'qr_color_tab/shared.dart';
part 'qr_color_tab/solid_row.dart';
part 'qr_color_tab/gradient_row.dart';
part 'qr_color_tab/gradient_editor.dart';
part 'qr_color_tab/color_grid_modal.dart';

/// [색상] 탭: built-in 5개 + 사용자 단색/그라디언트 프리셋 + 그라디언트 편집기.
class QrColorTab extends ConsumerStatefulWidget {
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<QrGradient?> onGradientChanged;
  final ValueChanged<bool>? onEditorModeChanged;

  const QrColorTab({
    super.key,
    required this.onColorSelected,
    required this.onGradientChanged,
    this.onEditorModeChanged,
  });

  @override
  ConsumerState<QrColorTab> createState() => QrColorTabState();
}

class QrColorTabState extends ConsumerState<QrColorTab> {
  // ── 프리셋 데이터 ──
  HiveColorPaletteDataSource? _datasource;
  List<UserColorPalette> _solidPresets = [];
  List<UserColorPalette> _gradientPresets = [];

  // ── 선택 상태 ──
  String? _selectedSolidPresetId;
  String? _selectedGradientPresetId;

  // ── 그라디언트 편집기 상태 ──
  bool _showGradientEditor = false;
  String? _editingGradientPresetId;
  String _gradientType = 'linear';
  double _angleDegrees = 45;
  String _center = 'center';
  List<_ColorStop> _stops = [
    _ColorStop(color: const Color(0xFF0066CC), position: 0.0),
    _ColorStop(color: const Color(0xFF6A0DAD), position: 1.0),
  ];

  // ── 재정렬 지연 타이머 ──
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
    final box = Hive.isBoxOpen(HiveColorPaletteDataSource.boxName)
        ? Hive.box<UserColorPaletteModel>(HiveColorPaletteDataSource.boxName)
        : await Hive.openBox<UserColorPaletteModel>(
            HiveColorPaletteDataSource.boxName);
    _datasource = HiveColorPaletteDataSource(box);
    _loadPresets();
  }

  void _loadPresets() {
    if (_datasource == null) return;
    setState(() {
      _solidPresets = _datasource!.readAllSortedByRecency(PaletteType.solid);
      _gradientPresets =
          _datasource!.readAllSortedByRecency(PaletteType.gradient);
    });
  }

  /// 선택 하이라이트를 먼저 보여주고 재정렬.
  void _delayedReloadPresets() {
    _reorderTimer?.cancel();
    _reorderTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) _loadPresets();
    });
  }

  // ── 편집기 open/close ──────────────────────────────────────────────────

  void _openGradientEditor({String? editingId, UserColorPalette? preset}) {
    if (preset != null) {
      _loadGradientIntoEditorState(preset);
    } else {
      _resetEditorStateToDefault();
    }
    setState(() {
      _showGradientEditor = true;
      _editingGradientPresetId = editingId;
    });
    _emitGradient();
    widget.onEditorModeChanged?.call(true);
  }

  void _closeGradientEditor() {
    setState(() {
      _showGradientEditor = false;
      _editingGradientPresetId = null;
    });
    widget.onEditorModeChanged?.call(false);
  }

  // ── 외부 공개 API ──────────────────────────────────────────────────────

  /// 외부(부모)에서 호출 — AppBar 뒤로가기 시: 현재 편집 값 자동 저장 후 닫기.
  /// (도트/눈 shape editor 와 동형)
  Future<bool> cancelAndCloseEditor() async {
    if (!_showGradientEditor) return true;
    if (_editingGradientPresetId != null) {
      await _updateExistingGradientPreset();
    } else {
      await _saveCurrentGradientAsPreset();
    }
    _closeGradientEditor();
    return true;
  }

  /// 외부(부모)에서 호출 — 탭 전환 시 확인 처리.
  Future<void> confirmAndCloseEditor() async {
    await cancelAndCloseEditor();
  }

  String? activeEditorLabel(AppLocalizations l10n) =>
      _showGradientEditor ? l10n.labelCustomGradient : null;

  // ── Save / Update / Delete ─────────────────────────────────────────────

  Future<void> _saveSolidAsPreset(Color color) async {
    if (_datasource == null) return;
    final argb = color.toARGB32();

    final existing =
        _solidPresets.where((p) => p.solidColorArgb == argb).firstOrNull;
    if (existing != null) {
      await _datasource!.touchLastUsed(existing.id);
      setState(() => _selectedSolidPresetId = existing.id);
      widget.onGradientChanged(null);
      widget.onColorSelected(color);
      _loadPresets();
      return;
    }

    final id = const Uuid().v4();
    final now = DateTime.now();
    final preset = UserColorPalette(
      id: id,
      name: id.substring(0, 8),
      type: PaletteType.solid,
      solidColorArgb: argb,
      createdAt: now,
      updatedAt: now,
    );
    await _datasource!.write(UserColorPaletteModel.fromEntity(preset));
    setState(() => _selectedSolidPresetId = id);
    widget.onGradientChanged(null);
    widget.onColorSelected(color);
    _loadPresets();
  }

  Future<void> _saveCurrentGradientAsPreset() async {
    if (_datasource == null) return;
    final current = QrGradient(
      type: _gradientType,
      colors: _stops.map((s) => s.color).toList(),
      stops: _stops.map((s) => s.position).toList(),
      angleDegrees: _angleDegrees,
      center: _gradientType == 'radial' ? _center : null,
    );

    final existing = _gradientPresets.where((p) {
      return _gradientEquals(_qrGradientFromPalette(p), current);
    }).firstOrNull;
    if (existing != null) {
      await _datasource!.touchLastUsed(existing.id);
      setState(() => _selectedGradientPresetId = existing.id);
      _loadPresets();
      return;
    }

    final id = const Uuid().v4();
    final now = DateTime.now();
    final preset = UserColorPalette(
      id: id,
      name: id.substring(0, 8),
      type: PaletteType.gradient,
      gradientColorArgbs: current.colors.map((c) => c.toARGB32()).toList(),
      gradientStops: current.stops,
      gradientType: current.type,
      gradientAngle: current.angleDegrees.toInt(),
      createdAt: now,
      updatedAt: now,
    );
    await _datasource!.write(UserColorPaletteModel.fromEntity(preset));
    setState(() => _selectedGradientPresetId = id);
    _loadPresets();
  }

  Future<void> _updateExistingGradientPreset() async {
    if (_datasource == null || _editingGradientPresetId == null) return;
    final existing = _gradientPresets
        .where((p) => p.id == _editingGradientPresetId)
        .firstOrNull;
    if (existing == null) {
      await _saveCurrentGradientAsPreset();
      return;
    }
    final updated = UserColorPalette(
      id: existing.id,
      name: existing.name,
      type: existing.type,
      gradientColorArgbs: _stops.map((s) => s.color.toARGB32()).toList(),
      gradientStops: _stops.map((s) => s.position).toList(),
      gradientType: _gradientType,
      gradientAngle: _angleDegrees.toInt(),
      sortOrder: existing.sortOrder,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      remoteId: existing.remoteId,
      syncedToCloud: false,
    );
    await _datasource!.write(UserColorPaletteModel.fromEntity(updated));
    setState(() => _selectedGradientPresetId = existing.id);
    _loadPresets();
  }

  // ── Select handlers ────────────────────────────────────────────────────

  void _onBuiltinSolidSelect(Color c) {
    setState(() => _selectedSolidPresetId = null);
    widget.onGradientChanged(null);
    widget.onColorSelected(c);
  }

  Future<void> _onUserSolidSelect(UserColorPalette p) async {
    if (p.solidColorArgb == null) return;
    setState(() => _selectedSolidPresetId = p.id);
    widget.onGradientChanged(null);
    widget.onColorSelected(Color(p.solidColorArgb!));
    await _datasource?.touchLastUsed(p.id);
    _delayedReloadPresets();
  }

  Future<void> _onUserSolidLongPress(UserColorPalette p) async {
    if (p.solidColorArgb == null) return;
    await _openColorWheel(context, Color(p.solidColorArgb!), (newColor) {
      // 신규 생성 (원본 유지). dedup 은 _saveSolidAsPreset 내부에서 처리.
      _saveSolidAsPreset(newColor);
    });
  }

  void _onBuiltinGradientSelect(QrGradient g) {
    setState(() => _selectedGradientPresetId = null);
    widget.onGradientChanged(g);
  }

  Future<void> _onUserGradientSelect(UserColorPalette p) async {
    final g = _qrGradientFromPalette(p);
    setState(() => _selectedGradientPresetId = p.id);
    widget.onGradientChanged(g);
    await _datasource?.touchLastUsed(p.id);
    _delayedReloadPresets();
  }

  void _onUserGradientLongPress(UserColorPalette p) {
    _openGradientEditor(editingId: p.id, preset: p);
  }

  // ── Grid modal ─────────────────────────────────────────────────────────

  Future<void> _showSolidGridModal({required _ColorGridMode mode}) async {
    if (_solidPresets.isEmpty) return;
    final result = await showModalBottomSheet<_ColorGridResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ColorGridModal(
        presets: _solidPresets,
        mode: mode,
        isGradient: false,
        selectedPresetId: _selectedSolidPresetId,
      ),
    );
    if (result == null) return;
    switch (result) {
      case _ColorGridDeleteResult(:final deletedIds):
        if (deletedIds.contains(_selectedSolidPresetId)) {
          setState(() => _selectedSolidPresetId = null);
        }
        for (final id in deletedIds) {
          await _datasource?.delete(id);
        }
        _loadPresets();
      case _ColorGridSelectResult(:final preset):
        await _onUserSolidSelect(preset);
      case _ColorGridEditResult():
        // solid 는 modal 에서 편집 진입 없음 (롱프레스는 null 콜백)
        break;
    }
  }

  Future<void> _showGradientGridModal({required _ColorGridMode mode}) async {
    if (_gradientPresets.isEmpty) return;
    final result = await showModalBottomSheet<_ColorGridResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ColorGridModal(
        presets: _gradientPresets,
        mode: mode,
        isGradient: true,
        selectedPresetId: _selectedGradientPresetId,
      ),
    );
    if (result == null) return;
    switch (result) {
      case _ColorGridDeleteResult(:final deletedIds):
        if (deletedIds.contains(_selectedGradientPresetId)) {
          setState(() => _selectedGradientPresetId = null);
          widget.onGradientChanged(null);
        }
        for (final id in deletedIds) {
          await _datasource?.delete(id);
        }
        _loadPresets();
      case _ColorGridSelectResult(:final preset):
        await _onUserGradientSelect(preset);
      case _ColorGridEditResult(:final preset):
        _openGradientEditor(editingId: preset.id, preset: preset);
    }
  }

  // ── Color wheel (공용 다이얼로그) ──────────────────────────────────────

  Future<void> _openColorWheel(BuildContext context, Color initial,
      ValueChanged<Color> onConfirm) async {
    final l10n = AppLocalizations.of(context)!;
    Color temp = initial;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.dialogColorPickerTitle),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: temp,
            onColorChanged: (c) => temp = c,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm(temp);
  }

  // ── 그라디언트 편집기 UI / 헬퍼 ────────────────────────────────────────

  Widget _buildGradientEditor(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabelWithDelete(label: l10n.labelCustomGradient),
          const SizedBox(height: 12),
          _buildTypeAndOptionRow(l10n),
          const SizedBox(height: 16),
          Text(l10n.labelColorStops,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          _GradientSliderBar(
            stops: _stops,
            onChanged: (newStops) {
              setState(() => _stops = newStops);
              _emitGradient();
            },
            onStopAdded: _stops.length < 5
                ? (newStops) {
                    setState(() => _stops = newStops);
                    _emitGradient();
                  }
                : null,
          ),
          const SizedBox(height: 16),
          _buildColorStopList(l10n),
        ],
      ),
    );
  }

  Widget _buildTypeAndOptionRow(AppLocalizations l10n) {
    const angles = [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0];
    final centerOptions = {
      'center': l10n.optionCenterCenter,
      'topLeft': l10n.optionCenterTopLeft,
      'topRight': l10n.optionCenterTopRight,
      'bottomLeft': l10n.optionCenterBottomLeft,
      'bottomRight': l10n.optionCenterBottomRight,
    };
    return Row(
      children: [
        Expanded(
          child: _LabeledDropdown<String>(
            label: l10n.labelGradientType,
            value: _gradientType,
            items: [
              DropdownMenuItem(value: 'linear', child: Text(l10n.optionLinear)),
              DropdownMenuItem(value: 'radial', child: Text(l10n.optionRadial)),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _gradientType = v);
              _emitGradient();
            },
          ),
        ),
        const SizedBox(width: 12),
        if (_gradientType == 'linear')
          Expanded(
            child: _LabeledDropdown<double>(
              label: l10n.labelAngle,
              value: _angleDegrees,
              items: angles
                  .map((a) => DropdownMenuItem(
                      value: a, child: Text('${a.toInt()}°')))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _angleDegrees = v);
                _emitGradient();
              },
            ),
          )
        else
          Expanded(
            child: _LabeledDropdown<String>(
              label: l10n.labelCenter,
              value: _center,
              items: centerOptions.entries
                  .map((e) => DropdownMenuItem(
                      value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _center = v);
                _emitGradient();
              },
            ),
          ),
      ],
    );
  }

  Widget _buildColorStopList(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_stops.length, (i) {
        final stop = _stops[i];
        final canDelete = _stops.length > 2;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              GestureDetector(
                onTap: () =>
                    _openColorWheel(context, stop.color, (newColor) {
                  setState(() => _stops[i] =
                      _ColorStop(color: newColor, position: stop.position));
                  _emitGradient();
                }),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: stop.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                app_color_hex.colorToHex(stop.color),
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              if (canDelete)
                SizedBox(
                  height: 28,
                  child: TextButton(
                    onPressed: () {
                      setState(() => _stops.removeAt(i));
                      _redistributeStopPositions();
                      _emitGradient();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.actionDeleteStop,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  void _emitGradient() {
    final gradient = QrGradient(
      type: _gradientType,
      colors: _stops.map((s) => s.color).toList(),
      stops: _stops.map((s) => s.position).toList(),
      angleDegrees: _angleDegrees,
      center: _gradientType == 'radial' ? _center : null,
    );
    widget.onGradientChanged(gradient);
  }

  void _redistributeStopPositions() {
    if (_stops.length < 2) return;
    for (var i = 0; i < _stops.length; i++) {
      final pos = i / (_stops.length - 1);
      _stops[i] = _ColorStop(color: _stops[i].color, position: pos);
    }
  }

  void _loadGradientIntoEditorState(UserColorPalette p) {
    final colors = p.gradientColorArgbs ?? [0xFF000000, 0xFFFFFFFF];
    final positions = p.gradientStops ??
        List.generate(colors.length, (i) => i / (colors.length - 1));
    setState(() {
      _gradientType = p.gradientType ?? 'linear';
      _angleDegrees = (p.gradientAngle ?? 45).toDouble();
      _center = 'center';
      _stops = List.generate(colors.length, (i) {
        return _ColorStop(
          color: Color(colors[i]),
          position:
              i < positions.length ? positions[i] : i / (colors.length - 1),
        );
      });
    });
  }

  void _resetEditorStateToDefault() {
    setState(() {
      _gradientType = 'linear';
      _angleDegrees = 45;
      _center = 'center';
      _stops = [
        _ColorStop(color: const Color(0xFF0066CC), position: 0.0),
        _ColorStop(color: const Color(0xFF6A0DAD), position: 1.0),
      ];
    });
  }

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qrResultProvider);
    final l10n = AppLocalizations.of(context)!;

    if (_showGradientEditor) {
      return _buildGradientEditor(l10n);
    }

    final currentGradient = state.style.customGradient;
    final currentColor = state.style.qrColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 단색 섹션 ──
          _SectionLabelWithDelete(
            label: l10n.tabColorSolid,
            onDeleteTap: _solidPresets.isNotEmpty
                ? () => _showSolidGridModal(mode: _ColorGridMode.delete)
                : null,
          ),
          const SizedBox(height: 10),
          _SolidRow(
            builtinSelected: (currentGradient == null &&
                    _selectedSolidPresetId == null)
                ? currentColor
                : null,
            userPresets: _solidPresets,
            selectedPresetId: _selectedSolidPresetId,
            onBuiltinSelect: _onBuiltinSolidSelect,
            onAddTap: () =>
                _openColorWheel(context, currentColor, _saveSolidAsPreset),
            onUserSelect: _onUserSolidSelect,
            onUserLongPress: _onUserSolidLongPress,
            onShowAll: () => _showSolidGridModal(mode: _ColorGridMode.view),
          ),
          const SizedBox(height: 24),

          // ── 그라디언트 섹션 ──
          _SectionLabelWithDelete(
            label: l10n.tabColorGradient,
            onDeleteTap: _gradientPresets.isNotEmpty
                ? () => _showGradientGridModal(mode: _ColorGridMode.delete)
                : null,
          ),
          const SizedBox(height: 10),
          _GradientRow(
            currentGradient: currentGradient,
            userPresets: _gradientPresets,
            selectedPresetId: _selectedGradientPresetId,
            onBuiltinSelect: _onBuiltinGradientSelect,
            onAddTap: () => _openGradientEditor(),
            onUserSelect: _onUserGradientSelect,
            onUserLongPress: _onUserGradientLongPress,
            onShowAll: () =>
                _showGradientGridModal(mode: _ColorGridMode.view),
          ),
        ],
      ),
    );
  }
}
