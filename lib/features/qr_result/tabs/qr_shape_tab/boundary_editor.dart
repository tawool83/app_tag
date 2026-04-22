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
                      // 타입 변경 시 프레임 모드 기본값 설정
                      var updated = params.copyWith(type: type);
                      if (type != QrBoundaryType.square &&
                          params.frameScale <= 1.0) {
                        updated = updated.copyWith(frameScale: 1.4);
                      }
                      onChanged(updated);
                      onDragEnd(updated);
                    },
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),

        // ── 프레임 크기 슬라이더 (type != square) ──
        if (params.type != QrBoundaryType.square)
          _SliderRow(
            label: l10n.sliderFrameScale,
            value: params.frameScale.clamp(1.0, 2.0),
            min: 1.0,
            max: 2.0,
            valueLabel: '${params.frameScale.toStringAsFixed(1)}x',
            onChanged: (v) {
              onDragStart();
              onChanged(params.copyWith(frameScale: v));
            },
            onChangeEnd: (v) => onDragEnd(params.copyWith(frameScale: v)),
          ),

        // ── 마진 패턴 선택 (프레임 모드일 때만) ──
        if (params.isFrameMode) ...[
          const SizedBox(height: 8),
          _sectionLabel(l10n.labelMarginPattern),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: QrMarginPattern.values.map((p) {
              return ChoiceChip(
                label: Text(_patternLabel(p, l10n)),
                selected: params.marginPattern == p,
                onSelected: (_) {
                  final updated = params.copyWith(marginPattern: p);
                  onChanged(updated);
                  onDragEnd(updated);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // ── 패턴 밀도 (패턴 != none) ──
        if (params.isFrameMode &&
            params.marginPattern != QrMarginPattern.none)
          _SliderRow(
            label: l10n.sliderPatternDensity,
            value: params.patternDensity.clamp(0.5, 2.0),
            min: 0.5,
            max: 2.0,
            valueLabel: '${params.patternDensity.toStringAsFixed(1)}x',
            onChanged: (v) {
              onDragStart();
              onChanged(params.copyWith(patternDensity: v));
            },
            onChangeEnd: (v) =>
                onDragEnd(params.copyWith(patternDensity: v)),
          ),

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
        // 패딩 (비프레임 모드에서만 — 프레임 모드는 frameScale 이 역할 대체)
        if (!params.isFrameMode)
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

  static String _patternLabel(QrMarginPattern p, AppLocalizations l10n) {
    return switch (p) {
      QrMarginPattern.none => l10n.patternNone,
      QrMarginPattern.qrDots => l10n.patternQrDots,
      QrMarginPattern.maze => l10n.patternMaze,
      QrMarginPattern.zigzag => l10n.patternZigzag,
      QrMarginPattern.wave => l10n.patternWave,
      QrMarginPattern.grid => l10n.patternGrid,
    };
  }

  static Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500));
}
