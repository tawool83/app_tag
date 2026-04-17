# Design: QR 화면 재설계 & Supabase 템플릿 시스템

> 아키텍처 선택: **Option B — Clean Architecture**
> Plan 참조: `docs/01-plan/features/qr-focus-redesign.plan.md`

---

## 1. 디렉터리 구조 (Before → After)

### Before
```
lib/
├─ features/qr_result/
│   ├─ gradient_qr_painter.dart   ← 삭제
│   ├─ qr_result_provider.dart
│   └─ qr_result_screen.dart
├─ models/
│   └─ qr_template.dart
├─ services/
│   └─ template_service.dart
└─ shared/constants/
    └─ app_config.dart
```

### After
```
lib/
├─ features/qr_result/
│   ├─ qr_result_provider.dart        (수정 — QrEyeStyle, customGradient, kQrPresetGradients)
│   ├─ qr_result_screen.dart          (수정 — 슬림화)
│   ├─ tabs/
│   │   ├─ recommended_tab.dart       (신규)
│   │   ├─ customize_tab.dart         (신규 — 아이 모양 enum, 단색/그라디언트 토글)
│   │   └─ all_templates_tab.dart     (신규)
│   └─ widgets/
│       ├─ qr_preview_section.dart    (신규 — buildPrettyQr(), buildQrGradientShader())
│       └─ template_thumbnail.dart    (수정 — buildQrGradientShader() 적용)
├─ models/
│   └─ qr_template.dart               (수정 — tagTypes, roundFactor)
├─ repositories/
│   └─ template_repository.dart       (신규)
├─ services/
│   ├─ supabase_service.dart          (신규)
│   └─ template_service.dart          (수정 — Supabase 동기화)
└─ shared/constants/
    └─ app_config.dart                (수정 — kQrMaxLength, Supabase 상수)
```

**변경 요약**: 신규 7개, 수정 7개, 삭제 1개 (`gradient_qr_painter.dart`)

---

## 2. 패키지 변경 (`pubspec.yaml`)

```yaml
dependencies:
  # 추가
  supabase_flutter: ^2.5.0
  pretty_qr_code: ^3.3.0

  # 제거
  # qr_flutter: ^4.1.0
```

---

## 3. 데이터 레이어

### 3.1 Supabase 스키마

```sql
-- 카테고리
CREATE TABLE qr_template_categories (
  id            text PRIMARY KEY,
  name          text NOT NULL,
  display_order int  NOT NULL DEFAULT 0
);

-- 템플릿
CREATE TABLE qr_templates (
  id                 text PRIMARY KEY,
  name               text NOT NULL,
  category_id        text REFERENCES qr_template_categories(id),
  tag_types          text[]       NOT NULL DEFAULT '{}',
  display_order      int          NOT NULL DEFAULT 0,
  thumbnail_url      text,
  is_premium         boolean      NOT NULL DEFAULT false,
  style              jsonb        NOT NULL,
  min_engine_version int          NOT NULL DEFAULT 1,
  created_at         timestamptz  DEFAULT now(),
  updated_at         timestamptz  DEFAULT now()
);

-- RLS (익명 읽기)
ALTER TABLE qr_template_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE qr_templates           ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public read" ON qr_template_categories FOR SELECT USING (true);
CREATE POLICY "public read" ON qr_templates           FOR SELECT USING (true);

-- updated_at 자동 트리거
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = now(); RETURN NEW; END; $$ LANGUAGE plpgsql;
CREATE TRIGGER qr_templates_updated_at
  BEFORE UPDATE ON qr_templates FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

### 3.2 `lib/models/qr_template.dart` 변경

```dart
class QrTemplate {
  // 기존 필드 유지 ...
  final List<String> tagTypes;   // 신규: [] | ['all'] | ['website','contact']
  final double? roundFactor;     // 신규: 0.0~1.0, null = 스타일 기본값

