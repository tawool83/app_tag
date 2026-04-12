# Plan: QR 템플릿 시스템 (qr-template-system) — v1.0

## Executive Summary

| 관점 | 내용 |
|------|------|
| **Problem** | QR 스타일을 개별 설정(도트/눈 모양, 색상)으로만 커스터마이징할 수 있어 시각적으로 풍부한 QR 코드를 만들기 어렵고, 앱 업데이트 없이 새 스타일을 제공할 방법이 없다. |
| **Solution** | 관리자가 CDN에 JSON 형식으로 업로드하는 "QR 스타일 템플릿" 시스템. 앱은 원격 JSON을 로컬 캐시와 병합하여 템플릿 갤러리를 표시하고, 사용자는 1탭으로 적용한다. |
| **Function/UX Effect** | QR 결과 화면에 카테고리별 템플릿 갤러리 추가(소셜/비즈니스/계절 등). 선택 즉시 미리보기에 반영. 관리자는 JSON 파일 교체로 신규 템플릿 배포. |
| **Core Value** | 앱 스토어 심사 없이 콘텐츠(템플릿)를 실시간 갱신 가능한 OTA(Over-The-Air) 템플릿 구조. 그라디언트/로고 내장 QR로 브랜드 아이덴티티 표현 가능. |

---

## 버전 범위

| 버전 | 내용 | 상태 |
|------|------|------|
| **v1.0 (현재)** | CDN 정적 JSON + 앱 내 템플릿 갤러리 UI | ✅ 개발 대상 |
| v2.0 | Supabase 마이그레이션 + 관리자 웹 UI | 예정 |
| v2.0+ | 홈 메뉴 항목도 원격 JSON으로 제공 (OTA 메뉴) | 예정 |
| v3.0 | 유료 템플릿, 사용자 커스텀 템플릿 공유 | 예정 |

> **v1.0 핵심 원칙**: 신규 패키지 추가 없이 기존 스택(`http`, `hive_flutter`, `qr_flutter`)만으로 구현. Supabase/Firebase 없이 동작.

---

## 1. 배경 및 목표

### 문제 정의
- 현재 QR 커스터마이징: 도트 모양(사각/원형), 눈 모양(사각/원형), 단색 팔레트 10종, 이모지 중앙 아이콘
- 한계: 그라디언트 없음, 브랜드 로고 없음, 앱 배포 없이 새 스타일 추가 불가

### 목표
1. **원격 템플릿 제공**: 관리자가 JSON 파일 교체만으로 새 템플릿 즉시 제공
2. **풍부한 스타일**: 그라디언트 색상, 브랜드 로고(외부 URL 이미지), 도트/눈 모양 조합
3. **카테고리 분류**: 소셜(인스타그램, 페이스북, X 등), 비즈니스, 계절, 미니멀 등

---

## 2. 템플릿 데이터 스키마

### 2.1 핵심 설계 원칙
- **순수 JSON**: 렌더링에 필요한 모든 정보를 JSON으로 표현
- **qr_flutter 호환**: `QrEyeShape`, `QrDataModuleShape` 등 기존 필드 재사용
- **그라디언트 확장**: `QrPainter` + `CustomPainter`로 그라디언트 직접 렌더링
- **하위 호환**: 미지원 필드는 무시(앱 구버전도 동작)

### 2.2 JSON 스키마

