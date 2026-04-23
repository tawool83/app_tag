import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/tag_payload_encoder.dart';
import '../../l10n/app_localizations.dart';

class SmsTagScreen extends StatefulWidget {
  final Map<String, dynamic>? prefill;
  const SmsTagScreen({super.key, this.prefill});

  @override
  State<SmsTagScreen> createState() => _SmsTagScreenState();
}

class _SmsTagScreenState extends State<SmsTagScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.prefill != null) {
      _phoneController.text = widget.prefill!['phone'] as String? ?? '';
      _messageController.text = widget.prefill!['message'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildArgs() => {
        'appName': 'SMS',
        'deepLink': TagPayloadEncoder.sms(
          phone: _phoneController.text.trim(),
          message: _messageController.text.trim(),
        ),
        'platform': 'universal',
        'appIconBytes': null,
        'tagType': 'sms',
      };

  void _onQr() {
    if (!_formKey.currentState!.validate()) return;
    context.push('/qr-result', extra: _buildArgs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.screenSmsTitle)),
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
                    Text(AppLocalizations.of(context)!.labelPhoneRequired,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.hintPhone,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.msgPhoneRequired : null,
                    ),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.labelMessageOptional,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.hintSmsMessage,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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
