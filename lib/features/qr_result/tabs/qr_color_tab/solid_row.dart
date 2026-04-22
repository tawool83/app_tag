part of '../qr_color_tab.dart';

/// 단색 섹션의 2-행 레이아웃.
///
/// 1행: built-in 5개 (Wrap)
/// 2행: `[+]` + user presets + `···` (LayoutBuilder 오버플로)
class _SolidRow extends StatelessWidget {
  /// built-in 선택 중인 색상. null = user preset 선택 중 또는 그라디언트 활성.
  final Color? builtinSelected;

  /// 사용자 저장 단색 프리셋 (updatedAt desc).
  final List<UserColorPalette> userPresets;

  /// 사용자 프리셋 선택 중인 id. null = 미선택 또는 built-in 선택 중.
  final String? selectedPresetId;

  final ValueChanged<Color> onBuiltinSelect;
  final VoidCallback onAddTap;
  final ValueChanged<UserColorPalette> onUserSelect;
  final ValueChanged<UserColorPalette> onUserLongPress;
  final VoidCallback onShowAll;

  const _SolidRow({
    required this.builtinSelected,
    required this.userPresets,
    required this.selectedPresetId,
    required this.onBuiltinSelect,
    required this.onAddTap,
    required this.onUserSelect,
    required this.onUserLongPress,
    required this.onShowAll,
  });

  static const _chipSize = 36.0;
  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1행: built-in 5개 ──
        Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: qrSafeColors.map((c) {
            final isSelected =
                builtinSelected?.toARGB32() == c.toARGB32();
            return _ColorCircle(
              color: c,
              isSelected: isSelected,
              onTap: () => onBuiltinSelect(c),
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
              const fixedWidth = _chipSize + _gap; // [+] 1개 고정 폭
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
                    child: _AddCircleButton(onTap: onAddTap),
                  ),
                  ...inlinePresets.map((p) => Padding(
                        padding: const EdgeInsets.only(right: _gap),
                        child: _ColorCircle(
                          color: Color(p.solidColorArgb ?? 0xFF000000),
                          isSelected: p.id == selectedPresetId,
                          onTap: () => onUserSelect(p),
                          onLongPress: () => onUserLongPress(p),
                        ),
                      )),
                  if (needMore)
                    Padding(
                      padding: const EdgeInsets.only(right: _gap),
                      child: _MoreCircleButton(onTap: onShowAll),
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
