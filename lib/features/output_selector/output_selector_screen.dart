import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('출력 방식 선택')),
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
                    label: 'QR 코드',
                    description: '카메라로 스캔하여 앱 실행',
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
                    loading: () => const _OutputCard(
                      icon: Icons.nfc,
                      label: 'NFC 태그',
                      description: '...',
                      enabled: false,
                    ),
                    error: (_, e) => const _OutputCard(
                      icon: Icons.nfc,
                      label: 'NFC 태그',
                      description: 'NFC 확인 실패',
                      enabled: false,
                    ),
                    data: (nfcAvailable) {
                      if (!nfcAvailable) {
                        return _OutputCard(
                          icon: Icons.nfc,
                          label: 'NFC 태그',
                          description: _isIOSSimulator
                              ? '시뮬레이터에서는 NFC를 테스트할 수 없습니다'
                              : '이 기기는 NFC를 지원하지 않습니다',
                          enabled: false,
                        );
                      }
                      return nfcWriteSupportedAsync.when(
                        loading: () => const _OutputCard(
                          icon: Icons.nfc,
                          label: 'NFC 태그',
                          description: '...',
                          enabled: false,
                        ),
                        error: (_, e) => const _OutputCard(
                          icon: Icons.nfc,
                          label: 'NFC 태그',
                          description: '확인 실패',
                          enabled: false,
                        ),
                        data: (writeSupported) => writeSupported
                            ? _OutputCard(
                                icon: Icons.nfc,
                                label: 'NFC 태그',
                                description: '태그에 가져다 대어 앱 실행',
                                onTap: () => context.push('/nfc-writer', extra: {
                                  'appName': appName,
                                  'deepLink': deepLink,
                                  'packageName': packageName,
                                  'platform': platform,
                                  'outputType': 'nfc',
                                  'appIconBytes': appIconBytes,
                                }),
                              )
                            : const _OutputCard(
                                icon: Icons.nfc,
                                label: 'NFC 태그',
                                description:
                                    'NFC 쓰기는 iPhone XS 이상에서 지원됩니다',
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
