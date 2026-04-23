import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/tag_payload_encoder.dart';
import '../../l10n/app_localizations.dart';

class LocationTagScreen extends StatefulWidget {
  final Map<String, dynamic>? prefill;
  const LocationTagScreen({super.key, this.prefill});

  @override
  State<LocationTagScreen> createState() => _LocationTagScreenState();
}

class _LocationTagScreenState extends State<LocationTagScreen> {
  final _mapController = MapController();
  final _labelController = TextEditingController();

  LatLng? _selected;
  String? _address;      // 한국식 포맷 주소
  String? _buildingName; // 건물명 (QR 기본 문구)
  bool _isGeocoding = false;
  LatLng? _myLocation;           // GPS로 얻은 내 위치 (파란 마커)
  bool _mapReady = false;        // onMapReady 전에는 move() 금지
  LatLng? _pendingMove;          // 지도 준비 전에 위치가 오면 보관

  static const _fallbackCenter = LatLng(37.5665, 126.9780); // 서울 시청 (fallback)
  static const _myLocationZoom = 17.0; // 내 위치 확인 시 확대 줌
  static const _initialZoom = 12.0;    // 초기(fallback) 줌

  @override
  void initState() {
    super.initState();
    if (widget.prefill != null) {
      final lat = widget.prefill!['lat'] as double?;
      final lng = widget.prefill!['lng'] as double?;
      final label = widget.prefill!['label'] as String?;
      if (lat != null && lng != null) {
        _selected = LatLng(lat, lng);
        _pendingMove = _selected;
      }
      if (label != null && label.isNotEmpty) {
        _labelController.text = label;
        _buildingName = label;
      }
    }
    _moveToCurrentLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      final current = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _myLocation = current);
      if (_mapReady) {
        _mapController.move(current, _myLocationZoom);
      } else {
        // 지도가 아직 준비되지 않았으면 보관 → onMapReady에서 처리
        setState(() => _pendingMove = current);
      }
    } catch (_) {
      // 위치 획득 실패 시 기본 위치(서울 시청) 유지
    }
  }

  Future<void> _onMapTap(TapPosition _, LatLng latLng) async {
    setState(() {
      _selected = latLng;
      _address = null;
      _buildingName = null;
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
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        final formatted = _formatKoreanAddress(addr);
        final building = _extractBuildingName(addr);
        setState(() {
          _address = formatted.isNotEmpty ? formatted : null;
          _buildingName = building;
          _isGeocoding = false;
        });
      } else {
        setState(() => _isGeocoding = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  /// Nominatim address 객체 → 한국식 주소 (큰 단위 → 작은 단위)
  String _formatKoreanAddress(Map<String, dynamic> addr) {
    final parts = <String>[];

    final state = addr['state'] as String?;
    final city = addr['city'] as String? ??
        addr['town'] as String? ??
        addr['county'] as String?;
    final cityDistrict = addr['city_district'] as String?;
    final suburb = addr['suburb'] as String? ??
        addr['quarter'] as String? ??
        addr['neighbourhood'] as String?;
    final road = addr['road'] as String?;
    final houseNumber = addr['house_number'] as String?;

    if (state != null) parts.add(state);
    // city가 state와 동일하면 생략 (서울특별시 등)
    if (city != null && city != state) parts.add(city);
    if (cityDistrict != null) parts.add(cityDistrict);
    if (suburb != null) parts.add(suburb);
    if (road != null) {
      parts.add(houseNumber != null ? '$road $houseNumber' : road);
    }

    return parts.join(' ');
  }

  /// 건물명/장소명 추출 (우선순위 순)
  String? _extractBuildingName(Map<String, dynamic> addr) {
    return addr['amenity'] as String? ??
        addr['building'] as String? ??
        addr['shop'] as String? ??
        addr['office'] as String? ??
        addr['tourism'] as String? ??
        addr['leisure'] as String?;
  }

  void _zoom(double delta) {
    final current = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, current + delta);
  }

  Map<String, dynamic> _buildArgs() {
    // QR 기본 문구: 건물명 → 장소명 입력값 → '위치' 순
    final label = _labelController.text.trim().isNotEmpty
        ? _labelController.text.trim()
        : (_buildingName ?? '위치');

    return {
      'appName': label,
      'deepLink': TagPayloadEncoder.location(
        lat: _selected!.latitude,
        lng: _selected!.longitude,
        label: label,
      ),
      'platform': 'universal',
      'appIconBytes': null,
      'tagType': 'location',
    };
  }

  void _onQr() {
    if (_selected == null) {
      context.showSnack(AppLocalizations.of(context)!.msgSelectLocation);
      return;
    }
    context.push('/qr-result', extra: _buildArgs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.screenLocationTitle)),
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
                    initialCenter: _fallbackCenter,
                    initialZoom: _initialZoom,
                    onTap: _onMapTap,
                    onMapReady: () {
                      _mapReady = true;
                      if (_pendingMove != null) {
                        _mapController.move(_pendingMove!, _myLocationZoom);
                        _pendingMove = null;
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app_tag',
                    ),
                    // 내 위치 마커 (파란 원)
                    if (_myLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _myLocation!,
                            width: 36,
                            height: 36,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.blue, width: 2),
                              ),
                              child: const Icon(Icons.circle,
                                  color: Colors.blue, size: 14),
                            ),
                          ),
                        ],
                      ),
                    // 선택 위치 마커 (빨간 핀)
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
                      _ZoomButton(icon: Icons.add, onTap: () => _zoom(1)),
                      const SizedBox(height: 6),
                      _ZoomButton(icon: Icons.remove, onTap: () => _zoom(-1)),
                    ],
                  ),
                ),
                // ── 내 위치 버튼 ──────────────────────────────────────
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: _ZoomButton(
                    icon: Icons.my_location,
                    onTap: _moveToCurrentLocation,
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
                                AppLocalizations.of(context)!.screenLocationTapHint,
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13),
                              ),
                            ],
                          )
                        : _isGeocoding
                            ? Row(
                                children: [
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(AppLocalizations.of(context)!.msgSearchingAddress,
                                      style: const TextStyle(fontSize: 13)),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_buildingName != null) ...[
                                    Row(
                                      children: [
                                        Icon(Icons.business,
                                            size: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _buildingName!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.place,
                                          size: 14,
                                          color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _address ?? AppLocalizations.of(context)!.msgAddressUnavailable,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                  ),
                  const SizedBox(height: 14),
                  Text(AppLocalizations.of(context)!.labelPlaceNameOptional,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _labelController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.hintPlaceName,
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
