part of '../qr_shape_tab.dart';

// ── 눈 편집기 (슬라이더 5개) ──────────────────────────────────────────────
//
// 슬라이더:
//   cornerQ1 / Q2 / Q3 / Q4 (0.0 둥글 ~ 1.0 사각) — local 좌표계
//   innerN (2.0 원 ~ 20.0 사각) — 내부 fill superellipse

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
          label: l10n.sliderCornerQ1,
          value: params.cornerQ1,
          min: 0, max: 1,
          valueLabel: params.cornerQ1.toStringAsFixed(2),
          onChanged: (v) {
            onDragStart();
            onChanged(params.copyWith(cornerQ1: v));
          },
          onChangeEnd: (v) => onDragEnd(params.copyWith(cornerQ1: v)),
        ),
        _SliderRow(
          label: l10n.sliderCornerQ2,
          value: params.cornerQ2,
          min: 0, max: 1,
          valueLabel: params.cornerQ2.toStringAsFixed(2),
          onChanged: (v) {
            onDragStart();
            onChanged(params.copyWith(cornerQ2: v));
          },
          onChangeEnd: (v) => onDragEnd(params.copyWith(cornerQ2: v)),
        ),
        _SliderRow(
          label: l10n.sliderCornerQ3,
          value: params.cornerQ3,
          min: 0, max: 1,
          valueLabel: params.cornerQ3.toStringAsFixed(2),
          onChanged: (v) {
            onDragStart();
            onChanged(params.copyWith(cornerQ3: v));
          },
          onChangeEnd: (v) => onDragEnd(params.copyWith(cornerQ3: v)),
        ),
        _SliderRow(
          label: l10n.sliderCornerQ4,
          value: params.cornerQ4,
          min: 0, max: 1,
          valueLabel: params.cornerQ4.toStringAsFixed(2),
          onChanged: (v) {
            onDragStart();
            onChanged(params.copyWith(cornerQ4: v));
          },
          onChangeEnd: (v) => onDragEnd(params.copyWith(cornerQ4: v)),
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
