part of '../qr_shape_tab.dart';

// ── 도트 편집기 (듀얼 모드: 대칭/비대칭) ──────────────────────────────────────

class _DotEditor extends StatelessWidget {
  final DotShapeParams params;
  final ValueChanged<DotShapeParams> onChanged;
  final VoidCallback onDragStart;
  final ValueChanged<DotShapeParams> onDragEnd;

  const _DotEditor({
    required this.params,
    required this.onChanged,
    required this.onDragStart,
    required this.onDragEnd,
  });

  // Superformula 프리셋 목록
  static const _sfPresets = <(String, DotShapeParams)>[
    ('●', DotShapeParams.sfCircle),
    ('■', DotShapeParams.sfSquare),
    ('★', DotShapeParams.sfStar),
    ('✿', DotShapeParams.sfFlower),
    ('♥', DotShapeParams.sfHeart),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSymmetric = params.mode == DotShapeMode.symmetric;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── [대칭] / [비대칭] 토글 ──
        Row(
          children: [
            Expanded(
              child: _ModeToggleButton(
                label: l10n.labelSymmetric,
                isSelected: isSymmetric,
                onTap: () => _switchMode(DotShapeMode.symmetric),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ModeToggleButton(
                label: l10n.labelAsymmetric,
                isSelected: !isSymmetric,
                onTap: () => _switchMode(DotShapeMode.asymmetric),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── 모드별 슬라이더 ──
        if (isSymmetric) ..._buildSymmetricSliders(l10n)
        else ..._buildAsymmetricSliders(l10n),

        // ── 공통: 회전 ──
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

        // ── 공통: 크기 (중앙 0% = 1.0x, -100% = 0.5x, +100% = 2.0x) ──
        _buildScaleSlider(l10n),
      ],
    );
  }

  void _switchMode(DotShapeMode mode) {
    if (params.mode == mode) return;
    final newParams = mode == DotShapeMode.symmetric
        ? DotShapeParams(mode: mode, rotation: params.rotation, scale: params.scale)
        : DotShapeParams(
            mode: mode, rotation: params.rotation, scale: params.scale,
            sfM: 5, sfN1: 0.3, sfN2: 0.3, sfN3: 0.3, // 별 기본값
          );
    onChanged(newParams);
    onDragEnd(newParams);
  }

  // 슬라이더 내부값(-1.0~+1.0) ↔ scale 비대칭 매핑
  //   s >= 0 → scale = 1 + s         (0~+1 → 1.0~2.0, +100%에서 2배)
  //   s < 0  → scale = 1 + s * 0.5   (-1~0 → 0.5~1.0, -100%에서 절반)
  double _sliderToScale(double s) => s >= 0 ? 1.0 + s : 1.0 + s * 0.5;
  double _scaleToSlider(double v) => v >= 1.0 ? v - 1.0 : (v - 1.0) * 2;

  String _formatScaleLabel(double sliderVal) {
    final pct = (sliderVal * 100).round();
    return pct > 0 ? '+$pct%' : '$pct%';
  }

  Widget _buildScaleSlider(AppLocalizations l10n) {
    final sliderVal = _scaleToSlider(params.scale);
    return _SliderRow(
      label: l10n.sliderDotScale,
      value: sliderVal,
      min: -1.0, max: 1.0,
      valueLabel: _formatScaleLabel(sliderVal),
      onChanged: (s) {
        onDragStart();
        onChanged(params.copyWith(scale: _sliderToScale(s)));
      },
      onChangeEnd: (s) => onDragEnd(params.copyWith(scale: _sliderToScale(s))),
    );
  }

  List<Widget> _buildSymmetricSliders(AppLocalizations l10n) => [
    _SliderRow(
      label: l10n.sliderVertices,
      value: params.vertices.toDouble(),
      min: 3, max: 12, divisions: 9,
      valueLabel: '${params.vertices}',
      onChanged: (v) {
        onDragStart();
        onChanged(params.copyWith(vertices: v.round()));
      },
      onChangeEnd: (v) => onDragEnd(params.copyWith(vertices: v.round())),
    ),
    _SliderRow(
      label: l10n.sliderInnerRadius,
      value: params.innerRadius,
      min: 0, max: 1,
      valueLabel: params.innerRadius.toStringAsFixed(2),
      onChanged: (v) {
        onDragStart();
        onChanged(params.copyWith(innerRadius: v));
      },
      onChangeEnd: (v) => onDragEnd(params.copyWith(innerRadius: v)),
    ),
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
  ];

  List<Widget> _buildAsymmetricSliders(AppLocalizations l10n) => [
    // Superformula 프리셋 행
    SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _sfPresets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final (label, preset) = _sfPresets[i];
          return GestureDetector(
            onTap: () {
              final p = preset.copyWith(rotation: params.rotation);
              onChanged(p);
              onDragEnd(p);
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(label, style: const TextStyle(fontSize: 20)),
              ),
            ),
          );
        },
      ),
    ),
    const SizedBox(height: 12),
    _SliderRow(
      label: l10n.sliderSfM,
      value: params.sfM,
      min: 0, max: 20,
      valueLabel: params.sfM.toStringAsFixed(1),
      onChanged: (v) {
        onDragStart();
        onChanged(params.copyWith(sfM: v));
      },
      onChangeEnd: (v) => onDragEnd(params.copyWith(sfM: v)),
    ),
    _SliderRow(
      label: l10n.sliderSfN1,
      value: params.sfN1.clamp(0.1, 40),
      min: 0.1, max: 40,
      valueLabel: params.sfN1.toStringAsFixed(1),
      onChanged: (v) {
        onDragStart();
        onChanged(params.copyWith(sfN1: v));
      },
      onChangeEnd: (v) => onDragEnd(params.copyWith(sfN1: v)),
    ),
    _SliderRow(
      label: l10n.sliderSfN2,
      value: params.sfN2.clamp(0.1, 40),
      min: 0.1, max: 40,
      valueLabel: params.sfN2.toStringAsFixed(1),
      onChanged: (v) {
        onDragStart();
        onChanged(params.copyWith(sfN2: v));
      },
      onChangeEnd: (v) => onDragEnd(params.copyWith(sfN2: v)),
    ),
    _SliderRow(
      label: l10n.sliderSfN3,
      value: params.sfN3.clamp(-5, 40),
      min: -5, max: 40,
      valueLabel: params.sfN3.toStringAsFixed(1),
      onChanged: (v) {
        onDragStart();
        onChanged(params.copyWith(sfN3: v));
      },
      onChangeEnd: (v) => onDragEnd(params.copyWith(sfN3: v)),
    ),
    _SliderRow(
      label: l10n.sliderSfA,
      value: params.sfA.clamp(0.5, 2),
      min: 0.5, max: 2,
      valueLabel: params.sfA.toStringAsFixed(2),
      onChanged: (v) {
        onDragStart();
        onChanged(params.copyWith(sfA: v));
      },
      onChangeEnd: (v) => onDragEnd(params.copyWith(sfA: v)),
    ),
    _SliderRow(
      label: l10n.sliderSfB,
      value: params.sfB.clamp(0.5, 2),
      min: 0.5, max: 2,
      valueLabel: params.sfB.toStringAsFixed(2),
      onChanged: (v) {
        onDragStart();
        onChanged(params.copyWith(sfB: v));
      },
      onChangeEnd: (v) => onDragEnd(params.copyWith(sfB: v)),
    ),
  ];
}

/// 대칭/비대칭 토글 버튼.
class _ModeToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
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
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
