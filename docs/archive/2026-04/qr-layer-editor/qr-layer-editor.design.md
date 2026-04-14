# Design: QR Layer Editor

**Architecture**: Option C — 구조체 그룹화 + 위젯 분해  
**Plan Reference**: `docs/01-plan/features/qr-layer-editor.plan.md`  
**Date**: 2026-04-14

---

## 1. 전체 구조

### 1.1 탭 구조 (현재 → 변경)

```
현재 3탭                      변경 후 5탭
─────────────────────         ─────────────────────────────────
[추천] [꾸미기] [전체 템플릿]  [전체 템플릿] [배경] [QR] [스티커] [나의 템플릿]
                              index:  0         1     2    3       4
```

- `TabController(length: 5)` (기존 3 → 5)
- 기본 탭: index 0 (전체 템플릿)
- `recommended_tab.dart` 삭제
- `customize_tab.dart` 삭제 (역할 분리)

### 1.2 레이어 스택 (렌더링 순서)

```
RepaintBoundary  ←── 캡처 기준
└── QrLayerStack (Stack)
    ├── [Layer 0] BackgroundLayer     — 갤러리 이미지 or 흰 배경
    ├── [Layer 1] QrLayer             — 콰이어트 존 + buildPrettyQr()
    └── [Layer 2] StickerLayer        — 로고 + 상단 텍스트 + 하단 텍스트
```

### 1.3 파일 변경 요약

| 구분 | 파일 | 내용 |
|------|------|------|
| 신규 | `lib/models/background_config.dart` | BackgroundConfig 값 객체 |
| 신규 | `lib/models/sticker_config.dart` | StickerConfig, StickerText, LogoPosition, LogoBackground |
| 신규 | `lib/models/user_qr_template.dart` | UserQrTemplate Hive 모델 |
| 신규 | `lib/models/user_qr_template.g.dart` | Hive 어댑터 (build_runner 생성) |
| 신규 | `lib/repositories/user_template_repository.dart` | 나의 템플릿 CRUD |
| 신규 | `lib/features/qr_result/widgets/qr_layer_stack.dart` | 3레이어 렌더링 위젯 |
| 신규 | `lib/features/qr_result/tabs/background_tab.dart` | 배경화면 탭 |
| 신규 | `lib/features/qr_result/tabs/qr_style_tab.dart` | QR 스타일 탭 |
| 신규 | `lib/features/qr_result/tabs/sticker_tab.dart` | 스티커 탭 |
| 신규 | `lib/features/qr_result/tabs/my_templates_tab.dart` | 나의 템플릿 탭 |
| 수정 | `lib/features/qr_result/qr_result_provider.dart` | 신규 상태 필드, setter 추가 |
| 수정 | `lib/features/qr_result/qr_result_screen.dart` | 5탭, 액션버튼 변경 |
| 수정 | `lib/features/qr_result/widgets/qr_preview_section.dart` | QrLayerStack 사용 |
| 수정 | `lib/main.dart` | UserQrTemplate Hive 박스 등록 |
| 수정 | `pubspec.yaml` | image_picker, image_cropper 추가 |
| 삭제 | `lib/features/qr_result/tabs/recommended_tab.dart` | 추천 탭 제거 |
| 삭제 | `lib/features/qr_result/tabs/customize_tab.dart` | 역할 분리로 해체 |

---

## 2. 데이터 모델

### 2.1 BackgroundConfig

```dart
// lib/models/background_config.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';

class BackgroundConfig {
  final Uint8List? imageBytes;  // null = 흰 배경
  final double scale;           // 이미지 스케일 (0.5 ~ 2.0)
  final BoxFit fit;             // 기본: BoxFit.cover

  const BackgroundConfig({
    this.imageBytes,
    this.scale = 1.0,
    this.fit = BoxFit.cover,
  });

  BackgroundConfig copyWith({
    Object? imageBytes = _sentinel,
    double? scale,
    BoxFit? fit,
  }) =>
      BackgroundConfig(
        imageBytes: imageBytes == _sentinel
            ? this.imageBytes
            : imageBytes as Uint8List?,
        scale: scale ?? this.scale,
        fit: fit ?? this.fit,
      );

  bool get hasImage => imageBytes != null;
}

const _sentinel = Object();
```

