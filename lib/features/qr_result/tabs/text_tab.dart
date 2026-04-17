import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/sticker_config.dart';
import '../../../l10n/app_localizations.dart';
import '../qr_result_provider.dart' show qrResultProvider;

// 플랫폼 제네릭 폰트: assets 추가 없이 Android/iOS 모두 동작
const _kFonts = [
  (label: 'Sans', family: 'sans-serif'),  // Android: Roboto, iOS: SF Pro
  (label: 'Serif', family: 'serif'),       // Android: Noto Serif, iOS: Georgia
  (label: 'Mono', family: 'monospace'),    // Android: Droid Mono, iOS: Courier
];

/// [텍스트] 탭: 상단/하단 텍스트 편집.
/// 로고 탭에서 분리되어 스크롤 부담을 줄입니다.
class TextTab extends ConsumerWidget {
  final VoidCallback onChanged;

  const TextTab({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sticker = ref.watch(qrResultProvider).sticker;

    void update(StickerConfig updated) {
      ref.read(qrResultProvider.notifier).setSticker(updated);
      onChanged();
    }

    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ① 상단 텍스트
          _TextEditor(
            label: l10n.labelTopText,
            text: sticker.topText,
            onChanged: (t) => update(sticker.copyWith(topText: t)),
          ),
          const SizedBox(height: 20),

          const Divider(height: 1),
          const SizedBox(height: 16),

          // ② 하단 텍스트
          _TextEditor(
            label: l10n.labelBottomText,
            text: sticker.bottomText,
            onChanged: (t) => update(sticker.copyWith(bottomText: t)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── 텍스트 편집기 ─────────────────────────────────────────────────────────────

class _TextEditor extends StatefulWidget {
  final String label;
  final StickerText? text;
  final ValueChanged<StickerText?> onChanged;

  const _TextEditor({
    required this.label,
    required this.text,
    required this.onChanged,
  });

  @override
  State<_TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<_TextEditor> {
  late final TextEditingController _ctrl;
  // 색상·폰트·크기 설정을 content가 비어있어도 로컬에 유지
  late StickerText _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.text ?? const StickerText(content: '');
    _ctrl = TextEditingController(text: _draft.content);
  }

  @override
  void didUpdateWidget(_TextEditor old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text && widget.text != null) {
      final incoming = widget.text!;
      if (incoming.content != _draft.content) {
        _draft = incoming;
        _ctrl.text = incoming.content;
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
    widget.onChanged(result);
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
    final t = _draft;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: 라벨 + 텍스트 입력란
        Row(
          children: [
            Text(
              '${widget.label} :',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _ctrl,
                maxLength: 40,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.hintEnterText,
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
        const SizedBox(height: 8),

        // Row 2: 색상 버튼 + 폰트 드롭다운 + 크기 스텝퍼
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
                  border:
                      Border.all(color: Colors.grey.shade300, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: t.color.withValues(alpha: 0.4),
                        blurRadius: 4),
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
                      child: Text(f.label,
                          style: TextStyle(
                              fontSize: 13, fontFamily: f.family)),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) _emit(t.copyWith(fontFamily: v));
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      color: primaryColor,
                    ),
                  ),
                ),
                _StepButton(
                  icon: Icons.add,
                  onTap: t.fontSize < 64
                      ? () => _emit(t.copyWith(fontSize: t.fontSize + 1))
                      : null,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ── 스텝퍼 버튼 ───────────────────────────────────────────────────────────────

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
