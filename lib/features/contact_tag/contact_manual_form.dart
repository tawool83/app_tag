import 'package:flutter/material.dart';
import '../../shared/utils/tag_payload_encoder.dart';
import '../../shared/widgets/output_action_buttons.dart';

class ContactManualFormScreen extends StatefulWidget {
  const ContactManualFormScreen({super.key});

  @override
  State<ContactManualFormScreen> createState() =>
      _ContactManualFormScreenState();
}

class _ContactManualFormScreenState extends State<ContactManualFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildArgs() => {
        'appName': '연락처',
        'deepLink': TagPayloadEncoder.contact(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
        ),
        'platform': 'universal',
        'appIconBytes': null,
        'tagType': 'contact',
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
      appBar: AppBar(title: const Text('직접 입력')),
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
                    _label('이름 *'),
                    _field(_nameController,
                        hint: '홍길동',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? '이름을 입력해주세요.' : null),
                    const SizedBox(height: 16),
                    _label('전화번호'),
                    _field(_phoneController,
                        hint: '010-0000-0000',
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _label('이메일'),
                    _field(_emailController,
                        hint: 'example@email.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (!v.contains('@')) return '올바른 이메일 형식으로 입력해주세요.';
                          return null;
                        }),
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _field(
    TextEditingController controller, {
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: validator,
      );
}
