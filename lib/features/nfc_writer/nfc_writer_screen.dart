import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/tag_history.dart';
import '../qr_result/qr_result_provider.dart';
import 'nfc_writer_provider.dart';

class NfcWriterScreen extends ConsumerStatefulWidget {
  const NfcWriterScreen({super.key});

  @override
  ConsumerState<NfcWriterScreen> createState() => _NfcWriterScreenState();
}

class _NfcWriterScreenState extends ConsumerState<NfcWriterScreen> {
  bool _historySaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      ref.read(nfcWriterProvider.notifier).startWrite(args['deepLink']);
    });
  }

  Future<void> _onWriteSuccess(Map<String, dynamic> args) async {
    await _saveHistory(args);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  Future<void> _saveHistory(Map<String, dynamic> args) async {
    if (_historySaved) return;
    _historySaved = true;
    final history = TagHistory(
      id: const Uuid().v4(),
      appName: args['appName'],
      deepLink: args['deepLink'],
      platform: args['platform'],
      outputType: 'nfc',
      createdAt: DateTime.now(),
      packageName: args['packageName'],
      appIconBytes: args['appIconBytes'] as Uint8List?,
    );
    await ref.read(historyServiceProvider).saveHistory(history);
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final appName = args['appName'] as String;

    final state = ref.watch(nfcWriterProvider);

    // 성공 시 이력 저장 및 자동 이동
    ref.listen(nfcWriterProvider, (_, next) {
      if (next.status == NfcWriteStatus.success) {
        _onWriteSuccess(args);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC 기록'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              appName,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            _buildStatusWidget(state),
            const SizedBox(height: 32),
            _buildStatusText(state),
            const SizedBox(height: 24),
            if (state.status == NfcWriteStatus.error)
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(nfcWriterProvider.notifier).reset();
                  ref
                      .read(nfcWriterProvider.notifier)
                      .startWrite(args['deepLink']);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            if (state.status == NfcWriteStatus.waiting)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusWidget(NfcWriterState state) {
    switch (state.status) {
      case NfcWriteStatus.waiting:
        return const SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(strokeWidth: 6),
        );
      case NfcWriteStatus.success:
        return const Icon(Icons.check_circle,
            size: 120, color: Colors.green);
      case NfcWriteStatus.error:
        return const Icon(Icons.error_outline,
            size: 120, color: Colors.red);
      default:
        return const Icon(Icons.nfc, size: 120, color: Colors.grey);
    }
  }

  Widget _buildStatusText(NfcWriterState state) {
    switch (state.status) {
      case NfcWriteStatus.waiting:
        return const Text(
          'NFC 태그를 스마트폰 뒷면에\n가져다 대세요',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        );
      case NfcWriteStatus.success:
        return const Text(
          '기록 완료!\n홈으로 이동합니다...',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green),
        );
      case NfcWriteStatus.error:
        return Text(
          state.errorMessage ?? 'NFC 기록에 실패했습니다.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.red),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
