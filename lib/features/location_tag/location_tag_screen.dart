import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/utils/tag_payload_encoder.dart';

class LocationTagScreen extends StatefulWidget {
  const LocationTagScreen({super.key});

  @override
  State<LocationTagScreen> createState() => _LocationTagScreenState();
}

class _LocationTagScreenState extends State<LocationTagScreen> {
  final _formKey = GlobalKey<FormState>();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _labelController = TextEditingController();

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;
    final lat = double.parse(_latController.text.trim());
    final lng = double.parse(_lngController.text.trim());
    Navigator.pushNamed(
      context,
      '/output-selector',
      arguments: {
        'appName': '위치',
        'deepLink': TagPayloadEncoder.location(
          lat: lat,
          lng: lng,
          label: _labelController.text.trim(),
        ),
        'platform': 'universal',
        'outputType': 'qr',
        'appIconBytes': null,
        'tagType': 'location',
      },
    );
  }

  Future<void> _previewMap() async {
    if (_latController.text.isEmpty || _lngController.text.isEmpty) return;
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null) return;
    final uri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  String? _validateLatitude(String? v) {
    if (v == null || v.trim().isEmpty) return '위도를 입력해주세요.';
    final d = double.tryParse(v.trim());
    if (d == null) return '숫자를 입력해주세요.';
    if (d < -90 || d > 90) return '-90 ~ 90 범위로 입력해주세요.';
    return null;
  }

  String? _validateLongitude(String? v) {
    if (v == null || v.trim().isEmpty) return '경도를 입력해주세요.';
    final d = double.tryParse(v.trim());
    if (d == null) return '숫자를 입력해주세요.';
    if (d < -180 || d > 180) return '-180 ~ 180 범위로 입력해주세요.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('위치 태그')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('위도 *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _latController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: InputDecoration(
                  hintText: '37.566535',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: _validateLatitude,
              ),
              const SizedBox(height: 16),
              const Text('경도 *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lngController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: InputDecoration(
                  hintText: '126.977969',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: _validateLongitude,
              ),
              const SizedBox(height: 16),
              const Text('장소명 (선택)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _labelController,
                decoration: InputDecoration(
                  hintText: '예: 서울시청',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _previewMap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('지도에서 미리보기'),
              ),
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
