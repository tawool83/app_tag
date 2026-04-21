import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class HistoryTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback onToggleFavorite;

  const HistoryTile({
    super.key,
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.isFavorite,
    this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconBgColor.withValues(alpha: 0.15),
        child: Icon(icon, color: iconBgColor),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
        maxLines: 1,
      ),
      trailing: IconButton(
        icon: Icon(
          isFavorite ? Icons.star : Icons.star_border,
          color: isFavorite ? Colors.amber : Colors.grey,
        ),
        tooltip: l10n.actionFavorite,
        onPressed: onToggleFavorite,
      ),
      onTap: onTap,
    );
  }
}
