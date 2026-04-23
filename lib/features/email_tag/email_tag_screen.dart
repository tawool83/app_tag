import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/tag_payload_encoder.dart';
import '../../l10n/app_localizations.dart';

class EmailTagScreen extends StatefulWidget {
  final Map<String, dynamic>? prefill;
  const EmailTagScreen({super.key, this.prefill});

  @override
  State<EmailTagScreen> createState() => _EmailTagScreenState();
}

class _EmailTagScreenState extends State<EmailTagScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.prefill != null) {
      _addressController.text = widget.prefill!['address'] as String? ?? '';
      _subjectController.text = widget.prefill!['subject'] as String? ?? '';
      _bodyController.text = widget.prefill!['body'] as String? ?? '';
    }
  }

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
    context.push('/qr-result', extra: _buildArgs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.screenEmailTitle)),
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
                    Text(AppLocalizations.of(context)!.labelEmailRequired,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.hintEmail,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) {
                        final l10n = AppLocalizations.of(context)!;
                        if (v == null || v.trim().isEmpty) return l10n.msgEmailRequired;
                        if (!v.contains('@')) return l10n.msgEmailInvalid;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.labelEmailSubjectOptional,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.hintEmailSubject,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.labelEmailBodyOptional,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bodyController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.hintEmailBody,
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
