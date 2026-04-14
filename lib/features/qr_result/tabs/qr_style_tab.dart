import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/qr_dot_style.dart';
import '../../../models/qr_template.dart' show QrGradient;
import '../qr_result_provider.dart' show QrEyeStyle, qrSafeColors, kQrPresetGradients, qrResultProvider;

// 눈 모양 프리셋
const _kEyePresets = [
  (label: '사각형',   style: QrEyeStyle.square),
  (label: '둥글기',   style: QrEyeStyle.rounded),
  (label: '원형',     style: QrEyeStyle.circle),
  (label: '부드럽게', style: QrEyeStyle.smooth),
];

/// [QR] 탭: 도트 모양, 눈 모양, 색상/그라디언트.
class QrStyleTab extends ConsumerWidget {
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<QrGradient?> onGradientChanged;
  final ValueChanged<QrDotStyle> onDotStyleChanged;
  final ValueChanged<QrEyeStyle> onEyeStyleChanged;
  const QrStyleTab({
    super.key,
    required this.onColorSelected,
    required this.onGradientChanged,
    required this.onDotStyleChanged,
    required this.onEyeStyleChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qrResultProvider);
    final dotStyle = state.dotStyle;
    final eyeStyle = state.eyeStyle;
    final selectedColor = state.qrColor;
    final customGradient = state.customGradient;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ① 도트 모양
          _sectionLabel('도트 모양'),
          const SizedBox(height: 10),
          _DotStyleGrid(selected: dotStyle, onSelected: onDotStyleChanged),
          const SizedBox(height: 16),

          // ② 눈 모양
          _sectionLabel('눈 모양'),
          const SizedBox(height: 10),
          _EyeShapeSelector(eyeStyle: eyeStyle, onSelected: onEyeStyleChanged),
          const SizedBox(height: 16),

          // ③ QR 색상
          _sectionLabel('QR 색상'),
          const SizedBox(height: 8),
          _ShapeToggle<bool>(
            selected: customGradient != null,
            options: const [(false, '단색'), (true, '그라디언트')],
            onChanged: (isGradient) {
              if (!isGradient) {
                onGradientChanged(null);
              } else if (customGradient == null) {
                onGradientChanged(kQrPresetGradients.first);
              }
            },
          ),
          const SizedBox(height: 10),
          if (customGradient == null)
            _HorizontalColorPicker(
              colors: qrSafeColors,
              selected: selectedColor,
              onSelected: onColorSelected,
            )
          else
            _GradientPicker(selected: customGradient, onSelected: onGradientChanged),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      );
}

// ── 도트 모양 그리드 ───────────────────────────────────────────────────────────

class _DotStyleGrid extends StatelessWidget {
  final QrDotStyle selected;
  final ValueChanged<QrDotStyle> onSelected;

  const _DotStyleGrid({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final styles = QrDotStyle.values;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.1,
      ),
      itemCount: styles.length,
      itemBuilder: (context, i) {
        final style = styles[i];
        final label = kQrDotStyleLabels[style] ?? '';
        final isSelected = selected == style;
        return GestureDetector(
          onTap: () => onSelected(style),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
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
                  fontSize: 18,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black87,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── 수평 스크롤 색상 선택기 ────────────────────────────────────────────────────

class _HorizontalColorPicker extends StatelessWidget {
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelected;

  const _HorizontalColorPicker({
    required this.colors,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: _NoScrollbarBehavior(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: colors.map((c) {
            final isSelected = c.toARGB32() == selected.toARGB32();
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => onSelected(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6)]
                        : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// 스크롤바 숨기기 behaviour
class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;
}

// ── 눈 모양 선택기 ────────────────────────────────────────────────────────────

class _EyeShapeSelector extends StatelessWidget {
  final QrEyeStyle eyeStyle;
  final ValueChanged<QrEyeStyle> onSelected;

  const _EyeShapeSelector({required this.eyeStyle, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_kEyePresets.length, (i) {
        final preset = _kEyePresets[i];
        final isSelected = eyeStyle == preset.style;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => onSelected(preset.style),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
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
                  child: Center(child: _EyeIcon(style: preset.style)),
                ),
                const SizedBox(height: 4),
                Text(
                  preset.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _EyeIcon extends StatelessWidget {
  final QrEyeStyle style;
  const _EyeIcon({required this.style});

  BorderRadius get _outerRadius {
    switch (style) {
      case QrEyeStyle.square:  return BorderRadius.zero;
      case QrEyeStyle.rounded: return BorderRadius.circular(5);
      case QrEyeStyle.circle:  return BorderRadius.circular(14);
      case QrEyeStyle.smooth:  return BorderRadius.circular(8);
    }
  }

  BorderRadius get _innerRadius {
    switch (style) {
      case QrEyeStyle.square:  return BorderRadius.zero;
      case QrEyeStyle.rounded: return BorderRadius.circular(3);
      case QrEyeStyle.circle:  return BorderRadius.circular(7);
      case QrEyeStyle.smooth:  return BorderRadius.circular(5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28, height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 2.5),
              borderRadius: _outerRadius,
            ),
          ),
          Container(
            width: 14, height: 14,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: _innerRadius,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 모양 토글 / 그라디언트 선택기 ─────────────────────────────────────────────

class _ShapeToggle<T> extends StatelessWidget {
  final T selected;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  const _ShapeToggle({required this.selected, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final (value, label) = opt;
        final isSelected = selected == value;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GradientPicker extends StatelessWidget {
  final QrGradient? selected;
  final ValueChanged<QrGradient> onSelected;

  const _GradientPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: kQrPresetGradients.map((g) {
        final isSelected = selected != null &&
            selected!.type == g.type &&
            selected!.angleDegrees == g.angleDegrees &&
            selected!.colors.first.toARGB32() == g.colors.first.toARGB32();
        return GestureDetector(
          onTap: () => onSelected(g),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: g.type == 'radial'
                  ? RadialGradient(colors: g.colors, stops: g.stops)
                  : LinearGradient(
                      colors: g.colors,
                      stops: g.stops,
                      transform: GradientRotation(g.angleDegrees * 3.14159 / 180),
                    ),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: g.colors.first.withValues(alpha: 0.4), blurRadius: 6)]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