  factory QrTemplate.fromJson(Map<String, dynamic> json) => QrTemplate(
    // 기존 ...
    tagTypes: (json['tagTypes'] as List<dynamic>?)
        ?.map((e) => e as String).toList() ?? const [],
    roundFactor: (json['roundFactor'] as num?)?.toDouble(),
  );
}
```

### 3.3 `assets/default_templates.json` 변경

각 템플릿 오브젝트에 `tagTypes` 추가:
```json
{
  "id": "minimal_black",
  "tagTypes": ["all"],
  "roundFactor": 0.0,
  ...
}
```

태그 타입별 추천 매핑 예시:
| templateId | tagTypes |
|-----------|---------|
| `minimal_black`, `minimal_navy` | `["all"]` |
| `social_instagram`, `social_facebook` | `["website", "clipboard"]` |
| `biz_clean`, `biz_elegant` | `["contact", "email"]` |

---

## 4. 서비스 레이어

### 4.1 `lib/services/supabase_service.dart` (신규)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/constants/app_config.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: kSupabaseUrl,
      anonKey: kSupabaseAnonKey,
    );
  }
}
```

- `main.dart`에서 `await SupabaseService.initialize()` 호출

### 4.2 `lib/repositories/template_repository.dart` (신규)

```dart
/// 템플릿 데이터 접근 단일 창구.
/// TemplateService(캐시/로컬), SupabaseService(원격)를 조합.
class TemplateRepository {
  /// 로컬 우선 로드 + 백그라운드 Supabase 동기화.
  /// [onRefresh]: 동기화 완료 후 UI 갱신 콜백
  static Future<QrTemplateManifest> getTemplates({
    void Function(QrTemplateManifest updated)? onRefresh,
  }) async {
    // 1. 로컬/캐시 즉시 반환
    final local = await TemplateService.getTemplates();

    // 2. 백그라운드 Supabase 동기화
    _syncFromSupabase(local, onRefresh);

    return local;
  }

  static Future<void> _syncFromSupabase(
    QrTemplateManifest local,
    void Function(QrTemplateManifest)? onRefresh,
  ) async {
    try {
      // Supabase에서 가장 최근 updated_at 확인
      final row = await SupabaseService.client
          .from('qr_templates')
          .select('updated_at')
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row == null) return;
      final remoteUpdatedAt = DateTime.parse(row['updated_at'] as String);

      // 로컬 캐시보다 새 데이터가 있으면 전체 로드
      final cacheTs = await TemplateService.getCacheTimestamp();
      if (cacheTs != null && !remoteUpdatedAt.isAfter(cacheTs)) return;

      // 전체 템플릿 로드
      final rows = await SupabaseService.client
          .from('qr_templates')
          .select('*, qr_template_categories(id, name, display_order)');

      final manifest = _parseSupabaseRows(rows);
      await TemplateService.saveToCache(manifest);
      onRefresh?.call(manifest);
    } catch (_) {
      // 동기화 실패는 무시 (로컬 데이터 유지)
    }
  }

  static QrTemplateManifest _parseSupabaseRows(List<dynamic> rows) { ... }
}
```

### 4.3 `lib/services/template_service.dart` 변경

추가 메서드:
```dart
/// 캐시 타임스탬프 반환 (Supabase diff 비교용)
static Future<DateTime?> getCacheTimestamp() async { ... }

/// Repository가 파싱한 manifest를 캐시에 저장
static Future<void> saveToCache(QrTemplateManifest manifest) async { ... }
```

기존 CDN(`kQrTemplatesUrl`) 로직은 **제거** (Supabase Repository로 대체).

---

## 5. 상태 관리 (`qr_result_provider.dart`)

### 5.1 `QrEyeStyle` enum (신규)

```dart
/// QR finder pattern(눈) 모양 프리셋.
/// PrettyQrShape.custom(finderPattern:) 에 각각 다른 symbol 타입 매핑.
enum QrEyeStyle { square, rounded, circle, smooth }
//  square  → PrettyQrSquaresSymbol(rounding: 0.0)  — 날카로운 직각
//  rounded → PrettyQrSquaresSymbol(rounding: 0.8)  — 크게 둥근 사각형
//  circle  → PrettyQrDotsSymbol()                  — 원형
//  smooth  → PrettyQrSmoothSymbol(roundFactor: 1.0) — 완전 부드러운 연결형
```

