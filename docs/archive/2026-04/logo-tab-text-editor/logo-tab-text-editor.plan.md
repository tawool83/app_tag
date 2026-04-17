# Plan: 로고 탭 텍스트 에디터 개편

## Executive Summary

| 관점 | 내용 |
|------|------|
| **Problem** | 로고 탭 텍스트 편집 UI가 추천 색상 팔레트만 제공해 자유로운 색상 선택이 불가능하고, 폰트 크기 상한(24sp)이 낮아 제목용 대형 텍스트를 만들기 어려우며, 레이아웃이 길어 UX가 복잡하다. 또한 QR 하단에 이미 표시되는 앱 이름 라벨이 스티커 레이어와 별개로 관리돼 스타일을 변경할 수 없다. |
| **Solution** | 색상을 HSV 컬러 휠 피커로 교체하고 폰트 크기 상한을 64sp으로 확장한다. 레이아웃을 라벨+입력란 / 색상·폰트·사이즈 2줄로 압축하고, 하단 텍스트는 기존 `customLabel`(앱 이름/태그 타입)을 `StickerText` 기반으로 통합해 스타일 편집을 지원한다. |
| **Functional UX Effect** | 사용자는 1개의 통합된 텍스트 에디터 인터페이스에서 QR 하단 라벨을 색상·폰트·크기까지 바꿀 수 있고, 상단 텍스트도 자유 색상으로 꾸밀 수 있다. 탭 내 스크롤 길이가 절반 이하로 감소한다. |
| **Core Value** | 텍스트 스티커를 브랜딩 도구로 격상. '앱 이름' 라벨이 단순 정보 표시에서 커스터마이징 가능한 디자인 요소로 진화. |

---

## 1. 현황 및 문제점

### 1.1 현재 상단/하단 텍스트 편집 UI 문제

| 항목 | 현재 | 문제 |
|------|------|------|
| 색상 선택 | WCAG 추천 10색 팔레트 | 자유 색상 불가, 흰색 등 많은 색 선택 불가 |
| 폰트 크기 | 슬라이더 10~24sp | 배너·제목용 대형 텍스트 불가 |
| 레이아웃 | 입력란 + 색상 행 + 폰트 행 + 크기 슬라이더 (4행) | 스크롤 길고 복잡 |
| 하단 텍스트 | 별도 자유 입력 | 이미 있는 앱 이름 라벨과 중복·분리 |

### 1.2 현재 하단 라벨 구조

```
QrPreviewSection
└── Column
    ├── QrLayerStack (size × size)
    │   └── sticker.bottomText (StickerText?) — 스티커 레이어
    └── Text(label)  ←── customLabel ?? appName  ← 별도 표시
```

- `customLabel`(`String?`)은 `QrResultState`에서 독립 관리
- 스티커 `bottomText`와 `customLabel`이 이중 표시될 수 있음
- `customLabel`에 색상·폰트·크기 지정 불가

---

## 2. 목표

1. **색상 피커**: HSV 컬러 휠 (`flutter_colorpicker`) — 모든 색상 자유 선택
2. **폰트 크기 확장**: 10~64sp
3. **레이아웃 압축**: 라벨+입력란 한 행 + 색상·폰트·사이즈 한 행
4. **하단 텍스트 통합**: `customLabel`을 `StickerText` 기반으로 교체, QR 하단 라벨이 스타일 편집 가능한 텍스트 스티커가 됨

---

## 3. 기능 요구사항

### 3.1 상단 텍스트 레이아웃 변경

**변경 전** (4행):
```
[텍스트 입력창 full-width]
색상: ● ● ● ● ● ● ● ● ●  ← 추천 팔레트 Wrap
폰트: [Sans] [Serif] [Mono]
크기: [────●──────] 14sp
```

**변경 후** (2행):
```
상단 텍스트: [입력란──────────────────────] ✕
[🎨] [Sans▾] [14sp ▲▼]
```

- Row 1: 라벨 "상단 텍스트 :" + `TextField` (flex 확장) + clear 버튼
- Row 2: 색상 버튼(탭 → 컬러 휠 다이얼로그) + 폰트 드롭다운 + 사이즈 스텝퍼

### 3.2 색상 피커 (HSV 컬러 휠)

- `flutter_colorpicker` 패키지 사용
- 현재 색상 아이콘 탭 → `showDialog` + `ColorPicker(pickerColor, onColorChanged)` 위젯
- 다이얼로그: 확인/취소 버튼
- 색상 아이콘: 현재 선택 색 원형 표시 (24px)

```dart
// 사용 예
showDialog(
  builder: (_) => AlertDialog(
    title: const Text('색상 선택'),
    content: ColorPicker(
      pickerColor: currentColor,
      onColorChanged: (c) => tempColor = c,
    ),
    actions: [확인, 취소],
  ),
);
```

### 3.3 폰트 선택 (드롭다운)

