import 'package:flutter/material.dart';
import '../../shared/utils/tag_payload_encoder.dart';

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

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pushNamed(
      context,
      '/output-selector',
      arguments: {
        'appName': 'WiFi',
        'deepLink': TagPayloadEncoder.wifi(
          ssid: _ssidController.text.trim(),
          securityType: _securityType,
          password: _securityType == 'nopass' ? null : _passwordController.text,
        ),
        'platform': 'universal',
        'outputType': 'qr',
        'appIconBytes': null,
        'tagType': 'wifi',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WiFi 태그')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
}
