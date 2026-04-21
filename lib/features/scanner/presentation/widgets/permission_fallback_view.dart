import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../l10n/app_localizations.dart';

class PermissionFallbackView extends StatelessWidget {
  final VoidCallback onGalleryImport;

  const PermissionFallbackView({super.key, required this.onGalleryImport});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 72, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              l10n.scannerPermissionTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.scannerPermissionDesc,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings),
              label: Text(l10n.scannerPermissionOpenSettings),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onGalleryImport,
              icon: const Icon(Icons.photo_library),
              label: Text(l10n.scannerPermissionGalleryFallback),
            ),
          ],
        ),
      ),
    );
  }
}
