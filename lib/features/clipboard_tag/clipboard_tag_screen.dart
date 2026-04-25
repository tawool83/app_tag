import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/tag_payload_encoder.dart';
import '../../l10n/app_localizations.dart';

class ClipboardTagScreen extends StatefulWidget {
  final Map<String, dynamic>? prefill;
  const ClipboardTagScreen({super.key, this.prefill});

  @override
  State<ClipboardTagScreen> createState() => _ClipboardTagScreenState();
}

class _ClipboardTagScreenState extends State<ClipboardTagScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEmpty = false;

  @override
  void initState() {
    super.initState();
    final prefillText = widget.prefill?['text'] as String?;
    if (prefillText != null && prefillText.isNotEmpty) {
      _controller.text = prefillText;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted) return;
      if (data == null || (data.text ?? '').isEmpty) {
        setState(() => _isEmpty = true);
      } else {
        _controller.text = data.text!;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildArgs() => {
        'appName': '클립보드',
        'deepLink': TagPayloadEncoder.clipboard(_controller.text.trim()),
        'platform': 'universal',
        'appIconBytes': null,
        'tagType': 'clipboard',
        if (widget.prefill?['editTaskId'] != null)
          'editTaskId': widget.prefill!['editTaskId'],
      };

  void _onQr() {
    if (!_formKey.currentState!.validate()) return;
    context.push('/qr-result', extra: _buildArgs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.screenClipboardTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _onQr,
              child: Text(AppLocalizations.of(context)!.actionNext),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(AppLocalizations.of(context)!.msgClipboardEmpty),
                      ),
                    ],
                  ),
                ),
              Text(AppLocalizations.of(context)!.labelContent, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _controller,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.hintClipboardText,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.msgContentRequired : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