### 2.2 StickerConfig + 보조 타입

```dart
// lib/models/sticker_config.dart

import 'package:flutter/material.dart';

enum LogoPosition { center, bottomRight }
enum LogoBackground { none, square, circle }

class StickerText {
  final String content;
  final Color color;
  final String fontFamily;  // 'Roboto' | 'NotoSerif' | 'RobotoMono'
  final double fontSize;    // 10 ~ 24

  const StickerText({
    required this.content,
    this.color = Colors.black,
    this.fontFamily = 'Roboto',
    this.fontSize = 14,
  });

  StickerText copyWith({
    String? content,
    Color? color,
    String? fontFamily,
    double? fontSize,
  }) =>
      StickerText(
        content: content ?? this.content,
        color: color ?? this.color,
        fontFamily: fontFamily ?? this.fontFamily,
        fontSize: fontSize ?? this.fontSize,
      );

  bool get isEmpty => content.trim().isEmpty;
}

class StickerConfig {
  final LogoPosition logoPosition;    // center | bottomRight
  final LogoBackground logoBackground; // none | square | circle
  final StickerText? topText;
  final StickerText? bottomText;

  const StickerConfig({
    this.logoPosition = LogoPosition.center,
    this.logoBackground = LogoBackground.none,
    this.topText,
    this.bottomText,
  });

  StickerConfig copyWith({
    LogoPosition? logoPosition,
    LogoBackground? logoBackground,
    Object? topText = _sentinel,
    Object? bottomText = _sentinel,
  }) =>
      StickerConfig(
        logoPosition: logoPosition ?? this.logoPosition,
        logoBackground: logoBackground ?? this.logoBackground,
        topText: topText == _sentinel ? this.topText : topText as StickerText?,
        bottomText:
            bottomText == _sentinel ? this.bottomText : bottomText as StickerText?,
      );

  bool get hasAnySticker =>
      topText?.isEmpty == false || bottomText?.isEmpty == false;
}

const _sentinel = Object();
```

### 2.3 UserQrTemplate (Hive 모델)

```dart
// lib/models/user_qr_template.dart

import 'dart:typed_data';
import 'package:hive/hive.dart';

part 'user_qr_template.g.dart';

@HiveType(typeId: 1)
class UserQrTemplate extends HiveObject {
  @HiveField(0)  String id;
  @HiveField(1)  String name;
  @HiveField(2)  DateTime createdAt;

  // 배경 레이어
  @HiveField(3)  Uint8List? backgroundImageBytes;
  @HiveField(4)  double backgroundScale;

  // QR 레이어
  @HiveField(5)  int qrColorValue;         // Color.value
  @HiveField(6)  String? gradientJson;     // QrGradient.toJson() 문자열
  @HiveField(7)  double roundFactor;
  @HiveField(8)  int eyeStyleIndex;        // QrEyeStyle.index
  @HiveField(9)  int quietZoneColorValue;  // Color.value

  // 스티커 레이어
  @HiveField(10) int logoPositionIndex;
  @HiveField(11) int logoBackgroundIndex;
  @HiveField(12) String? topTextContent;
  @HiveField(13) int? topTextColorValue;
  @HiveField(14) String? topTextFont;
  @HiveField(15) double? topTextSize;
  @HiveField(16) String? bottomTextContent;
  @HiveField(17) int? bottomTextColorValue;
  @HiveField(18) String? bottomTextFont;
  @HiveField(19) double? bottomTextSize;

  // 클라우드 동기화 대비 (현재 미사용)
  @HiveField(20) String? remoteId;
  @HiveField(21) bool syncedToCloud;

  // 썸네일 (갤러리저장 결과 축소본 — 나의 템플릿 그리드 표시용)
  @HiveField(22) Uint8List? thumbnailBytes;

  UserQrTemplate({
    required this.id,
    required this.name,
    required this.createdAt,
    this.backgroundImageBytes,
    this.backgroundScale = 1.0,
    this.qrColorValue = 0xFF000000,
    this.gradientJson,
    this.roundFactor = 0.0,
    this.eyeStyleIndex = 0,
    this.quietZoneColorValue = 0xFFFFFFFF,
    this.logoPositionIndex = 0,
    this.logoBackgroundIndex = 0,
    this.topTextContent,
    this.topTextColorValue,
    this.topTextFont,
    this.topTextSize,
    this.bottomTextContent,
    this.bottomTextColorValue,
    this.bottomTextFont,
    this.bottomTextSize,
    this.remoteId,
    this.syncedToCloud = false,
    this.thumbnailBytes,
  });
}
```

