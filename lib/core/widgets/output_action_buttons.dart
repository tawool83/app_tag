import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/app_picker/app_picker_provider.dart';
import '../../l10n/app_localizations.dart';

class OutputActionButtons extends ConsumerWidget {
  final VoidCallback onQrPressed;
  final VoidCallback onNfcPressed;

  const OutputActionButtons({
    super.key,
    required this.onQrPressed,
    required this.onNfcPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nfcAvailableAsync = ref.watch(nfcAvailableProvider);
    final nfcWriteSupportedAsync = ref.watch(nfcWriteSupportedProvider);

    final bool nfcEnabled = nfcAvailableAsync.maybeWhen(
      data: (available) {
        if (!available) return false;
        return nfcWriteSupportedAsync.maybeWhen(
          data: (supported) => supported,
          orElse: () => false,
        );
      },
      orElse: () => false,
    );

    final l10n = AppLocalizations.of(context)!;
    final nfcLabel = nfcAvailableAsync.maybeWhen(
      data: (available) {
        if (!available) return l10n.msgNfcUnsupportedDevice;
        return nfcWriteSupportedAsync.maybeWhen(
          data: (supported) =>
              supported ? l10n.actionNfcWrite : l10n.msgNfcUnsupportedDevice,
          orElse: () => l10n.actionNfcWrite,
        );
      },
      orElse: () => l10n.actionNfcWrite,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    const buttonPadding = EdgeInsets.symmetric(vertical: 20, horizontal: 12);

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onQrPressed,
            style: ElevatedButton.styleFrom(
              padding: buttonPadding,
              shape: buttonShape,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code, size: 36),
                const SizedBox(height: 8),
                Text(l10n.labelQrCode, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: nfcEnabled ? onNfcPressed : null,
            style: OutlinedButton.styleFrom(
              padding: buttonPadding,
              shape: buttonShape,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.nfc, size: 36),
                const SizedBox(height: 8),
                Text(
                  nfcLabel,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
