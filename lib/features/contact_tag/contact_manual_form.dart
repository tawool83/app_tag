import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/tag_payload_encoder.dart';
import '../../core/widgets/output_action_buttons.dart';
import '../../l10n/app_localizations.dart';

class ContactManualFormScreen extends StatefulWidget {
  final Map<String, dynamic>? prefill;
  const ContactManualFormScreen({super.key, this.prefill});

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
  void initState() {
    super.initState();
    if (widget.prefill != null) {
      _nameController.text = widget.prefill!['name'] as String? ?? '';
      _phoneController.text = widget.prefill!['phone'] as String? ?? '';
      _emailController.text = widget.prefill!['email'] as String? ?? '';
    }
  }

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
    context.push('/qr-result', extra: _buildArgs());
  }

  void _onNfc() {
    if (!_formKey.currentState!.validate()) return;
    context.push('/nfc-writer', extra: _buildArgs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.screenContactManualTitle)),
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
                    _label(AppLocalizations.of(context)!.labelNameRequired),
                    _field(_nameController,
                        hint: AppLocalizations.of(context)!.hintName,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.msgNameRequired : null),
                    const SizedBox(height: 16),
                    _label(AppLocalizations.of(context)!.labelPhone),
                    _field(_phoneController,
                        hint: AppLocalizations.of(context)!.hintPhone,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _label(AppLocalizations.of(context)!.labelEmail),
                    _field(_emailController,
                        hint: AppLocalizations.of(context)!.hintEmail,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (!v.contains('@')) return AppLocalizations.of(context)!.msgEmailInvalid;
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