- `DropdownButton<String>` 사용 (기존 세그먼트 버튼 대체)
- 옵션: Sans / Serif / Mono (platform-generic 폰트명)
- 컴팩트 표시: 현재 폰트명 + 화살표 아이콘

### 3.4 폰트 크기 스텝퍼

- `-` / 현재값 표시 / `+` 버튼 조합
- 범위: 10~64sp, 1sp 단위
- 직접 탭하면 편집 가능한 숫자 입력 (선택 사항)

```
[−]  24sp  [+]
```

### 3.5 하단 텍스트 통합

#### 변경 사항

| 항목 | 변경 전 | 변경 후 |
|------|---------|---------|
| `customLabel` | `String?` in `QrResultState` | 제거 |
| 하단 표시 | `Text(customLabel ?? appName)` in `QrPreviewSection` | `sticker.bottomText` (StickerText) in `QrLayerStack` |
| 기본값 | 없음(null) | 진입 시 앱 이름/태그 타입명으로 자동 pre-fill |
| 스타일 편집 | 불가 | 색상·폰트·크기 동일 컨트롤 제공 |

#### 기본값 pre-fill 시점

`QrResultScreen` 진입 시 (`initState` 또는 첫 렌더):
```dart
// sticker.bottomText가 null이면 앱 이름으로 초기화
if (state.sticker.bottomText == null) {
  ref.read(qrResultProvider.notifier).setSticker(
    state.sticker.copyWith(
      bottomText: StickerText(content: widget.appName),
    ),
  );
}
```

#### UI 레이아웃 (상단 텍스트와 동일 구조)

```
하단 텍스트: [앱 이름──────────────────────] ✕
[🎨] [Sans▾] [14sp ▲▼]
```

---

## 4. 레이아웃 와이어프레임

```
┌──────────────────────────────────────────────────┐
│ 아이콘 표시  [────────────────────────] Switch    │
│                                                   │
│ 로고 위치   [중앙]  [우하단]                      │
│ 로고 배경   [없음]  [사각]  [원형]                │
│                                                   │
│ ─────────────────────────────────────────────     │
│                                                   │
│ 상단 텍스트 : [────────────────────────] ✕       │
│ [● 색상]  [Sans    ▾]  [−] 14sp [+]             │
│                                                   │
│ ─────────────────────────────────────────────     │
│                                                   │
│ 하단 텍스트 : [앱 이름────────────────] ✕        │
│ [● 색상]  [Sans    ▾]  [−] 14sp [+]             │
│                                                   │
└──────────────────────────────────────────────────┘
```

---

## 5. 데이터 모델 변경

### 5.1 `QrResultState`

```dart
// 제거
final String? customLabel;
final String? printTitle;

// 유지 (하단 텍스트는 sticker.bottomText로 통합)
final StickerConfig sticker; // bottomText 포함
```

### 5.2 `StickerText.fontSize` 범위

```dart
// 변경 전
Slider(min: 10, max: 24)

// 변경 후
_FontSizeStepper(min: 10, max: 64, step: 1)
```

### 5.3 `QrPreviewSection` 하단 라벨 제거

```dart
// 제거
if (label.isNotEmpty) Text(label, ...)
```

---

## 6. 의존성 추가

| 패키지 | 용도 | 버전 |
|--------|------|------|
| `flutter_colorpicker` | HSV 컬러 휠 다이얼로그 | ^1.1.0 |

---

## 7. 변경 파일 목록

| 파일 | 변경 내용 |
|------|-----------|
| `lib/features/qr_result/tabs/sticker_tab.dart` | TextEditor 2줄 레이아웃, HSV 피커, 폰트 드롭다운, 크기 스텝퍼 |
| `lib/features/qr_result/qr_result_provider.dart` | `customLabel` 제거, `printTitle` 정리 |
| `lib/features/qr_result/qr_result_screen.dart` | bottomText 초기값 pre-fill, label 파라미터 정리 |
| `lib/features/qr_result/widgets/qr_preview_section.dart` | 하단 `Text(label)` 제거 |
| `pubspec.yaml` | `flutter_colorpicker` 추가 |

---

## 8. 범위 제외 (Out of Scope)

| 항목 | 이유 |
|------|------|
| 텍스트 그림자·아웃라인 효과 | 별도 피처로 분리 |
| 구글 폰트 다운로드 | 번들 크기 이슈, 플랫폼 제네릭 폰트로 충분 |
| 프리셋 하단 문구 목록 | 단일 기본값 방식 채택 |

---

## 9. 성공 기준

| 기준 | 측정 방법 |
|------|-----------|
| HSV 컬러 휠에서 임의 색상 선택 후 텍스트에 반영 | 시각 확인 |
| 폰트 크기 64sp 정상 렌더링 | QR 미리보기 확인 |
| QR 진입 시 하단 텍스트에 앱 이름 자동 입력 | 앱 선택 → QR 결과 화면 진입 확인 |
| `customLabel` 제거 후 기존 기능 회귀 없음 | QR 저장·공유 동작 확인 |
