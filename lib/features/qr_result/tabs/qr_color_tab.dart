import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/color_hex.dart' as app_color_hex;
import '../domain/entities/qr_template.dart' show QrGradient;
import '../../../l10n/app_localizations.dart';
import '../domain/entities/qr_color_presets.dart';
import '../qr_result_provider.dart' show qrResultProvider;

/// [색상] 탭: 단색 팔레트 + 그라디언트 프리셋 + 맞춤 그라디언트 편집기.
class QrColorTab extends ConsumerStatefulWidget {
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<QrGradient?> onGradientChanged;

  /// 편집기 모드 진입/해제 시 부모에게 알림 (하단 버튼 교체용).
  final ValueChanged<bool>? onEditorModeChanged;

  const QrColorTab({
    super.key,
    required this.onColorSelected,
    required this.onGradientChanged,
    this.onEditorModeChanged,
  });

  @override
  ConsumerState<QrColorTab> createState() => QrColorTabState();
}

class QrColorTabState extends ConsumerState<QrColorTab> {
  bool _showCustomEditor = false;

  // editor state
  String _gradientType = 'linear';
  double _angleDegrees = 45;
  String _center = 'center';
  late List<_ColorStop> _stops;

  // 편집 시작 전 그라디언트 백업 (취소용)
  QrGradient? _gradientBeforeEdit;

  @override
  void initState() {
    super.initState();
    _stops = [
      _ColorStop(color: const Color(0xFF0066CC), position: 0.0),
      _ColorStop(color: const Color(0xFF6A0DAD), position: 1.0),
    ];
  }

  void _emitGradient() {
    final gradient = QrGradient(
      type: _gradientType,
      colors: _stops.map((s) => s.color).toList(),
      stops: _stops.map((s) => s.position).toList(),
      angleDegrees: _angleDegrees,
      center: _gradientType == 'radial' ? _center : null,
    );
    widget.onGradientChanged(gradient);
  }

  void _openEditor() {
    final state = ref.read(qrResultProvider);
    _gradientBeforeEdit = state.style.customGradient;
    setState(() => _showCustomEditor = true);
    _emitGradient();
    widget.onEditorModeChanged?.call(true);
  }

  /// 외부(부모)에서 호출 — 탭 전환 시 자동 확인 처리용.
  void confirmAndCloseEditor() {
    if (!_showCustomEditor) return;
    _confirmEditor();
  }

  /// 외부(부모)에서 호출 — AppBar 뒤로가기 시 편집기 취소.
  void cancelAndCloseEditor() {
    if (!_showCustomEditor) return;
    _cancelEditor();
  }

  void _confirmEditor() {
    setState(() => _showCustomEditor = false);
    widget.onEditorModeChanged?.call(false);
  }

  void _cancelEditor() {
    setState(() => _showCustomEditor = false);
    widget.onGradientChanged(_gradientBeforeEdit);
    widget.onEditorModeChanged?.call(false);
  }

