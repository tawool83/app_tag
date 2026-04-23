import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/entities/logo_source.dart';
import '../domain/entities/sticker_config.dart';
import '../qr_result_provider.dart' show qrResultProvider;
import 'logo_editors/logo_image_editor.dart';
import 'logo_editors/logo_library_editor.dart';
import 'logo_editors/logo_text_editor.dart';

/// [로고] 탭:
///  Row 1: [유형 드롭다운]   [위치 segment]
///  Row 2: [배경 segment]   [색상 swatch]
///  Divider
///  IndexedStack: 타입별 편집기 (유형 == none 일 때는 숨김)
class StickerTab extends ConsumerWidget {
  final VoidCallback onChanged;

  const StickerTab({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qrResultProvider);
    final sticker = state.sticker;
    final l10n = AppLocalizations.of(context)!;

    // 드롭다운 표시 값 — 레거시(null)도 UI 에서는 "없음" 으로 표시.
    final currentType = sticker.logoType ?? LogoType.none;
    final isTextType = currentType == LogoType.text;
    final isNoneType = currentType == LogoType.none;

    void update(StickerConfig updated) {
      ref.read(qrResultProvider.notifier).setSticker(updated);
      onChanged();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: 유형 드롭다운 | 위치 ────────────────────────────────────
          // 유형은 콘텐츠 폭(96~200dp), 위치는 Expanded 로 남은 폭 확보 → 위치 옵션 한 줄 유지.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 96, maxWidth: 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(l10n.labelLogoType),
                      const SizedBox(height: 8),
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<LogoType>(
                            value: currentType,
                            isDense: true,
                            items: [
                              DropdownMenuItem(
                                value: LogoType.none,
                                child: Text(l10n.optionNone,
                                    style: const TextStyle(fontSize: 13)),
                              ),
                              DropdownMenuItem(
                                value: LogoType.logo,
                                child: Text(l10n.optionLogoTypeLogo,
                                    style: const TextStyle(fontSize: 13)),
                              ),
                              DropdownMenuItem(
                                value: LogoType.image,
                                child: Text(l10n.optionLogoTypeImage,
                                    style: const TextStyle(fontSize: 13)),
                              ),
                              DropdownMenuItem(
                                value: LogoType.text,
                                child: Text(l10n.optionLogoTypeText,
                                    style: const TextStyle(fontSize: 13)),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                ref
                                    .read(qrResultProvider.notifier)
                                    .setLogoType(v);
                                onChanged();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(l10n.labelLogoTabPosition),
                    const SizedBox(height: 8),
                    _SegmentRow<LogoPosition>(
                      enabled: !isNoneType,
                      selected: sticker.logoPosition,
                      options: [
                        (LogoPosition.center, l10n.optionCenter),
                        (LogoPosition.bottomRight, l10n.optionBottomRight),
                      ],
                      onChanged: (v) =>
                          update(sticker.copyWith(logoPosition: v)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!isNoneType) ...[
            const SizedBox(height: 16),

            // ── Row 2: 배경 | 색상 ─────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(l10n.labelLogoTabBackground),
                      const SizedBox(height: 8),
                      _SegmentRow<LogoBackground>(
                        selected: _normalizedBackground(
                            sticker.logoBackground, isTextType),
                        options: isTextType
                            ? [
                                (LogoBackground.none, l10n.optionNone),
                                (LogoBackground.rectangle,
                                    l10n.optionRectangle),
                                (LogoBackground.roundedRectangle,
                                    l10n.optionRoundedRectangle),
                              ]
                            : [
                                (LogoBackground.none, l10n.optionNone),
                                (LogoBackground.square, l10n.optionSquare),
                                (LogoBackground.circle, l10n.optionCircle),
                              ],
                        onChanged: (v) =>
                            update(sticker.copyWith(logoBackground: v)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _BackgroundColorColumn(
                  enabled: sticker.logoBackground != LogoBackground.none,
                  currentColor: sticker.logoBackgroundColor,
                  onColorChanged: (c) {
                    ref
                        .read(qrResultProvider.notifier)
                        .setLogoBackgroundColor(c);
                    onChanged();
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // ── 타입별 편집기 (none 은 숨김) ────────────────────────────────
            IndexedStack(
              // currentType.index - 1: none=0 을 제외하고 logo/image/text 를 0/1/2 로 매핑
              index: currentType.index - 1,
              children: [
                LogoLibraryEditor(onChanged: onChanged),
                LogoImageEditor(onChanged: onChanged),
                LogoTextEditor(onChanged: onChanged),
              ],
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// 타입 전환 시 현재 선택된 배경이 그 타입에 부적합하면 none 으로 정규화.
/// - 텍스트 타입: square/circle 는 부적합 → none
/// - 이미지/로고 타입: rectangle/roundedRectangle 는 부적합 → none
/// (UI 표시용 selection 만 보정. 실제 state 변경은 사용자가 옵션 탭할 때 발생)
LogoBackground _normalizedBackground(LogoBackground bg, bool isTextType) {
  if (isTextType) {
    if (bg == LogoBackground.square || bg == LogoBackground.circle) {
      return LogoBackground.none;
    }
  } else {
    if (bg == LogoBackground.rectangle ||
        bg == LogoBackground.roundedRectangle) {
      return LogoBackground.none;
    }
  }
  return bg;
}

// ── 배경 색상 Column (위치/배경 옆 3번째 열) ────────────────────────────────

class _BackgroundColorColumn extends StatelessWidget {
  final bool enabled;
  final Color? currentColor;
  final ValueChanged<Color?> onColorChanged;

  const _BackgroundColorColumn({
    required this.enabled,
    required this.currentColor,
    required this.onColorChanged,
  });

  Future<void> _pickColor(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    Color temp = currentColor ?? const Color(0xFF0066CC);
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
            paletteType: PaletteType.hueWheel,
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
    if (confirmed == true) onColorChanged(temp);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = currentColor;
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(l10n.labelLogoBackgroundColor),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _pickColor(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c ?? Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: c == null ? null : () => onColorChanged(null),
                  child: Text(
                    l10n.actionLogoBackgroundReset,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── 섹션 레이블 ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      );
}

// ── 세그먼트 선택 행 ────────────────────────────────────────────────────────

class _SegmentRow<T> extends StatelessWidget {
  final T selected;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  final bool enabled;

  const _SegmentRow({
    required this.selected,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final row = Wrap(
      spacing: 8,
      runSpacing: 6,
      children: options.map((opt) {
        final (value, label) = opt;
        final isSelected = selected == value;
        return GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
        );
      }).toList(),
    );
    if (enabled) return row;
    return IgnorePointer(child: Opacity(opacity: 0.4, child: row));
  }
}