---

## 3. 상태 관리

### 3.1 QrResultState 변경

기존 필드 유지 + 신규 3개 필드 추가:

```dart
class QrResultState {
  // ── 기존 필드 (변경 없음) ──────────────────────────────
  final Uint8List? capturedImage;
  final QrActionStatus saveStatus;
  final QrActionStatus shareStatus;
  final String? errorMessage;
  final String? customLabel;
  final Color qrColor;
  final double roundFactor;
  final QrEyeStyle eyeStyle;
  final QrGradient? customGradient;
  final bool embedIcon;
  final Uint8List? defaultIconBytes;
  final String? centerEmoji;
  final Uint8List? emojiIconBytes;
  final String? tagType;
  final String? activeTemplateId;
  final QrGradient? templateGradient;
  final Uint8List? templateCenterIconBytes;
  // printSizeCm, printStatus, printTitle 유지 (호환성)

  // ── 신규 필드 ──────────────────────────────────────────
  final BackgroundConfig background;   // 배경 레이어 설정
  final StickerConfig sticker;         // 스티커 레이어 설정
  final Color quietZoneColor;          // QR 콰이어트 존 배경색

  const QrResultState({
    // ... 기존 기본값 유지
    this.background = const BackgroundConfig(),
    this.sticker = const StickerConfig(),
    this.quietZoneColor = Colors.white,
  });
}
```

### 3.2 QrResultNotifier 신규 setter

```dart
// 배경 레이어
void setBackground(BackgroundConfig config) =>
    state = state.copyWith(background: config);

// QR 레이어
void setQuietZoneColor(Color color) =>
    state = state.copyWith(quietZoneColor: color);

// 스티커 레이어
void setSticker(StickerConfig config) =>
    state = state.copyWith(sticker: config);

// 나의 템플릿 적용 (모든 레이어 일괄 복원)
void applyUserTemplate(UserQrTemplate t) {
  state = state.copyWith(
    background: BackgroundConfig(
      imageBytes: t.backgroundImageBytes,
      scale: t.backgroundScale,
    ),
    qrColor: Color(t.qrColorValue),
    customGradient: t.gradientJson != null
        ? QrGradient.fromJson(jsonDecode(t.gradientJson!))
        : null,   // sentinel 처리 필요
    roundFactor: t.roundFactor,
    eyeStyle: QrEyeStyle.values[t.eyeStyleIndex],
    quietZoneColor: Color(t.quietZoneColorValue),
    sticker: StickerConfig(
      logoPosition: LogoPosition.values[t.logoPositionIndex],
      logoBackground: LogoBackground.values[t.logoBackgroundIndex],
      topText: t.topTextContent != null
          ? StickerText(
              content: t.topTextContent!,
              color: Color(t.topTextColorValue!),
              fontFamily: t.topTextFont!,
              fontSize: t.topTextSize!,
            )
          : null,
      bottomText: t.bottomTextContent != null
          ? StickerText(
              content: t.bottomTextContent!,
              color: Color(t.bottomTextColorValue!),
              fontFamily: t.bottomTextFont!,
              fontSize: t.bottomTextSize!,
            )
          : null,
    ),
  );
}
```

---

## 4. 렌더링 위젯

### 4.1 QrLayerStack