```json
{
  "version": 1,
  "updatedAt": "2026-04-12T00:00:00Z",
  "categories": [
    {
      "id": "social",
      "name": "소셜",
      "order": 1
    }
  ],
  "templates": [
    {
      "id": "instagram",
      "version": 1,
      "name": "Instagram",
      "categoryId": "social",
      "order": 1,
      "thumbnailUrl": "https://cdn.example.com/qr-templates/logos/instagram_thumb.png",
      "isPremium": false,
      "style": {
        "dataModuleShape": "circle",
        "eyeShape": "circle",
        "backgroundColor": "#FFFFFF",
        "foreground": {
          "type": "gradient",
          "solidColor": null,
          "gradient": {
            "type": "linear",
            "colors": ["#F58529", "#DD2A7B", "#8134AF", "#515BD4"],
            "stops": [0.0, 0.33, 0.66, 1.0],
            "angleDegrees": 45
          }
        },
        "eyeColor": {
          "type": "solid",
          "solidColor": "#8134AF"
        },
        "centerIcon": {
          "type": "url",
          "url": "https://cdn.example.com/qr-templates/logos/instagram.png",
          "sizeRatio": 0.20
        },
        "frame": {
          "enabled": false
        }
      }
    },
    {
      "id": "facebook",
      "name": "Facebook",
      "categoryId": "social",
      "order": 2,
      "thumbnailUrl": "https://cdn.example.com/qr-templates/logos/facebook_thumb.png",
      "isPremium": false,
      "style": {
        "dataModuleShape": "square",
        "eyeShape": "square",
        "backgroundColor": "#FFFFFF",
        "foreground": {
          "type": "solid",
          "solidColor": "#1877F2"
        },
        "eyeColor": { "type": "solid", "solidColor": "#1877F2" },
        "centerIcon": {
          "type": "url",
          "url": "https://cdn.example.com/qr-templates/logos/facebook.png",
          "sizeRatio": 0.20
        },
        "frame": { "enabled": false }
      }
    },
    {
      "id": "minimal_black",
      "name": "미니멀 블랙",
      "categoryId": "minimal",
      "order": 1,
      "thumbnailUrl": null,
      "isPremium": false,
      "style": {
        "dataModuleShape": "circle",
        "eyeShape": "square",
        "backgroundColor": "#FFFFFF",
        "foreground": { "type": "solid", "solidColor": "#000000" },
        "eyeColor": { "type": "solid", "solidColor": "#000000" },
        "centerIcon": { "type": "none" },
        "frame": { "enabled": false }
      }
    }
  ]
}
```

### 2.3 스타일 필드 정의

| 필드 | 타입 | 설명 |
|------|------|------|
| `dataModuleShape` | `"square"` \| `"circle"` | QR 데이터 도트 모양 |
| `eyeShape` | `"square"` \| `"circle"` | QR 눈(코너 패턴) 모양 |
| `backgroundColor` | hex string | QR 배경색 |
| `foreground.type` | `"solid"` \| `"gradient"` | 전경 색상 방식 |
| `foreground.solidColor` | hex string | 단색일 때 색상 |
| `foreground.gradient.type` | `"linear"` \| `"radial"` \| `"sweep"` | 그라디언트 종류 |
| `foreground.gradient.colors` | `[hex, ...]` | 그라디언트 색상 스톱 |
| `foreground.gradient.angleDegrees` | number | linear 방향 (0=우측, 90=하단) |
| `eyeColor.type` | `"solid"` \| `"gradient"` \| `"inherit"` | 눈 색상 (inherit=foreground 따름) |
| `centerIcon.type` | `"url"` \| `"emoji"` \| `"none"` | 중앙 아이콘 종류 |
| `centerIcon.url` | URL string | 외부 이미지 URL (PNG 권장) |
| `centerIcon.sizeRatio` | 0.10~0.30 | QR 크기 대비 아이콘 비율 |
| `frame.enabled` | bool | 외부 프레임 여부 |

---

## 3. 기술 아키텍처

### 3.1 원격 배포 방식: CDN 정적 JSON

```
[관리자] JSON 파일 편집 + 이미지 업로드
        ↓
[CDN / 정적 호스트]  (GitHub Pages / Cloudflare Pages / Vercel)
        ↓  HTTP GET (TTL 1h)
[앱: TemplateService]  로컬 Hive 캐시 (TTL 만료 전 캐시 반환)
        ↓
[QrResultScreen: 템플릿 갤러리 UI]
```

