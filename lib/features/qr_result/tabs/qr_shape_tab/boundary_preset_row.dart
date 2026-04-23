part of '../qr_shape_tab.dart';

// ── Boundary 프리셋 행 ──────────────────────────────────────────────────────

class _BoundaryPresetRow extends StatelessWidget {
  final QrBoundaryType selected;
  final bool isFrameMode;
  final ValueChanged<QrBoundaryParams> onPresetApply;
  final List<UserShapePreset> presets;
  final VoidCallback onAdd;
  final ValueChanged<UserShapePreset> onPresetSelect;
  final ValueChanged<UserShapePreset> onPresetDelete;

  const _BoundaryPresetRow({
    required this.selected,
    required this.isFrameMode,
    required this.onPresetApply,
    required this.presets,
    required this.onAdd,
    required this.onPresetSelect,
    required this.onPresetDelete,
  });

  @override
  Widget build(BuildContext context) {
    // "기본(사각형, 변형 없음)으로 돌아가기" 복귀 버튼. 다른 built-in 외곽은 제거됨.
    final isSquareSelected =
        selected == QrBoundaryType.square && !isFrameMode;
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _AddButton(onTap: onAdd),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _ShapeButton(
              isSelected: isSquareSelected,
              dimmed: false,
              onTap: () => onPresetApply(QrBoundaryParams.square),
              tooltip: QrBoundaryType.square.name,
              child: Icon(Icons.crop_square, size: 22,
                color: isSquareSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black87),
            ),
          ),
          // 사용자 프리셋
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
