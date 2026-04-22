part of '../qr_color_tab.dart';

/// 그라디언트 섹션 2-행 레이아웃.
/// 1행: built-in 5개. 2행: [+] + user presets + ···.
class _GradientRow extends StatelessWidget {
  /// 현재 적용된 그라디언트. null = 그라디언트 비활성(단색 모드).
  final QrGradient? currentGradient;

  /// 사용자 저장 그라디언트 프리셋 (updatedAt desc).
  final List<UserColorPalette> userPresets;

  /// 사용자 프리셋 선택 중인 id.
  final String? selectedPresetId;

  final ValueChanged<QrGradient> onBuiltinSelect;
  final VoidCallback onAddTap;
  final ValueChanged<UserColorPalette> onUserSelect;
  final ValueChanged<UserColorPalette> onUserLongPress;
  final VoidCallback onShowAll;

  const _GradientRow({
    required this.currentGradient,
    required this.userPresets,
    required this.selectedPresetId,
    required this.onBuiltinSelect,
    required this.onAddTap,
    required this.onUserSelect,
    required this.onUserLongPress,
    required this.onShowAll,
  });

  static const _chipSize = 48.0;
  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1행: built-in 5개 ──
        Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: kQrPresetGradients.map((g) {
            // 사용자 preset 을 선택 중이면 built-in 선택 해제 (id 우선)
            final isSelected = selectedPresetId == null &&
                currentGradient != null &&
                _gradientEquals(currentGradient!, g);
            return _GradientCircle(
              gradient: g,
              isSelected: isSelected,
              onTap: () => onBuiltinSelect(g),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        // ── 2행: [+] + user presets + ··· ──
        SizedBox(
          height: _chipSize + 4,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              const fixedWidth = _chipSize + _gap;
              final remaining = totalWidth - fixedWidth;
              final maxSlots = (remaining / (_chipSize + _gap)).floor();
              final needMore =
                  userPresets.length > maxSlots && maxSlots > 0;
              final inlineCount = needMore
                  ? (maxSlots - 1).clamp(0, userPresets.length)
                  : maxSlots.clamp(0, userPresets.length);
              final inlinePresets = userPresets.sublist(0, inlineCount);

              return Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: _gap),
                    child: _AddCircleButton(onTap: onAddTap, size: _chipSize),
                  ),
                  ...inlinePresets.map((p) => Padding(
                        padding: const EdgeInsets.only(right: _gap),
                        child: _GradientCircle(
                          gradient: _qrGradientFromPalette(p),
                          isSelected: p.id == selectedPresetId,
                          onTap: () => onUserSelect(p),
                          onLongPress: () => onUserLongPress(p),
                        ),
                      )),
                  if (needMore)
                    Padding(
                      padding: const EdgeInsets.only(right: _gap),
                      child: _MoreCircleButton(
                          onTap: onShowAll, size: _chipSize),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Helper: UserColorPalette → QrGradient 변환 ───────────────────────────

QrGradient _qrGradientFromPalette(UserColorPalette p) {
  final argbs = p.gradientColorArgbs ?? [0xFF000000, 0xFFFFFFFF];
  return QrGradient(
    type: p.gradientType ?? 'linear',
    colors: argbs.map((i) => Color(i)).toList(),
    stops: p.gradientStops,
    angleDegrees: (p.gradientAngle ?? 45).toDouble(),
    center: (p.gradientType ?? 'linear') == 'radial' ? 'center' : null,
  );
}

// ── Helper: QrGradient 값 비교 (colors/stops 포함, operator== 보강) ─────

bool _gradientEquals(QrGradient a, QrGradient b) {
  if (a.type != b.type) return false;
  if (a.angleDegrees != b.angleDegrees) return false;
  if (a.center != b.center) return false;
  if (a.colors.length != b.colors.length) return false;
  for (var i = 0; i < a.colors.length; i++) {
    if (a.colors[i].toARGB32() != b.colors[i].toARGB32()) return false;
  }
  final aStops = a.stops;
  final bStops = b.stops;
  if (aStops == null && bStops == null) return true;
  if (aStops == null || bStops == null) return false;
  if (aStops.length != bStops.length) return false;
  for (var i = 0; i < aStops.length; i++) {
    if ((aStops[i] - bStops[i]).abs() > 1e-6) return false;
  }
  return true;
}
