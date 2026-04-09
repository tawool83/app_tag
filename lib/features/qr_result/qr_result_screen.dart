import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/tag_history.dart';
import 'qr_result_provider.dart';

class QrResultScreen extends ConsumerStatefulWidget {
  const QrResultScreen({super.key});

  @override
  ConsumerState<QrResultScreen> createState() => _QrResultScreenState();
}

class _QrResultScreenState extends ConsumerState<QrResultScreen> {
  final _repaintKey = GlobalKey();
  bool _historySaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureAndSaveHistory());
  }

  Future<void> _captureAndSaveHistory() async {
    if (_historySaved) return;
    _historySaved = true;

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final appName = args['appName'] as String;
    final deepLink = args['deepLink'] as String;
    final packageName = args['packageName'] as String?;
    final platform = args['platform'] as String;
    final appIconBytes = args['appIconBytes'] as Uint8List?;

    // QR 이미지 캡처
    await Future.delayed(const Duration(milliseconds: 300));
    final boundary =
        _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      final bytes = await ref.read(qrServiceProvider).captureQrImage(boundary);
      if (bytes != null) {
        ref.read(qrResultProvider.notifier).setCapturedImage(bytes);
      }
    }

    // 이력 자동 저장
    final history = TagHistory(
      id: const Uuid().v4(),
      appName: appName,
      deepLink: deepLink,
      platform: platform,
      outputType: 'qr',
      createdAt: DateTime.now(),
      packageName: packageName,
      appIconBytes: appIconBytes,
    );
    await ref.read(historyServiceProvider).saveHistory(history);
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final appName = args['appName'] as String;
    final deepLink = args['deepLink'] as String;

    final state = ref.watch(qrResultProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('QR 코드')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // QR 코드 이미지 (캡처용 RepaintBoundary 포함)
            RepaintBoundary(
              key: _repaintKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    QrImageView(
                      data: deepLink,
                      version: QrVersions.auto,
                      size: 240,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              deepLink,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            // 액션 버튼들
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.save_alt,
                    label: '갤러리 저장',
                    status: state.saveStatus,
                    onTap: () => ref
                        .read(qrResultProvider.notifier)
                        .saveToGallery(appName),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.share,
                    label: '공유',
                    status: state.shareStatus,
                    onTap: () => ref
                        .read(qrResultProvider.notifier)
                        .shareImage(appName),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.print,
                    label: '인쇄',
                    status: state.printStatus,
                    onTap: () => ref
                        .read(qrResultProvider.notifier)
                        .printQrCode(appName),
                  ),
                ),
              ],
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final QrActionStatus status;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = status == QrActionStatus.loading;
    final isDone = status == QrActionStatus.success;

    return ElevatedButton(
      onPressed: isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor:
            isDone ? Colors.green.shade100 : null,
      ),
      child: Column(
        children: [
          isLoading
              ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(isDone ? Icons.check : icon, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
