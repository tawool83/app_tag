part of '../qr_color_tab.dart';

// ── 섹션 헤더 ──────────────────────────────────────────────────────────────

/// 섹션 라벨 + 선택적 삭제 아이콘 (user preset 이 있을 때만 표시).
class _SectionLabelWithDelete extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleteTap;

  const _SectionLabelWithDelete({
    required this.label,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        if (onDeleteTap != null)
          GestureDetector(
            onTap: onDeleteTap,
            child: Icon(
              Icons.delete_outline,
              size: 18,
              color: Colors.grey.shade600,
            ),
          ),
      ],
    );
  }
}

// ── 단색 원형 버튼 ───────────────────────────────────────────────────────────

class _ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
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
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}

// ── 그라디언트 원형 버튼 ──────────────────────────────────────────────────────

class _GradientCircle extends StatelessWidget {
  final QrGradient gradient;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _GradientCircle({
    required this.gradient,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: gradient.type == 'radial'
              ? RadialGradient(colors: gradient.colors, stops: gradient.stops)
              : LinearGradient(
                  colors: gradient.colors,
                  stops: gradient.stops,
                  transform: GradientRotation(
                      gradient.angleDegrees * math.pi / 180),
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
                      color: gradient.colors.first.withValues(alpha: 0.4),
                      blurRadius: 6)
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}

// ── "+" 추가 버튼 ────────────────────────────────────────────────────────────

class _AddCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const _AddCircleButton({required this.onTap, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400),
          color: Colors.grey.shade50,
        ),
        child: Icon(
          Icons.add,
          size: size < 40 ? 18 : 20,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

// ── "···" 더보기 버튼 ────────────────────────────────────────────────────────

class _MoreCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const _MoreCircleButton({required this.onTap, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400),
          color: Colors.grey.shade100,
        ),
        child: Center(
          child: Text(
            '···',
            style: TextStyle(
              fontSize: size < 40 ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── 라벨 + 드롭다운 (편집기용) ──────────────────────────────────────────────

class _LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          isDense: true,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
          ),
          style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
      ],
    );
  }
}
