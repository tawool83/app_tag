import 'package:flutter/material.dart';
import '../../shared/utils/tag_payload_encoder.dart';
import '../../shared/widgets/output_action_buttons.dart';

class EmailTagScreen extends StatefulWidget {
  const EmailTagScreen({super.key});

  @override
  State<EmailTagScreen> createState() => _EmailTagScreenState();
}

class _EmailTagScreenState extends State<EmailTagScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildArgs() => {
        'appName': '이메일',
        'deepLink': TagPayloadEncoder.email(
          address: _addressController.text.trim(),
          subject: _subjectController.text.trim(),
          body: _bodyController.text.trim(),
        ),
        'platform': 'universal',
        'appIconBytes': null,
        'tagType': 'email',
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
      appBar: AppBar(title: const Text('이메일 태그')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('이메일 주소 *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'example@email.com',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return '이메일 주소를 입력해주세요.';
                  if (!v.contains('@')) return '올바른 이메일 형식으로 입력해주세요.';
                  return null;
                },
              ), 
              const SizedBox(height: 16),
              const Text('제목 (선택)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  hintText: '이메일 제목',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('내용 (선택)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '이메일 본문',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
