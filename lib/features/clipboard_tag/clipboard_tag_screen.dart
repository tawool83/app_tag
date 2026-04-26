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

  @override
  void initState() {
    super.initState();
    final prefillText = widget.prefill?['text'] as String?;
    if (prefillText != null && prefillText.isNotEmpty) {
      _controller.text = prefillText;
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    if (data == null || (data.text ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.msgClipboardEmpty)),
      );
    } else {
      final sel = _controller.selection;
      final text = _controller.text;
      final clip = data.text!;
      if (sel.isValid && sel.start >= 0) {
        final newText = text.replaceRange(sel.start, sel.end, clip);
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: sel.start + clip.length),
        );
      } else {
        // 커서 위치 없으면 끝에 추가
        _controller.value = TextEditingValue(
          text: text + clip,
          selection: TextSelection.collapsed(offset: text.length + clip.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildArgs() => {
        'appName': '텍스트',
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
              Row(
                children: [
                  Text(AppLocalizations.of(context)!.labelContent, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _pasteFromClipboard,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.content_paste, size: 18, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text('클립보드', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _controller,
                maxLines: 15,
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
