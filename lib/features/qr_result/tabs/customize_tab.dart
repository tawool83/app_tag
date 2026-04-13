import 'package:flutter/material.dart';
import '../../../models/qr_template.dart' show QrGradient;
import '../qr_result_provider.dart' show QrEyeStyle, qrSafeColors, kQrPresetGradients;

// 중앙 아이콘 옵션
enum QrCenterOption { none, defaultIcon, emoji }

// 이모지 카테고리 목록
const _kEmojiCategories = [
  ('스마일', ['😀', '😂', '🥰', '😎', '🤔', '🥳', '😴', '🤩']),
  ('제스처', ['👋', '👍', '🙌', '💪', '🤝', '🤙', '👏', '✌️']),
  ('사물', ['📱', '💻', '🖥️', '📷', '🎧', '📺', '⌚', '🔋']),
  ('장소', ['🏠', '🏢', '🏪', '🏨', '🏦', '🏥', '🏫', '⛪']),
  ('음식', ['🍕', '🍔', '🍜', '☕', '🍺', '🍰', '🍎', '🥗']),
  ('자연', ['🌸', '🌺', '🌈', '⭐', '🌙', '☀️', '🌊', '🍀']),
  ('활동', ['🎮', '🎵', '🎨', '⚽', '🎯', '🎲', '📚', '✏️']),
  ('교통', ['🚗', '✈️', '🚂', '🚢', '🚲', '🛵', '🚀', '🗺️']),
];

const _kMinPrintSize = 2.5;
const _kMaxPrintSize = 20.0;
const _kSizeStep = 0.5;

// 아이 모양 프리셋 (QrEyeStyle 매핑)
const _kEyePresets = [
  (label: '사각형',   style: QrEyeStyle.square),
  (label: '둥글기',   style: QrEyeStyle.rounded),
  (label: '원형',     style: QrEyeStyle.circle),
  (label: '부드럽게', style: QrEyeStyle.smooth),
];

/// [꾸미기] 탭: 색상, 도트 스타일, 중앙 아이콘, 텍스트 레이블, 인쇄 크기.
class CustomizeTab extends StatelessWidget {
  final TextEditingController labelController;
  final TextEditingController printTitleController;
  final Color selectedColor;
  final QrGradient? customGradient;
  final double printSizeCm;
  final double roundFactor;
  final QrEyeStyle eyeStyle;
  final QrCenterOption centerOption;
  final String? centerEmoji;
  final bool hasDefaultIcon;
  final ValueChanged<String> onLabelChanged;
  final ValueChanged<String> onPrintTitleChanged;
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<QrGradient?> onGradientChanged;
  final ValueChanged<double> onSizeChanged;
  final ValueChanged<double> onRoundFactorChanged;
  final ValueChanged<QrEyeStyle> onEyeStyleChanged;
  final ValueChanged<QrCenterOption> onCenterOptionChanged;
  final ValueChanged<String> onEmojiSelected;

