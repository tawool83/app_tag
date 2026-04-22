import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/logo_source.dart';
import '../../presentation/providers/qr_result_providers.dart';
import '../../qr_result_provider.dart';

/// "이미지" 드롭다운 타입의 편집기.
///
/// UX:
///  - 썸네일 영역 탭 → 갤러리에서 새 이미지 선택 (교체 포함).
///  - "다시 자르기" 버튼은 이미 선택된 이미지가 있을 때만 표시되며,
///    갤러리를 거치지 않고 현재 이미지의 crop/rotation 편집 UI 를 바로 띄움.
class LogoImageEditor extends ConsumerWidget {
  final VoidCallback onChanged;

  const LogoImageEditor({super.key, required this.onChanged});

  /// [existingBytes] 가 null 이면 갤러리에서 새로 선택, non-null 이면 해당 bytes 재크롭.
  Future<void> _pickAndCrop(
    BuildContext context,
    WidgetRef ref, {
    Uint8List? existingBytes,
  }) async {
    final useCase = ref.read(cropLogoImageUseCaseProvider);
    final res =
        await useCase(context: context, existingBytes: existingBytes);
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
        // 썸네일 — 탭하면 갤러리 열림 (이미지 없으면 추가, 있으면 교체).
        Center(
          child: GestureDetector(
            onTap: () => _pickAndCrop(context, ref),
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
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            color: Colors.grey.shade500, size: 32),
                        const SizedBox(height: 4),
                        Text(
                          l10n.labelLogoGallery,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        // 다시 자르기 — 이미지가 있을 때만 노출.
        if (bytes != null) ...[
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.crop),
              label: Text(l10n.labelLogoRecrop),
              onPressed: () => _pickAndCrop(context, ref, existingBytes: bytes),
            ),
          ),
        ],
      ],
    );
  }
}
