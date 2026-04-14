import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/sticker_config.dart';
import '../../../services/settings_service.dart';
import '../qr_result_provider.dart' show qrResultProvider, qrSafeColors;

const _kFonts = [
  (label: 'Sans', family: 'Roboto'),
  (label: 'Serif', family: 'NotoSerifKR'),
  (label: 'Mono', family: 'RobotoMono'),
];

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ① 아이콘 표시 토글
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel('아이콘 표시'),
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
                '앱 아이콘 또는 이모지가 설정된 경우에만 표시됩니다.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          const SizedBox(height: 4),

          // ② 로고 위치
          _SectionLabel('로고 위치'),
          const SizedBox(height: 8),
          _SegmentRow<LogoPosition>(
            selected: sticker.logoPosition,
            options: const [
              (LogoPosition.center, '중앙'),
              (LogoPosition.bottomRight, '우하단'),
            ],
            onChanged: (v) => update(sticker.copyWith(logoPosition: v)),
          ),
          const SizedBox(height: 12),

          // ③ 로고 배경
          _SectionLabel('로고 배경'),
          const SizedBox(height: 8),
          _SegmentRow<LogoBackground>(
            selected: sticker.logoBackground,
            options: const [
              (LogoBackground.none, '없음'),
              (LogoBackground.square, '사각'),
              (LogoBackground.circle, '원형'),
            ],
            onChanged: (v) => update(sticker.copyWith(logoBackground: v)),
          ),
          const SizedBox(height: 20),

          const Divider(height: 1),
          const SizedBox(height: 16),

          // ④ 상단 텍스트
          _SectionLabel('상단 텍스트'),
          const SizedBox(height: 8),
          _TextEditor(
            text: sticker.topText,
            onChanged: (t) => update(sticker.copyWith(topText: t)),
          ),
          const SizedBox(height: 20),

          const Divider(height: 1),
          const SizedBox(height: 16),

          // ⑤ 하단 텍스트
          _SectionLabel('하단 텍스트'),
          const SizedBox(height: 8),
          _TextEditor(
            text: sticker.bottomText,
            onChanged: (t) => update(sticker.copyWith(bottomText: t)),
          ),
          const SizedBox(height: 16),
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
    return Row(
      children: options.map((opt) {
        final (value, label) = opt;
        final isSelected = selected == value;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
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
          ),
        );
      }).toList(),
    );
  }
}

// ── 텍스트 편집기 (상단/하단 공용) ────────────────────────────────────────────────

class _TextEditor extends StatefulWidget {
  final StickerText? text;
  final ValueChanged<StickerText?> onChanged;

  const _TextEditor({required this.text, required this.onChanged});

  @override
  State<_TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<_TextEditor> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.text?.content ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  StickerText get _current =>
      widget.text ?? const StickerText(content: '');

  void _emit(StickerText updated) {
    final result = updated.content.trim().isEmpty ? null : updated;
    widget.onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final t = _current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 내용 입력
        TextField(
          controller: _ctrl,
          maxLength: 40,
          decoration: InputDecoration(
            hintText: '텍스트를 입력하세요',
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _ctrl.clear();
                      _emit(t.copyWith(content: ''));
                    },
                  )
                : null,
          ),
          onChanged: (v) => _emit(t.copyWith(content: v)),
        ),
        const SizedBox(height: 10),

        // 색상 선택
        const Text('색상', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: qrSafeColors.map((c) {
            final isSelected = t.color.toARGB32() == c.toARGB32();
            return GestureDetector(
              onTap: () => _emit(t.copyWith(color: c)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 5)]
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        // 폰트 선택
        const Text('폰트', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        Row(
          children: _kFonts.map((f) {
            final isSelected = t.fontFamily == f.family;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _emit(t.copyWith(fontFamily: f.family)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    f.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: f.family,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        // 크기 슬라이더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('크기', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
              '${t.fontSize.round()}sp',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: t.fontSize,
          min: 10,
          max: 24,
          divisions: 14,
          onChanged: (v) => _emit(t.copyWith(fontSize: v)),
        ),
      ],
    );
  }
}
