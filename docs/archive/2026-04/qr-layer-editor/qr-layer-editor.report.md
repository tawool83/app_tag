# Report: QR Layer Editor

**Feature**: qr-layer-editor  
**Date**: 2026-04-14  
**Status**: Completed  
**Match Rate**: 96% (post-fix, all critical gaps resolved)

---

## Executive Summary

| 관점 | 실제 결과 |
|------|----------|
| **Problem** | QR 꾸미기가 단일 탭에 혼재하고 배경 이미지·스티커·템플릿 저장이 불가능해 창의적 QR 제작이 제한됨 |
| **Solution** | 레이어 기반 5탭 구조(전체 템플릿/배경/QR/로고/나의 템플릿) + 13종 도트 모양 + 나만의 템플릿 저장 완전 구현 |
| **Functional UX Effect** | 탭별 레이어 개념으로 직관적 QR 꾸미기 가능. 완성 스타일을 '나의 템플릿'으로 저장해 1탭 재적용 실현. 완료 버튼 제거로 화면 정돈 |
| **Core Value** | 단순 QR 출력 도구에서 개인화 브랜드 QR 제작 플랫폼으로 진화. Hive 기반 템플릿 저장 완료, Supabase 클라우드 동기화 구조 예약 완료 |

### 1.3 Value Delivered

| 관점 | 계획 | 실제 |
|------|------|------|
| **UI 구조** | 3탭 → 5탭 재편 | 5탭 완성 (전체 템플릿/배경/QR/로고/나의 템플릿) |
| **도트 모양** | 원형·사각 등 기본 | 13종 프리셋 (★●◆■▼♥♠♣☀🌑💧🔥🌏) |
| **배경화면** | 갤러리 이미지 + crop | 구현 완료 (image_picker + image_cropper) |
| **나의 템플릿** | 저장·재적용 | Hive 영구 저장 + 롱프레스 삭제 + 썸네일 완성 |

---

## 1. Plan vs 구현 대조

### 1.1 탭 구조 변경

| 계획 | 구현 | 상태 |
|------|------|------|
| 3탭 → 5탭 재편 | `TabController(length: 5)` 완성 | ✅ |
| 추천 탭 제거 | `recommended_tab.dart` 삭제 | ✅ |
| 꾸미기 탭 해체 | `customize_tab.dart` 삭제, 역할 분리 | ✅ |
| 기본 탭: 전체 템플릿(0) | index 0 설정 | ✅ |
| 완료 버튼 제거 | `_ActionButtons`에서 제거 | ✅ |

### 1.2 배경화면 탭

| 계획 | 구현 | 상태 |
|------|------|------|
| 갤러리 이미지 선택 | `image_picker` 연동 | ✅ |
| 자유 비율 crop | `image_cropper` 적용 | ✅ |
| 크기 슬라이더 | `backgroundScale` 슬라이더 | ✅ |
| 이미지 제거 버튼 | 구현 완료 | ✅ |

### 1.3 QR 탭

| 계획 | 구현 | 상태 |
|------|------|------|
| 도트 모양 선택 | 13종 `QrDotStyle` 프리셋 그리드 | ✅ (도트 둥글기 슬라이더 대체) |
| 눈(Eye) 모양 선택 | `QrEyeStyle` 4종 세그먼트 | ✅ |
| 단색 색상 선택 | 수평 스크롤 팔레트 (스크롤바 없음) | ✅ |
| 그라디언트 선택 | `kQrPresetGradients` 8종 | ✅ |
| 콰이어트 존 배경색 | UI 제거 (흰색 기본값 유지) | ✅ (범위 조정) |

### 1.4 로고(스티커) 탭

| 계획 | 구현 | 상태 |
|------|------|------|
| 아이콘 표시 토글 | Switch + SettingsService 퍼시스팅 | ✅ |
| 로고 위치(중앙/우하단) | `LogoPosition` 세그먼트 | ✅ |
| 로고 배경(없음/사각/원형) | `LogoBackground` 세그먼트 | ✅ |
| 상단 텍스트 편집 | 내용·색상·폰트·크기 완전 구현 | ✅ |
| 하단 텍스트 편집 | 상단과 동일 구조 | ✅ |
| 탭 이름 '스티커' → '로고' | 변경 완료 | ✅ |