  const CustomizeTab({
    super.key,
    required this.labelController,
    required this.printTitleController,
    required this.selectedColor,
    required this.customGradient,
    required this.printSizeCm,
    required this.roundFactor,
    required this.eyeStyle,
    required this.centerOption,
    required this.centerEmoji,
    required this.hasDefaultIcon,
    required this.onLabelChanged,
    required this.onPrintTitleChanged,
    required this.onColorSelected,
    required this.onGradientChanged,
    required this.onSizeChanged,
    required this.onRoundFactorChanged,
    required this.onEyeStyleChanged,
    required this.onCenterOptionChanged,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 인쇄 상단 문구
          _sectionLabel('인쇄 상단 문구'),
          const SizedBox(height: 8),
          TextField(
            controller: printTitleController,
            onChanged: onPrintTitleChanged,
            decoration: _inputDeco('비워두면 표시 안 함'),
          ),
          const SizedBox(height: 16),

          // QR 하단 문구
          _sectionLabel('QR 하단 문구'),
          const SizedBox(height: 8),
          TextField(
            controller: labelController,
            onChanged: onLabelChanged,
            decoration: _inputDeco('비워두면 표시 안 함'),
          ),
          const SizedBox(height: 16),

          // QR 색상 / 그라디언트
          _sectionLabel('QR 색상'),
          const SizedBox(height: 8),
          // 단색 / 그라디언트 토글
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
          if (customGradient == null) ...[
            // 단색 팔레트
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: qrSafeColors
                  .map((c) => _ColorChip(
                        color: c,
                        isSelected: c.toARGB32() == selectedColor.toARGB32(),
                        onTap: () => onColorSelected(c),
                      ))
                  .toList(),
            ),
          ] else ...[
            // 그라디언트 팔레트
            _GradientPicker(
              selected: customGradient,
              onSelected: onGradientChanged,
            ),
          ],
          const SizedBox(height: 16),

          // 아이 모양 (eye shape preset — finder pattern 전용)
          _sectionLabel('아이 모양'),
          const SizedBox(height: 10),
          _EyeShapeSelector(
            eyeStyle: eyeStyle,
            onSelected: onEyeStyleChanged,
          ),
          const SizedBox(height: 16),

          // 도트 둥글기 (roundFactor)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('도트 둥글기'),
              Text(
                roundFactor == 0.0
                    ? '사각형'
                    : roundFactor == 1.0
                        ? '원형'
                        : '${(roundFactor * 100).round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: roundFactor,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: onRoundFactorChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('■ 사각형',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              Text('● 원형',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 16),

          // 중앙 아이콘
          _sectionLabel('중앙 아이콘'),
          const SizedBox(height: 8),
          _ShapeToggle<QrCenterOption>(
            selected: centerOption,
            options: [
              (QrCenterOption.none, '없음'),
              if (hasDefaultIcon) (QrCenterOption.defaultIcon, '기본 아이콘'),
              (QrCenterOption.emoji, '이모지'),
            ],
            onChanged: onCenterOptionChanged,
          ),

          // 이모지 그리드
          if (centerOption == QrCenterOption.emoji) ...[
            const SizedBox(height: 12),
            _EmojiGrid(
              selectedEmoji: centerEmoji,
              onEmojiTap: onEmojiSelected,
            ),
          ],
          const SizedBox(height: 16),

          // 인쇄 크기 슬라이더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('인쇄 크기 (정사각형)'),
              Text(
                '${printSizeCm.toStringAsFixed(1)} cm',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: printSizeCm,
            min: _kMinPrintSize,
            max: _kMaxPrintSize,
            divisions:
                ((_kMaxPrintSize - _kMinPrintSize) / _kSizeStep).round(),
            label: '${printSizeCm.toStringAsFixed(1)} cm',
            onChanged: onSizeChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_kMinPrintSize.toStringAsFixed(1)} cm',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text('${_kMaxPrintSize.toStringAsFixed(0)} cm',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    );
  }

  static InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}

// ── 아이 모양 선택기 ────────────────────────────────────────────────────────────

class _EyeShapeSelector extends StatelessWidget {
  final QrEyeStyle eyeStyle;
  final ValueChanged<QrEyeStyle> onSelected;

  const _EyeShapeSelector({
    required this.eyeStyle,
    required this.onSelected,
  });

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
                  child: Center(
                    child: _EyeIcon(style: preset.style),
                  ),
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

/// QR 아이(눈) 모양을 미리보기로 표시하는 아이콘 위젯.
/// 바깥 테두리 + 안쪽 채운 사각형으로 QR eye 구조를 표현.
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
          // 바깥 테두리
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 2.5),
              borderRadius: _outerRadius,
            ),
          ),
          // 안쪽 채운 사각형
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

// ── 색상 칩 ───────────────────────────────────────────────────────────────────

class _ColorChip extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorChip({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 6,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}

// ── 모양 선택 토글 ────────────────────────────────────────────────────────────

class _ShapeToggle<T> extends StatelessWidget {
  final T selected;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  const _ShapeToggle({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

// ── 이모지 그리드 ──────────────────────────────────────────────────────────────

class _EmojiGrid extends StatelessWidget {
  final String? selectedEmoji;
  final ValueChanged<String> onEmojiTap;

  const _EmojiGrid({required this.selectedEmoji, required this.onEmojiTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _kEmojiCategories.map((cat) {
        final (name, emojis) = cat;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: emojis.map((emoji) {
                final isSelected = selectedEmoji == emoji;
                return GestureDetector(
                  onTap: () => onEmojiTap(emoji),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
        );
      }).toList(),
    );
  }
}

// ── 그라디언트 선택기 ─────────────────────────────────────────────────────────

class _GradientPicker extends StatelessWidget {
  final QrGradient? selected;
  final ValueChanged<QrGradient> onSelected;

  const _GradientPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: kQrPresetGradients.map((g) {
        final isSelected = selected != null &&
            selected!.type == g.type &&
            selected!.angleDegrees == g.angleDegrees &&
            selected!.colors.first.toARGB32() == g.colors.first.toARGB32();
        return GestureDetector(
          onTap: () => onSelected(g),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: g.type == 'radial'
                  ? RadialGradient(colors: g.colors, stops: g.stops)
                  : LinearGradient(
                      colors: g.colors,
                      stops: g.stops,
                      transform: GradientRotation(
                          g.angleDegrees * 3.14159 / 180),
                    ),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: g.colors.first.withValues(alpha: 0.4),
                        blurRadius: 6,
                      )
                    ]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
