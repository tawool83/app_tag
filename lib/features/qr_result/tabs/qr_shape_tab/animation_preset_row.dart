part of '../qr_shape_tab.dart';

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