  Future<void> _openColorWheel(BuildContext context, Color initial,
      ValueChanged<Color> onConfirm) async {
    final l10n = AppLocalizations.of(context)!;
    Color temp = initial;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.dialogColorPickerTitle),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: temp,
            onColorChanged: (c) => temp = c,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm(temp);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qrResultProvider);
    final selectedColor = state.style.qrColor;
    final customGradient = state.style.customGradient;
    final l10n = AppLocalizations.of(context)!;

    // 맞춤 편집기 모드일 때: 팔레트 숨기고 편집기 + 하단 추가/취소 표시
    if (_showCustomEditor) {
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(label: l10n.labelCustomGradient),
                  const SizedBox(height: 12),
                  _buildCustomEditor(l10n),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // 기본 모드: 단색 + 그라디언트 팔레트
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 단색 섹션 ──────────────────────────────────────────────────
          _SectionHeader(label: l10n.tabColorSolid),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...qrSafeColors.map((c) {
                final isSelected =
                    c.toARGB32() == selectedColor.toARGB32() &&
                        customGradient == null;
                return _ColorCircle(
                  color: c,
                  isSelected: isSelected,
                  onTap: () {
                    widget.onGradientChanged(null);
                    widget.onColorSelected(c);
                  },
                );
              }),
              _AddCircleButton(
                onTap: () => _openColorWheel(context, selectedColor, (c) {
                  widget.onGradientChanged(null);
                  widget.onColorSelected(c);
                }),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── 그라디언트 섹션 ────────────────────────────────────────────
          _SectionHeader(label: l10n.tabColorGradient),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ...kQrPresetGradients.map((g) {
                final isSelected = customGradient != null &&
                    customGradient.type == g.type &&
                    customGradient.angleDegrees == g.angleDegrees &&
                    customGradient.colors.first.toARGB32() ==
                        g.colors.first.toARGB32();
                return _GradientRect(
                  gradient: g,
                  isSelected: isSelected,
                  onTap: () => widget.onGradientChanged(g),
                );
              }),
              _AddRectButton(onTap: _openEditor),
            ],
          ),
        ],
      ),
    );
  }

  // ── 맞춤 그라디언트 편집기 ─────────────────────────────────────────────────

  Widget _buildCustomEditor(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fix 1: 유형 + 각도/가운데를 드롭다운으로 한 행에 배치
        _buildTypeAndOptionRow(l10n),
        const SizedBox(height: 16),

        // "색 지점" 타이틀 (미리보기 바 위)
        Text(l10n.labelColorStops,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 6),

        // 그라디언트 미리보기 + 드래그 슬라이더 통합 (바 탭으로 색 지점 추가)
        _GradientSliderBar(
          stops: _stops,
          onChanged: (newStops) {
            setState(() => _stops = newStops);
            _emitGradient();
          },
          onStopAdded: _stops.length < 5
              ? (newStops) {
                  setState(() => _stops = newStops);
                  _emitGradient();
                }
              : null,
        ),
        const SizedBox(height: 16),

        // 색 지점 목록 (미리보기 바 아래)
        _buildColorStopList(l10n),
      ],
    );
  }

  // ── Fix 1: 유형 + 각도/가운데 드롭다운 한 행 ──────────────────────────────

  Widget _buildTypeAndOptionRow(AppLocalizations l10n) {
    const angles = [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0];
    final centerOptions = {
      'center': l10n.optionCenterCenter,
      'topLeft': l10n.optionCenterTopLeft,
      'topRight': l10n.optionCenterTopRight,
      'bottomLeft': l10n.optionCenterBottomLeft,
      'bottomRight': l10n.optionCenterBottomRight,
    };

    return Row(
      children: [
        // 유형 드롭다운
        Expanded(
          child: _LabeledDropdown<String>(
            label: l10n.labelGradientType,
            value: _gradientType,
            items: [
              DropdownMenuItem(value: 'linear', child: Text(l10n.optionLinear)),
              DropdownMenuItem(value: 'radial', child: Text(l10n.optionRadial)),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _gradientType = v);
              _emitGradient();
            },
          ),
        ),
        const SizedBox(width: 12),
        // 각도 또는 가운데 드롭다운
        if (_gradientType == 'linear')
          Expanded(
            child: _LabeledDropdown<double>(
              label: l10n.labelAngle,
              value: _angleDegrees,
              items: angles
                  .map((a) => DropdownMenuItem(
                      value: a, child: Text('${a.toInt()}°')))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _angleDegrees = v);
                _emitGradient();
              },
            ),
          )
        else
          Expanded(
            child: _LabeledDropdown<String>(
              label: l10n.labelCenter,
              value: _center,
              items: centerOptions.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _center = v);
                _emitGradient();
              },
            ),
          ),
      ],
    );
  }

  // ── 색 지점 목록 ──────────────────────────────────────────────────────────

  Widget _buildColorStopList(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(_stops.length, (i) {
          final stop = _stops[i];
          final canDelete = _stops.length > 2;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      _openColorWheel(context, stop.color, (newColor) {
                    setState(() => _stops[i] =
                        _ColorStop(color: newColor, position: stop.position));
                    _emitGradient();
                  }),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: stop.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  app_color_hex.colorToHex(stop.color),
                  style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.grey.shade700),
                ),
                const Spacer(),
                if (canDelete)
                  SizedBox(
                    height: 28,
                    child: TextButton(
                      onPressed: () {
                        setState(() => _stops.removeAt(i));
                        _redistributePositions();
                        _emitGradient();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(l10n.actionDeleteStop,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.red)),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _redistributePositions() {
    if (_stops.length < 2) return;
    for (var i = 0; i < _stops.length; i++) {
      final pos = i / (_stops.length - 1);
      _stops[i] = _ColorStop(color: _stops[i].color, position: pos);
    }
  }
}

// ── 데이터 모델 ────────────────────────────────────────────────────────────────

class _ColorStop {
  final Color color;
  final double position;

  const _ColorStop({required this.color, required this.position});
}

// ── 공통 위젯 ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700));
  }
}

