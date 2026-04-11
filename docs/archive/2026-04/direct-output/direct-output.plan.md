# Plan: direct-output

## Executive Summary

| 관점 | 내용 |
|------|------|
| Problem | 모든 태그 입력 화면에서 "다음 →" 버튼 → OutputSelectorScreen 경유 → QR/NFC 선택의 2단계 흐름이 필요하여 UX 불편 |
| Solution | 각 태그 입력 화면 하단에 "QR 코드 생성" + "NFC 태그 쓰기" 버튼을 직접 배치하고 OutputSelectorScreen 경유 제거 |
| UX Effect | 입력 완료 후 즉시 원하는 출력 방식 선택 가능, 화면 이동 1단계 감소 |
| Core Value | 태그 생성 흐름 단순화, NFC 미지원 기기에서는 NFC 버튼 비활성화(기존 동작 유지) |

## 요구사항

### 기능 요구사항
- 대상 화면 8개: clipboard, website, contact_manual_form, wifi, location, event, email, sms
  - contact_tag_screen (picker): 연락처 탭 시 직접 QR/NFC로 이동
- 각 화면에서 기존 "다음 →" 단일 버튼 제거
- 하단에 두 버튼 배치:
  - `QR 코드 생성` (항상 활성)
  - `NFC 태그 쓰기` (NFC 지원 여부에 따라 활성/비활성)
- NFC 버튼 활성 조건: `nfcAvailableProvider` && `nfcWriteSupportedProvider` 모두 true
- NFC 미지원 시 버튼 비활성 + 툴팁/설명 없음 (비활성 상태로만 표시)

### 공유 위젯
- `lib/shared/widgets/output_action_buttons.dart` 생성
  - `ConsumerWidget` 기반 (Riverpod nfc provider 사용)
  - 생성자 파라미터: `appName`, `deepLink`, `platform`, `packageName`, `appIconBytes`, `tagType`
  - QR 버튼: `/qr-result`로 pushNamed
  - NFC 버튼: `/nfc-writer`로 pushNamed
  - 버튼 스타일: ElevatedButton(QR) + OutlinedButton(NFC), 가로 전체 너비, 세로 패딩 16

### 비기능 요구사항
- OutputSelectorScreen은 유지 (app-picker 흐름 등 다른 진입점에서 여전히 사용)
- ios_input_screen은 별도 흐름(앱 선택 기반)으로 변경 대상 아님

## 구현 범위

### 수정 파일 (8개)
| 파일 | 현재 버튼 | 변경 후 |
|------|-----------|---------|
| clipboard_tag_screen.dart | `다음 →` → `/output-selector` | `OutputActionButtons` 위젯 |
| website_tag_screen.dart | `다음 →` → `/output-selector` | `OutputActionButtons` 위젯 |
| contact_manual_form.dart | `다음 →` → `/output-selector` | `OutputActionButtons` 위젯 |
| wifi_tag_screen.dart | `다음 →` → `/output-selector` | `OutputActionButtons` 위젯 |
| location_tag_screen.dart | `다음 →` → `/output-selector` | `OutputActionButtons` 위젯 |
| event_tag_screen.dart | `다음 →` → `/output-selector` | `OutputActionButtons` 위젯 |
| email_tag_screen.dart | `다음 →` → `/output-selector` | `OutputActionButtons` 위젯 |
| sms_tag_screen.dart | `다음 →` → `/output-selector` | `OutputActionButtons` 위젯 |

### 신규 파일 (1개)
- `lib/shared/widgets/output_action_buttons.dart`

### contact_tag_screen 처리
- `_onContactSelected`: `/output-selector` → 직접 `/qr-result` 이동 (연락처는 QR이 주 사용)
- NFC 버튼은 contact_tag_screen에 불필요 (리스트 탭 액션이므로 별도 처리)

## 검수 기준 (AC)
1. 모든 8개 태그 입력 화면 하단에 QR/NFC 버튼 2개 표시
2. QR 버튼 탭 시 `/qr-result` 화면으로 올바른 arguments 전달
3. NFC 버튼 탭 시 `/nfc-writer` 화면으로 올바른 arguments 전달
4. NFC 미지원 기기(시뮬레이터 포함)에서 NFC 버튼 비활성화
5. OutputSelectorScreen 화면은 유지되고 기존 app-picker 흐름 정상 동작
6. 폼 validation 실패 시 버튼 탭해도 화면 이동 안 함
