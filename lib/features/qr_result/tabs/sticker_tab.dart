import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/sticker_config.dart';
import '../../../core/services/settings_service.dart';
import '../../../l10n/app_localizations.dart';
import '../qr_result_provider.dart' show qrResultProvider;

/// [로고] 탭: 아이콘 표시 토글 + 위치/배경 + 상단/하단 텍스트 편집.
class StickerTab extends ConsumerWidget {
  final VoidCallback onChanged;

  const StickerTab({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qrResultProvider);
    final sticker = state.sticker;
    final embedIcon = state.embedIcon;
    final hasIconSource = state.templateCenterIconBytes != null ||
        state.emojiIconBytes != null ||
        state.defaultIconBytes != null;

    void update(StickerConfig updated) {
      ref.read(qrResultProvider.notifier).setSticker(updated);
      onChanged();
    }

    void toggleEmbedIcon(bool v) {
      ref.read(qrResultProvider.notifier).setEmbedIcon(v);
      SettingsService.saveQrEmbedIcon(v);
      onChanged();
    }

    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ① 아이콘 표시 토글
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionLabel(l10n.labelShowIcon),
              Switch(
                value: embedIcon,
                onChanged: hasIconSource ? toggleEmbedIcon : null,
              ),
            ],
          ),
          if (!hasIconSource)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.msgIconUnavailable,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          const SizedBox(height: 4),

          // ② 로고 위치 + ③ 로고 배경 (좌우 나란히 배치)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(l10n.labelLogoPosition),
                    const SizedBox(height: 8),
                    _SegmentRow<LogoPosition>(
                      selected: sticker.logoPosition,
                      options: [
                        (LogoPosition.center, l10n.optionCenter),
                        (LogoPosition.bottomRight, l10n.optionBottomRight),
                      ],
                      onChanged: (v) => update(sticker.copyWith(logoPosition: v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(l10n.labelLogoBackground),
                    const SizedBox(height: 8),
                    _SegmentRow<LogoBackground>(
                      selected: sticker.logoBackground,
                      options: [
                        (LogoBackground.none, l10n.optionNone),
                        (LogoBackground.square, l10n.optionSquare),
                        (LogoBackground.circle, l10n.optionCircle),
                      ],
                      onChanged: (v) => update(sticker.copyWith(logoBackground: v)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── 섹션 레이블 ────────────────────────────────────────────────────────────────

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

// ── 세그먼트 선택 행 ────────────────────────────────────────────────────────────

class _SegmentRow<T> extends StatelessWidget {
  final T selected;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  const _SegmentRow({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
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
  }
}

