import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tag_history.dart';
import 'history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final histories = ref.watch(historyNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('생성 이력'),
        actions: [
          if (histories.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: '전체 삭제',
              onPressed: () => _confirmClearAll(context, ref),
            ),
        ],
      ),
      body: histories.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('이력이 없습니다.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.separated(
              itemCount: histories.length,
              separatorBuilder: (_, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = histories[index];
                return _HistoryTile(item: item);
              },
            ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('전체 삭제'),
        content: const Text('모든 이력을 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(historyNotifierProvider.notifier).clearAll();
    }
  }
}

class _HistoryTile extends ConsumerWidget {
  final TagHistory item;
  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isQr = item.outputType == 'qr';
    final isAndroid = item.platform == 'android';
    final iconBytes = item.appIconBytes;

    return ListTile(
      leading: iconBytes != null
          ? CircleAvatar(
              backgroundImage: MemoryImage(iconBytes),
              backgroundColor: Colors.transparent,
            )
          : CircleAvatar(
              backgroundColor:
                  isQr ? Colors.blue.shade100 : Colors.purple.shade100,
              child: Icon(
                isQr ? Icons.qr_code_2 : Icons.nfc,
                color: isQr ? Colors.blue : Colors.purple,
              ),
            ),
      title: Text(item.appName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${isQr ? 'QR 코드' : 'NFC 태그'} · ${isAndroid ? 'Android' : 'iOS'}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            _formatDate(item.createdAt),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.grey),
        onPressed: () => _confirmDelete(context, ref),
      ),
      onTap: () => Navigator.pushNamed(
        context,
        '/output-selector',
        arguments: {
          'appName': item.appName,
          'deepLink': item.deepLink,
          'packageName': item.packageName,
          'platform': item.platform,
          'appIconBytes': item.appIconBytes,
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이력 삭제'),
        content: Text('"${item.appName}" 이력을 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(historyNotifierProvider.notifier).delete(item.id);
    }
  }
}
