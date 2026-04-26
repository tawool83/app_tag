part of '../qr_background_tab.dart';

// ── Boundary 편집기 ────────────────────────────────────────��───────────────

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

  static const _boundaryTypes = [
    QrBoundaryType.circle,
    QrBoundaryType.superellipse,
    QrBoundaryType.star,
    QrBoundaryType.heart,
    QrBoundaryType.hexagon,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Row 1: 외곽 종류 + 선 종류 ──
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<QrBoundaryType>(
                initialValue: _boundaryTypes.contains(params.type)
                    ? params.type
                    : QrBoundaryType.circle,
                decoration: InputDecoration(
                  labelText: l10n.labelBoundaryType,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: _boundaryTypes
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_boundaryTypeLabel(t, l10n),
                              style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (type) {
                  if (type == null) return;
                  var updated = params.copyWith(type: type);
                  if (params.frameScale < 1.1) {
                    updated = updated.copyWith(frameScale: 1.4);
                  }
                  onChanged(updated);
                  onDragEnd(updated);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<QrBorderStyle>(
                initialValue: params.borderStyle,
                decoration: InputDecoration(
                  labelText: l10n.labelBorderStyle,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: QrBorderStyle.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(_borderStyleLabel(s, l10n),
                              style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (style) {
                  if (style == null) return;
                  final updated = params.copyWith(borderStyle: style);
                  onChanged(updated);
                  onDragEnd(updated);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── 선 두께 (borderStyle != none) ──
        if (params.borderStyle != QrBorderStyle.none)
          _SliderRow(
            label: l10n.sliderBorderWidth,
            value: params.borderWidth.clamp(1.0, 6.0),
            min: 1.0,
            max: 6.0,
            valueLabel: params.borderWidth.toStringAsFixed(1),
            onChanged: (v) {
              onDragStart();
              onChanged(params.copyWith(borderWidth: v));
            },
            onChangeEnd: (v) => onDragEnd(params.copyWith(borderWidth: v)),
          ),

        // ── 프레임 크기 슬라이더 ──
        _SliderRow(
            label: l10n.sliderFrameScale,
            value: params.frameScale.clamp(1.1, 3.0),
            min: 1.1,
            max: 3.0,
            valueLabel: '${params.frameScale.toStringAsFixed(1)}x',
            onChanged: (v) {
              onDragStart();
              onChanged(params.copyWith(frameScale: v));
            },
            onChangeEnd: (v) => onDragEnd(params.copyWith(frameScale: v)),
          ),

        // Superellipse N (superellipse/custom 타입)
        if (params.type == QrBoundaryType.superellipse ||
            params.type == QrBoundaryType.custom)
          _SliderRow(
            label: l10n.sliderSuperellipseN,
            value: params.superellipseN,
            min: 2,
            max: 20,
            valueLabel: params.superellipseN.toStringAsFixed(1),
            onChanged: (v) {
              onDragStart();
              onChanged(params.copyWith(superellipseN: v));
            },
            onChangeEnd: (v) =>
                onDragEnd(params.copyWith(superellipseN: v)),
          ),
        // Star 전용 슬라이더
        if (params.type == QrBoundaryType.star) ...[
          _SliderRow(
            label: l10n.sliderStarVertices,
            value: params.starVertices.toDouble(),
            min: 5,
            max: 12,
            divisions: 7,
            valueLabel: '${params.starVertices}',
            onChanged: (v) {
              onDragStart();
              onChanged(params.copyWith(starVertices: v.round()));
            },
            onChangeEnd: (v) =>
                onDragEnd(params.copyWith(starVertices: v.round())),
          ),
          _SliderRow(
            label: l10n.sliderStarInnerRadius,
            value: params.starInnerRadius,
            min: 0.3,
            max: 0.8,
            valueLabel: params.starInnerRadius.toStringAsFixed(2),
            onChanged: (v) {
              onDragStart();
              onChanged(params.copyWith(starInnerRadius: v));
            },
            onChangeEnd: (v) =>
                onDragEnd(params.copyWith(starInnerRadius: v)),
          ),
        ],
        // 공통: 회전
        _SliderRow(
          label: l10n.sliderRotation,
          value: params.rotation,
          min: 0,
          max: 360,
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
            min: 0,
            max: 1,
            valueLabel: params.roundness.toStringAsFixed(2),
            onChanged: (v) {
              onDragStart();
              onChanged(params.copyWith(roundness: v));
            },
            onChangeEnd: (v) => onDragEnd(params.copyWith(roundness: v)),
          ),

        // ── 마진 패턴 드롭다운 (isFrameMode) ──
        if (params.isFrameMode) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<QrMarginPattern>(
            initialValue: params.marginPattern,
            decoration: InputDecoration(
              labelText: l10n.labelMarginPattern,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            items: QrMarginPattern.values
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(_patternLabel(p, l10n),
                          style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            onChanged: (p) {
              if (p == null) return;
              final updated = params.copyWith(marginPattern: p);
              onChanged(updated);
              onDragEnd(updated);
            },
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

        // 패딩 (비프레임 모드에서만)
        if (!params.isFrameMode)
          _SliderRow(
            label: l10n.sliderPadding,
            value: params.padding,
            min: 0,
            max: 0.15,
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

  // ── 라벨 매핑 ──

  static String _boundaryTypeLabel(QrBoundaryType t, AppLocalizations l10n) {
    return switch (t) {
      QrBoundaryType.circle => l10n.boundaryCircle,
      QrBoundaryType.superellipse => l10n.boundarySuperellipse,
      QrBoundaryType.star => l10n.boundaryStar,
      QrBoundaryType.heart => l10n.boundaryHeart,
      QrBoundaryType.hexagon => l10n.boundaryHexagon,
      _ => t.name,
    };
  }

  static String _borderStyleLabel(QrBorderStyle s, AppLocalizations l10n) {
    return switch (s) {
      QrBorderStyle.none => l10n.borderNone,
      QrBorderStyle.solid => l10n.borderSolid,
      QrBorderStyle.dashed => l10n.borderDashed,
      QrBorderStyle.dotted => l10n.borderDotted,
      QrBorderStyle.dashDot => l10n.borderDashDot,
      QrBorderStyle.double_ => l10n.borderDouble,
    };
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

}
