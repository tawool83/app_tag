import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class HistoryFilterChips extends StatelessWidget {
  final List<String> availableTypes;
  final String? selectedType;
  final ValueChanged<String?> onSelected;

  const HistoryFilterChips({
    super.key,
    required this.availableTypes,
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(l10n.historyFilterAll),
              selected: selectedType == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final type in availableTypes)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(type),
                selected: selectedType == type,
                onSelected: (_) => onSelected(type),
              ),
            ),
        ],
      ),
    );
  }
}
