import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/qr_dot_style.dart';
import '../qr_result_provider.dart' show QrEyeStyle, qrResultProvider;

// 눈 모양 프리셋
const _kEyePresets = [
  (label: '사각형',   style: QrEyeStyle.square),
  (label: '둥글기',   style: QrEyeStyle.rounded),
  (label: '원형',     style: QrEyeStyle.circle),
  (label: '부드럽게', style: QrEyeStyle.smooth),
];

/// [모양] 탭: 도트 모양 + 눈 모양 선택.
class QrShapeTab extends ConsumerWidget {
  final ValueChanged<QrDotStyle> onDotStyleChanged;
  final ValueChanged<QrEyeStyle> onEyeStyleChanged;

  const QrShapeTab({
    super.key,
    required this.onDotStyleChanged,
    required this.onEyeStyleChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qrResultProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ① 도트 모양
          _sectionLabel('도트 모양'),
          const SizedBox(height: 10),
          _DotStyleGrid(
            selected: state.dotStyle,
            onSelected: onDotStyleChanged,
          ),
          const SizedBox(height: 20),

          const Divider(height: 1),
          const SizedBox(height: 16),

          // ② 눈 모양
          _sectionLabel('눈 모양'),
          const SizedBox(height: 10),
          _EyeShapeSelector(
            eyeStyle: state.eyeStyle,
            onSelected: onEyeStyleChanged,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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

// ── 눈 모양 선택기 ────────────────────────────────────────────────────────────

class _EyeShapeSelector extends StatelessWidget {
  final QrEyeStyle eyeStyle;
  final ValueChanged<QrEyeStyle> onSelected;

  const _EyeShapeSelector(
      {required this.eyeStyle, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_kEyePresets.length, (i) {
        final preset = _kEyePresets[i];
        final isSelected = eyeStyle == preset.style;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => onSelected(preset.style),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 48,
                  height: 48,
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
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
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
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 2.5),
              borderRadius: _outerRadius,
            ),
          ),
          Container(
            width: 14,
            height: 14,
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
