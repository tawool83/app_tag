import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class HistorySearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const HistorySearchBar({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: l10n.historySearchHint,
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}
