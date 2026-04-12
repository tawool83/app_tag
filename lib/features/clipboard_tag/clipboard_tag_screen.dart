import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/utils/tag_payload_encoder.dart';
import '../../shared/widgets/output_action_buttons.dart';

class ClipboardTagScreen extends StatefulWidget {
  const ClipboardTagScreen({super.key});

  @override
  State<ClipboardTagScreen> createState() => _ClipboardTagScreenState();
}

class _ClipboardTagScreenState extends State<ClipboardTagScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEmpty = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted) return;
      if (data == null || (data.text ?? '').isEmpty) {
        setState(() => _isEmpty = true);
      } else {
        _controller.text = data.text!;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildArgs() => {
        'appName': '클립보드',
        'deepLink': TagPayloadEncoder.clipboard(_controller.text.trim()),
        'platform': 'universal',
        'appIconBytes': null,
        'tagType': 'clipboard',
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
      appBar: AppBar(title: const Text('클립보드 태그')),
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
                    if (_isEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('클립보드가 비어 있습니다. 직접 입력하세요.'),
                            ),
                          ],
                        ),
                      ),
                    const Text('내용', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _controller,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: '태그에 저장할 텍스트',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? '내용을 입력해주세요.' : null,
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
