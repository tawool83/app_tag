# Gap Analysis — main-screen-redesign

> 분석일: 2026-04-23
> Design: `docs/02-design/features/main-screen-redesign.design.md`
> Match Rate: **97%**

---

## Overall Scores

| Category | Score | Status |
|----------|:-----:|:------:|
| Design Match | 95% | OK |
| Architecture Compliance | 100% | OK |
| Convention Compliance | 98% | OK |
| **Overall** | **97%** | OK |

---

## Implementation Order Status

Design 문서에서 15~18번이 "미착수"로 표기되어 있으나, 실제로는 **모두 완료됨**:

| # | Item | Design 표기 | 실제 | 근거 |
|:-:|------|:---:|:---:|------|
| 15 | UserQrTemplate 삭제 | 미착수 | DONE | `user_qr_template.dart` 등 관련 파일 모두 삭제됨 |
| 16 | Hive box 삭제 | 미착수 | DONE | `hive_config.dart:23` — `Hive.deleteBoxFromDisk('user_qr_templates')` |
| 17 | output_selector + router | 미착수 | DONE | `output_selector_screen.dart` 삭제, router에 route 없음 |
| 18 | default_templates.json 축소 | 미착수 | DONE | 3개 템플릿(minimal_black, minimal_red, social_instagram) 확인 |

**실제 완료: 18/18 (100%)**

---

## 12개 핵심 요구사항 검증

| # | 요구사항 | 결과 | 상세 |
|:-:|---------|:----:|------|
| 1 | QrTask entity v2 (name, thumbnailBytes, showOnHome, schema v2) | PASS | `currentSchemaVersion = 2`, fallback 정상 |
| 2 | Home: CTA row + GridView + listHomeVisibleUseCaseProvider | PASS | ElevatedButton.icon 64px, GridView.builder 정상 |
| 3 | 삭제 모드: trash + multi-select + hideFromHomeUseCase | PASS | `_enterDeleteMode`, `_selectAll`, `_confirmDeleteSelected` 정상 |
| 4 | 액션시트: 220px + Transform.scale(1.15) + 5 actions | PASS | maxSide=220, thumbScale=1.15, 5개 ListTile |
| 5 | _editAgain: await push + onChanged() | PASS | pop → await push → onChanged() |
| 6 | _rename: 다이얼로그 먼저, pop 나중 | PASS | showRenameDialog → Navigator.pop |
| 7 | flushPendingPush() + _confirmAndPop 호출 | PASS | provider에 메서드 존재, screen에서 호출 |
| 8 | AppBar: arrow_back + "저장" TextButton | PASS | 편집기 모드 시 숨김 정상 |
| 9 | PopScope(canPop: false) | PASS | 모든 뒤로가기 인터셉트 |
| 10 | Repository: 3개 메서드 추가 | PASS | interface + impl 모두 존재 |
| 11 | 5 UseCase + 5 Provider | PASS | `qr_task_providers.dart:61-80` 등록 |
| 12 | 바텀시트: useSafeArea + isScrollControlled + heightFactor 0.8 | PASS | `home_screen.dart:63-69` |

---

## 발견된 차이

### 경미한 UI 차이 (Design != Implementation)

| 항목 | Design | 구현 | 영향 |
|------|--------|------|------|
| 갤러리 타일 폰트 크기 | fontSize: 11 | fontSize: 12 | Low |
| 갤러리 타일 테두리 (비선택) | 0.5px | 1px | Low |
| 갤러리 타일 간격 | h: 4 | height: 6 | Low |

### 파일 크기

| 파일 | 실제 | 제한 | 상태 |
|------|-----:|:----:|:----:|
| `home_screen.dart` | 433 | 400 | WARN |
| `create_picker_sheet.dart` | 163 | 400 | OK |
| `qr_task_action_sheet.dart` | 177 | 400 | OK |
| `qr_task_gallery_card.dart` | 95 | 400 | OK |
| `rename_dialog.dart` | 37 | 150 | OK |
| `qr_task.dart` | 112 | 200 | OK |

---

## 권장 조치

### 즉시 (Priority)
1. **Design 문서 업데이트**: 15~18번 "미착수" → "완료"로 갱신
2. **home_screen.dart 분할**: 433줄 → `_LegalLinkTile` + `_buildDrawer`/`_showAppInfoDialog` 를 `widgets/home_drawer.dart`로 추출

### 선택 (Optional)
3. 갤러리 타일 미세 조정 (fontSize/border/gap) — 구현 중 의도적 조정일 수 있음
4. 액션시트의 영구 삭제 vs 홈 숨기기 구분을 Design에 명시

---

_Match Rate >= 90% 기준 충족. `/pdca report main-screen-redesign` 실행 가능._