### 5.2 그라디언트 프리셋 상수 (신규)

```dart
/// 꾸미기 탭 그라디언트 팔레트 — WCAG 흰 배경 스캔 안전 기준 8종
const kQrPresetGradients = [
  QrGradient(type: 'linear', angleDegrees: 45,
      colors: [Color(0xFF0066CC), Color(0xFF6A0DAD)]),  // 블루-퍼플
  QrGradient(type: 'linear', angleDegrees: 45,
      colors: [Color(0xFFCC3300), Color(0xFFCC8800)]),  // 선셋
  QrGradient(type: 'linear', angleDegrees: 135,
      colors: [Color(0xFF006644), Color(0xFF003388)]),  // 에메랄드-네이비
  QrGradient(type: 'linear', angleDegrees: 45,
      colors: [Color(0xFFCC0055), Color(0xFF660099)]),  // 로즈-퍼플
  QrGradient(type: 'linear', angleDegrees: 135,
      colors: [Color(0xFF0077B6), Color(0xFF023E8A)]),  // 오션
  QrGradient(type: 'linear', angleDegrees: 45,
      colors: [Color(0xFF1B5E20), Color(0xFF1A237E)]),  // 포레스트
  QrGradient(type: 'linear', angleDegrees: 135,
      colors: [Color(0xFF1A237E), Color(0xFF006064)]),  // 미드나잇
  QrGradient(type: 'radial',
      colors: [Color(0xFF880000), Color(0xFF4A0080)]),  // 라디얼 다크
];
```

### 5.3 QrResultState 변경

```dart
class QrResultState {
  // 기존 필드 유지 ...

  // 신규
  final String? tagType;           // 현재 태그 타입 ('website', 'contact' 등)
  final double roundFactor;        // 도트(데이터 모듈) 둥글기 (0.0~1.0)
  final QrEyeStyle eyeStyle;       // 아이(finder pattern) 모양 — 도트와 독립 제어
  final QrGradient? customGradient; // 꾸미기 탭에서 직접 선택한 그라디언트 (null = 단색)

  // 기존 (템플릿 시스템)
  final QrGradient? templateGradient; // 템플릿에서 설정된 그라디언트 (우선순위 높음)

  const QrResultState({
    // ...
    this.tagType,
    this.roundFactor = 0.0,
    this.eyeStyle = QrEyeStyle.square,
    this.customGradient,
  });
}
```

### 5.4 QrResultNotifier 신규 메서드

```dart
void setTagType(String? tagType) =>
    state = state.copyWith(tagType: tagType);

void setRoundFactor(double factor) =>
    state = state.copyWith(roundFactor: factor);

void setEyeStyle(QrEyeStyle style) =>
    state = state.copyWith(eyeStyle: style);

void setCustomGradient(QrGradient? gradient) =>
    state = state.copyWith(customGradient: gradient);
```

### 5.5 `applyTemplate` 변경

```dart
void applyTemplate(QrTemplate template, {Uint8List? centerIconBytes}) {
  final style = template.style;
  state = state.copyWith(
    activeTemplateId: template.id,
    roundFactor: template.roundFactor ?? 0.0,
    qrColor: style.foreground.solidColor ?? const Color(0xFF000000),
    templateGradient: style.foreground.gradient,
    embedIcon: style.centerIcon.type != 'none',
    templateCenterIconBytes: centerIconBytes,
    centerEmoji: null,
    emojiIconBytes: null,
    // customGradient는 건드리지 않음 (독립 유지)
  );
}
```

---

## 6. UI 레이어

### 6.1 `lib/features/qr_result/widgets/qr_preview_section.dart` (신규)