```dart
// lib/features/qr_result/widgets/qr_layer_stack.dart

class QrLayerStack extends ConsumerWidget {
  final String deepLink;
  final double size;           // 미리보기: 160, 다이얼로그: 300
  final bool isDialog;

  const QrLayerStack({
    super.key,
    required this.deepLink,
    this.size = 160,
    this.isDialog = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qrResultProvider);
    final bg = state.background;
    final sticker = state.sticker;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ── Layer 0: 배경 ──────────────────────────────
          Positioned.fill(
            child: bg.hasImage
                ? Image.memory(
                    bg.imageBytes!,
                    fit: bg.fit,
                    scale: 1.0 / bg.scale,
                  )
                : Container(color: Colors.white),
          ),

          // ── Layer 1: QR (콰이어트 존 + buildPrettyQr) ─
          Positioned.fill(
            child: _QrWithQuietZone(
              state: state,
              deepLink: deepLink,
              size: size,
              isDialog: isDialog,
            ),
          ),

          // ── Layer 2: 스티커 ────────────────────────────
          if (!sticker.topText.isNullOrEmpty)
            Positioned(
              top: 6,
              left: 0, right: 0,
              child: _StickerTextWidget(text: sticker.topText!),
            ),

          // 로고 (center or bottomRight)
          _LogoWidget(sticker: sticker, state: state, size: size),

          if (!sticker.bottomText.isNullOrEmpty)
            Positioned(
              bottom: 6,
              left: 0, right: 0,
              child: _StickerTextWidget(text: sticker.bottomText!),
            ),
        ],
      ),
    );
  }
}

// 콰이어트 존 + QR 합성
class _QrWithQuietZone extends StatelessWidget {
  final QrResultState state;
  final String deepLink;
  final double size;
  final bool isDialog;

  // 콰이어트 존 패딩: QR 크기의 5% (최소 8px)
  double get quietPadding => (size * 0.05).clamp(8.0, 20.0);

  @override
  Widget build(BuildContext context) {
    final qrSize = size - quietPadding * 2;
    return Container(
      color: state.quietZoneColor,
      padding: EdgeInsets.all(quietPadding),
      child: buildPrettyQr(state, deepLink: deepLink, size: qrSize, isDialog: isDialog),
    );
  }
}
```

### 4.2 LogoWidget (스티커 레이어)

```dart
class _LogoWidget extends StatelessWidget {
  final StickerConfig sticker;
  final QrResultState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconProvider = _centerImageProvider(state);
    if (iconProvider == null) return const SizedBox.shrink();

    final iconSize = size * 0.22;
    final Widget iconWidget = _buildIconWithBackground(iconProvider, iconSize, sticker.logoBackground);

    if (sticker.logoPosition == LogoPosition.center) {
      return Positioned.fill(
        child: Center(child: iconWidget),
      );
    } else {
      // bottomRight
      return Positioned(
        right: 8,
        bottom: sticker.bottomText?.isEmpty == false ? 28 : 8,
        child: iconWidget,
      );
    }
  }

  Widget _buildIconWithBackground(
      ImageProvider img, double size, LogoBackground bg) {
    final content = ClipOval(child: Image(image: img, width: size, height: size, fit: BoxFit.contain));

    switch (bg) {
      case LogoBackground.none:
        return SizedBox(width: size, height: size, child: content);
      case LogoBackground.square:
        return Container(
          width: size + 8, height: size + 8,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.all(4),
          child: content,
        );
      case LogoBackground.circle:
        return Container(
          width: size + 8, height: size + 8,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          padding: const EdgeInsets.all(4),
          child: content,
        );
    }
  }
}
```

### 4.3 QrPreviewSection 변경

```dart
// 기존: buildPrettyQr() 직접 호출
// 변경: QrLayerStack 사용

class QrPreviewSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // 캡처 영역
            RepaintBoundary(
              key: repaintKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (printTitle.isNotEmpty) _PrintTitleText(printTitle),
                    // ← 기존 buildPrettyQr 대신 QrLayerStack 사용
                    QrLayerStack(deepLink: deepLink, size: 160),
                    if (label.isNotEmpty) _LabelText(label),
                  ],
                ),
              ),
            ),
            // 돋보기 버튼
            Positioned(right: 0, bottom: 0, child: _ZoomButton(...)),
          ],
        ),
        _DeepLinkText(deepLink),
      ],
    );
  }

  void _showZoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrLayerStack(deepLink: deepLink, size: 300, isDialog: true),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 5. 탭 위젯 설계

### 5.1 BackgroundTab

```dart
// lib/features/qr_result/tabs/background_tab.dart

class BackgroundTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = ref.watch(qrResultProvider).background;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 선택 버튼
          OutlinedButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text('갤러리에서 이미지 불러오기'),
            onPressed: () => _pickAndCropImage(context, ref),
          ),

          // 현재 이미지 미리보기 + 제거
          if (bg.hasImage) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(bg.imageBytes!, height: 120, fit: BoxFit.cover),
            ),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('이미지 제거'),
              onPressed: () => ref.read(qrResultProvider.notifier)
                  .setBackground(const BackgroundConfig()),
            ),

            // 스케일 슬라이더
            _SectionLabel('크기'),
            Slider(
              value: bg.scale,
              min: 0.5, max: 2.0,
              divisions: 30,
              label: '${(bg.scale * 100).round()}%',
              onChanged: (v) => ref.read(qrResultProvider.notifier)
                  .setBackground(bg.copyWith(scale: v)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickAndCropImage(BuildContext context, WidgetRef ref) async {
    // 1. image_picker로 갤러리 선택
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    // 2. image_cropper로 자유 비율 crop
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.square,
      ],
      uiSettings: [
        AndroidUiSettings(toolbarTitle: '배경 이미지 편집', lockAspectRatio: false),
        IOSUiSettings(title: '배경 이미지 편집', aspectRatioLockEnabled: false),
      ],
    );
    if (cropped == null) return;

    // 3. 이미지 리사이즈 (최대 800x800, 용량 절감)
    final bytes = await _compressImage(cropped.path);
    if (context.mounted) {
      ref.read(qrResultProvider.notifier)
          .setBackground(ref.read(qrResultProvider).background.copyWith(imageBytes: bytes));
    }
  }

  // image 패키지로 리사이즈 + JPEG 압축
  Future<Uint8List> _compressImage(String path) async {
    final raw = await File(path).readAsBytes();
    final img = decodeImage(raw)!;
    final resized = img.width > 800 || img.height > 800
        ? copyResize(img, width: 800)
        : img;
    return encodeJpg(resized, quality: 80) as Uint8List;
  }
}
```

### 5.2 QrStyleTab

```dart
// lib/features/qr_result/tabs/qr_style_tab.dart
// 기존 customize_tab.dart에서 QR 관련 섹션만 추출

class QrStyleTab extends ConsumerWidget {
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<QrGradient?> onGradientChanged;
  final ValueChanged<double> onRoundFactorChanged;
  final ValueChanged<QrEyeStyle> onEyeStyleChanged;
  final ValueChanged<Color> onQuietZoneColorChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qrResultProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ① 도트 모양 (기존 roundFactor 슬라이더 유지)
          _SectionLabel('도트 둥글기'),
          Slider(value: state.roundFactor, min: 0, max: 1, ...),

          // ② 눈(eye) 모양 (기존 EyeShapeSelector 이동)
          _SectionLabel('눈 모양'),
          _EyeShapeSelector(eyeStyle: state.eyeStyle, onChange: onEyeStyleChanged),

          // ③ 색상 (기존 단색/그라디언트 토글 이동)
          _SectionLabel('색상'),
          _ColorSection(
            selectedColor: state.qrColor,
            customGradient: state.customGradient,
            onColorSelected: onColorSelected,
            onGradientChanged: onGradientChanged,
          ),

          // ④ 콰이어트 존 배경색 (신규)
          _SectionLabel('여백 색상'),
          _QuietZoneColorPicker(
            selected: state.quietZoneColor,
            onChange: onQuietZoneColorChanged,
          ),
        ],
      ),
    );
  }
}

