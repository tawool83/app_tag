import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../qr_task/domain/entities/qr_task.dart';
import '../../../qr_task/domain/entities/qr_task_kind.dart';
import '../../../qr_task/presentation/providers/qr_task_list_notifier.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(qrTaskListNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('생성 이력'),
        actions: [
          if (tasks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: '전체 삭제',
              onPressed: () => _confirmClearAll(context, ref),
            ),
        ],
      ),
      body: tasks.isEmpty
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
              itemCount: tasks.length,
              separatorBuilder: (_, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _QrTaskTile(task: tasks[index]);
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
      await ref.read(qrTaskListNotifierProvider.notifier).clearAll();
    }
  }
}

class _QrTaskTile extends ConsumerWidget {
  final QrTask task;
  const _QrTaskTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isQr = task.kind == QrTaskKind.qr;
    final isAndroid = task.meta.platform == 'android';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isQr ? Colors.blue.shade100 : Colors.purple.shade100,
        child: Icon(
          isQr ? Icons.qr_code_2 : Icons.nfc,
          color: isQr ? Colors.blue : Colors.purple,
        ),
      ),
      title: Text(task.meta.appName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${isQr ? 'QR 코드' : 'NFC 태그'} · ${isAndroid ? 'Android' : 'iOS'}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            _formatDate(task.updatedAt),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.grey),
        onPressed: () => _confirmDelete(context, ref),
      ),
      // 탭 시 QR 결과 화면으로 이동, 같은 taskId 로 이어서 편집.
      // QR 작업만 편집 복원 (NFC 는 P4 미구현).
      onTap: isQr
          ? () => context.push('/qr-result', extra: {
                'editTaskId': task.id,
                'appName': task.meta.appName,
                'deepLink': task.meta.deepLink,
                'platform': task.meta.platform,
                'packageName': task.meta.packageName,
                'tagType': task.meta.tagType,
              })
          : null,
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
        content: Text('"${task.meta.appName}" 이력을 삭제하시겠습니까?'),
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
      await ref
          .read(qrTaskListNotifierProvider.notifier)
          .delete(task.id);
    }
  }
}
