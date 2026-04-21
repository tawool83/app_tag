import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/scan_result.dart';
import 'data_type_tag.dart';
import 'preview_area.dart';
import 'primary_actions.dart';

/// 스캔 결과 Bottom Sheet 표시.
Future<void> showResultBottomSheet({
  required BuildContext context,
  required ScanResult result,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ResultSheetBody(result: result),
  );
}

class _ResultSheetBody extends StatelessWidget {
  final ScanResult result;

  const _ResultSheetBody({required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.scanResultTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          DataTypeTag(type: result.detectedType),
          const SizedBox(height: 12),
          PreviewArea(result: result),
          const SizedBox(height: 20),
          PrimaryActions(result: result),
        ],
      ),
    );
  }
}
