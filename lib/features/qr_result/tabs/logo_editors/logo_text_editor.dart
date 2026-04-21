import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/sticker_config.dart';
import '../../qr_result_provider.dart';

/// 플랫폼 제네릭 폰트 (text_tab.dart 의 _kFonts 와 동일)
const _kFonts = [
  (label: 'Sans', family: 'sans-serif'),
  (label: 'Serif', family: 'serif'),
  (label: 'Mono', family: 'monospace'),
];

/// "텍스트" 드롭다운 타입의 편집기.
/// 로고 영역에 들어가는 짧은 문구(최대 6자) + 색상/폰트/크기.
class LogoTextEditor extends ConsumerStatefulWidget {
  final VoidCallback onChanged;

  const LogoTextEditor({super.key, required this.onChanged});

  @override
  ConsumerState<LogoTextEditor> createState() => _LogoTextEditorState();
}

class _LogoTextEditorState extends ConsumerState<LogoTextEditor> {
  late final TextEditingController _ctrl;
  late StickerText _draft;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(qrResultProvider).sticker.logoText;
    _draft = existing ??
        const StickerText(content: '', fontSize: 20);
    _ctrl = TextEditingController(text: _draft.content);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _emit(StickerText updated) {
    setState(() => _draft = updated);
    final emit = updated.content.trim().isEmpty ? null : updated;
    ref.read(qrResultProvider.notifier).applyLogoText(emit);
    widget.onChanged();
  }

  Future<void> _pickColor() async {
    final l10n = AppLocalizations.of(context)!;
    Color temp = _draft.color;
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
    if (confirmed == true) {
      _emit(_draft.copyWith(color: temp));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;
    final t = _draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${l10n.labelLogoTextContent} :',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _ctrl,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: l10n.hintLogoTextContent,
                  isDense: true,
                  counterText: '',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _ctrl.clear();
                            _emit(t.copyWith(content: ''));
                          },
                        )
                      : null,
                ),
                onChanged: (v) => _emit(t.copyWith(content: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            GestureDetector(
              onTap: _pickColor,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: t.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: t.color.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: t.fontFamily,
                  isDense: true,
                  items: _kFonts.map((f) {
                    return DropdownMenuItem(
                      value: f.family,
                      child: Text(
                        f.label,
                        style: TextStyle(fontSize: 13, fontFamily: f.family),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) _emit(t.copyWith(fontFamily: v));
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            _StepButton(
              icon: Icons.remove,
              onTap: t.fontSize > 10
                  ? () => _emit(t.copyWith(fontSize: t.fontSize - 1))
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '${t.fontSize.round()}sp',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ),
            _StepButton(
              icon: Icons.add,
              onTap: t.fontSize < 40
                  ? () => _emit(t.copyWith(fontSize: t.fontSize + 1))
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? Colors.grey.shade100 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? Colors.black87 : Colors.grey.shade400,
        ),
      ),
    );
  }
}