```dart
/// 소형(160px) QR 미리보기 + 돋보기 버튼
class QrPreviewSection extends ConsumerWidget {
  final GlobalKey repaintKey;
  final String deepLink;
  final String label;
  final String printTitle;
  final VoidCallback onZoom;  // 확대 팝업

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qrResultProvider);
    return Column(
      children: [
        Stack(
          children: [
            RepaintBoundary(
              key: repaintKey,
              child: _buildQrWidget(state, size: 160),  // PrettyQrView
            ),
            Positioned(
              right: 4, bottom: 4,
              child: IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: onZoom,
              ),
            ),
          ],
        ),
        // 라벨, deepLink URL
      ],
    );
  }
}
```

**확대 팝업** (`showDialog`):
```dart
void _showZoomDialog(BuildContext context, String deepLink, QrResultState state) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQrWidget(state, size: 300),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    ),
  );
}
```

### 6.2 `lib/features/qr_result/tabs/recommended_tab.dart` (신규)

```dart
/// [추천] 탭: tagType에 맞는 템플릿 필터링
class RecommendedTab extends StatelessWidget {
  final QrTemplateManifest manifest;
  final String? activeTemplateId;
  final String? tagType;
  final void Function(QrTemplate) onTemplateSelected;

  List<QrTemplate> get _filtered {
    final typed = manifest.templates.where((t) =>
      t.tagTypes.contains(tagType) || t.tagTypes.contains('all')).toList();
    return typed.isNotEmpty ? typed : manifest.templates.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 0.75,
      ),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _TemplateThumbnail(
        template: _filtered[i],
        isSelected: _filtered[i].id == activeTemplateId,
        onTap: () => onTemplateSelected(_filtered[i]),
      ),
    );
  }
}
```

### 6.3 `lib/features/qr_result/tabs/customize_tab.dart` (신규)

```dart
/// [꾸미기] 탭 — 실제 구현된 파라미터 기준
class CustomizeTab extends StatelessWidget {
  // 텍스트 입력
  final TextEditingController labelController;
  final TextEditingController printTitleController;
  final ValueChanged<String> onLabelChanged;
  final ValueChanged<String> onPrintTitleChanged;

  // 색상 / 그라디언트
  final Color selectedColor;
  final QrGradient? customGradient;        // null = 단색 모드
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<QrGradient?> onGradientChanged; // null 전달 시 단색 전환

  // 아이 모양 (finder pattern)
  final QrEyeStyle eyeStyle;
  final ValueChanged<QrEyeStyle> onEyeStyleChanged;

  // 도트 둥글기
  final double roundFactor;
  final ValueChanged<double> onRoundFactorChanged;

  // 중앙 아이콘
  final QrCenterOption centerOption;
  final String? centerEmoji;
  final bool hasDefaultIcon;
  final ValueChanged<QrCenterOption> onCenterOptionChanged;
  final ValueChanged<String> onEmojiSelected;

  // 인쇄 크기 (cm)
  final double printSizeCm;
  final ValueChanged<double> onSizeChanged;
}
```

**UI 구성 순서**:
1. 인쇄 상단 문구 텍스트필드
2. QR 하단 문구 텍스트필드
3. **QR 색상** — `[단색 | 그라디언트]` 토글
   - 단색: 10색 `_ColorChip` 팔레트 (`qrSafeColors`)
   - 그라디언트: 8종 `_GradientPicker` (원형 그라디언트 칩)
4. **아이 모양** — `_EyeShapeSelector` (4종 프리셋 카드 + `_EyeIcon` 미리보기)
5. **도트 둥글기** — `Slider` (0.0~1.0)
6. **중앙 아이콘** — `[없음 | 기본 아이콘 | 이모지]` 토글 + 이모지 그리드
7. **인쇄 크기** — `Slider` (2.5cm ~ 20.0cm)

### 6.4 `lib/features/qr_result/tabs/all_templates_tab.dart` (신규)

