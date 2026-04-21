import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/logo_source.dart';
import '../../presentation/providers/qr_result_providers.dart';
import '../../qr_result_provider.dart';

/// "이미지" 드롭다운 타입의 편집기.
/// 썸네일 미리보기 + 갤러리 선택/재크롭 버튼.
class LogoImageEditor extends ConsumerWidget {
  final VoidCallback onChanged;

  const LogoImageEditor({super.key, required this.onChanged});

  Future<void> _pickAndCrop(BuildContext context, WidgetRef ref) async {
    final useCase = ref.read(cropLogoImageUseCaseProvider);
    final res = await useCase(context: context);
    if (!context.mounted) return;
    switch (res) {
      case Success<LogoSourceImage?>(:final value):
        if (value == null) return; // 사용자 취소
        ref.read(qrResultProvider.notifier).applyLogoImage(value.croppedBytes);
        onChanged();
      case Err<LogoSourceImage?>():
        final l10n = AppLocalizations.of(context)!;
        context.showSnack(l10n.msgLogoCropFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bytes = ref.watch(
        qrResultProvider.select((s) => s.sticker.logoImageBytes));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 썸네일 미리보기
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.antiAlias,
            child: bytes != null
                ? Image.memory(bytes, fit: BoxFit.cover)
                : Icon(Icons.image, color: Colors.grey.shade400, size: 40),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.photo_library),
                label: Text(l10n.labelLogoGallery),
                onPressed: () => _pickAndCrop(context, ref),
              ),
            ),
            if (bytes != null) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.crop),
                label: Text(l10n.labelLogoRecrop),
                onPressed: () => _pickAndCrop(context, ref),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