### 1.5 나의 템플릿 탭

| 계획 | 구현 | 상태 |
|------|------|------|
| 2열 그리드 표시 | `GridView.builder` 2열 | ✅ |
| 탭 → 즉시 적용 | `applyUserTemplate()` | ✅ |
| 롱프레스 → 삭제 다이얼로그 | `InkWell.onLongPress` + `AlertDialog` | ✅ |
| 삭제 아이콘도 유지 | `Icons.delete_outline` 탭 | ✅ |
| 썸네일 표시 | `thumbnailBytes` 저장 + `Image.memory` | ✅ |
| 빈 상태 안내 | `Icons.bookmark_border` + 설명 텍스트 | ✅ |

### 1.6 데이터 모델

| 계획 | 구현 | 상태 |
|------|------|------|
| `UserQrTemplate` Hive 모델 | `@HiveType(typeId: 1)`, HiveField 0~23 | ✅ |
| `BackgroundConfig` 값 객체 | 완성 | ✅ |
| `StickerConfig` 값 객체 | 완성 | ✅ |
| `QrDotStyle` enum | 13종 + `buildDotShape()` | ✅ (계획에 없던 신규) |
| `QrGradient.toJson()` | 완성 (M-6 해결) | ✅ |
| 클라우드 대비 필드 (`remoteId`, `syncedToCloud`) | 예약 필드 포함 | ✅ |

---

## 2. 구현된 파일

### 2.1 신규 파일

| 파일 | 역할 |
|------|------|
| `lib/models/background_config.dart` | BackgroundConfig 값 객체 |
| `lib/models/sticker_config.dart` | StickerConfig, StickerText, LogoPosition, LogoBackground |
| `lib/models/user_qr_template.dart` | UserQrTemplate Hive 모델 (field 0~23) |
| `lib/models/user_qr_template.g.dart` | Hive 어댑터 (build_runner 자동생성) |
| `lib/models/qr_dot_style.dart` | QrDotStyle 13종, buildDotShape(), _CustomDotSymbol |
| `lib/repositories/user_template_repository.dart` | 나의 템플릿 CRUD (Hive) |
| `lib/features/qr_result/widgets/qr_layer_stack.dart` | 3레이어 Stack 렌더링 위젯 |
| `lib/features/qr_result/tabs/background_tab.dart` | 배경화면 탭 UI |
| `lib/features/qr_result/tabs/qr_style_tab.dart` | QR 스타일 탭 (도트 모양 그리드 + 색상 수평 스크롤) |
| `lib/features/qr_result/tabs/sticker_tab.dart` | 로고 탭 (아이콘 토글 + 텍스트 편집) |
| `lib/features/qr_result/tabs/my_templates_tab.dart` | 나의 템플릿 탭 (그리드 + 롱프레스 삭제) |

### 2.2 수정 파일

| 파일 | 주요 변경 내용 |
|------|--------------|
| `lib/features/qr_result/qr_result_provider.dart` | `QrDotStyle`, `BackgroundConfig`, `StickerConfig`, `quietZoneColor` 필드 추가; setter/applyUserTemplate 추가 |
| `lib/features/qr_result/qr_result_screen.dart` | 5탭, 완료 버튼 제거, 템플릿 저장 바텀시트, dotStyleIndex 저장 |
| `lib/features/qr_result/widgets/qr_preview_section.dart` | `buildDotShape(state.dotStyle)` 사용, QrLayerStack 통합 |
| `lib/models/qr_template.dart` | `_colorToHex()` 헬퍼, `QrGradient.toJson()` 추가 |
| `lib/models/user_qr_template.dart` | `@HiveField(23) int dotStyleIndex` 추가 |
| `lib/main.dart` | `UserTemplateRepository.init()` 등록 |
| `pubspec.yaml` | `hive`, `image_picker`, `image_cropper`, `image` 추가 |
| `android/app/src/main/AndroidManifest.xml` | `READ_MEDIA_IMAGES`, `UCropActivity` 추가 |
| `ios/Runner/Info.plist` | 사진 라이브러리 권한 설명 추가 |

