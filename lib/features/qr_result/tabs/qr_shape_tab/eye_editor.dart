part of '../qr_shape_tab.dart';

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
      ],
    );
  }
}
