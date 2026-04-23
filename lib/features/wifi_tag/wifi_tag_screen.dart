import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/tag_payload_encoder.dart';
import '../../l10n/app_localizations.dart';

class WifiTagScreen extends StatefulWidget {
  final Map<String, dynamic>? prefill;
  const WifiTagScreen({super.key, this.prefill});

  @override
  State<WifiTagScreen> createState() => _WifiTagScreenState();
}

class _WifiTagScreenState extends State<WifiTagScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  String _securityType = 'WPA2';
  bool _obscurePassword = true;

  List<(String, String)> _securityOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      ('WPA2', l10n.optionWpa2),
      ('WPA', 'WPA'),
      ('WEP', 'WEP'),
      ('nopass', l10n.optionNoSecurity),
    ];
  }

  @override
  void initState() {
    super.initState();
    if (widget.prefill != null) {
      _ssidController.text = widget.prefill!['ssid'] as String? ?? '';
      _passwordController.text = widget.prefill!['password'] as String? ?? '';
      final sec = widget.prefill!['securityType'] as String?;
      if (sec != null && sec.isNotEmpty) _securityType = sec;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.screenWifiTitle)),
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
                    Text(AppLocalizations.of(context)!.labelWifiSsid,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ssidController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.hintWifiSsid,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.msgSsidRequired : null,
                    ),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.labelWifiSecurity,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _securityType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _securityOptions(context)
                          .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                          .toList(),
                      onChanged: (v) => setState(() => _securityType = v!),
                    ),
                    if (_securityType != 'nopass') ...[
                      const SizedBox(height: 16),
                      Text(AppLocalizations.of(context)!.labelWifiPassword,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.hintWifiPassword,
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
