# location-map-picker Design

> Plan 참조: `docs/01-plan/features/location-map-picker.plan.md`

---

## 1. 아키텍처 개요

### 변경 범위
단일 파일 재작성 + `pubspec.yaml` 의존성 추가.

```
pubspec.yaml
└── flutter_map: ^7.0.0
└── latlong2: ^0.9.0

lib/features/location_tag/
└── location_tag_screen.dart   ← 전면 재작성
```

### 상태 관리
- `StatefulWidget` 유지 (Riverpod 불필요 — 로컬 상태만 존재)
- 핵심 상태: `LatLng? _selected` — null이면 미선택, non-null이면 선택 완료

---

## 2. 화면 레이아웃

```
┌─────────────────────────────────────┐
│ AppBar: "위치 태그"                   │
├─────────────────────────────────────┤
│                                     │
│   FlutterMap (Expanded flex: 3)     │
│   - TileLayer (OpenStreetMap)       │
│   - MarkerLayer (선택 시 핀 표시)    │
│   - onTap → _selected 업데이트      │
│                                     │
├─────────────────────────────────────┤
│  Padding(24)                        │
│  ┌─────────────────────────────┐    │
│  │ 위도  [readOnly TextField]  │    │
│  │ 경도  [readOnly TextField]  │    │
│  │ 장소명 [TextField (선택)]   │    │
│  └─────────────────────────────┘    │
├─────────────────────────────────────┤
│  Padding: OutputActionButtons       │  ← 하단 고정
└─────────────────────────────────────┘
```

**비율**: 지도(flex 3) : 입력 영역(flex 2) — 화면 높이에 따라 자연스럽게 분할

---

## 3. 위젯 구조

```dart
Scaffold
└── body: Column
    ├── Expanded(flex: 3)
    │   └── FlutterMap(
    │         mapController: _mapController,
    │         options: MapOptions(
    │           initialCenter: LatLng(37.5665, 126.9780),  // 서울 시청
    │           initialZoom: 12,
    │           onTap: (tapPos, latLng) => _onMapTap(latLng),
    │         ),
    │         children: [
    │           TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
    │           MarkerLayer(markers: _selected == null ? [] : [_buildMarker()]),
    │         ],
    │       )
    ├── Expanded(flex: 2)
    │   └── SingleChildScrollView
    │       └── Form(key: _formKey)
    │           └── Column
    │               ├── _CoordField(label: '위도', value: _selected?.latitude)
    │               ├── _CoordField(label: '경도', value: _selected?.longitude)
    │               └── TextField(controller: _labelController, label: '장소명 (선택)')
    └── Padding
        └── OutputActionButtons(onQrPressed: _onQr, onNfcPressed: _onNfc)
```

---

## 4. 핵심 로직

### 4.1 지도 탭 처리
```dart
void _onMapTap(LatLng latLng) {
  setState(() => _selected = latLng);
}
```

### 4.2 마커 생성
```dart
Marker _buildMarker() => Marker(
  point: _selected!,
  width: 40,
  height: 40,
  child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
);
```

### 4.3 좌표 표시 필드 (`_CoordField`)
- `readOnly: true`
- `controller`에 `_selected` 변경 시 `text` 업데이트 (소수점 6자리)
- `_selected == null`이면 빈 문자열

### 4.4 유효성 검사
```dart
// _onQr / _onNfc 공통
void _onQr() {
  if (_selected == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('지도에서 위치를 선택해주세요.')),
    );
    return;
  }
  Navigator.pushNamed(context, '/qr-result', arguments: _buildArgs());
}
```

### 4.5 `_buildArgs()`
```dart
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
```

---

## 5. 의존성

### pubspec.yaml 추가
```yaml
dependencies:
  flutter_map: ^7.0.0
  latlong2: ^0.9.0
```

### iOS — `Info.plist` 추가 불필요
- `flutter_map`은 네트워크 타일만 사용, 위치 권한 불필요

### Android — 추가 설정 불필요
- 인터넷 권한은 기본적으로 허용됨

---

## 6. 제거 항목

기존 `LocationTagScreen`에서 제거:
- `_latController`, `_lngController` (TextEditingController)
- `_validateLatitude()`, `_validateLongitude()` 메서드
- `_previewMap()` 메서드 (지도 자체가 미리보기 역할)
- `url_launcher` import (지도 탭으로 대체)

---

## 7. 완료 기준

- [ ] `flutter_map` TileLayer가 지도를 표시함
- [ ] 지도 탭 시 마커가 표시되고 위도·경도 필드가 업데이트됨
- [ ] 위치 미선택 시 SnackBar 표시 후 진행 차단
- [ ] 장소명 선택 입력 유지
- [ ] `flutter analyze` 에러 없음
