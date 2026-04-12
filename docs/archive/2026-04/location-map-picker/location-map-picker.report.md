# location-map-picker 완료 보고서

## Executive Summary

### 1.1 프로젝트 개요

| 항목 | 내용 |
|------|------|
| Feature | location-map-picker |
| 시작일 | 2026-04-12 |
| 완료일 | 2026-04-12 |
| Match Rate | 97% |
| 변경 파일 | 3개 (pubspec.yaml, pubspec.lock, location_tag_screen.dart) |
| 커밋 수 | 3개 (fdff638, 5072acb, 2c84642) |

### 1.2 작업 범위

| 단계 | 내용 |
|------|------|
| Plan | 위치 입력 UX 개선 기획 (직접 입력 → 지도 탭 선택) |
| Design | flutter_map 기반 지도 피커 UI 설계 |
| Do | 구현 + 역지오코딩 + 줌 버튼 + 한국식 주소 (사용자 요청 확장) |
| Check | Gap 분석 97% 달성 |

### 1.3 Value Delivered

| 관점 | 결과 |
|------|------|
| **Problem** | 위도·경도 직접 숫자 입력 진입 장벽 → 지도 탭 1회로 해결 |
| **Solution** | flutter_map(OSM) + Nominatim 역지오코딩 무료 구현, API 키 불필요 |
| **Function UX Effect** | 탭 → 마커 표시 + 한국식 주소 + 건물명 자동 추출 → QR 기본 문구 자동 설정 |
| **Core Value** | 비전문가도 즉시 사용 가능한 직관적 위치 입력 경험 |

---

## 2. 구현 상세

### 2.1 의존성 추가

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `flutter_map` | ^7.0.0 | OpenStreetMap 지도 위젯 |
| `latlong2` | ^0.9.0 | LatLng 좌표 타입 |
| `http` | ^1.2.0 | Nominatim API 호출 |

### 2.2 핵심 변경 사항

**제거:**
- 위도·경도 `TextFormField` 직접 입력
- `_latController`, `_lngController`
- `_validateLatitude`, `_validateLongitude`
- `_previewMap` (url_launcher 외부 지도 열기)

**추가:**
- `FlutterMap` (OSM TileLayer + MarkerLayer) — flex:3
- 지도 탭 → `_onMapTap` → `_selected` 업데이트
- `_reverseGeocode` — Nominatim API 역지오코딩 (한국어)
- `_formatKoreanAddress` — 시/도 → 구/군 → 동 → 도로명 포맷
- `_extractBuildingName` — amenity/building/shop 등 우선순위 추출
- 주소 표시 컨테이너 (건물명 강조 + 한국식 주소 + 로딩 인디케이터)
- 줌 +/- 버튼 `_ZoomButton` (지도 우하단 고정)
- QR 기본 문구 자동 설정: 장소명 입력 → 건물명 → `'위치'`

### 2.3 레이아웃 구조

```
Scaffold
└── Column
    ├── Expanded(flex:3) FlutterMap + ZoomButtons (Stack)
    ├── Expanded(flex:2) SingleChildScrollView
    │   ├── 주소 표시 컨테이너 (건물명 + 한국식 주소)
    │   └── 장소명 TextField (선택)
    └── Padding → OutputActionButtons (하단 고정)
```

---

## 3. Gap 분석 결과

- **Match Rate**: 97%
- **의도적 변경**: 좌표 필드 → 주소 표시 컨테이너 (사용자 요청)
- **추가 구현**: 역지오코딩, 한국식 주소, 건물명 추출, 줌 버튼 (모두 사용자 요청)
- **결함**: 없음

---

## 4. 커밋 이력

| 커밋 | 내용 |
|------|------|
| `fdff638` | 위치 태그 입력을 지도 탭 방식으로 변경 |
| `5072acb` | 역지오코딩(주소 변환) 및 줌 버튼 추가 |
| `2c84642` | 한국식 주소 포맷 및 QR 기본 문구에 건물명 적용 |

---

## 5. 완료 기준 체크

- [x] 지도에서 탭하면 마커가 표시됨
- [x] 탭 위치의 실제 주소(한국식)가 표시됨
- [x] 건물명이 있으면 QR 기본 문구로 자동 설정
- [x] 위치 미선택 시 QR/NFC 진행 차단 (SnackBar)
- [x] 줌 +/- 버튼 동작
- [x] `flutter analyze` 에러 없음
- [x] API 키 불필요 (OpenStreetMap + Nominatim 무료)
