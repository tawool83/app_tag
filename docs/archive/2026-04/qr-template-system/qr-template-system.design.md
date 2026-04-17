# Design: QR 템플릿 시스템 (qr-template-system) — v1.0

> Plan 참조: `docs/01-plan/features/qr-template-system.plan.md`

---

## 1. 파일 구조

```
lib/
├── models/
│   └── qr_template.dart          # QrTemplate, QrStyleData, QrGradient 등 데이터 모델
├── services/
│   ├── template_service.dart     # HTTP 로드 + Hive 캐시 + TTL + 버전 필터링
│   └── settings_service.dart     # (기존) activeTemplateId 저장 메서드 추가
├── features/
│   └── qr_result/
│       ├── qr_result_provider.dart  # (기존) activeTemplateId, templateGradient 필드 추가
│       ├── qr_result_screen.dart    # (기존) 렌더러 분기 + _TemplateGallery 위젯 추가
│       └── gradient_qr_painter.dart # 신규: GradientQrPainter (CustomPainter)
└── shared/
    └── constants/
        └── app_config.dart          # 신규: CDN URL, 엔진 버전 상수

assets/
└── default_templates.json           # 신규: 오프라인/첫 실행용 빌트인 템플릿 10개
```

**pubspec.yaml 변경 없음** — 신규 패키지 불필요.  
assets 섹션에 `- assets/default_templates.json` 추가 필요.

---

## 2. 상수 (`app_config.dart`)

```dart
// lib/shared/constants/app_config.dart

/// CDN 기본 URL. v2에서 Supabase로 교체 시 이 값만 변경.
const String kTemplateCdnBaseUrl = 'https://your-cdn.com/app-config/v1';

/// qr-templates.json 전체 URL
const String kQrTemplatesUrl = '$kTemplateCdnBaseUrl/qr-templates.json';

/// 현재 앱이 렌더링 가능한 최대 템플릿 엔진 버전.
/// 새 스타일 기능 추가(v2) 시 앱 업데이트와 함께 값을 올린다.
const int kTemplateEngineVersion = 1;

/// 로컬 캐시 유효 시간
const Duration kTemplateCacheTtl = Duration(hours: 1);
```

---

## 3. 데이터 모델 (`qr_template.dart`)

### 3.1 클래스 계층

```
QrTemplateManifest
  ├── schemaVersion: int
  ├── updatedAt: DateTime
  ├── categories: List<QrTemplateCategory>
  └── templates: List<QrTemplate>

QrTemplateCategory
  ├── id: String
  ├── name: String
  └── order: int

QrTemplate
  ├── id: String
  ├── minEngineVersion: int
  ├── name: String
  ├── categoryId: String
  ├── order: int
  ├── thumbnailUrl: String?
  ├── isPremium: bool
  └── style: QrStyleData

QrStyleData
  ├── dataModuleShape: QrDataModuleShape
  ├── eyeShape: QrEyeShape
  ├── backgroundColor: Color
  ├── foreground: QrForeground
  ├── eyeColor: QrForeground?   (null = foreground 상속)
  └── centerIcon: QrCenterIconData

QrForeground
  ├── type: 'solid' | 'gradient'
  ├── solidColor: Color?
  └── gradient: QrGradient?

QrGradient
  ├── type: 'linear' | 'radial' | 'sweep'
  ├── colors: List<Color>
  ├── stops: List<double>?
  └── angleDegrees: double      (linear 전용)

QrCenterIconData
  ├── type: 'url' | 'emoji' | 'none'
  ├── url: String?
  ├── emoji: String?
  └── sizeRatio: double         (기본 0.20)
```

### 3.2 주요 파싱 로직

```dart
// lib/models/qr_template.dart

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrTemplateManifest {
  final int schemaVersion;
  final List<QrTemplateCategory> categories;
  final List<QrTemplate> templates;

  const QrTemplateManifest({
    required this.schemaVersion,
    required this.categories,
    required this.templates,
  });

  factory QrTemplateManifest.fromJson(Map<String, dynamic> json) =>
      QrTemplateManifest(
        schemaVersion: json['schemaVersion'] as int? ?? 1,
        categories: (json['categories'] as List<dynamic>? ?? [])
            .map((e) => QrTemplateCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
        templates: (json['templates'] as List<dynamic>? ?? [])
            .map((e) => QrTemplate.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class QrTemplate {
  final String id;
  final int minEngineVersion;
  final String name;
  final String categoryId;
  final int order;
  final String? thumbnailUrl;
  final bool isPremium;
  final QrStyleData style;

  const QrTemplate({...});

  factory QrTemplate.fromJson(Map<String, dynamic> json) => QrTemplate(
    id: json['id'] as String,
    minEngineVersion: json['minEngineVersion'] as int? ?? 1,
    name: json['name'] as String,
    categoryId: json['categoryId'] as String,
    order: json['order'] as int? ?? 0,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    isPremium: json['isPremium'] as bool? ?? false,
    style: QrStyleData.fromJson(json['style'] as Map<String, dynamic>),
  );
}

// hex string → Color 파싱 헬퍼
Color _hexToColor(String hex) {
  final clean = hex.replaceFirst('#', '');
  return Color(int.parse(clean.length == 6 ? 'FF$clean' : clean, radix: 16));
}
```