// 콰이어트 존 색상: 흰색 / 투명(없음) / 커스텀 3가지
class _QuietZoneColorPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QzChip(label: '흰색', color: Colors.white, selected: selected, onChange: onChange),
        _QzChip(label: '투명', color: Colors.transparent, selected: selected, onChange: onChange),
        // 커스텀 색상 picker (showColorPicker dialog)
        _QzCustomChip(selected: selected, onChange: onChange),
      ],
    );
  }
}
```

### 5.3 StickerTab

```dart
// lib/features/qr_result/tabs/sticker_tab.dart

class StickerTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qrResultProvider);
    final sticker = state.sticker;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 로고 섹션 ─────────────────────────────────
          _SectionLabel('로고'),

          // 아이콘 소스 선택 (기존 center option 이동)
          _CenterOptionRow(state: state, ref: ref),

          // 로고 위치
          _SectionLabel('위치'),
          _LogoPositionSelector(
            selected: sticker.logoPosition,
            onChange: (p) => ref.read(qrResultProvider.notifier)
                .setSticker(sticker.copyWith(logoPosition: p)),
          ),

          // 로고 배경
          _SectionLabel('배경'),
          _LogoBackgroundSelector(
            selected: sticker.logoBackground,
            onChange: (b) => ref.read(qrResultProvider.notifier)
                .setSticker(sticker.copyWith(logoBackground: b)),
          ),

          const Divider(height: 32),

          // ── 텍스트 섹션 ───────────────────────────────
          _SectionLabel('상단 텍스트'),
          _StickerTextEditor(
            text: sticker.topText,
            onChanged: (t) => ref.read(qrResultProvider.notifier)
                .setSticker(sticker.copyWith(topText: t)),
          ),

          const SizedBox(height: 16),
          _SectionLabel('하단 텍스트'),
          _StickerTextEditor(
            text: sticker.bottomText,
            onChanged: (t) => ref.read(qrResultProvider.notifier)
                .setSticker(sticker.copyWith(bottomText: t)),
          ),
        ],
      ),
    );
  }
}

// 텍스트 편집기 (내용 + 색상 + 폰트 + 크기)
class _StickerTextEditor extends StatefulWidget {
  final StickerText? text;
  final ValueChanged<StickerText?> onChanged;

  @override
  State<_StickerTextEditor> createState() => _StickerTextEditorState();
}

class _StickerTextEditorState extends State<_StickerTextEditor> {
  late final TextEditingController _ctrl;

  @override
  Widget build(BuildContext context) {
    final t = widget.text ?? const StickerText(content: '');
    return Column(
      children: [
        TextField(
          controller: _ctrl,
          decoration: const InputDecoration(hintText: '텍스트 입력'),
          onChanged: (v) => widget.onChanged(
            v.trim().isEmpty ? null : t.copyWith(content: v)),
        ),
        Row(
          children: [
            // 색상 팔레트 (qrSafeColors 재사용)
            _MiniColorPicker(selected: t.color,
                onChange: (c) => widget.onChanged(t.copyWith(color: c))),
            // 폰트 선택
            _FontSelector(selected: t.fontFamily,
                onChange: (f) => widget.onChanged(t.copyWith(fontFamily: f))),
            // 크기 슬라이더 (10~24sp)
            Expanded(
              child: Slider(value: t.fontSize, min: 10, max: 24, divisions: 14,
                  label: '${t.fontSize.round()}sp',
                  onChanged: (s) => widget.onChanged(t.copyWith(fontSize: s))),
            ),
          ],
        ),
      ],
    );
  }
}
```

**지원 폰트 (3종)**:

| 키 | 표시명 | 계열 |
|----|--------|------|
| `'Roboto'` | Sans | 시스템 기본 |
| `'NotoSerifKR'` | Serif | 본명조 |
| `'RobotoMono'` | Mono | 고정폭 |

> `google_fonts` 패키지 추가 없이 asset 폰트로 번들링 (용량 최소화)

### 5.4 MyTemplatesTab

```dart
// lib/features/qr_result/tabs/my_templates_tab.dart

