part of '../qr_shape_tab.dart';

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