---

## 4. 서비스 (`template_service.dart`)

### 4.1 인터페이스

```dart
// lib/services/template_service.dart

class TemplateService {
  // Hive Box 이름
  static const String _boxName = 'qr_templates_cache';
  static const String _keyData = 'data';     // JSON raw string
  static const String _keyFetchedAt = 'fetched_at';  // ISO 8601

  /// 지원 가능한 템플릿 목록 반환 (버전 필터 적용, 카테고리별 정렬)
  static Future<QrTemplateManifest> getTemplates() async { ... }

  /// 강제 갱신 (TTL 무시)
  static Future<QrTemplateManifest> refreshTemplates() async { ... }

  /// 단일 URL 이미지를 bytes로 로드 (5초 타임아웃)
  static Future<Uint8List?> loadImageBytes(String url) async { ... }
}
```

### 4.2 캐시 흐름

```
getTemplates()
  ├── [캐시 유효] Hive 캐시 반환 (fetchedAt + TTL > now)
  │     └── 버전 필터: templates.where(t => t.minEngineVersion <= kTemplateEngineVersion)
  │
  ├── [캐시 만료 or 없음] HTTP GET kQrTemplatesUrl
  │     ├── 성공: 파싱 → 캐시 저장 → 버전 필터 → 반환
  │     └── 실패(네트워크): 캐시 반환 (만료 무시) or 빌트인 폴백
  │
  └── [schemaVersion 불일치] 빌트인 default_templates.json 로드
```

### 4.3 버전 필터링

```dart
List<QrTemplate> _filterByEngineVersion(List<QrTemplate> all) =>
    all.where((t) => t.minEngineVersion <= kTemplateEngineVersion).toList();
```

### 4.4 이미지 로드 (URL 아이콘)

```dart
static Future<Uint8List?> loadImageBytes(String url) async {
  try {
    final response = await http.get(Uri.parse(url))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) return response.bodyBytes;
  } catch (_) {}
  return null;
}
```

---

## 5. 그라디언트 렌더러 (`gradient_qr_painter.dart`)

### 5.1 클래스 설계

```dart
// lib/features/qr_result/gradient_qr_painter.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/qr_template.dart';

class GradientQrPainter extends CustomPainter {
  final String data;
  final QrEyeShape eyeShape;
  final QrDataModuleShape dataModuleShape;
  final QrGradient gradient;
  final int errorCorrectionLevel;

  const GradientQrPainter({
    required this.data,
    required this.eyeShape,
    required this.dataModuleShape,
    required this.gradient,
    this.errorCorrectionLevel = QrErrorCorrectLevel.M,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. 격리 레이어 (blendMode.srcIn 적용 범위 제한)
    canvas.saveLayer(rect, Paint());

    // 2. QrPainter로 흑백 QR 렌더링
    QrPainter(
      data: data,
      version: QrVersions.auto,
      eyeStyle: QrEyeStyle(eyeShape: eyeShape, color: Colors.black),
      dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: dataModuleShape, color: Colors.black),
      errorCorrectionLevel: errorCorrectionLevel,
    ).paint(canvas, size);

    // 3. 그라디언트 셰이더를 srcIn 블렌드로 적용
    canvas.drawRect(
      rect,
      Paint()
        ..shader = _createShader(rect)
        ..blendMode = BlendMode.srcIn,
    );

    canvas.restore();
  }

  Shader _createShader(Rect rect) {
    switch (gradient.type) {
      case 'radial':
        return RadialGradient(
          colors: gradient.colors,
          stops: gradient.stops,
        ).createShader(rect);
      case 'sweep':
        return SweepGradient(
          colors: gradient.colors,
          stops: gradient.stops,
        ).createShader(rect);
      case 'linear':
      default:
        final angle = gradient.angleDegrees * pi / 180;
        final dx = cos(angle);
        final dy = sin(angle);
        return LinearGradient(
          begin: Alignment(-dx, -dy),
          end: Alignment(dx, dy),
          colors: gradient.colors,
          stops: gradient.stops,
        ).createShader(rect);
    }
  }

  @override
  bool shouldRepaint(GradientQrPainter old) =>
      data != old.data ||
      eyeShape != old.eyeShape ||
      dataModuleShape != old.dataModuleShape ||
      gradient != old.gradient;
}
```

