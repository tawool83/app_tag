import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// 제네릭 히스토리 리스트 위젯.
class HistoryListView<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T) titleExtractor;
  final String Function(T) subtitleExtractor;
  final IconData Function(T) iconExtractor;
  final Color Function(T) iconColorExtractor;
  final bool Function(T) isFavoriteExtractor;
  final void Function(T) onTap;
  final void Function(T) onDelete;
  final void Function(T) onToggleFavorite;
  final String Function(T) keyExtractor;

  const HistoryListView({
    super.key,
    required this.items,
    required this.titleExtractor,
    required this.subtitleExtractor,
    required this.iconExtractor,
    required this.iconColorExtractor,
    required this.isFavoriteExtractor,
    required this.onTap,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.keyExtractor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.historyEmpty, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return Dismissible(
          key: ValueKey(keyExtractor(item)),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) => _confirmDelete(context, l10n),
          onDismissed: (_) => onDelete(item),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: iconColorExtractor(item).withValues(alpha: 0.15),
              child: Icon(iconExtractor(item), color: iconColorExtractor(item)),
            ),
            title: Text(
              titleExtractor(item),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              subtitleExtractor(item),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
            ),
            trailing: IconButton(
              icon: Icon(
                isFavoriteExtractor(item) ? Icons.star : Icons.star_border,
                color: isFavoriteExtractor(item) ? Colors.amber : Colors.grey,
              ),
              tooltip: l10n.actionFavorite,
              onPressed: () => onToggleFavorite(item),
            ),
            onTap: () => onTap(item),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, AppLocalizations l10n) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogDeleteHistoryTitle),
        content: Text(l10n.dialogClearAllContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionDelete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
