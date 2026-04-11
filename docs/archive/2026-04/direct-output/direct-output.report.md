# Report: direct-output

## Executive Summary

| 관점 | 내용 |
|------|------|
| **Problem** | 모든 태그 입력 화면에서 "다음 →" 버튼 → OutputSelectorScreen → QR/NFC 선택의 2단계 흐름으로 UX 불편 |
| **Solution** | 공유 위젯 `OutputActionButtons` 1개 신규 생성, 9개 화면에서 직접 QR/NFC 버튼 배치 |
| **UX Effect** | 화면 이동 1단계 감소, 버튼 탭 즉시 원하는 출력 방식 진입 |
| **Core Value** | NFC 미지원 기기 자동 감지 및 버튼 비활성화, OutputSelectorScreen 기존 흐름 유지 |

### 1.3 Value Delivered

| 관점 | 계획 | 실제 결과 |
|------|------|-----------|
| Problem | 2단계 흐름 제거 | 9개 화면 모두 1단계로 단축 완료 |
| Solution | 공유 위젯 1개 + 9개 화면 수정 | `OutputActionButtons` 신규 + 9개 화면 수정, 코드 중복 없음 |
| UX Effect | 버튼 좌우 배치, 아이콘 강조 | Row 레이아웃, 아이콘 36px, 수직 패딩 20px 적용 |
| Core Value | NFC 가용성 자동 처리 | Riverpod provider 구독으로 NFC 상태 자동 반영 |

---

## 1. 프로젝트 개요

| 항목 | 내용 |
|------|------|
| Feature | direct-output |
| 시작일 | 2026-04-12 |
| 완료일 | 2026-04-12 |
| Match Rate | 100% |
| Iteration | 0회 |

---

## 2. 구현 내역

### 2.1 신규 파일

**`lib/shared/widgets/output_action_buttons.dart`**
- `ConsumerWidget` 기반 공유 위젯
- `nfcAvailableProvider` + `nfcWriteSupportedProvider` 구독
- QR(ElevatedButton) + NFC(OutlinedButton) 좌우 Row 배치
- 아이콘 36px, 수직 패딩 20px, border radius 16
- NFC 미지원 시 라벨 `"NFC 미지원 기기"`, `onPressed: null`

### 2.2 수정 파일 (9개)

| 파일 | 변경 내용 |
|------|-----------|
| clipboard_tag_screen.dart | `_onNext` → `_onQr`/`_onNfc` + `OutputActionButtons` |
| website_tag_screen.dart | 동일 |
| contact_manual_form.dart | 동일 |
| wifi_tag_screen.dart | 동일 |
| location_tag_screen.dart | 동일 |
| event_tag_screen.dart | 동일 (종료시간 유효성 검사 `_buildArgs()` nullable 처리) |
| email_tag_screen.dart | 동일 |
| sms_tag_screen.dart | 동일 |
| ios_input_screen.dart | 동일 (단축어 화면) |

### 2.3 picker 화면 처리

**`contact_tag_screen.dart`** — 연락처 탭 시 `/output-selector` → `/qr-result` 직접 이동

### 2.4 유지 파일

- `output_selector_screen.dart` — app-picker, history 흐름에서 여전히 사용

---

## 3. 검수 결과

| AC | 항목 | 결과 |
|----|------|------|
| AC-01 | 9개 화면 하단 QR/NFC 버튼 2개 | ✅ |
| AC-02 | QR 버튼 → `/qr-result` | ✅ |
| AC-03 | NFC 버튼 → `/nfc-writer` | ✅ |
| AC-04 | NFC 미지원 시 버튼 비활성 | ✅ |
| AC-05 | 폼 validation 선행 | ✅ |
| AC-06 | OutputSelectorScreen 유지 | ✅ |
| AC-07 | contact_tag picker → `/qr-result` | ✅ |

**Match Rate: 100% (7/7 AC 통과)**
