part of '../qr_shape_tab.dart';

// ── 커스텀 눈 프리셋 행 ───────────────────────────────────────────────────────
// [+][user...][···] — 도트 행과 동일한 구조. 빌트인 없음 (눈 빌트인은
// 아래의 내각/외각 행이 담당).

class _CustomEyeRow extends StatelessWidget {
  final String? selectedPresetId;
  final bool dimmed;
  final List<UserShapePreset> presets;
  final VoidCallback onAdd;
  final ValueChanged<UserShapePreset> onUserSelect;
  final ValueChanged<UserShapePreset> onUserLongPress;
  final VoidCallback onShowAll;
  final ValueChanged<Set<String>>? onInlineIdsChanged;

  const _CustomEyeRow({
    super.key,
    required this.selectedPresetId,
    required this.dimmed,
    required this.presets,
    required this.onAdd,
    required this.onUserSelect,
    required this.onUserLongPress,
    required this.onShowAll,
    this.onInlineIdsChanged,
  });

  static const _chipSize = 48.0;
  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: dimmed ? 0.4 : 1.0,
      child: SizedBox(
        height: 52,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            // 고정 영역: "+" 버튼
            final fixedWidth = _chipSize + _gap;
            final remaining = totalWidth - fixedWidth;
            final maxSlots = (remaining / (_chipSize + _gap)).floor();
            final needMore = presets.length > maxSlots && maxSlots > 0;
            final inlineCount = needMore
                ? (maxSlots - 1).clamp(0, presets.length)
                : maxSlots.clamp(0, presets.length);
            final inlinePresets = presets.sublist(0, inlineCount);

            if (onInlineIdsChanged != null) {
              final ids = inlinePresets.map((p) => p.id).toSet();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onInlineIdsChanged!(ids);
              });
            }

            return Row(
              children: [
                // "+" 추가 버튼
                Padding(
                  padding: const EdgeInsets.only(right: _gap),
                  child: GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      width: _chipSize,
                      height: _chipSize,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child:
                          const Icon(Icons.add, size: 24, color: Colors.grey),
                    ),
                  ),
                ),
                // 인라인 사용자 프리셋
                ...inlinePresets.map((p) => _PresetChip(
                      preset: p,
                      isSelected: p.id == selectedPresetId,
                      onTap: () => onUserSelect(p),
                      onLongPress: () => onUserLongPress(p),
                    )),
                // ··· 더보기 버튼
                if (needMore)
                  Padding(
                    padding: const EdgeInsets.only(right: _gap),
                    child: GestureDetector(
                      onTap: onShowAll,
                      child: Container(
                        width: _chipSize,
                        height: _chipSize,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Center(
                          child: Text('···',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── 눈 격자 모달 (보기 / 삭제 모드) ────────────────────────────────────────────

enum _EyeGridMode { view, delete }

sealed class _EyeGridResult {}
class _EyeGridDeleteResult extends _EyeGridResult { final Set<String> deletedIds; _EyeGridDeleteResult(this.deletedIds); }
class _EyeGridEditResult extends _EyeGridResult { final UserShapePreset preset; _EyeGridEditResult(this.preset); }

class _EyeGridModal extends StatefulWidget {
  final List<UserShapePreset> presets;
  final _EyeGridMode mode;
  final String? selectedPresetId;
  final ValueChanged<UserShapePreset> onSelect;

  const _EyeGridModal({
    required this.presets,
    required this.mode,
    required this.onSelect,
    this.selectedPresetId,
  });

  @override
  State<_EyeGridModal> createState() => _EyeGridModalState();
}

class _EyeGridModalState extends State<_EyeGridModal> {
  final _markedForDeletion = <String>{};
  String? _localSelectedId;

  @override
  void initState() {
    super.initState();
    _localSelectedId = widget.selectedPresetId;
  }

  bool _isSelected(UserShapePreset preset) =>
      preset.id == _localSelectedId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDelete = widget.mode == _EyeGridMode.delete;
    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.6),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들바
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: widget.presets.length,
              itemBuilder: (context, i) {
                final preset = widget.presets[i];
                final isMarked = _markedForDeletion.contains(preset.id);
                final isCurrent = _isSelected(preset);
                return GestureDetector(
                  onTap: () {
                    if (isDelete) {
                      setState(() {
                        if (isMarked) {
                          _markedForDeletion.remove(preset.id);
                        } else {
                          _markedForDeletion.add(preset.id);
                        }
                      });
                    } else {
                      setState(() => _localSelectedId = preset.id);
                      widget.onSelect(preset);
                    }
                  },
                  onLongPress: isDelete
                      ? null
                      : () => Navigator.pop(context, _EyeGridEditResult(preset)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isMarked
                          ? Colors.red.shade50
                          : isCurrent
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isMarked
                            ? Colors.red
                            : isCurrent
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                        width: (isMarked || isCurrent) ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: ImageFiltered(
                            imageFilter: isMarked
                                ? dart_ui.ImageFilter.blur(
                                    sigmaX: 3, sigmaY: 3)
                                : dart_ui.ImageFilter.blur(
                                    sigmaX: 0, sigmaY: 0),
                            child: CustomPaint(
                              size: const Size(32, 32),
                              painter: _PresetIconPainter(preset: preset),
                            ),
                          ),
                        ),
                        if (isMarked)
                          const Center(
                            child: Icon(Icons.delete_outline,
                                color: Colors.red, size: 24),
                          ),
                        if (isCurrent && !isMarked)
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Icon(Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                                size: 14),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (isDelete)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _markedForDeletion.isNotEmpty
                        ? Colors.red
                        : Colors.grey.shade400,
                  ),
                  onPressed: _markedForDeletion.isNotEmpty
                      ? () => Navigator.pop(
                          context, _EyeGridDeleteResult(_markedForDeletion))
                      : null,
                  icon: const Icon(Icons.delete, size: 18),
                  label: Text(l10n.actionDeleteCount(_markedForDeletion.length)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 눈 외곽 모양 행 ─────────────────────────────────────────────────────────

Map<QrEyeOuter, String> _outerLabels(AppLocalizations l10n) => {
  QrEyeOuter.square:      l10n.shapeSquare,
  QrEyeOuter.rounded:     l10n.shapeRounded,
  QrEyeOuter.circle:      l10n.shapeCircle,
  QrEyeOuter.circleRound: l10n.shapeCircleRound,
  QrEyeOuter.smooth:      l10n.shapeSmooth,
};

class _OuterShapeRow extends StatelessWidget {
  final QrEyeOuter? selected;
  final bool dimmed;
  final ValueChanged<QrEyeOuter> onSelected;

  const _OuterShapeRow({
    required this.selected,
    required this.dimmed,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final labels = _outerLabels(AppLocalizations.of(context)!);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: QrEyeOuter.values.map((outer) {
        final isSelected = !dimmed && selected == outer;
        return _ShapeButton(
          isSelected: isSelected,
          dimmed: dimmed || selected == null,
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

// ── 눈 내부 모양 행 ─────────────────────────────────────────────────────────

Map<QrEyeInner, String> _innerLabels(AppLocalizations l10n) => {
  QrEyeInner.square:  l10n.shapeSquare,
  QrEyeInner.circle:  l10n.shapeCircle,
  QrEyeInner.diamond: l10n.shapeDiamond,
  QrEyeInner.star:    l10n.shapeStar,
};

class _InnerShapeRow extends StatelessWidget {
  final QrEyeInner? selected;
  final bool dimmed;
  final ValueChanged<QrEyeInner> onSelected;

  const _InnerShapeRow({
    required this.selected,
    required this.dimmed,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final labels = _innerLabels(AppLocalizations.of(context)!);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: QrEyeInner.values.map((inner) {
        final isSelected = !dimmed && selected == inner;
        return _ShapeButton(
          isSelected: isSelected,
          dimmed: dimmed || selected == null,
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
