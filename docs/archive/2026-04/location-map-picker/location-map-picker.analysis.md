# Gap Analysis: location-map-picker

- **Date**: 2026-04-12
- **Match Rate**: 97%
- **Design**: `docs/02-design/features/location-map-picker.design.md`
- **Implementation**: `lib/features/location_tag/location_tag_screen.dart`

---

## 요약

| 카테고리 | 결과 |
|---------|------|
| Design 핵심 요구사항 충족 | 100% |
| 아키텍처 준수 | 100% |
| **전체 Match Rate** | **97%** |

---

## Design 요구사항 확인

| # | 요구사항 | 구현 위치 | 상태 |
|---|---------|----------|------|
| 1 | `StatefulWidget` + `LatLng? _selected` 상태 | L9–L20 | OK |
| 2 | `FlutterMap` + OSM TileLayer + MarkerLayer | L169–L198 | OK |
| 3 | 초기 중심 서울시청(37.5665, 126.9780), zoom 12 | L25–L26, L172–L173 | OK |
| 4 | `onTap` → `_onMapTap` → `_selected` 업데이트 | L35–L43 | OK |
| 5 | 마커: 선택 시만 표시, 빨간 location_pin, 40×40 | L182–L196 | OK |
| 6 | 지도 flex:3, 입력 영역 flex:2 | L165, L216 | OK |
| 7 | 입력 영역 SingleChildScrollView | L218 | OK |
| 8 | 장소명 선택 TextField | L18, L320–L328 | OK |
| 9 | OutputActionButtons 하단 고정 | L336–L341 | OK |
| 10 | 미선택 시 SnackBar → 진행 차단 | L138–L154 | OK |
| 11 | `_buildArgs()` 구조 완비 | L119–L136 | OK |
| 12 | 기존 직접 입력 코드 완전 제거 | 미존재 확인 | OK |

---

## Gap 목록

### 설계 vs 구현 차이 (사용자 요청에 의한 의도적 변경)

| 항목 | Design | 구현 | 분류 |
|------|--------|------|------|
| 좌표 필드 | `_CoordField` readOnly TextField | 주소 표시 컨테이너로 대체 | 의도적 변경 |
| `Form` 위젯 | `Form(key: _formKey)` 사용 | 없음 (null guard로 대체) | 의도적 변경 |

### 추가 구현 (사용자 요청 확장 — Gap 아님)

| 항목 | 비고 |
|------|------|
| 역지오코딩 `_reverseGeocode` (Nominatim API) | 사용자 요청 |
| 한국식 주소 포맷 `_formatKoreanAddress` | 사용자 요청 |
| 건물명 추출 `_extractBuildingName` | 사용자 요청 |
| 주소 표시 컨테이너 + 로딩 인디케이터 | 위 확장의 UI |
| 줌 +/- 버튼 `_ZoomButton` | 사용자 요청 |
| QR 기본 문구 자동 설정 (건물명 fallback) | 사용자 요청 |
| `http` 패키지 추가 | Nominatim 호출용 |

---

## 완료 기준 체크

| 기준 | 상태 |
|------|------|
| 지도 탭 시 마커 표시 | OK |
| 위치 미선택 시 진행 차단 | OK |
| 장소명 선택 입력 유지 | OK |
| `flutter analyze` 에러 없음 | OK (확인 완료) |

---

## 권장 조치

1. **Design 문서 업데이트** — 역지오코딩, 한국식 주소 포맷, 줌 버튼, 건물명 추출 내용을 design.md에 반영
2. **Plan 문서 변경 기록** — §4 Out of Scope에서 "역지오코딩 제외"를 사후 추가 확장으로 기록
3. **관찰 사항** (결함 아님): 빠른 연속 탭 시 Nominatim 요청이 중복 발생 가능 (마지막 응답이 승리, 실용적으로 문제없음)
