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

  static const _builtinClipPresets = <(QrBoundaryType, QrBoundaryParams, IconData)>[
    (QrBoundaryType.square, QrBoundaryParams.square, Icons.crop_square),
    (QrBoundaryType.circle, QrBoundaryParams.circle, Icons.circle_outlined),
    (QrBoundaryType.superellipse, QrBoundaryParams.squircle, Icons.rounded_corner),
    (QrBoundaryType.star, QrBoundaryParams.star5, Icons.star_outline),
    (QrBoundaryType.heart, QrBoundaryParams.heart, Icons.favorite_outline),
    (QrBoundaryType.hexagon, QrBoundaryParams.hexagon, Icons.hexagon_outlined),
  ];

  static const _builtinFramePresets = <(String, QrBoundaryParams, IconData)>[
    ('circle', QrBoundaryParams.circleFrame, Icons.panorama_fish_eye),
    ('hexagon', QrBoundaryParams.hexagonFrame, Icons.hexagon),
    ('heart', QrBoundaryParams.heartFrame, Icons.favorite),
    ('star', QrBoundaryParams.starFrame, Icons.star),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _AddButton(onTap: onAdd),
          // 기존 clip 프리셋
          ..._builtinClipPresets.map((entry) {
            final (type, params, icon) = entry;
            final isSel = selected == type && !isFrameMode;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ShapeButton(
                isSelected: isSel,
                dimmed: false,
                onTap: () => onPresetApply(params),
                tooltip: type.name,
                child: Icon(icon, size: 22,
                  color: isSel
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black87),
              ),
            );
          }),
          // 구분선
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Container(width: 1, color: Colors.grey.shade300),
          ),
          // 프레임 프리셋
          ..._builtinFramePresets.map((entry) {
            final (label, params, icon) = entry;
            final isSel = selected == params.type && isFrameMode;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ShapeButton(
                isSelected: isSel,
                dimmed: false,
                onTap: () => onPresetApply(params),
                tooltip: '$label frame',
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(icon, size: 22,
                      color: isSel
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black87),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('F',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            color: isSel
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          )),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
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
