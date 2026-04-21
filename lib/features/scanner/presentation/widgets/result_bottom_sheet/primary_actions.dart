import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/scan_detected_type.dart';
import '../../../domain/entities/scan_result.dart';

class PrimaryActions extends StatelessWidget {
  final ScanResult result;

  const PrimaryActions({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = _buildActions(context, l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: actions,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _onCustomize(context),
          icon: const Icon(Icons.auto_fix_high),
          label: Text(l10n.scanActionCustomize),
        ),
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context, AppLocalizations l10n) {
    return switch (result.detectedType) {
      ScanDetectedType.url => [
          _ActionChip(
            label: l10n.scanActionOpenBrowser,
            icon: Icons.open_in_browser,
            onPressed: () => _launchUrl(result.parsedMeta['url'] as String),
          ),
          _ActionChip(
            label: l10n.scanActionCopyLink,
            icon: Icons.copy,
            onPressed: () => _copy(context, result.parsedMeta['url'] as String),
          ),
        ],
      ScanDetectedType.wifi => [
          _ActionChip(
            label: l10n.scanActionCopySsid,
            icon: Icons.copy,
            onPressed: () => _copy(context, result.parsedMeta['ssid'] as String),
          ),
          if (result.parsedMeta['password'] != null)
            _ActionChip(
              label: l10n.scanActionCopyPassword,
              icon: Icons.key,
              onPressed: () =>
                  _copy(context, result.parsedMeta['password'] as String),
            ),
        ],
      ScanDetectedType.text || ScanDetectedType.appDeepLink => [
          _ActionChip(
            label: l10n.scanActionCopyAll,
            icon: Icons.copy,
            onPressed: () => _copy(context, result.rawValue),
          ),
          _ActionChip(
            label: l10n.scanActionShare,
            icon: Icons.share,
            onPressed: () => Share.share(result.rawValue),
          ),
        ],
      _ => [
          // Contact/SMS/Email/Location/Event — OS intent
          _ActionChip(
            label: l10n.scanActionOpenApp,
            icon: Icons.open_in_new,
            onPressed: () => _launchUrl(result.rawValue),
          ),
          _ActionChip(
            label: l10n.scanActionCopyAll,
            icon: Icons.copy,
            onPressed: () => _copy(context, result.rawValue),
          ),
        ],
    };
  }

  void _onCustomize(BuildContext context) {
    Navigator.pop(context); // 시트 닫기
    final route = result.detectedType.tagRoute;
    context.push(route, extra: result.parsedMeta);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
