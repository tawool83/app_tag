part of '../qr_shape_tab.dart';

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