```dart
/// [전체 템플릿] 탭: 카테고리별 그룹화
class AllTemplatesTab extends StatelessWidget {
  final QrTemplateManifest manifest;
  final String? activeTemplateId;
  final void Function(QrTemplate) onTemplateSelected;
  final VoidCallback onTemplateClear;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // "템플릿 없음" 선택 옵션
        SliverToBoxAdapter(child: _ClearTemplateButton(onTap: onTemplateClear)),
        // 카테고리별 섹션
        for (final cat in manifest.categories) ...[
          SliverToBoxAdapter(child: _CategoryHeader(cat.name)),
          SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _TemplateThumbnail(
                template: _templatesForCategory(cat.id)[i],
                isSelected: ...,
                onTap: ...,
              ),
              childCount: _templatesForCategory(cat.id).length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, childAspectRatio: 0.75,
            ),
          ),
        ],
      ],
    );
  }
}
```

### 6.5 `lib/features/qr_result/qr_result_screen.dart` 재구성

```dart
class QrResultScreen extends ConsumerStatefulWidget { ... }

class _QrResultScreenState extends ConsumerState<QrResultScreen>
    with SingleTickerProviderStateMixin {
  final _repaintKey = GlobalKey();
  late TabController _tabController;          // 신규
  late TextEditingController _labelController;
  late TextEditingController _printTitleController;
  QrTemplateManifest _templateManifest = QrTemplateManifest.empty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // 기존 initState 로직 유지
    // TemplateService → TemplateRepository.getTemplates(onRefresh: ...) 변경
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR 코드')),
      body: Column(
        children: [
          // ① 소형 미리보기 (고정)
          QrPreviewSection(
            repaintKey: _repaintKey,
            deepLink: deepLink,
            label: label,
            printTitle: printTitle,
            onZoom: () => _showZoomDialog(context),
          ),

          // ② 탭 바 + 탭 뷰 (Expanded)
          TabBar(controller: _tabController, tabs: const [
            Tab(text: '추천'),
            Tab(text: '꾸미기'),
            Tab(text: '전체 템플릿'),
          ]),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RecommendedTab(...),
                CustomizeTab(...),
                AllTemplatesTab(...),
              ],
            ),
          ),

          // ③ 액션 버튼 (고정)
          _ActionButtons(state: state, appName: appName),
        ],
      ),
    );
  }
}
```

---

## 7. `pretty_qr_code` 공통 QR 빌더

`qr_preview_section.dart`에 공개 함수로 정의. `QrPreviewSection`, 확대 팝업, `TemplateThumbnail`에서 공용 사용.

### 7.1 `buildPrettyQr()` — 메인 QR 렌더러

