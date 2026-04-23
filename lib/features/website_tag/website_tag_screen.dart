import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/tag_payload_encoder.dart';
import '../../l10n/app_localizations.dart';

class WebsiteTagScreen extends StatefulWidget {
  final Map<String, dynamic>? prefill;
  const WebsiteTagScreen({super.key, this.prefill});

  @override
  State<WebsiteTagScreen> createState() => _WebsiteTagScreenState();
}

class _WebsiteTagScreenState extends State<WebsiteTagScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final url = widget.prefill?['url'] as String?;
    if (url != null && url.isNotEmpty) {
      _controller.text = url;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildArgs() => {
        'appName': '웹 사이트',
        'deepLink': TagPayloadEncoder.website(_controller.text.trim()),
        'platform': 'universal',
        'appIconBytes': null,
        'tagType': 'website',
      };

  void _onQr() {
    if (!_formKey.currentState!.validate()) return;
    context.push('/qr-result', extra: _buildArgs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.screenWebsiteTitle)),
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
                    Text(AppLocalizations.of(context)!.labelUrl, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _controller,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.hintUrl,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) {
                        final l10n = AppLocalizations.of(context)!;
                        if (v == null || v.trim().isEmpty) return l10n.msgUrlRequired;
                        final url = v.trim();
                        final normalized = url.startsWith('http') ? url : 'https://$url';
                        final uri = Uri.tryParse(normalized);
                        if (uri == null || !uri.hasAuthority) return l10n.msgUrlInvalid;
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _onQr,
                icon: const Icon(Icons.palette),
                label: Text(AppLocalizations.of(context)!.actionStartCustomize),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