class MyTemplatesTab extends StatelessWidget {
  final List<UserQrTemplate> templates;
  final ValueChanged<UserQrTemplate> onApply;
  final ValueChanged<UserQrTemplate> onDelete;
  final VoidCallback onSaveCurrent;   // "현재 설정 저장" 버튼

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('저장된 템플릿이 없습니다.'),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: templates.length,
      itemBuilder: (_, i) => _TemplateCard(
        template: templates[i],
        onApply: () => onApply(templates[i]),
        onDelete: () => onDelete(templates[i]),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _confirmDelete(context),
      child: Card(
        child: Column(
          children: [
            Expanded(
              child: template.thumbnailBytes != null
                  ? Image.memory(template.thumbnailBytes!, fit: BoxFit.cover)
                  : const Icon(Icons.qr_code, size: 60),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(template.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            TextButton(onPressed: onApply, child: const Text('적용')),
          ],
        ),
      ),
    );
  }
}
```

---

## 6. Repository

### 6.1 UserTemplateRepository

```dart
// lib/repositories/user_template_repository.dart

class UserTemplateRepository {
  static const _boxName = 'user_qr_templates';

  static Future<Box<UserQrTemplate>> _openBox() async =>
      Hive.isBoxOpen(_boxName)
          ? Hive.box<UserQrTemplate>(_boxName)
          : await Hive.openBox<UserQrTemplate>(_boxName);

  static Future<List<UserQrTemplate>> getAll() async {
    final box = await _openBox();
    return box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> save(UserQrTemplate template) async {
    final box = await _openBox();
    await box.put(template.id, template);
  }

  static Future<void> delete(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }
}
```

---

## 7. QrResultScreen 변경

### 7.1 탭 구조

```dart
// 기존 TabController(length: 3) → TabController(length: 5)
_tabController = TabController(length: 5, vsync: this);

// TabBar
TabBar(
  controller: _tabController,
  isScrollable: true,        // 5개 탭이므로 스크롤 가능
  tabs: const [
    Tab(text: '템플릿'),
    Tab(text: '배경'),
    Tab(text: 'QR'),
    Tab(text: '스티커'),
    Tab(text: '나의'),
  ],
),

// TabBarView
TabBarView(
  controller: _tabController,
  children: [
    AllTemplatesTab(...),     // index 0 — 기존 all_templates_tab 재사용
    BackgroundTab(),           // index 1 — 신규
    QrStyleTab(...),           // index 2 — 신규
    StickerTab(),              // index 3 — 신규
    MyTemplatesTab(            // index 4 — 신규
      templates: _myTemplates,
      onApply: _applyUserTemplate,
      onDelete: _deleteUserTemplate,
    ),
  ],
),
```

### 7.2 액션 버튼 변경

```dart
// 기존: 갤러리저장 / 공유 / 인쇄 / 저장
// 변경: 갤러리저장 / 템플릿저장 / 공유

Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    _ActionButton(
      icon: Icons.save_alt,
      label: '갤러리저장',
      onTap: () => ref.read(qrResultProvider.notifier).saveToGallery(label),
    ),
    _ActionButton(
      icon: Icons.bookmark_add,
      label: '템플릿저장',
      onTap: () => _showSaveTemplateSheet(context),
    ),
    _ActionButton(
      icon: Icons.share,
      label: '공유',
      onTap: () => ref.read(qrResultProvider.notifier).shareImage(label),
    ),
  ],
),
```

### 7.3 템플릿저장 바텀시트

```dart
void _showSaveTemplateSheet(BuildContext context) {
  final nameCtrl = TextEditingController();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24,
          MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('템플릿 이름', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: '예) 내 카페 QR')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveCurrentAsTemplate(nameCtrl.text.trim());
            },
            child: const Text('저장'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _saveCurrentAsTemplate(String name) async {
  if (name.isEmpty) return;
  final state = ref.read(qrResultProvider);
  final sticker = state.sticker;

  final template = UserQrTemplate(
    id: const Uuid().v4(),
    name: name,
    createdAt: DateTime.now(),
    backgroundImageBytes: state.background.imageBytes,
    backgroundScale: state.background.scale,
    qrColorValue: state.qrColor.value,
    gradientJson: state.customGradient != null
        ? jsonEncode(state.customGradient!.toJson())
        : null,
    roundFactor: state.roundFactor,
    eyeStyleIndex: state.eyeStyle.index,
    quietZoneColorValue: state.quietZoneColor.value,
    logoPositionIndex: sticker.logoPosition.index,
    logoBackgroundIndex: sticker.logoBackground.index,
    topTextContent: sticker.topText?.content,
    topTextColorValue: sticker.topText?.color.value,
    topTextFont: sticker.topText?.fontFamily,
    topTextSize: sticker.topText?.fontSize,
    bottomTextContent: sticker.bottomText?.content,
    bottomTextColorValue: sticker.bottomText?.color.value,
    bottomTextFont: sticker.bottomText?.fontFamily,
    bottomTextSize: sticker.bottomText?.fontSize,
    thumbnailBytes: ref.read(qrResultProvider).capturedImage,
  );

  await UserTemplateRepository.save(template);
  setState(() => _myTemplates.add(template));

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$name" 템플릿이 저장되었습니다.')),
    );
    // 나의 템플릿 탭으로 이동
    _tabController.animateTo(4);
  }
}
```

---

## 8. main.dart 변경

```dart
// UserQrTemplate Hive 어댑터 등록
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TagHistoryAdapter());   // typeId: 0 — 기존
  Hive.registerAdapter(UserQrTemplateAdapter()); // typeId: 1 — 신규
  // ...
}
```

---

## 9. pubspec.yaml 추가 패키지

```yaml
dependencies:
  image_picker: ^1.1.2        # 갤러리 이미지 선택
  image_cropper: ^8.0.2       # 자유 비율 crop (네이티브 UI)
  image: ^4.2.0               # 이미지 리사이즈·압축 (순수 Dart)