```dart
Widget buildPrettyQr(
  QrResultState state, {
  required String deepLink,
  required double size,
  bool isDialog = false,  // ValueKey 충돌 방지
}) {
  final centerImage = _centerImageProvider(state);

  // 그라디언트 우선순위: 템플릿 > 커스텀
  final activeGradient = state.templateGradient ?? state.customGradient;
  final hasGradient = activeGradient != null;
  final dotColor = hasGradient ? Colors.black : state.qrColor;

  // 도트 shape (데이터 모듈)
  final dotShape = PrettyQrSmoothSymbol(roundFactor: state.roundFactor, color: dotColor);

  // 아이 shape (finder pattern) — QrEyeStyle enum → 다른 symbol 타입 매핑
  final PrettyQrShape qrShape;
  switch (state.eyeStyle) {
    case QrEyeStyle.square:
      qrShape = PrettyQrShape.custom(dotShape,
          finderPattern: PrettyQrSquaresSymbol(rounding: 0.0, color: dotColor));
    case QrEyeStyle.rounded:
      qrShape = PrettyQrShape.custom(dotShape,
          finderPattern: PrettyQrSquaresSymbol(rounding: 0.8, color: dotColor));
    case QrEyeStyle.circle:
      qrShape = PrettyQrShape.custom(dotShape,
          finderPattern: PrettyQrDotsSymbol(color: dotColor));
    case QrEyeStyle.smooth:
      qrShape = PrettyQrShape.custom(dotShape,
          finderPattern: PrettyQrSmoothSymbol(roundFactor: 1.0, color: dotColor));
  }

  // 그라디언트 + 아이콘 동시 사용 시 아이콘을 ShaderMask 밖으로 분리
  final useIconOverlay = hasGradient && centerImage != null;

  // ValueKey: state 변경 시 PrettyQrRenderView 강제 재생성 (repaint boundary 이슈 우회)
  final qrKey = ValueKey(Object.hash(isDialog, deepLink,
      state.roundFactor, state.eyeStyle, state.qrColor,
      state.embedIcon, centerImage != null,
      state.templateGradient, state.customGradient, state.activeTemplateId));

  final qrWidget = PrettyQrView.data(
    key: qrKey,
    data: deepLink,
    errorCorrectLevel: centerImage != null ? QrErrorCorrectLevel.H : QrErrorCorrectLevel.M,
    decoration: PrettyQrDecoration(
      shape: qrShape,
      // useIconOverlay 시 아이콘 제외 (Stack 오버레이로 대신)
      image: !useIconOverlay && centerImage != null
          ? PrettyQrDecorationImage(
              image: centerImage,
              position: PrettyQrDecorationImagePosition.embedded)
          : null,
    ),
  );

  if (hasGradient) {
    Widget gradientQr = SizedBox(
      width: size, height: size,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => buildQrGradientShader(activeGradient!, bounds),
        child: qrWidget,
      ),
    );

    if (useIconOverlay) {
      // 아이콘을 흰 원형 배지로 중앙 Stack 오버레이 → 원본 색상 보존
      final iconSize = size * 0.22;
      gradientQr = Stack(
        alignment: Alignment.center,
        children: [
          gradientQr,
          Container(
            width: iconSize, height: iconSize,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)]),
            padding: EdgeInsets.all(iconSize * 0.08),
            child: ClipOval(child: Image(image: centerImage!, fit: BoxFit.contain)),
          ),
        ],
      );
    }
    return gradientQr;
  }

  return SizedBox(width: size, height: size, child: qrWidget);
}
```

### 7.2 `buildQrGradientShader()` — 공개 그라디언트 셰이더 빌더

```dart
/// TemplateThumbnail에서도 import해서 사용하는 공용 함수.
Shader buildQrGradientShader(QrGradient gradient, Rect bounds) {
  if (gradient.type == 'radial') {
    return RadialGradient(colors: gradient.colors, stops: gradient.stops)
        .createShader(bounds);
  }
  // linear (기본)
  final rad = gradient.angleDegrees * pi / 180;
  return LinearGradient(
    colors: gradient.colors,
    stops: gradient.stops,
    transform: GradientRotation(rad),
  ).createShader(bounds);
}
```

### 7.3 `TemplateThumbnail` 그라디언트 렌더링

`template_thumbnail.dart`에서 `buildQrGradientShader()`를 import해 그라디언트 템플릿을 미리보기와 동일한 방식으로 표시:

```dart
// 기존: 첫 번째 gradient color를 단색으로 사용 (부정확)
// 개선: buildQrGradientShader()로 ShaderMask 적용
Widget _buildQrPreview() {
  final gradient = style.foreground.isGradient ? style.foreground.gradient : null;
  final qr = PrettyQrView.data(..., decoration: PrettyQrDecoration(
    shape: PrettyQrSmoothSymbol(
      roundFactor: roundFactor,
      color: gradient != null ? Colors.black : dotColor,
    ),
  ));

  if (gradient != null) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => buildQrGradientShader(gradient, bounds),
      child: qr,
    );
  }
  return qr;
}
```

> **핵심 설계 결정**:
> - `PrettyQrShape.custom()` API는 `@experimental` — finder pattern 독립 제어 가능하지만 breaking 변경 가능성 있음
> - 그라디언트는 `PrettyQrLinearGradientDecoration` 대신 **`ShaderMask(BlendMode.srcIn)`** 방식 채택 (더 유연한 RadialGradient 지원)
> - 그라디언트 + 중앙 아이콘 조합 시 `BlendMode.srcIn`이 아이콘까지 물들이는 문제 → `useIconOverlay` Stack 분리로 해결