### 2.3 삭제 파일

| 파일 | 이유 |
|------|------|
| `lib/features/qr_result/tabs/recommended_tab.dart` | 추천 탭 제거 |
| `lib/features/qr_result/tabs/customize_tab.dart` | 역할 분리로 해체 |

---

## 3. 기술 하이라이트

### 3.1 13종 커스텀 도트 모양

`pretty_qr_code` 패키지의 `PrettyQrShape` 추상 클래스를 확장해 `_CustomDotSymbol`을 구현:
- `PrettyQrPaintingContext.matrix` 순회 → 각 다크 모듈마다 `Path`를 `Canvas`에 직접 그림
- `module.resolveRect(context)`로 모듈 바운딩 박스 계산
- 하트·물방울·불꽃은 cubic bezier; 별·태양은 `_starPath()`; 초승달은 `PathOperation.difference`
- 기존 `PrettyQrSmoothSymbol`(square), `PrettyQrDotsSymbol`(circle) 포함 13종 제공

### 3.2 색상 팔레트 수평 스크롤 (스크롤바 없음)

```dart
ScrollConfiguration(
  behavior: _NoScrollbarBehavior(),
  child: SingleChildScrollView(scrollDirection: Axis.horizontal, ...),
)

class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(context, child, details) => child;
}
```

### 3.3 나의 템플릿 새로고침 패턴

`ConsumerStatefulWidgetState`의 제네릭 타입 문제를 우회해 `int _myTemplatesVersion` 카운터 + `ValueKey(_myTemplatesVersion)` 패턴 사용 — 저장 후 `setState(() => _myTemplatesVersion++)` 호출로 탭 위젯 재생성, `initState` 재실행.

### 3.4 QrGradient.toJson() 표준화

로컬 헬퍼 `_gradientToJson()` 제거 후 `QrGradient` 모델에 `toJson()` 메서드 추가:
```dart
Map<String, dynamic> toJson() => {
  'type': type,
  'colors': colors.map(_colorToHex).toList(),
  if (stops != null) 'stops': stops,
  'angleDegrees': angleDegrees,
};
```

---

## 4. Gap 분석 결과 및 해결

갭 분석 결과 93% Match Rate에서 3개 갭 확인 후 모두 해결:

| ID | 심각도 | 내용 | 해결 방법 |
|----|--------|------|-----------|
| I-1 | Important | 나의 템플릿 삭제 UX: 아이콘 탭만 있고 롱프레스 없음 | `InkWell.onLongPress: onDelete` 추가 |
| M-2 | Minor | `onQuietZoneColorChanged` 미사용 파라미터 잔존 | `QrStyleTab` 생성자에서 제거, `qr_result_screen.dart` 배선 제거 |
| M-6 | Minor | `QrGradient.toJson()` 없어 로컬 헬퍼 사용 | `QrGradient.toJson()` 추가, 헬퍼 제거 |

**최종 Match Rate**: 96%+

---

## 5. 주요 학습

1. **`PrettyQrShape` 확장**: 패키지 내부 API(`PrettyQrPaintingContext.matrix`, `module.resolveRect`) 사용이 핵심 — 공식 문서보다 소스 탐색이 효과적이었음
2. **Hive 스키마 변경**: 새 `@HiveField` 추가 시 `build_runner` 재실행 필수. `typeId`는 전체 앱에서 고유해야 함
3. **scrollbar 제거**: `ScrollConfiguration` + `ScrollBehavior` 오버라이드가 가장 깔끔한 방법 (`Scrollbar(thumbVisibility: false)` 대비)
4. **ConsumerStatefulWidget 새로고침**: state key 패턴(`ValueKey(counter++)`)이 직접 메서드 호출보다 안정적

---

## 6. 다음 단계 (선택)

| 항목 | 우선순위 |
|------|--------|
| Supabase 클라우드 동기화 (`UserQrTemplate.remoteId`) | 유료 플랜 연동 시 |
| QR 도트 모양 애니메이션 전환 | 선택적 UX 개선 |
| 나의 템플릿 이름 편집 | 추가 편의 기능 |
| 배경 이미지 압축 최적화 (JPEG 80%, max 800px) | 저장 용량 절감 |
