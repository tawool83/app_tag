import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/background_config.dart';
import '../qr_result_provider.dart';

/// [배경화면] 탭: 갤러리에서 이미지 선택 → 자유 비율 crop → 크기 조정.
class BackgroundTab extends ConsumerWidget {
  final VoidCallback onChanged;

  const BackgroundTab({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = ref.watch(qrResultProvider).background;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 갤러리 선택 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('갤러리에서 이미지 불러오기'),
              onPressed: () => _pickAndCropImage(context, ref),
            ),
          ),

          if (bg.hasImage) ...[
            const SizedBox(height: 16),

            // 현재 이미지 미리보기
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  bg.imageBytes!,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 스케일 슬라이더
            _SectionLabel('크기'),
            Row(
              children: [
                const Icon(Icons.photo_size_select_small, size: 18, color: Colors.grey),
                Expanded(
                  child: Slider(
                    value: bg.scale,
                    min: 0.5,
                    max: 2.0,
                    divisions: 30,
                    label: '${(bg.scale * 100).round()}%',
                    onChanged: (v) {
                      ref
                          .read(qrResultProvider.notifier)
                          .setBackground(bg.copyWith(scale: v));
                      onChanged();
                    },
                  ),
                ),
                const Icon(Icons.photo_size_select_large, size: 18, color: Colors.grey),
              ],
            ),

            const SizedBox(height: 8),

            // 이미지 제거
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('이미지 제거', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  ref
                      .read(qrResultProvider.notifier)
                      .setBackground(const BackgroundConfig());
                  onChanged();
                },
              ),
            ),
          ] else ...[
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Icon(Icons.image_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(
                    '배경 이미지가 없으면 흰 배경으로 표시됩니다.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickAndCropImage(BuildContext context, WidgetRef ref) async {
    // 1. 갤러리 선택
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    // 2. 자유 비율 crop
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '배경 이미지 편집',
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: '배경 이미지 편집',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
        ),
      ],
    );
    if (cropped == null) return;

    // 3. 리사이즈 + JPEG 압축 (최대 800px, quality 80)
    final bytes = await _compressImage(cropped.path);
    if (bytes == null) return;

    if (context.mounted) {
      ref.read(qrResultProvider.notifier).setBackground(
            ref.read(qrResultProvider).background.copyWith(imageBytes: bytes),
          );
      ref.read(qrResultProvider.notifier).setBackground(
            ref.read(qrResultProvider).background.copyWith(imageBytes: bytes, scale: 1.0),
          );
      onChanged();
    }
  }

  Future<Uint8List?> _compressImage(String path) async {
    try {
      final raw = await File(path).readAsBytes();
      var decoded = img.decodeImage(raw);
      if (decoded == null) return null;
      if (decoded.width > 800 || decoded.height > 800) {
        decoded = img.copyResize(decoded, width: 800);
      }
      return Uint8List.fromList(img.encodeJpg(decoded, quality: 80));
    } catch (_) {
      return null;
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
