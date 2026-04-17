import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../app_picker/presentation/providers/app_picker_providers.dart';

bool get _isIOSSimulator =>
    Platform.isIOS &&
    Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');

class OutputSelectorScreen extends ConsumerWidget {
  const OutputSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args =
        GoRouterState.of(context).extra as Map<String, dynamic>;
    final appName = args['appName'] as String;
    final deepLink = args['deepLink'] as String;
    final packageName = args['packageName'] as String?;
    final platform = args['platform'] as String;

    final appIconBytes = args['appIconBytes'] as Uint8List?;

    final nfcAvailableAsync = ref.watch(nfcAvailableProvider);
    final nfcWriteSupportedAsync = ref.watch(nfcWriteSupportedProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenOutputSelectorTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '앱: $appName',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              deepLink,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _OutputCard(
                    icon: Icons.qr_code_2,
                    label: l10n.labelQrCode,
                    description: l10n.screenOutputQrDesc,
                    onTap: () => context.push('/qr-result', extra: {
                      'appName': appName,
                      'deepLink': deepLink,
                      'packageName': packageName,
                      'platform': platform,
                      'outputType': 'qr',
                      'appIconBytes': appIconBytes,
                    }),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: nfcAvailableAsync.when(
                    loading: () => _OutputCard(
                      icon: Icons.nfc,
                      label: l10n.labelNfcTag,
                      description: '...',
                      enabled: false,
                    ),
                    error: (_, e) => _OutputCard(
                      icon: Icons.nfc,
                      label: l10n.labelNfcTag,
                      description: l10n.msgNfcCheckFailed,
                      enabled: false,
                    ),
                    data: (nfcAvailable) {
                      if (!nfcAvailable) {
                        return _OutputCard(
                          icon: Icons.nfc,
                          label: l10n.labelNfcTag,
                          description: _isIOSSimulator
                              ? l10n.msgNfcSimulator
                              : l10n.msgNfcNotSupported,
                          enabled: false,
                        );
                      }
                      return nfcWriteSupportedAsync.when(
                        loading: () => _OutputCard(
                          icon: Icons.nfc,
                          label: l10n.labelNfcTag,
                          description: '...',
                          enabled: false,
                        ),
                        error: (_, e) => _OutputCard(
                          icon: Icons.nfc,
                          label: l10n.labelNfcTag,
                          description: l10n.msgNfcCheckFailed,
                          enabled: false,
                        ),
                        data: (writeSupported) => writeSupported
                            ? _OutputCard(
                                icon: Icons.nfc,
                                label: l10n.labelNfcTag,
                                description: l10n.screenOutputNfcDesc,
                                onTap: () => context.push('/nfc-writer', extra: {
                                  'appName': appName,
                                  'deepLink': deepLink,
                                  'packageName': packageName,
                                  'platform': platform,
                                  'outputType': 'nfc',
                                  'appIconBytes': appIconBytes,
                                }),
                              )
                            : _OutputCard(
                                icon: Icons.nfc,
                                label: l10n.labelNfcTag,
                                description: l10n.msgNfcWriteIosMin,
                                enabled: false,
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OutputCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback? onTap;
  final bool enabled;

  const _OutputCard({
    required this.icon,
    required this.label,
    required this.description,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: enabled
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: enabled
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: enabled ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: enabled ? Colors.grey.shade600 : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
