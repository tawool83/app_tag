import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/deep_link_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/output_action_buttons.dart';

class IosInputScreen extends StatefulWidget {
  const IosInputScreen({super.key});

  @override
  State<IosInputScreen> createState() => _IosInputScreenState();
}

class _IosInputScreenState extends State<IosInputScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildArgs() {
    final name = _controller.text.trim();
    return {
      'appName': name,
      'deepLink': DeepLinkConstants.iosShortcutLink(name),
      'platform': 'ios',
      'appIconBytes': null,
      'tagType': 'app',
    };
  }

  void _onQr() {
    if (!_formKey.currentState!.validate()) return;
    context.push('/qr-result', extra: _buildArgs());
  }

  void _onNfc() {
    if (!_formKey.currentState!.validate()) return;
    context.push('/nfc-writer', extra: _buildArgs());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenIosInputTitle)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.labelShortcutName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: l10n.hintShortcutName,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.msgAppNameRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                l10n.screenIosInputGuideTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.screenIosInputGuideSteps,
                            style: const TextStyle(fontSize: 14, height: 1.6),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse(
                                  'https://support.apple.com/ko-kr/guide/shortcuts/welcome/ios');
                              try {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              } catch (_) {}
                            },
                            icon: Icon(Icons.open_in_new,
                                size: 16, color: Colors.blue.shade700),
                            label: Text(
                              l10n.actionAppleShortcutsGuide,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.blue.shade700),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: OutputActionButtons(
              onQrPressed: _onQr,
              onNfcPressed: _onNfc,
            ),
          ),
        ],
      ),
    );
  }
}