**CDN URL 구조** (v2+ 확장을 고려한 네임스페이스 설계)
```
https://your-cdn.com/app-config/
  v1/
    qr-templates.json       ← QR 스타일 템플릿 목록 (v1.0 대상)
    menu.json               ← 홈 메뉴 항목 (v2.0+ 예정)
  logos/
    instagram.png
    facebook.png
    ...
```

- `app-config/v1/` 네임스페이스: 향후 `menu.json`, `banners.json` 등 확장 가능
- v2에서 Supabase로 이전 시 URL만 교체하면 클라이언트 코드 변경 최소화
- **v1.0에서는 `qr-templates.json`만 구현**

**선택 이유**: Firebase/Supabase 없이 동작. `http` 패키지로 충분. 향후 Supabase로 마이그레이션 용이.

### 3.2 그라디언트 렌더링: CustomPainter + QrPainter

`qr_flutter 4.x`의 `QrPainter`는 `CustomPainter`로 직접 사용 가능.

```dart
// 그라디언트 QR 렌더링 원리
class GradientQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. saveLayer로 격리 레이어 생성
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    
    // 2. QrPainter로 흑백 QR 도트 렌더링
    final qrPainter = QrPainter(data: deepLink, version: QrVersions.auto, ...);
    qrPainter.paint(canvas, size);
    
    // 3. 그라디언트를 srcIn 블렌드로 덮어씀 (도트 모양 유지, 색상만 교체)
    final gradient = LinearGradient(colors: [...]);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..blendMode = BlendMode.srcIn,
    );
    
    canvas.restore();
  }
}
```

### 3.3 로컬 캐싱: Hive

```dart
// 새 Hive Box: 'qr_templates'
// 캐시 구조:
{
  'templates_data': List<QrTemplate>,
  'fetched_at': DateTime (ISO 8601),
  'cache_version': int
}
```

---

## 4. 기능 요구사항

### FR-1: 템플릿 원격 로딩
- [ ] `TemplateService.fetchTemplates()`: CDN URL에서 JSON 로드 (TTL 1시간)
- [ ] TTL 내: Hive 캐시 반환
- [ ] TTL 만료: HTTP GET → 파싱 → 캐시 갱신
- [ ] 오프라인: 캐시 반환 (캐시 없으면 빌트인 기본 템플릿 사용)
- [ ] `templates.json` 구조 버전 필드(`"version": 1`) 관리

### FR-2: 템플릿 데이터 모델
- [ ] `QrTemplate` Dart 클래스 (fromJson/toJson)
- [ ] `QrStyleData` (foreground, eyeColor, centerIcon, frame 포함)
- [ ] `QrGradient` (type, colors, stops, angleDegrees)
- [ ] `QrCenterIconData` (type, url, emoji, sizeRatio)

### FR-3: 그라디언트 QR 렌더링
- [ ] `GradientQrPainter extends CustomPainter` 구현
- [ ] 단색: 기존 `QrImageView` 위젯 사용 (변경 없음)
- [ ] 그라디언트: `CustomPaint(painter: GradientQrPainter(...))` 사용
- [ ] 눈 색상 별도 지정 지원 (`eyeColor.type = "solid"`)
- [ ] `RepaintBoundary` 캡처 호환 (저장/공유/인쇄 동작)

### FR-4: 중앙 아이콘 (URL 이미지)
- [ ] `centerIcon.type = "url"`: HTTP 이미지 로드 → `MemoryImage` 변환
- [ ] `cached_network_image` 또는 직접 http 로드 후 Hive 캐시
- [ ] 로드 실패 시: 아이콘 없이 QR 표시

### FR-5: 템플릿 갤러리 UI
- [ ] QR 결과 화면 커스터마이징 패널에 "템플릿" 섹션 추가
- [ ] 카테고리 탭 (가로 스크롤)
- [ ] 템플릿 썸네일 그리드 (또는 가로 스크롤 리스트)
- [ ] 선택 시 즉시 QR 미리보기에 반영
- [ ] 선택한 템플릿 ID를 SharedPreferences에 저장 (재진입 시 복원)

