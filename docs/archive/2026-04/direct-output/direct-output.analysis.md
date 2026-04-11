# Analysis: direct-output

## Gap Analysis Result

**Match Rate: 100%**  
**Date**: 2026-04-12  
**Phase**: Check

---

## AC Verification

| # | Acceptance Criteria | Status | Evidence |
|---|---------------------|--------|----------|
| AC-01 | 9개 입력 화면 하단 QR/NFC 버튼 배치 | ✅ PASS | clipboard, website, contact_manual, wifi, location, event, email, sms, ios_input 모두 `OutputActionButtons` 적용 확인 |
| AC-02 | QR 버튼 탭 → `/qr-result` 이동 | ✅ PASS | 전 화면 `_onQr()` → `Navigator.pushNamed('/qr-result', ...)` |
| AC-03 | NFC 버튼 탭 → `/nfc-writer` 이동 | ✅ PASS | 전 화면 `_onNfc()` → `Navigator.pushNamed('/nfc-writer', ...)` |
| AC-04 | NFC 미지원 시 버튼 비활성 | ✅ PASS | `nfcAvailableProvider` + `nfcWriteSupportedProvider` 구독, `onPressed: nfcEnabled ? onNfcPressed : null` |
| AC-05 | 폼 빈 칸 탭 시 유효성 오류, 이동 없음 | ✅ PASS | `_formKey.currentState!.validate()` 선행 확인 |
| AC-06 | OutputSelectorScreen 유지 (app-picker 흐름) | ✅ PASS | `app_picker_screen.dart:84`, `history_screen.dart:115` 여전히 `/output-selector` 사용 |
| AC-07 | contact_tag_screen 연락처 탭 → `/qr-result` | ✅ PASS | `contact_tag_screen.dart:78` `/qr-result` 직접 이동 확인 |

## Gap List

없음. 설계 대비 완전 구현.

## Implementation Summary

- **신규 파일**: `lib/shared/widgets/output_action_buttons.dart` (ConsumerWidget)
- **수정 파일**: 9개 화면 (`_onNext` 제거 → `_onQr` + `_onNfc` + `OutputActionButtons`)
- **NFC 라벨**: 미지원 시 `"NFC 미지원 기기"` 한 줄 표시
- **버튼 UI**: Row 좌우 배치, 아이콘 36px, 세로 패딩 20px