---

## 8. QR 데이터 150자 제한

### `lib/shared/constants/app_config.dart` 추가

```dart
const int kQrMaxLength = 150;
const String kSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String kSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
```

### 각 태그 입력 화면 검증 패턴

```dart
// 공통 유틸 (app_config.dart 또는 별도 validator.dart)
String? validateQrData(String data) {
  if (data.length > kQrMaxLength) {
    return 'QR 코드 최대 ${kQrMaxLength}자를 초과했습니다 (현재 ${data.length}자).';
  }
  return null;
}

// 각 태그 화면의 "다음" 버튼 처리
void _onNext() {
  final error = validateQrData(deepLink);
  if (error != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    return;
  }
  Navigator.pushNamed(context, '/qr-result', arguments: {...});
}
```

---

## 9. `TagHistory` Hive 스키마 변경

```dart
@HiveField(16)
final double? roundFactor;   // 신규 (nullable, 하위 호환)
```

`tag_history.g.dart` 재생성 필요 (`flutter pub run build_runner build`).

---

## 10. `main.dart` 변경

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TagHistoryAdapter());
  await SupabaseService.initialize();   // 신규
  runApp(const ProviderScope(child: AppTag()));
}
```

---

## 11. 구현 순서

```
1. pubspec.yaml 변경 (패키지 교체)
   → flutter pub get

2. app_config.dart — kQrMaxLength, Supabase 상수 추가

3. supabase_service.dart 신규 생성
   main.dart Supabase 초기화

4. qr_template.dart — tagTypes, roundFactor 필드 추가
   default_templates.json — tagTypes, roundFactor 추가
   tag_history.dart — HiveField(16) roundFactor 추가
   → build_runner 실행

5. TemplateService — getCacheTimestamp, saveToCache 추가
   template_repository.dart 신규 생성

6. Supabase DB 테이블 생성 (SQL 실행)
   초기 데이터 투입 (tagTypes 매핑)

7. qr_result_provider.dart — tagType, roundFactor state/method 추가

8. gradient_qr_painter.dart 삭제

9. 신규 위젯 파일 생성:
   - widgets/qr_preview_section.dart
   - tabs/recommended_tab.dart
   - tabs/customize_tab.dart
   - tabs/all_templates_tab.dart

10. qr_result_screen.dart 재구성
    (탭 컨트롤러, Column 레이아웃, 슬림화)

11. 각 태그 입력 화면 150자 검증 추가

12. flutter run 검증
```

---

## 12. 리스크 & 완화

| 리스크 | 완화 방법 |
|--------|----------|
| `pretty_qr_code` API가 기존 `QrEyeShape` enum과 불일치 | `QrEyeStyle` enum으로 독립 제어, Hive 문자열은 기존 필드 유지 |
| `PrettyQrShape.custom()` `@experimental` breaking 변경 | 패키지 업그레이드 시 API 호환성 검증 필수 (현재 3.6.0 고정) |
| 그라디언트 + 중앙 아이콘 동시 사용 시 아이콘 색상 오염 | `useIconOverlay` 플래그로 아이콘을 ShaderMask 밖 Stack으로 분리 (해결됨) |
| 템플릿 썸네일이 그라디언트 미표시 | `buildQrGradientShader()` 공용 함수로 미리보기와 동일 엔진 사용 (해결됨) |
| Supabase 오프라인 시 템플릿 없음 | `TemplateRepository` fallback → `TemplateService.getTemplates()` → 빌트인 JSON |
| `gradient_qr_painter.dart` 삭제 후 참조 누락 | 삭제 완료, `ShaderMask` 방식으로 전환됨 |
| Hive `roundFactor` HiveField(16) 충돌 | 신규 nullable 필드, 기존 어댑터와 충돌 없음 |
| `dart-define` Supabase 키 CI 누락 | `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` 문서화 |
| 그라디언트 QR 스캔 불가 | `kQrPresetGradients` 전 색상이 WCAG 흰 배경 대비비 기준 충족 |