### 5.2 v1 제약

| 기능 | v1 지원 여부 |
|------|:-----------:|
| Linear gradient | ✅ |
| Radial gradient | ✅ |
| Sweep gradient | ✅ |
| 눈(eye) 별도 색상 (그라디언트 시) | ❌ (v2) |
| 배경 그라디언트 | ❌ (v2) |

---

## 6. 상태 관리 변경 (`qr_result_provider.dart`)

### 6.1 `QrResultState` 신규 필드

```dart
// 기존 필드 유지 + 아래 추가
final String? activeTemplateId;      // 선택된 템플릿 ID (UI 하이라이트용)
final QrGradient? templateGradient;  // null = 단색, non-null = GradientQrPainter 사용
final Uint8List? templateCenterIconBytes; // URL 아이콘 로드 결과
```

### 6.2 신규 notifier 메서드

```dart
/// 템플릿 적용: 스타일 필드 일괄 갱신
void applyTemplate(QrTemplate template, {Uint8List? centerIconBytes}) {
  final style = template.style;
  state = state.copyWith(
    activeTemplateId: template.id,
    eyeShape: style.eyeShape,
    dataModuleShape: style.dataModuleShape,
    qrColor: style.foreground.solidColor ?? const Color(0xFF000000),
    templateGradient: style.foreground.gradient,
    embedIcon: style.centerIcon.type != 'none',
    templateCenterIconBytes: centerIconBytes,
    // 이모지/기본 아이콘 초기화
    centerEmoji: null,
    emojiIconBytes: null,
  );
}

/// 템플릿 해제 (커스텀 설정으로 복귀)
void clearTemplate() {
  state = state.copyWith(
    activeTemplateId: null,
    templateGradient: null,
    templateCenterIconBytes: null,
  );
}
```

### 6.3 렌더러 분기 결정 (qr_result_screen.dart)

```dart
// build() 내에서:
final hasGradient = state.templateGradient != null;

Widget qrWidget;
if (hasGradient) {
  qrWidget = CustomPaint(
    size: const Size(240, 240),
    painter: GradientQrPainter(
      data: deepLink,
      eyeShape: state.eyeShape,
      dataModuleShape: state.dataModuleShape,
      gradient: state.templateGradient!,
      errorCorrectionLevel: centerImage != null
          ? QrErrorCorrectLevel.H
          : QrErrorCorrectLevel.M,
    ),
  );
} else {
  qrWidget = QrImageView(
    data: deepLink,
    size: 240,
    eyeStyle: QrEyeStyle(eyeShape: state.eyeShape, color: state.qrColor),
    dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: state.dataModuleShape, color: state.qrColor),
    errorCorrectionLevel: centerImage != null
        ? QrErrorCorrectLevel.H
        : QrErrorCorrectLevel.M,
  );
}

// Stack에 qrWidget 배치 (center icon overlay는 기존과 동일)
Stack(alignment: Alignment.center, children: [
  qrWidget,
  if (centerImage != null) ... // 기존 clear zone + icon overlay
])
```

---

## 7. 중앙 아이콘 우선순위

템플릿 적용 후 중앙 아이콘 결정 순서:

```
1. templateCenterIconBytes (URL 로드 성공) → MemoryImage
2. emojiIconBytes (이모지 선택) → MemoryImage  
3. defaultIconBytes (태그 타입 Material 아이콘) → MemoryImage
4. embedIcon == false → 아이콘 없음
```

`_centerImageProvider()` 함수를 아래와 같이 수정:

```dart
ImageProvider? _centerImageProvider(QrResultState state) {
  if (!state.embedIcon) return null;
  if (state.templateCenterIconBytes != null)
    return MemoryImage(state.templateCenterIconBytes!);
  if (state.emojiIconBytes != null)
    return MemoryImage(state.emojiIconBytes!);
  if (state.defaultIconBytes != null)
    return MemoryImage(state.defaultIconBytes!);
  return null;
}
```

---

## 8. UI 설계 (`_TemplateGallery` 위젯)

### 8.1 배치: `_CustomizePanel` 내 최상단 섹션

```
_CustomizePanel (expanded)
  ├── [템플릿] ← 신규 (최상단)
  │     ├── 카테고리 탭 (가로 스크롤 Chip)
  │     └── 템플릿 가로 스크롤 리스트
  │           └── _TemplateTile (썸네일 or 미니 QR 프리뷰)
  ├── [인쇄 상단 문구]
  ├── [QR 하단 문구]
  ├── [QR 색상]       ← 템플릿 선택 시 숨김 처리 고려
  ├── [인쇄 크기]
  ├── [데이터 도트 모양]
  ├── [눈(코너) 모양]
  └── [중앙 아이콘]
```

