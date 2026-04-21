import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/tag_payload_encoder.dart';
import '../../core/widgets/output_action_buttons.dart';
import '../../l10n/app_localizations.dart';

class EventTagScreen extends StatefulWidget {
  const EventTagScreen({super.key});

  @override
  State<EventTagScreen> createState() => _EventTagScreenState();
}

class _EventTagScreenState extends State<EventTagScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();

  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = now;
    _startTime = TimeOfDay.fromDateTime(now);
    _endDate = now;
    _endTime = TimeOfDay.fromDateTime(now.add(const Duration(hours: 1)));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  DateTime _combine(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Map<String, dynamic>? _buildArgs() {
    final start = _combine(_startDate, _startTime);
    final end = _combine(_endDate, _endTime);
    if (!end.isAfter(start)) {
      context.showSnack(AppLocalizations.of(context)!.msgEventEndBeforeStart);
      return null;
    }
    return {
      'appName': '이벤트/일정',
      'deepLink': TagPayloadEncoder.event(
        title: _titleController.text.trim(),
        start: start,
        end: end,
        location: _locationController.text.trim(),
        description: _descController.text.trim(),
      ),
      'platform': 'universal',
      'appIconBytes': null,
      'tagType': 'event',
    };
  }

  void _onQr() {
    if (!_formKey.currentState!.validate()) return;
    final args = _buildArgs();
    if (args == null) return;
    context.push('/qr-result', extra: args);
  }

  void _onNfc() {
    if (!_formKey.currentState!.validate()) return;
    final args = _buildArgs();
    if (args == null) return;
    context.push('/nfc-writer', extra: args);
  }

  String _fmtDate(DateTime d) => '${d.year}.${d.month.toString().padLeft(2,'0')}.${d.day.toString().padLeft(2,'0')}';
  String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.screenEventTitle)),
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
                    Text(AppLocalizations.of(context)!.labelEventTitleRequired,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.hintEventTitle,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.msgEventTitleRequired : null,
                    ),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.labelEventStart,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(_fmtDate(_startDate)),
                            onPressed: () => _pickDate(isStart: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time, size: 18),
                            label: Text(_fmtTime(_startTime)),
                            onPressed: () => _pickTime(isStart: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.labelEventEnd,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(_fmtDate(_endDate)),
                            onPressed: () => _pickDate(isStart: false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time, size: 18),
                            label: Text(_fmtTime(_endTime)),
                            onPressed: () => _pickTime(isStart: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.labelEventLocationOptional,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.hintEventLocation,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.labelEventDescOptional,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.hintEventDesc,
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
