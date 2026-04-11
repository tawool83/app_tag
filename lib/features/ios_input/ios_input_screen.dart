import 'package:flutter/material.dart';
import '../../shared/constants/deep_link_constants.dart';
import '../../shared/widgets/output_action_buttons.dart';

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
    };
  }

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
      appBar: AppBar(title: const Text('iOS 앱 실행 설정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '실행할 앱의 단축어 이름',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: '예: 내냉장고',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '앱 이름을 입력해주세요.';
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
                          '단축어 설정 안내',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. iPhone의 단축어(Shortcuts) 앱을 열기\n'
                      '2. 실행하려는 앱을 여는 단축어 만들기\n'
                      '3. 단축어 이름을 위에 입력한 이름으로 저장\n'
                      '4. 아래 버튼을 눌러 QR/NFC 생성',
                      style: TextStyle(fontSize: 14, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              OutputActionButtons(
                onQrPressed: _onQr,
                onNfcPressed: _onNfc,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