### 8.2 `_TemplateGallery` 위젯 스펙

```dart
class _TemplateGallery extends StatefulWidget {
  final List<QrTemplateCategory> categories;
  final List<QrTemplate> templates;
  final String? activeTemplateId;
  final ValueChanged<QrTemplate> onTemplateSelected;
  final VoidCallback onTemplateClear;   // "없음(커스텀)" 선택
}
```

**카테고리 탭** (FilterChip 가로 스크롤):
- 첫 번째 항목: "전체" (모든 카테고리)
- 선택된 카테고리의 템플릿만 아래에 표시

**템플릿 타일** (80×80px):
- `thumbnailUrl` 있으면 Image.network (로딩 중: 회색 placeholder)
- `thumbnailUrl` 없으면 배경색 + 템플릿 이름 텍스트
- 선택 시: 파란 border + 체크 오버레이

**"없음" 타일** (항상 첫 번째):
- 아이콘: `Icons.tune` (커스텀 설정으로 복귀)
- `activeTemplateId == null` 일 때 selected 표시

### 8.3 로딩 상태

```
TemplateService.getTemplates()
  ├── 로딩 중: CircularProgressIndicator (작은, 갤러리 영역)
  ├── 성공: 템플릿 목록 표시
  └── 실패 (오프라인 + 캐시 없음): "인터넷 연결 필요" 텍스트
```

---

## 9. 빌트인 기본 템플릿 (`assets/default_templates.json`)

10개 템플릿, 모두 `minEngineVersion: 1`, URL 이미지 없음(thumbnailUrl: null):

| ID | 이름 | 카테고리 | 특징 |
|----|------|---------|------|
| `minimal_black` | 미니멀 블랙 | 미니멀 | 검정 단색, 원형 도트 |
| `minimal_white_inv` | 미니멀 화이트 | 미니멀 | 검정 배경, 흰 도트 |
| `minimal_navy` | 네이비 | 미니멀 | 남색 단색 |
| `social_instagram` | Instagram | 소셜 | 주황~보라 linear gradient |
| `social_facebook` | Facebook | 소셜 | #1877F2 단색 |
| `social_x` | X (Twitter) | 소셜 | 검정, 사각 도트+눈 |
| `social_youtube` | YouTube | 소셜 | #FF0000 단색 |
| `biz_clean` | 비즈니스 클린 | 비즈니스 | 진회색 단색, 사각 |
| `biz_gradient` | 비즈니스 그라디언트 | 비즈니스 | 네이비→청록 linear gradient |
| `biz_elegant` | 엘레강트 | 비즈니스 | 진보라 단색, 원형 눈 |

---

## 10. `settings_service.dart` 추가

```dart
const _kActiveTemplateId = 'active_template_id';

static Future<String?> getActiveTemplateId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_kActiveTemplateId);
}

static Future<void> saveActiveTemplateId(String? id) async {
  final prefs = await SharedPreferences.getInstance();
  if (id == null) {
    await prefs.remove(_kActiveTemplateId);
  } else {
    await prefs.setString(_kActiveTemplateId, id);
  }
}
```

---

## 11. 구현 순서

| 순서 | 파일 | 작업 |
|------|------|------|
| 1 | `lib/shared/constants/app_config.dart` | 상수 정의 |
| 2 | `lib/models/qr_template.dart` | 데이터 모델 + fromJson |
| 3 | `assets/default_templates.json` | 빌트인 10개 템플릿 JSON |
| 4 | `pubspec.yaml` | assets 항목 추가 |
| 5 | `lib/services/template_service.dart` | HTTP + Hive 캐시 + 버전 필터 |
| 6 | `lib/features/qr_result/gradient_qr_painter.dart` | CustomPainter 구현 |
| 7 | `lib/features/qr_result/qr_result_provider.dart` | 신규 필드 + applyTemplate() |
| 8 | `lib/features/qr_result/qr_result_screen.dart` | 렌더러 분기 + _TemplateGallery |
| 9 | `lib/services/settings_service.dart` | activeTemplateId 저장 메서드 |

---

## 12. 의존 관계

```
qr_result_screen
  ├── depends: qr_result_provider (state)
  ├── depends: template_service (manifest 로드)
  ├── depends: gradient_qr_painter (그라디언트 렌더링)
  └── depends: qr_template (데이터 모델)

template_service
  ├── depends: http (네트워크)
  ├── depends: hive_flutter (캐시)
  └── depends: qr_template (파싱)

gradient_qr_painter
  ├── depends: qr_flutter (QrPainter)
  └── depends: qr_template (QrGradient)
```