```

**Android 권한** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

**iOS Info.plist**:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>QR 배경 이미지로 사용할 사진을 선택합니다.</string>
```

---

## 10. 구현 순서

| 단계 | 작업 | 파일 |
|------|------|------|
| 1 | 데이터 모델 생성 + Hive 등록 | `background_config.dart`, `sticker_config.dart`, `user_qr_template.dart`, `main.dart` |
| 2 | QrResultState 확장 + setter 추가 | `qr_result_provider.dart` |
| 3 | QrLayerStack 위젯 구현 | `qr_layer_stack.dart` |
| 4 | QrPreviewSection → QrLayerStack 교체 | `qr_preview_section.dart` |
| 5 | BackgroundTab 구현 (패키지 설치 포함) | `background_tab.dart`, `pubspec.yaml` |
| 6 | QrStyleTab 구현 (customize_tab에서 추출) | `qr_style_tab.dart` |
| 7 | StickerTab 구현 | `sticker_tab.dart` |
| 8 | UserTemplateRepository 구현 | `user_template_repository.dart` |
| 9 | MyTemplatesTab 구현 | `my_templates_tab.dart` |
| 10 | QrResultScreen 탭 5개 + 액션버튼 교체 | `qr_result_screen.dart` |
| 11 | 추천 탭·꾸미기 탭 제거, 기존 탭 연결 정리 | `recommended_tab.dart` 삭제, `customize_tab.dart` 삭제 |
| 12 | 빌드 검증 + 플랫폼 권한 설정 | `AndroidManifest.xml`, `Info.plist` |

---

## 11. 성공 기준

| 기준 | 검증 방법 |
|------|-----------|
| 5탭 정상 전환 | 각 탭 이동 시 이전 탭 상태 유지 |
| 배경 이미지 crop → 미리보기 반영 | 갤러리 선택 → crop → QrLayerStack Layer 0에 즉시 표시 |
| 3레이어 합성 캡처 | 갤러리저장 이미지에 배경+QR+스티커 포함 확인 |
| 스티커 텍스트 전체 커스터마이징 | 내용·색상·폰트·크기 변경 시 미리보기 즉시 반영 |
| 나의 템플릿 저장·재사용 | 저장 후 앱 재시작해도 목록 유지, 적용 시 모든 레이어 복원 |
| 액션버튼 3개 | 갤러리저장/템플릿저장/공유만 표시 |
| 기존 회귀 없음 | deepLink 검증, QR 스캔, 공유 정상 동작 |
