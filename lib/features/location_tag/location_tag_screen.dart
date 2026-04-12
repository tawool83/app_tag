import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
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
  String? _address;
  bool _isGeocoding = false;

  static const _initialCenter = LatLng(37.5665, 126.9780); // 서울 시청
  static const _initialZoom = 12.0;

  @override
  void dispose() {
    _mapController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _onMapTap(TapPosition _, LatLng latLng) async {
    setState(() {
      _selected = latLng;
      _address = null;
      _isGeocoding = true;
    });
    await _reverseGeocode(latLng);
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json'
        '&lat=${latLng.latitude}'
        '&lon=${latLng.longitude}'
        '&accept-language=ko',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'AppTag/1.0'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final displayName = data['display_name'] as String?;
        setState(() {
          _address = displayName;
          _isGeocoding = false;
        });
      } else {
        setState(() => _isGeocoding = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  void _zoom(double delta) {
    final current = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, current + delta);
  }

  Map<String, dynamic> _buildArgs() => {
        'appName': '위치',
        'deepLink': TagPayloadEncoder.location(
          lat: _selected!.latitude,
          lng: _selected!.longitude,
          label: _labelController.text.trim().isNotEmpty
              ? _labelController.text.trim()
              : (_address ?? ''),
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
          // ── 지도 영역 ──────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialCenter,
                    initialZoom: _initialZoom,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                // ── 줌 버튼 ─────────────────────────────────────────
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Column(
                    children: [
                      _ZoomButton(
                        icon: Icons.add,
                        onTap: () => _zoom(1),
                      ),
                      const SizedBox(height: 6),
                      _ZoomButton(
                        icon: Icons.remove,
                        onTap: () => _zoom(-1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 주소/장소명 입력 영역 ──────────────────────────────────
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 선택된 주소 표시
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _selected == null
                          ? Colors.grey.shade100
                          : Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _selected == null
                        ? Row(
                            children: [
                              const Icon(Icons.touch_app,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                '지도를 탭하여 위치를 선택하세요.',
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13),
                              ),
                            ],
                          )
                        : _isGeocoding
                            ? const Row(
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text('주소 검색 중...',
                                      style: TextStyle(fontSize: 13)),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.place,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _address ?? '주소를 가져올 수 없습니다.',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                  ),
                  const SizedBox(height: 14),
                  const Text('장소명 (선택)',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
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

          // ── QR/NFC 버튼 ───────────────────────────────────────────
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

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}
