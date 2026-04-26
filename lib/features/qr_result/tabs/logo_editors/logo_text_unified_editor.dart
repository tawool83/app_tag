import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/sticker_config.dart';
import '../../qr_result_provider.dart';

/// 로고 유형="텍스트" 선택 시 표시되는 통합 텍스트 편집기.
/// v0.8: 텍스트 색상 swatch + 배경 색상 swatch 추가.
class LogoTextUnifiedEditor extends ConsumerWidget {
  final VoidCallback onChanged;

  const LogoTextUnifiedEditor({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sticker = ref.watch(qrResultProvider).sticker;
    final notifier = ref.read(qrResultProvider.notifier);

    return _CenterEditor(
      text: sticker.logoText,
      bandMode: sticker.bandMode,
      logoBackground: sticker.logoBackground,
      bgColor: sticker.logoBackgroundColor,
      isEvenSpacing: sticker.centerTextEvenSpacing,
      onTextChanged: (t) {
        notifier.applyLogoText(t);
        // 텍스트 비워지면 사각/원형 배경 자동 제거
        if (t == null) {
          final bg = ref.read(qrResultProvider).sticker.logoBackground;
          if (bg == LogoBackground.square || bg == LogoBackground.circle) {
            final cur = ref.read(qrResultProvider).sticker;
            notifier.setSticker(cur.copyWith(logoBackground: LogoBackground.none));
          }
        }
        onChanged();
      },
      onTextColorChanged: (c) {
        final cur = ref.read(qrResultProvider).sticker;
        final t = cur.logoText;
        if (t != null) {
          notifier.setSticker(cur.copyWith(logoText: t.copyWith(color: c)));
        }
        onChanged();
      },
      onBandModeChanged: (v) {
        notifier.setBandMode(v);
        onChanged();
      },
      onLogoBackgroundChanged: (v) {
        final current = ref.read(qrResultProvider).sticker;
        notifier.setSticker(current.copyWith(logoBackground: v));
        onChanged();
      },
      onBgColorChanged: (c) {
        notifier.setLogoBackgroundColor(c);
        onChanged();
      },
      onEvenSpacingChanged: (v) {
        notifier.setCenterTextEvenSpacing(v);
        onChanged();
      },
    );
  }
}

// ── 중앙 텍스트 편집기 ──────────────────────────────────────────────────────────

class _CenterEditor extends StatefulWidget {
  final StickerText? text;
  final BandMode bandMode;
  final LogoBackground logoBackground;
  final Color? bgColor;
  final bool isEvenSpacing;
  final ValueChanged<StickerText?> onTextChanged;
  final ValueChanged<Color> onTextColorChanged;
  final ValueChanged<BandMode> onBandModeChanged;
  final ValueChanged<LogoBackground> onLogoBackgroundChanged;
  final ValueChanged<Color?> onBgColorChanged;
  final ValueChanged<bool> onEvenSpacingChanged;

  const _CenterEditor({
    required this.text,
    required this.bandMode,
    required this.logoBackground,
    required this.bgColor,
    required this.isEvenSpacing,
    required this.onTextChanged,
    required this.onTextColorChanged,
    required this.onBandModeChanged,
    required this.onLogoBackgroundChanged,
    required this.onBgColorChanged,
    required this.onEvenSpacingChanged,
  });

  @override
  State<_CenterEditor> createState() => _CenterEditorState();
}

class _CenterEditorState extends State<_CenterEditor> {
  late final TextEditingController _ctrl;
  late StickerText _draft;

  bool get _hasBand => widget.bandMode != BandMode.none;

  /// 배경이 활성(🚫 아님)인지 여부
  bool get _hasBg =>
      widget.bandMode != BandMode.none ||
      widget.logoBackground == LogoBackground.square ||
      widget.logoBackground == LogoBackground.circle;

  @override
  void initState() {
    super.initState();
    _draft = widget.text ?? const StickerText(content: '');
    _ctrl = TextEditingController(text: _draft.content);
  }