/// 라벨 + 드롭다운을 세로로 묶는 컴팩트 위젯.
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
          style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color),
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

  const _ColorCircle({
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

class _AddCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCircleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
          color: Colors.grey.shade50,
        ),
        child: Icon(Icons.add, size: 18, color: Colors.grey.shade600),
      ),
    );
  }
}

// ── 그라디언트 사각 버튼 ─────────────────────────────────────────────────────

class _GradientRect extends StatelessWidget {
  final QrGradient gradient;
  final bool isSelected;
  final VoidCallback onTap;

  const _GradientRect({
    required this.gradient,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                  transform:
                      GradientRotation(gradient.angleDegrees * 3.14159 / 180),
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

class _AddRectButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddRectButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
          color: Colors.grey.shade50,
        ),
        child: Icon(Icons.add, size: 20, color: Colors.grey.shade600),
      ),
    );
  }
}

// ── 그라디언트 미리보기 바 ────────────────────────────────────────────────────

// ── 그라디언트 미리보기 + 드래그 슬라이더 통합 컴포넌트 ─────────────────────

class _GradientSliderBar extends StatefulWidget {
  final List<_ColorStop> stops;
  final ValueChanged<List<_ColorStop>> onChanged;

  /// 바 탭으로 새 색 지점 추가 시 콜백 (최대 5개 제한은 호출자가 판단).
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

  /// 바 탭: 기존 핸들 근처가 아니면 새 색 지점 추가.
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

    // 기존 핸들 근처(3% 이내)이면 추가하지 않음
    for (final s in widget.stops) {
      if ((s.position - ratio).abs() < 0.03) return;
    }

    // 랜덤 색상 생성
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
    // 양 끝(첫/마지막) 스톱은 고정
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

    // 그라디언트 바 그리기
    final colors = stops.map((s) => s.color).toList();
    final positions = stops.map((s) => s.position).toList();
    final gradient = LinearGradient(colors: colors, stops: positions);
    final shader = gradient.createShader(barRect.outerRect);

    canvas.drawRRect(barRect, Paint()..shader = shader);

    // 바 테두리
    canvas.drawRRect(
      barRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // 핸들 (바 중앙에 배치)
    final usableWidth = size.width - hPad * 2;
    final handleCy = barH / 2;

    for (var i = 0; i < stops.length; i++) {
      final stop = stops[i];
      final cx = hPad + stop.position * usableWidth;
      final isActive = i == activeIndex;
      final isEdge = i == 0 || i == stops.length - 1;
      final currentR = isActive ? rActive : r;

      // 핸들 그림자
      canvas.drawCircle(
        Offset(cx, handleCy + 1),
        currentR + 1,
        Paint()..color = Colors.black.withValues(alpha: 0.10),
      );

      // 핸들 배경 (흰색)
      canvas.drawCircle(
        Offset(cx, handleCy),
        currentR,
        Paint()..color = Colors.white,
      );

      // 핸들 테두리
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

      // 핸들 안쪽 색상 원
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
      if (a[i].color != b[i].color || a[i].position != b[i].position) return false;
    }
    return true;
  }
}
