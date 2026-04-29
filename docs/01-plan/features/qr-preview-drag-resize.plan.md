# Plan — QR 미리보기 드래그 확대/축소

> 생성일: 2026-04-29
> Feature ID: `qr-preview-drag-resize`
> 트리거: 미리보기 탭 → 팝업 UX 가 편집 흐름 끊김. 인라인 확대로 개선.

---

## Executive Summary

| Perspective | Summary |
|-------------|---------|
| **Problem** | QR 미리보기 탭 시 팝업(`showDialog`) 으로 확대 → 편집 중 컨텍스트 단절, 조작 흐름 끊김. 팝업·다이얼로그 코드 ~100줄 부담. |
| **Solution** | 미리보기 영역에 수직 드래그 제스처 추가. 아래로 쓸면 미리보기 확대 + 탭 영역 압축, 위로 쓸면 축소. 손 떼면 가까운 스냅 상태 (compact 184px / expanded 화면 70%) 로 부드럽게 전환. |
| **Function UX Effect** | 팝업 사라짐 → 컨텍스트 유지하며 큰 미리보기 확인. 편집 모드에서도 확대 가능. 작은 drag handle 로 발견성 확보. |
| **Core Value** | 편집·미리보기 동시 확인 가능한 매끄러운 UX. 기존 ~100줄 팝업 코드 제거로 간결화. |

---

## 1. 현재 동작

### 1.1 레이아웃 (qr_result_screen.dart)
```
Scaffold body Column:
├── Padding(QrPreviewSection)         ← 184px 고정
├── TabBar (편집기 모드 시 숨김)
└── Expanded(TabBarView)               ← 남은 공간
```

### 1.2 확대 메커니즘 (qr_preview_section.dart)
- `GestureDetector(onTap: _showQrZoomDialog)` — fullQr 모드일 때만 활성
- `_showQrZoomDialog` 가 별도 dialog 띄움 (~100줄)
- 편집 중 (dedicated mode) 에는 탭 비활성

---

## 2. 변경 사항

### 2.1 제스처 동작
- **수직 드래그 down**: 미리보기 높이 증가, 탭 영역 압축
- **수직 드래그 up**: 미리보기 높이 감소, 탭 영역 확장
- **드래그 종료 시 스냅**: 두 상태 (compact/expanded) 중 가까운 쪽으로 애니메이션 (300ms easeOut)
- **드래그 중 손가락 추적**: 1:1 비례로 즉시 반영 (스무스 피드백)

### 2.2 두 스냅 상태
| 상태 | 미리보기 높이 |
|------|---------------|
| `compact` | 184 px (현재 값 그대로) |
| `expanded` | `MediaQuery.height × 0.7` |

### 2.3 단일 탭 무시 (Q3=b)
드래그만 동작. 단일 탭은 no-op.

### 2.4 Drag handle UI
미리보기 박스 하단 가장자리 안쪽에 16×4px 회색 알약형 핸들 표시 — 드래그 가능 시각 단서.

### 2.5 편집기 모드 (Q4=a) 동작
편집 활성 (`_isEditorActive=true`) 에서도 드래그 동작. dedicated preview 가 expanded 영역에 비례 확대됨.

### 2.6 레거시 정리 (Q6=a)
`_showQrZoomDialog` 함수 + 하위 헬퍼 + `centerImageProvider` 의존성 정리. 다른 곳에서 사용 여부 확인 후 제거.

---

## 3. Architecture (CLAUDE.md 고정)

### 3.1 상태 위치
- 미리보기 확장 비율 (`_previewExtra: double`, 0~1) → **`_QrResultScreenState`** 에서 관리
  - 이미 StatefulWidget. 제스처 콜백·AnimationController 통합 자연스러움
  - Riverpod provider 까지 분리할 가치 없음 (UI 로컬 상태)
  - R-series Notifier 신규 없음 — CLAUDE.md "Claude 가독성 우선" 부합