  @override
  void didUpdateWidget(_CenterEditor old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text && widget.text != null) {
      final incoming = widget.text!;
      if (incoming.content != _draft.content) {
        _draft = incoming;
        _ctrl.text = incoming.content;
      } else {
        _draft = incoming;
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _emit(StickerText updated) {
    setState(() => _draft = updated);
    final result = updated.content.trim().isEmpty ? null : updated;
    widget.onTextChanged(result);
  }

  Future<void> _pickColor(Color initial, ValueChanged<Color> onPicked) async {
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
            enableAlpha: true,
            hexInputBar: true,
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
    if (confirmed == true) onPicked(temp);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textColor = _draft.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Row 1: 텍스트 입력 + 폰트 색상 swatch ──
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                maxLength: 20,
                decoration: InputDecoration(
                  hintText: l10n.hintEnterText,
                  isDense: true,
                  counterText: '',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 균등분할 아이콘 (띠 모드에서만 표시)
                      if (_hasBand)
                        IconButton(
                          icon: Icon(
                            Icons.space_bar,
                            size: 20,
                            color: widget.isEvenSpacing
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                          tooltip: l10n.labelEvenSpacing,
                          onPressed: () =>
                              widget.onEvenSpacingChanged(!widget.isEvenSpacing),
                        ),
                      // 클리어 버튼
                      if (_ctrl.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _ctrl.clear();
                            _emit(_draft.copyWith(content: ''));
                          },
                        ),
                    ],
                  ),
                ),
                onChanged: (v) => _emit(_draft.copyWith(content: v)),
              ),
            ),
            const SizedBox(width: 8),
            // 폰트 색상 swatch
            _ColorSwatch(
              color: textColor,
              tooltip: l10n.labelLogoBackgroundColor,
              onTap: () => _pickColor(textColor, widget.onTextColorChanged),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Row 2: 배경 토글 + 배경색 swatch ──
        Row(
          children: [
            Expanded(
              child: _BackgroundToggles(
                bandMode: widget.bandMode,
                logoBackground: widget.logoBackground,
                onBandModeChanged: widget.onBandModeChanged,
                onLogoBackgroundChanged: widget.onLogoBackgroundChanged,
              ),
            ),
            if (_hasBg) ...[
              const SizedBox(width: 8),
              _ColorSwatch(
                color: widget.bgColor ?? Colors.white,
                tooltip: l10n.labelLogoBackgroundColor,
                onTap: () => _pickColor(
                  widget.bgColor ?? Colors.white,
                  (c) => widget.onBgColorChanged(c),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ── 색상 원형 swatch ─────────────────────────────────────────────────────────

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade400, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── 배경 단일 토글 그룹: [🚫] [가로띠] [세로띠] [사각] [원형] ────────────────────

class _BackgroundToggles extends StatelessWidget {
  final BandMode bandMode;
  final LogoBackground logoBackground;
  final ValueChanged<BandMode> onBandModeChanged;
  final ValueChanged<LogoBackground> onLogoBackgroundChanged;

  const _BackgroundToggles({
    required this.bandMode,
    required this.logoBackground,
    required this.onBandModeChanged,
    required this.onLogoBackgroundChanged,
  });

  bool get _isNone =>
      bandMode == BandMode.none && logoBackground == LogoBackground.none;

  /// 단일 선택: 다른 옵션 탭 시 기존 해제 + 새 옵션 활성.
  /// 같은 항목 재탭 → 🚫로 복귀.
  void _selectBand(BandMode mode) {
    if (bandMode == mode) {
      onBandModeChanged(BandMode.none);
    } else {
      onBandModeChanged(mode);
      if (logoBackground != LogoBackground.none) {
        onLogoBackgroundChanged(LogoBackground.none);
      }
    }
  }

  void _selectShape(LogoBackground bg) {
    if (logoBackground == bg) {
      onLogoBackgroundChanged(LogoBackground.none);
    } else {
      onLogoBackgroundChanged(bg);
      if (bandMode != BandMode.none) {
        onBandModeChanged(BandMode.none);
      }
    }
  }

  void _selectNone() {
    if (!_isNone) {
      onBandModeChanged(BandMode.none);
      onLogoBackgroundChanged(LogoBackground.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _ToggleChip(
          label: '🚫',
          icon: null,
          isActive: _isNone,
          activeColor: Colors.grey.shade700,
          onTap: _selectNone,
        ),
        _ToggleChip(
          icon: Icons.view_day_outlined,
          isActive: bandMode == BandMode.horizontal,
          activeColor: primary,
          onTap: () => _selectBand(BandMode.horizontal),
        ),
        _ToggleChip(
          icon: Icons.view_week_outlined,
          isActive: bandMode == BandMode.vertical,
          activeColor: primary,
          onTap: () => _selectBand(BandMode.vertical),
        ),
        _ToggleChip(
          icon: Icons.crop_square,
          isActive: logoBackground == LogoBackground.square,
          activeColor: primary,
          onTap: () => _selectShape(LogoBackground.square),
        ),
        _ToggleChip(
          icon: Icons.circle_outlined,
          isActive: logoBackground == LogoBackground.circle,
          activeColor: primary,
          onTap: () => _selectShape(LogoBackground.circle),
        ),
      ],
    );
  }
}

/// 토글 칩 — 터치 친화적, 활성 시 컬러 강조.
class _ToggleChip extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleChip({
    this.label,
    this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconOnly = label == null && icon != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: iconOnly
            ? const EdgeInsets.all(8)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? activeColor : Colors.grey.shade300,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: iconOnly ? 20 : 15,
                  color: isActive ? activeColor : Colors.grey.shade600),
              if (label != null) const SizedBox(width: 4),
            ],
            if (label != null)
              Text(
                label!,
                style: TextStyle(
                  fontSize: icon == null ? 16 : 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? activeColor : Colors.black87,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
