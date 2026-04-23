import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// QrTask 이름 변경 다이얼로그. 새 이름 또는 null 반환.
Future<String?> showRenameDialog(BuildContext context, String currentName) {
  final controller = TextEditingController(text: currentName);
  final l10n = AppLocalizations.of(context)!;

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.dialogRenameTitle),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 40,
        decoration: InputDecoration(
          hintText: l10n.hintTaskName,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.actionCancel),
        ),
        ElevatedButton(
          onPressed: () {
            final name = controller.text.trim();
            if (name.isNotEmpty) Navigator.pop(ctx, name);
          },
          child: Text(l10n.actionSave),
        ),
      ],
    ),
  );
}
