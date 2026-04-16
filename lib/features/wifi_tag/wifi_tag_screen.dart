import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/tag_payload_encoder.dart';
import '../../core/widgets/output_action_buttons.dart';

class WifiTagScreen extends StatefulWidget {
  const WifiTagScreen({super.key});

  @override
  State<WifiTagScreen> createState() => _WifiTagScreenState();
}

class _WifiTagScreenState extends State<WifiTagScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  String _securityType = 'WPA2';
  bool _obscurePassword = true;

  static const _securityOptions = [
    ('WPA2', 'WPA2 (권장)'),
    ('WPA', 'WPA'),
    ('WEP', 'WEP'),
    ('nopass', '없음'),
  ];

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildArgs() => {
        'appName': 'WiFi',
        'deepLink': TagPayloadEncoder.wifi(
          ssid: _ssidController.text.trim(),
          securityType: _securityType,
          password: _securityType == 'nopass' ? null : _passwordController.text,
        ),
        'platform': 'universal',
        'appIconBytes': null,
        'tagType': 'wifi',
      };

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
    return Scaffold(
      appBar: AppBar(title: const Text('WiFi 태그')),
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
                    const Text('네트워크 이름 (SSID) *',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ssidController,
                      decoration: InputDecoration(
                        hintText: 'MyWiFi',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'SSID를 입력해주세요.' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('보안 방식',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _securityType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _securityOptions
                          .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                          .toList(),
                      onChanged: (v) => setState(() => _securityType = v!),
                    ),
                    if (_securityType != 'nopass') ...[
                      const SizedBox(height: 16),
                      const Text('비밀번호',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '비밀번호',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                    ],
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
