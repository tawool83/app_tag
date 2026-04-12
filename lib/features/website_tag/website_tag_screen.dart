import 'package:flutter/material.dart';
import '../../shared/utils/tag_payload_encoder.dart';
import '../../shared/widgets/output_action_buttons.dart';

class WebsiteTagScreen extends StatefulWidget {
  const WebsiteTagScreen({super.key});

  @override
  State<WebsiteTagScreen> createState() => _WebsiteTagScreenState();
}

class _WebsiteTagScreenState extends State<WebsiteTagScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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
    Navigator.pushNamed(context, '/qr-result', arguments: _buildArgs());
  }

  void _onNfc() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pushNamed(context, '/nfc-writer', arguments: _buildArgs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('웹 사이트 태그')),
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
                    const Text('URL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _controller,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        hintText: 'https://example.com',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'URL을 입력해주세요.';
                        final url = v.trim();
                        final normalized = url.startsWith('http') ? url : 'https://$url';
                        final uri = Uri.tryParse(normalized);
                        if (uri == null || !uri.hasAuthority) return '올바른 URL 형식으로 입력해주세요.';
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
