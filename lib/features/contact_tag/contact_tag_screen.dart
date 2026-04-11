import 'package:flutter/material.dart';
import '../../shared/utils/tag_payload_encoder.dart';

class ContactTagScreen extends StatefulWidget {
  const ContactTagScreen({super.key});

  @override
  State<ContactTagScreen> createState() => _ContactTagScreenState();
}

class _ContactTagScreenState extends State<ContactTagScreen> {
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

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pushNamed(
      context,
      '/output-selector',
      arguments: {
        'appName': '연락처',
        'deepLink': TagPayloadEncoder.contact(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
        ),
        'platform': 'universal',
        'outputType': 'qr',
        'appIconBytes': null,
        'tagType': 'contact',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('연락처 태그')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('이름 *'),
              _field(_nameController, hint: '홍길동', validator: (v) =>
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onNext,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('다음'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
