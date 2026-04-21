part of '../qr_shape_tab.dart';

// ── 커스텀 눈 프리셋 행 ───────────────────────────────────────────────────────

class _CustomEyeRow extends StatelessWidget {
  final List<UserShapePreset> presets;
  final VoidCallback onAdd;
  final ValueChanged<UserShapePreset> onSelect;
  final ValueChanged<UserShapePreset> onDelete;

  const _CustomEyeRow({
    required this.presets,
    required this.onAdd,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _AddButton(onTap: onAdd),
          ...presets.map((p) => _PresetChip(
                preset: p,
                onTap: () => onSelect(p),
                onLongPress: () => onDelete(p),
              )),
        ],
      ),
    );
  }
}

// ── 눈 외곽 모양 행 (기존) ──────────────────────────────────────────────────

Map<QrEyeOuter, String> _outerLabels(AppLocalizations l10n) => {
  QrEyeOuter.square:      l10n.shapeSquare,
  QrEyeOuter.rounded:     l10n.shapeRounded,
  QrEyeOuter.circle:      l10n.shapeCircle,
  QrEyeOuter.circleRound: l10n.shapeCircleRound,
  QrEyeOuter.smooth:      l10n.shapeSmooth,
};

class _OuterShapeRow extends StatelessWidget {
  final QrEyeOuter? selected;
  final ValueChanged<QrEyeOuter> onSelected;

  const _OuterShapeRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final labels = _outerLabels(AppLocalizations.of(context)!);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: QrEyeOuter.values.map((outer) {
        final isSelected = selected == outer;
        return _ShapeButton(
          isSelected: isSelected,
          dimmed: selected == null,
          onTap: () => onSelected(outer),
          tooltip: labels[outer] ?? '',
          child: CustomPaint(
            size: const Size(26, 26),
            painter: _OuterIconPainter(outer, isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.black87),
          ),
        );
      }).toList(),
    );
  }
}

// ── 눈 내부 모양 행 (기존) ──────────────────────────────────────────────────

Map<QrEyeInner, String> _innerLabels(AppLocalizations l10n) => {
  QrEyeInner.square:  l10n.shapeSquare,
  QrEyeInner.circle:  l10n.shapeCircle,
  QrEyeInner.diamond: l10n.shapeDiamond,
  QrEyeInner.star:    l10n.shapeStar,
};

class _InnerShapeRow extends StatelessWidget {
  final QrEyeInner? selected;
  final ValueChanged<QrEyeInner> onSelected;

  const _InnerShapeRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final labels = _innerLabels(AppLocalizations.of(context)!);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: QrEyeInner.values.map((inner) {
        final isSelected = selected == inner;
        return _ShapeButton(
          isSelected: isSelected,
          dimmed: selected == null,
          onTap: () => onSelected(inner),
          tooltip: labels[inner] ?? '',
          child: CustomPaint(
            size: const Size(26, 26),
            painter: _InnerIconPainter(inner, isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.black87),
          ),
        );
      }).toList(),
    );
  }
}

// ── 랜덤 눈 버튼 ──────────────────────────────────────────────────────────────

class _RandomEyeButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onGenerate;
  final VoidCallback onClear;

  const _RandomEyeButton({
    required this.isActive,
    required this.onGenerate,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.casino_outlined, size: 18),
            label: Text(isActive ? l10n.actionRandomRegenerate : l10n.actionRandomEye),
            style: FilledButton.styleFrom(
              backgroundColor: isActive
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (isActive) ...[
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            child: Text(l10n.actionClear),
          ),
        ],
      ],
    );
  }
}

// ── 아이콘 Painter ─────────────────────────────────────────────────────────────

class _OuterIconPainter extends CustomPainter {
  final QrEyeOuter outer;
  final Color color;
  const _OuterIconPainter(this.outer, this.color);

  void _addOuter(Path path, Rect r) {
    switch (outer) {
      case QrEyeOuter.square:
        path.addRect(r);
      case QrEyeOuter.rounded:
        path.addRRect(RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.18)));
      case QrEyeOuter.circle:
        path.addOval(r);
      case QrEyeOuter.circleRound:
        path.addOval(r);
      case QrEyeOuter.smooth:
        path.addRRect(RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.32)));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    final hole = r.deflate(size.width / 5);

    final path = Path()..fillType = PathFillType.evenOdd;
    _addOuter(path, r);
    if (outer == QrEyeOuter.circleRound) {
      path.addOval(hole);
    } else {
      path.addRect(hole);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OuterIconPainter old) => old.outer != outer || old.color != color;
}

class _InnerIconPainter extends CustomPainter {
  final QrEyeInner inner;
  final Color color;
  const _InnerIconPainter(this.inner, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final r = Rect.fromLTWH(
      size.width * 0.15, size.height * 0.15,
      size.width * 0.70, size.height * 0.70,
    );
    canvas.drawPath(_innerPath(r), paint);
  }

  Path _innerPath(Rect r) {
    switch (inner) {
      case QrEyeInner.square:
        return Path()..addRect(r);
      case QrEyeInner.circle:
        return Path()..addOval(r);
      case QrEyeInner.diamond:
        return Path()
          ..moveTo(r.center.dx, r.top)
          ..lineTo(r.right, r.center.dy)
          ..lineTo(r.center.dx, r.bottom)
          ..lineTo(r.left, r.center.dy)
          ..close();
      case QrEyeInner.star:
        return _starPath(r.center, r.width / 2, r.width * 0.22, 4);
    }
  }

  Path _starPath(Offset center, double outer, double innerR, int points) {
    final path = Path();
    final total = points * 2;
    for (int i = 0; i < total; i++) {
      final rr = i.isEven ? outer : innerR;
      final angle = (i * math.pi / points) - math.pi / 2;
      final pt = Offset(center.dx + rr * math.cos(angle), center.dy + rr * math.sin(angle));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_InnerIconPainter old) => old.inner != inner || old.color != color;
}
