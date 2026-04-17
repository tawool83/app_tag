import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../qr_task/domain/entities/qr_task.dart';
import '../../../qr_task/domain/entities/qr_task_kind.dart';
import '../../../qr_task/presentation/providers/qr_task_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(qrTaskListNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenHistoryTitle),
        actions: [
          if (tasks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: l10n.tooltipDeleteAll,
              onPressed: () => _confirmClearAll(context, ref),
            ),
        ],
      ),
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.screenHistoryEmpty,
                      style: const TextStyle(color: Colors.grey)),
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogClearAllTitle),
        content: Text(l10n.dialogClearAllContent),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.actionCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  Text(l10n.actionDelete, style: const TextStyle(color: Colors.red))),
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
    final l10n = AppLocalizations.of(context)!;

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
            '${isQr ? l10n.labelQrCode : l10n.labelNfcTag} · ${isAndroid ? 'Android' : 'iOS'}',
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogDeleteHistoryTitle),
        content: Text(l10n.dialogDeleteHistoryContent(task.meta.appName)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.actionCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  Text(l10n.actionDelete, style: const TextStyle(color: Colors.red))),
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