### 3.2 신규 컴포넌트
- `_QrPreviewDragHandle` — 작은 알약 핸들 위젯 (qr_result_screen 또는 qr_preview_section 내부 private 클래스)
- AnimationController 1개 (`_previewSnapController`) — 손 뗀 후 스냅 애니메이션

### 3.3 상호작용 흐름
```
qr_result_screen
├── _previewExtra (0.0 ~ 1.0)
├── _previewSnapController (snap-to-state animation)
├── computePreviewHeight(maxH) = lerp(184, maxH * 0.7, _previewExtra)
└── QrPreviewSection(extraHeight: computedHeight - 184)
    └── GestureDetector(onVerticalDragUpdate, onVerticalDragEnd)
        └── 콜백으로 _previewExtra 업데이트
```

---

## 4. 변경 파일 (예상 2~3개)

| 파일 | 변경 |
|------|------|
| `lib/features/qr_result/qr_result_screen.dart` | (a) `_previewExtra` state + AnimationController (b) `LayoutBuilder` 로 가용 높이 산출 (c) Column 의 미리보기 SizedBox 높이를 `computePreviewHeight()` 로 (d) 드래그 콜백 핸들러: `_onPreviewDragUpdate`, `_onPreviewDragEnd` |
| `lib/features/qr_result/widgets/qr_preview_section.dart` | (a) `extraHeight` / `onDragUpdate` / `onDragEnd` 인자 추가 (b) 단일 탭용 GestureDetector → `onVerticalDragUpdate`/`onVerticalDragEnd` 로 교체 (c) `_showQrZoomDialog` + 헬퍼 코드 제거 (~100줄) (d) 드래그 핸들 위젯 |
| `lib/features/qr_result/qr_result_screen/icon_renderer.dart` (확인) | 변경 없음 (참조용) |

총 **수정 2개 파일**, 신규 0개. 예상 ~120줄 추가/수정 + ~100줄 제거 = 순증 ~20줄.

---

## 5. 세부 결정 (자동 확정)

| 항목 | 결정 | 근거 |
|------|------|------|
| Compact 높이 | **184 px** | 현재 값 그대로 (회귀 0) |
| Expanded 높이 | **`screenHeight × 0.7`** | 탭바 살짝 보여서 컨텍스트 유지 |
| 스냅 애니메이션 | **`Duration(milliseconds: 300)`, `Curves.easeOut`** | 표준 modal sheet 와 일관 |
| 스냅 임계값 | **0.5** (pixel ratio) — 손가락 절반 이상 끌면 expand 쪽으로 | 직관적 |
| 플링(빠른 드래그) | velocity 절대값 > 500 → 방향 따라 강제 스냅 | 표준 BottomSheet 동작 |
| 드래그 핸들 색 | `Colors.grey.shade400` 알약 16×4 | 미리보기와 시각 분리 |
| 드래그 핸들 위치 | 미리보기 하단 안쪽 4px | 영역 침범 최소 |
| Tap 동작 | 무시 (no-op) | Q3=b |
| 편집 모드 동작 | 드래그 가능 | Q4=a |
| 가로 회전 | scope 제외 (세로 모드 전제) | YAGNI |

---

## 6. 구현 순서 (Do phase 참조용)

### Step 1 — 상태/컨트롤러 골격
1. `_QrResultScreenState` 에 필드 추가:
   - `double _previewExtra = 0.0` (0=compact, 1=expanded)
   - `late final AnimationController _previewSnapController` (300ms)
2. dispose 에서 정리

### Step 2 — 레이아웃 적용
3. body 의 `Column` 을 `LayoutBuilder` 로 감싸 `maxHeight` 획득
4. 미리보기 Padding 의 `child` 를 `SizedBox(height: computed)` 로 감싸기
5. `computePreviewHeight(maxH) = lerp(184, maxH * 0.7, _previewExtra.clamp(0,1))`

### Step 3 — 제스처 콜백
6. `_onPreviewDragUpdate(dy)`: `_previewExtra += dy / dragRange` clamp(0~1)
7. `_onPreviewDragEnd(velocity)`: 임계값/velocity 로 target(0 또는 1) 결정 → `_previewSnapController` 로 애니메이션
8. AnimationController.addListener — 매 tick 마다 `_previewExtra` 업데이트 + `setState`