### FR-6: 빌트인 기본 템플릿
- [ ] 오프라인/첫 실행 대비 앱 번들에 기본 템플릿 JSON 내장 (`assets/default_templates.json`)
- [ ] 최소 10개: 미니멀(3), 소셜(4), 비즈니스(3)

---

## 5. 비기능 요구사항

| 항목 | 요구사항 |
|------|---------|
| **캐시 TTL** | 1시간 (설정 가능) |
| **이미지 로드 타임아웃** | 5초 (초과 시 아이콘 없이 표시) |
| **템플릿 최대 수** | 제한 없음 (100개 이상 가능) |
| **오프라인 동작** | 캐시 or 빌트인 템플릿으로 완전 동작 |
| **그라디언트 렌더 성능** | 240px QR 기준 60fps 유지 |

---

## 6. 관리자 워크플로우

### v1.0: 정적 파일 방식 (GitHub Pages / Cloudflare Pages)

```
1. qr-templates.json 파일 편집 (새 템플릿 객체 추가)
2. 로고/썸네일 이미지를 logos/ 폴더에 업로드 (PNG, 512x512 권장)
3. git push → CDN 자동 배포
4. 앱이 다음 TTL 만료 시(1시간) 자동으로 새 템플릿 반영
```

### v2.0 예정: Supabase + 웹 관리자 UI
- Supabase Storage로 이미지 관리
- Supabase Table로 템플릿 메타데이터 관리
- 전용 웹 관리자 페이지에서 GUI로 템플릿 추가/수정/삭제

### v2.0+ 예정: 홈 메뉴 OTA
- `menu.json`으로 홈 화면 메뉴 항목(타이틀, 아이콘, 라우트, 순서) 원격 제어
- 앱 업데이트 없이 메뉴 추가/숨김/재배치 가능

---

## 7. 구현 순서

1. `QrTemplate` / `QrStyleData` 데이터 모델 클래스 작성
2. `TemplateService`: HTTP 로드 + Hive 캐시 + TTL 관리
3. `GradientQrPainter`: CustomPainter 그라디언트 렌더링
4. `assets/default_templates.json` 빌트인 템플릿 10개 작성
5. QR 결과 화면에 템플릿 갤러리 UI 추가
6. 템플릿 선택 → QrResultState에 반영 → 렌더러 자동 전환
7. CDN URL 설정값 추가 (`SettingsService` 또는 `app_config.dart`)

---

## 8. 의존성 추가

| 패키지 | 용도 | 필요 여부 |
|--------|------|----------|
| `cached_network_image` | 중앙 아이콘 URL 이미지 캐싱 | 선택 (http로 대체 가능) |
| `qr_flutter` 기존 | `QrPainter` 직접 사용 | 기존 패키지 활용 |
| `hive_flutter` 기존 | 템플릿 캐시 | 기존 패키지 활용 |
| `http` 기존 | JSON 로드 | 기존 패키지 활용 |

→ **신규 패키지 불필요** (기존 스택으로 구현 가능)

---

## 9. v1.0 범위 외 (다음 버전)

| 기능 | 버전 | 비고 |
|------|------|------|
| Supabase 마이그레이션 | v2.0 | 현재: CDN 정적 JSON |
| 관리자 웹 UI | v2.0 | 현재: JSON 파일 직접 편집 |
| 홈 메뉴 원격 JSON (`menu.json`) | v2.0+ | URL 구조는 v1에서 미리 설계 |
| 유료 템플릿 결제 연동 | v3.0 | `isPremium` 필드는 JSON에 포함하되 v1에선 무시 |
| 사용자 커스텀 템플릿 저장/공유 | v3.0 | |
| 애니메이션 QR (동적 도트) | v3.0 | |
