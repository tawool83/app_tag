import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../shared/utils/tag_payload_encoder.dart';
import '../../shared/widgets/output_action_buttons.dart';

class LocationTagScreen extends StatefulWidget {
  const LocationTagScreen({super.key});

  @override
  State<LocationTagScreen> createState() => _LocationTagScreenState();
}

class _LocationTagScreenState extends State<LocationTagScreen> {
  final _mapController = MapController();
  final _labelController = TextEditingController();

  LatLng? _selected;

  static const _initialCenter = LatLng(37.5665, 126.9780); // 서울 시청

  @override
  void dispose() {
    _mapController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition _, LatLng latLng) {
    setState(() => _selected = latLng);
  }

  Map<String, dynamic> _buildArgs() => {
        'appName': '위치',
        'deepLink': TagPayloadEncoder.location(
          lat: _selected!.latitude,
          lng: _selected!.longitude,
          label: _labelController.text.trim(),
        ),
        'platform': 'universal',
        'appIconBytes': null,
        'tagType': 'location',
      };

  void _onQr() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지도에서 위치를 선택해주세요.')),
      );
      return;
    }
    Navigator.pushNamed(context, '/qr-result', arguments: _buildArgs());
  }

  void _onNfc() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지도에서 위치를 선택해주세요.')),
      );
      return;
    }
    Navigator.pushNamed(context, '/nfc-writer', arguments: _buildArgs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('위치 태그')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: 12,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app_tag',
                ),
                if (_selected != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selected!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selected == null)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.touch_app, size: 16, color: Colors.grey),
                          SizedBox(width: 6),
                          Text(
                            '지도를 탭하여 위치를 선택하세요.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  _CoordField(
                    label: '위도',
                    value: _selected?.latitude,
                  ),
                  const SizedBox(height: 12),
                  _CoordField(
                    label: '경도',
                    value: _selected?.longitude,
                  ),
                  const SizedBox(height: 12),
                  const Text('장소명 (선택)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _labelController,
                    decoration: InputDecoration(
                      hintText: '예: 서울시청',
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
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

class _CoordField extends StatelessWidget {
  final String label;
  final double? value;

  const _CoordField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          readOnly: true,
          controller: TextEditingController(
            text: value != null ? value!.toStringAsFixed(6) : '',
          ),
          decoration: InputDecoration(
            hintText: '지도에서 선택',
            hintStyle: const TextStyle(color: Colors.grey),
            isDense: true,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }
}
