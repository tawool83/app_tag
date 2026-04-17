import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/qr_dot_style.dart';
import '../../../l10n/app_localizations.dart';
import '../qr_result_provider.dart' show QrEyeOuter, QrEyeInner, qrResultProvider;

/// [모양] 탭: 도트 모양 + 눈 외곽/내부 독립 선택 + 랜덤 눈 생성.
class QrShapeTab extends ConsumerWidget {
  final ValueChanged<QrDotStyle> onDotStyleChanged;
  final ValueChanged<QrEyeOuter> onEyeOuterChanged;
  final ValueChanged<QrEyeInner> onEyeInnerChanged;
  final VoidCallback onRandomEyeRequested;
  final VoidCallback onRandomEyeCleared;

  const QrShapeTab({
    super.key,
    required this.onDotStyleChanged,
    required this.onEyeOuterChanged,
    required this.onEyeInnerChanged,
    required this.onRandomEyeRequested,
    required this.onRandomEyeCleared,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qrResultProvider);
    final isRandom = state.randomEyeSeed != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ① 도트 모양
          _sectionLabel(AppLocalizations.of(context)!.labelDotShape),
          const SizedBox(height: 10),
          _DotStyleGrid(selected: state.dotStyle, onSelected: onDotStyleChanged),
          const SizedBox(height: 20),

          const Divider(height: 1),
          const SizedBox(height: 16),

          // ② 눈 모양 — 외곽
          _sectionLabel(AppLocalizations.of(context)!.labelEyeOuter),
          const SizedBox(height: 10),
          _OuterShapeRow(
            selected: isRandom ? null : state.eyeOuter,
            onSelected: onEyeOuterChanged,
          ),
          const SizedBox(height: 14),

          // ③ 눈 모양 — 내부
          _sectionLabel(AppLocalizations.of(context)!.labelEyeInner),
          const SizedBox(height: 10),
          _InnerShapeRow(
            selected: isRandom ? null : state.eyeInner,
            onSelected: onEyeInnerChanged,
          ),
          const SizedBox(height: 16),

          // ④ 랜덤 버튼
          _RandomEyeButton(
            isActive: isRandom,
            onGenerate: onRandomEyeRequested,
            onClear: onRandomEyeCleared,
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

// ── 눈 외곽 모양 행 ──────────────────────────────────────────────────────────

Map<QrEyeOuter, String> _outerLabels(AppLocalizations l10n) => {
  QrEyeOuter.square:      l10n.shapeSquare,
  QrEyeOuter.rounded:     l10n.shapeRounded,
  QrEyeOuter.circle:      l10n.shapeCircle,
  QrEyeOuter.circleRound: l10n.shapeCircleRound,
  QrEyeOuter.smooth:      l10n.shapeSmooth,
};

class _OuterShapeRow extends StatelessWidget {
  final QrEyeOuter? selected; // null → 랜덤 활성 중 (흐림 처리)
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

// ── 눈 내부 모양 행 ──────────────────────────────────────────────────────────

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
            width: 52,
            height: 52,
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

/// 외곽 링만 그리는 아이콘 (내부는 비움)
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
        path.addOval(r); // 외곽 원형 + 원형 구멍 → addOval(hole)로 처리
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
    // circleRound는 구멍도 원형
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

/// 내부 채움 모양만 그리는 아이콘
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

