part of '../qr_shape_tab.dart';

// ── "+" 추가 버튼 ────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Icon(Icons.add, size: 24, color: Colors.grey),
        ),
      ),
    );
  }
}

// ── 프리셋 칩 (모양 미리보기 표시) ───────────────────────────────────────────

class _PresetChip extends StatelessWidget {
  final UserShapePreset preset;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PresetChip({
    required this.preset,
    this.isSelected = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
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
          child: Stack(
            children: [
              Center(
                child: CustomPaint(
                  size: const Size(32, 32),
                  painter: _PresetIconPainter(preset: preset),
                ),
              ),
              if (isSelected)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Icon(Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 프리셋의 모양을 작은 아이콘으로 렌더링.
class _PresetIconPainter extends CustomPainter {
  final UserShapePreset preset;
  const _PresetIconPainter({required this.preset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    if (preset.dotParams != null) {
      final path = PolarPolygon.buildPath(center, radius * preset.dotParams!.scale, preset.dotParams!);
      canvas.drawPath(path, paint);
    } else if (preset.eyeParams != null) {
      final bounds = Rect.fromCenter(center: center, width: size.width * 0.8, height: size.height * 0.8);
      SuperellipsePath.paintEye(canvas, bounds, preset.eyeParams!, paint);
    } else if (preset.boundaryParams != null) {
      final clipPath = QrBoundaryClipper.buildClipPath(size, preset.boundaryParams!);
      if (clipPath != null) {
        canvas.drawPath(clipPath, paint..style = PaintingStyle.stroke..strokeWidth = 1.5);
      } else {
        canvas.drawRect(Offset.zero & size, paint..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
    } else if (preset.animParams != null) {
      final tp = _animTextPainters[preset.animParams!.type] ??=
          _buildAnimTextPainter(preset.animParams!.type);
      tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
    }
  }

  @override
  bool shouldRepaint(_PresetIconPainter old) => preset != old.preset;

  // 애니메이션 타입별 TextPainter 공유 캐시 (6종 고정, 레이아웃 비용 절감).
  static final Map<QrAnimationType, TextPainter> _animTextPainters = {};

  static TextPainter _buildAnimTextPainter(QrAnimationType type) {
    final text = switch (type) {
      QrAnimationType.none => 'Off',
      QrAnimationType.wave => '~',
      QrAnimationType.rainbow => '🌈',
      QrAnimationType.pulse => '♥',
      QrAnimationType.sequential => '►',
      QrAnimationType.rotationWave => '↻',
    };
    return TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }
}

// ── 공용 슬라이더 행 ──────────────────────────────────────────────────────────

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.valueLabel,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(valueLabel,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

// ── 공용 Shape 버튼 ───────────────────────────────────────────────────────────

class _ShapeButton extends StatelessWidget {
  final bool isSelected;
  final bool dimmed;
  final VoidCallback onTap;
  final Widget child;
  final String tooltip;

  const _ShapeButton({
    required this.isSelected,
    required this.dimmed,
    required this.onTap,
    required this.child,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: dimmed ? 0.4 : 1.0,
          child: AnimatedContainer(
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
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
