import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class ScannerControlBar extends StatelessWidget {
  final bool flashOn;
  final VoidCallback onToggleFlash;
  final VoidCallback onGalleryImport;

  const ScannerControlBar({
    super.key,
    required this.flashOn,
    required this.onToggleFlash,
    required this.onGalleryImport,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ControlButton(
              icon: flashOn ? Icons.flash_on : Icons.flash_off,
              tooltip: flashOn ? l10n.scannerFlashOff : l10n.scannerFlashOn,
              onPressed: onToggleFlash,
            ),
            const SizedBox(width: 48),
            _ControlButton(
              icon: Icons.photo_library,
              tooltip: l10n.scannerGalleryImport,
              onPressed: onGalleryImport,
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(28),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 28),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