### Step 4 — `QrPreviewSection` 수정
9. `extraHeight`, `onVerticalDragUpdate`, `onVerticalDragEnd` 인자 추가
10. 기존 `onTap` GestureDetector 제거
11. 새 `GestureDetector(onVerticalDragUpdate, onVerticalDragEnd)` 추가
12. SizedBox height 를 `184 + extraHeight` 또는 부모에서 control
13. drag handle 위젯 추가 (Stack 하단)

### Step 5 — 레거시 제거
14. `_showQrZoomDialog` 와 하위 closure 모두 삭제
15. 사용 안 하는 import 정리

### Step 6 — 검증
16. `flutter analyze` → 0 issue
17. 수동 검증: drag 부드러움, 스냅 동작, 편집 모드 호환

---

## 7. 검증 플랜

### 컴파일
- [ ] `flutter analyze` 변경 파일 issue 0
- [ ] `_showQrZoomDialog` 제거 후 unused import 없음

### UX 검증 (수동)
- [ ] compact 상태에서 아래로 드래그 → 미리보기 부드럽게 커짐
- [ ] 손 떼는 위치 50% 이상 → expanded 로 스냅
- [ ] 50% 미만 → compact 로 복귀
- [ ] 빠른 down-flick (velocity > 500) → 무조건 expand
- [ ] 빠른 up-flick → 무조건 compact
- [ ] expanded 상태에서 위로 드래그 → 작아짐 → 스냅
- [ ] 단일 탭 → 동작 없음 (no popup)
- [ ] 편집 모드 (도트 슬라이더 드래그 중) → 드래그 호출 안 됨 (제스처 영역 침범 없음 확인)
- [ ] 편집 모드 비활성 → 미리보기 드래그 정상
- [ ] 탭 컨텐츠 (TabBarView) 가로 스와이프 → 수직 드래그와 충돌 없음

### 회귀
- [ ] 미리보기 dedicated mode (도트/눈/외곽 슬라이드 시) 정상 동작
- [ ] QR repaint key 캡처 (저장/공유) 정상 동작
- [ ] 다크모드/라이트모드 핸들 가시성

---

## 8. 위험·전제

### 위험
1. **제스처 충돌**: TabBarView 의 가로 스와이프와 미리보기 수직 드래그가 같은 layout 에 공존. `onVerticalDragUpdate` 만 사용하면 Flutter 가 수직만 캡처하므로 충돌 적음. 다만 미리보기 영역에서만 활성화 (정확한 hitTest 영역).
2. **편집기 모드 미리보기 (`dedicatedDot/Eye/Boundary`)**: 슬라이더 드래그 중에는 슬라이더가 제스처 우선 — 편집 영역과 미리보기 영역이 분리되어 있으므로 충돌 없음 확인.
3. **AnimationController dispose 누락 시 메모리 리크**: dispose() 에서 명시적 처리.
4. **너무 작은 화면**: `screenHeight * 0.7` 이 184 보다 작을 가능성 (드물지만 매우 작은 폰). clamp 처리 필요.
5. **회전(가로모드)**: scope out. 세로 전제로 설계.

### 전제
- `MediaQuery.of(context).size.height` 안정적
- 편집기 모드에서 미리보기 영역이 동일하게 visible (현재 그렇다)
- 사용자가 드래그를 직관적으로 발견 가능 (Q5 핸들 표시로 보완)

---

## 9. Out-of-Scope

- 가로 모드 (landscape) 별도 레이아웃
- 미리보기 확대 비율을 사용자 설정으로 저장
- pinch-to-zoom (두 손가락 핀치)
- 미리보기 영역 외 swipe down 제스처 (Scaffold 전체에 영향)

---

## 10. Next Steps

1. 사용자 승인 → `/pdca design qr-preview-drag-resize` (필요 시 생략, 작은 작업)
2. 또는 바로 `/pdca do qr-preview-drag-resize`
