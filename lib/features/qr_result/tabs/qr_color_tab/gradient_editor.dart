part of '../qr_color_tab.dart';

// ── 색 지점 데이터 모델 ───────────────────────────────────────────────────────

class _ColorStop {
  final Color color;
  final double position;

  const _ColorStop({required this.color, required this.position});
}

// ── 그라디언트 미리보기 + 드래그 슬라이더 통합 ──────────────────────────────

class _GradientSliderBar extends StatefulWidget {
  final List<_ColorStop> stops;
  final ValueChanged<List<_ColorStop>> onChanged;
  final ValueChanged<List<_ColorStop>>? onStopAdded;

  const _GradientSliderBar({
    required this.stops,
    required this.onChanged,
    this.onStopAdded,
  });

  @override
  State<_GradientSliderBar> createState() => _GradientSliderBarState();
}

class _GradientSliderBarState extends State<_GradientSliderBar> {
  int? _draggingIndex;
  bool _didDrag = false;

  static const _barHeight = 33.0;
  static const _handleRadius = 15.0;
  static const _handleActiveRadius = 20.0;
  static const _horizontalPadding = _handleActiveRadius;
  static const _totalHeight = _barHeight + _handleRadius + 4;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: _onTapUp,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: (_) => setState(() => _draggingIndex = null),
      child: CustomPaint(
        size: const Size(double.infinity, _totalHeight),
        painter: _GradientSliderBarPainter(
          stops: widget.stops,
          activeIndex: _draggingIndex,
        ),
      ),
    );
  }

  double _ratioFromX(double localX, double totalWidth) {
    final usableWidth = totalWidth - _horizontalPadding * 2;
    return ((localX - _horizontalPadding) / usableWidth).clamp(0.0, 1.0);
  }

  void _onTapUp(TapUpDetails details) {
    if (_didDrag) {
      _didDrag = false;
      return;
    }
    if (widget.stops.length >= 5) return;
    if (widget.onStopAdded == null) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final ratio = _ratioFromX(
      details.localPosition.dx,
      renderBox.size.width,
    );

    for (final s in widget.stops) {
      if ((s.position - ratio).abs() < 0.03) return;
    }

    final newColor = Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
        .withValues(alpha: 1);
    final newStops = List<_ColorStop>.from(widget.stops)
      ..add(_ColorStop(color: newColor, position: ratio))
      ..sort((a, b) => a.position.compareTo(b.position));
    widget.onStopAdded!(newStops);
  }

  void _onDragStart(DragStartDetails details) {
    _didDrag = false;
    final renderBox = context.findRenderObject() as RenderBox;
    final ratio = _ratioFromX(
      details.localPosition.dx,
      renderBox.size.width,
    );

    double minDist = double.infinity;
    int closest = -1;
    for (var i = 0; i < widget.stops.length; i++) {
      final dist = (widget.stops[i].position - ratio).abs();
      if (dist < minDist) {
        minDist = dist;
        closest = i;
      }
    }
    if (closest == 0 || closest == widget.stops.length - 1) {
      _draggingIndex = null;
      return;
    }
    setState(() => _draggingIndex = closest);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_draggingIndex == null) return;
    _didDrag = true;
    final renderBox = context.findRenderObject() as RenderBox;
    final ratio = _ratioFromX(
      details.localPosition.dx,
      renderBox.size.width,
    );

    final i = _draggingIndex!;
    final minPos = widget.stops[i - 1].position + 0.01;
    final maxPos = widget.stops[i + 1].position - 0.01;
    final clamped = ratio.clamp(minPos, maxPos);

    final newStops = List<_ColorStop>.from(widget.stops);
    newStops[i] = _ColorStop(color: newStops[i].color, position: clamped);
    widget.onChanged(newStops);
  }
}

class _GradientSliderBarPainter extends CustomPainter {
  final List<_ColorStop> stops;
  final int? activeIndex;

  _GradientSliderBarPainter({required this.stops, required this.activeIndex});

  @override
  void paint(Canvas canvas, Size size) {
    const hPad = _GradientSliderBarState._horizontalPadding;
    const barH = _GradientSliderBarState._barHeight;
    const r = _GradientSliderBarState._handleRadius;
    const rActive = _GradientSliderBarState._handleActiveRadius;

    final barRect = RRect.fromLTRBR(
      hPad, 0, size.width - hPad, barH, const Radius.circular(8),
    );

    final colors = stops.map((s) => s.color).toList();
    final positions = stops.map((s) => s.position).toList();
    final gradient = LinearGradient(colors: colors, stops: positions);
    final shader = gradient.createShader(barRect.outerRect);

    canvas.drawRRect(barRect, Paint()..shader = shader);
    canvas.drawRRect(
      barRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final usableWidth = size.width - hPad * 2;
    final handleCy = barH / 2;

    for (var i = 0; i < stops.length; i++) {
      final stop = stops[i];
      final cx = hPad + stop.position * usableWidth;
      final isActive = i == activeIndex;
      final isEdge = i == 0 || i == stops.length - 1;
      final currentR = isActive ? rActive : r;

      canvas.drawCircle(
        Offset(cx, handleCy + 1),
        currentR + 1,
        Paint()..color = Colors.black.withValues(alpha: 0.10),
      );
      canvas.drawCircle(
        Offset(cx, handleCy),
        currentR,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(cx, handleCy),
        currentR,
        Paint()
          ..color = isActive
              ? Colors.blue
              : (isEdge ? Colors.grey.shade400 : Colors.grey.shade500)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isActive ? 2.5 : 1.5,
      );
      canvas.drawCircle(
        Offset(cx, handleCy),
        currentR - 3,
        Paint()..color = stop.color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GradientSliderBarPainter oldDelegate) =>
      activeIndex != oldDelegate.activeIndex ||
      !_stopsEqual(stops, oldDelegate.stops);

  static bool _stopsEqual(List<_ColorStop> a, List<_ColorStop> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].color != b[i].color || a[i].position != b[i].position) {
        return false;
      }
    }
    return true;
  }
}
