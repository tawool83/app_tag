part of '../qr_shape_tab.dart';

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
