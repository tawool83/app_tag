import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr/qr.dart';
import '../domain/entities/color_target_mode.dart';
import '../domain/entities/logo_source.dart' show LogoType;
import '../domain/entities/qr_dot_style.dart' show QrDotStyleToParams;
import '../domain/entities/qr_eye_shapes.dart' show eyeEnumsToParams;
import '../domain/entities/sticker_config.dart';
import '../qr_result_provider.dart';
import '../utils/logo_clear_zone.dart';
import 'custom_qr_painter.dart';
import 'decorative_frame_painter.dart';
import 'qr_preview_section.dart' show buildPrettyQr, centerImageProvider, buildQrGradientShader;

/// QR 결과 화면의 레이어 렌더링 위젯.
///
/// 렌더링 순서 (아래 → 위):
///   Layer 0: 흰 배경 (qr 배경 이미지 기능은 제거됨)
///   Layer 1: QrLayer          — 콰이어트 존 + CustomQrPainter (size×size, 중앙)
///   Layer 2: StickerLayer     — 로고 + 상/하단 텍스트
///
/// customDotParams 또는 customEyeParams가 설정된 경우 CustomQrPainter를 사용하고,
/// 그렇지 않으면 기존 buildPrettyQr()로 폴백합니다.
class QrLayerStack extends ConsumerStatefulWidget {
  final String deepLink;
  final double size;
  final bool isDialog;

  const QrLayerStack({
    super.key,
    required this.deepLink,
    this.size = 160,
    this.isDialog = false,
  });

  @override
  ConsumerState<QrLayerStack> createState() => _QrLayerStackState();
}

class _QrLayerStackState extends ConsumerState<QrLayerStack>
    with TickerProviderStateMixin {
  AnimationController? _animController;

  // ── 레이어 강조 플래시 ──
  late final AnimationController _flashController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  ColorTargetMode? _flashTarget;

  // (deepLink, ecLevel, minTypeNumber) 키가 같을 때 QrImage 재사용 — 애니메이션 중 parent rebuild 로
  // 60fps 재계산되던 QrCode.fromData() 를 제거해 매 프레임 비용을 0 에 가깝게 낮춘다.
  String? _cachedDeepLink;
  int? _cachedEcLevel;
  int? _cachedMinTypeNumber;
  QrImage? _cachedQrImage;

  /// [minTypeNumber] 가 지정되면 자동 산출된 typeNumber 가 그보다 작을 때
  /// 강제로 minTypeNumber 로 재생성. 띠 사용 시 V5 강제 (finder/timing 보호).
  QrImage _qrImageFor(String deepLink, int ecLevel, {int minTypeNumber = 1}) {
    if (_cachedDeepLink == deepLink &&
        _cachedEcLevel == ecLevel &&
        _cachedMinTypeNumber == minTypeNumber &&
        _cachedQrImage != null) {
      return _cachedQrImage!;
    }
    var qrCode = QrCode.fromData(data: deepLink, errorCorrectLevel: ecLevel);
    if (qrCode.typeNumber < minTypeNumber) {
      qrCode = QrCode(minTypeNumber, ecLevel)..addData(deepLink);
    }
    final img = QrImage(qrCode);
    _cachedDeepLink = deepLink;
    _cachedEcLevel = ecLevel;
    _cachedMinTypeNumber = minTypeNumber;
    _cachedQrImage = img;
    return img;
  }

  @override
  void dispose() {
    _animController?.dispose();
    _flashController.dispose();
    super.dispose();
  }

  void _ensureAnimController(bool needsAnim) {
    if (needsAnim && _animController == null) {
      _animController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat();
    } else if (!needsAnim && _animController != null) {
      _animController!.dispose();
      _animController = null;
    }
  }

  /// CustomQrPainter를 사용할지 여부 판단.
  ///
  /// 로고가 QR 중앙에 embed 되는 경우에도 CustomQrPainter 를 사용한다.
  /// PrettyQrView 의 PrettyQrDecorationImage(embedded) 는 이미지 포맷(JPEG 등)에
  /// 따라 clear 영역이 일관되지 않을 수 있으므로, 자체 clearZone 로직으로 통일.
  bool _useCustomPainter(QrResultState state) {
    final hasEmbeddedLogo = state.logo.embedIcon &&
        centerImageProvider(state) != null &&
        state.sticker.logoPosition == LogoPosition.center;
    final hasBand = _hasBand(state.sticker);
    // 사각/원형 텍스트 — ClearZone 필요 (🚫 모드는 ClearZone 없음)
    final hasTextClearZone = _hasTextClearZone(state.sticker);
    return hasEmbeddedLogo ||
        hasBand ||
        hasTextClearZone ||
        state.style.customEyeParams != null ||
        !state.style.boundaryParams.isDefault ||
        state.style.animationParams.isAnimated;
  }

  void _triggerFlash(ColorTargetMode mode) {
    _flashTarget = mode;
    _flashController.forward(from: 0);
  }

  /// 특정 레이어에 대해 플래시가 활성 상태인지 판단.
  bool _shouldFlash(ColorTargetMode layer) {
    if (_flashTarget == null) return false;
    if (_flashTarget == ColorTargetMode.both) return true;
    return _flashTarget == layer;
  }

  Widget _buildFlashOverlay(ColorTargetMode layer) {
    if (!_shouldFlash(layer)) return const SizedBox.shrink();
    return FadeTransition(
      opacity: Tween<double>(begin: 0.25, end: 0.0).animate(
        CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
      ),
      child: Container(
        color: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 색상 대상 모드 변경 감지 → 플래시 트리거
    ref.listen<ColorTargetMode>(colorTargetModeProvider, (prev, next) {
      if (prev != next) _triggerFlash(next);
    });

    final state = ref.watch(qrResultProvider);
    final sticker = state.sticker;
    final iconProvider = centerImageProvider(state);
    final isTextLogo = state.logo.embedIcon && sticker.logoType == LogoType.text;
    final useCustom = _useCustomPainter(state);
    final isFrameMode = state.style.boundaryParams.isFrameMode;

    _ensureAnimController(state.style.animationParams.isAnimated);

    // ── 프레임 모드: 별도 렌더링 경로 ──
    if (isFrameMode) {
      return _buildFrameLayout(state, sticker, iconProvider, isTextLogo);
    }

    // quiet zone 테두리선
    final borderEnabled = state.style.quietZoneBorderEnabled;
    final borderColor = state.style.bgColor ?? state.style.qrColor;
    final borderWidth = state.style.quietZoneBorderWidth;
    // 테두리는 안쪽으로 그려지므로, quiet zone 보존을 위해 borderInset 만큼 추가 여백
    final borderInset = borderEnabled ? borderWidth : 0.0;

    // 콰이어트 존 패딩: QR 크기의 5% (최소 8px, 최대 20px)
    final quietPadding = (widget.size * 0.05).clamp(8.0, 20.0);
    // 내부 콘텐츠 총 여백 = 테두리 두께 + quiet zone
    final contentInset = quietPadding + borderInset;
    final qrSize = widget.size - contentInset * 2;

    // ── QR 렌더링 위젯 결정 ──
    final Widget qrWidget;
    if (useCustom) {
      qrWidget = _buildCustomQr(state, qrSize);
    } else {
      qrWidget = buildPrettyQr(
        state,
        deepLink: widget.deepLink,
        size: qrSize,
        isDialog: widget.isDialog,
      );
    }

    // band 모드 판정
    final hasBand = _hasBand(sticker);

    final bgColor = state.style.quietZoneColor == Colors.transparent
        ? null
        : state.style.quietZoneColor;

    // ── Layer 구조: Column(상단텍스트 → QR 정사각 → 하단텍스트) ─────────
    // 상/하단 텍스트는 QR 바깥에 배치. 배경 Container 가 전체를 감쌈.
    final Widget qrSquare = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // QR 코드 + quiet zone (테두리 안쪽에 배치)
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(contentInset),
              child: qrWidget,
            ),
          ),
          // QR 레이어 플래시
          if (_shouldFlash(ColorTargetMode.qrOnly))
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(contentInset),
                child: _buildFlashOverlay(ColorTargetMode.qrOnly),
              ),
            ),
          // 로고 (logo/image 유형)
          if (iconProvider != null)
            _LogoWidget(
              sticker: sticker,
              iconProvider: iconProvider,
              size: widget.size,
            )
          // 중앙 텍스트 — 사각/원형 배경
          else if (isTextLogo && !hasBand &&
              sticker.logoBackground != LogoBackground.none &&
              sticker.logoText != null && !sticker.logoText!.isEmpty)
            _LogoWidget.text(
              sticker: sticker,
              size: widget.size,
            ),
          // 중앙 텍스트 (band 모드) — quiet zone 안쪽에 배치
          if (hasBand)
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(contentInset),
                child: Center(
                  child: _BandTextWidget(
                    text: sticker.logoText!,
                    qrSize: qrSize,
                    bandMode: sticker.bandMode,
                    evenSpacing: sticker.centerTextEvenSpacing,
                    bgColor: sticker.logoBackgroundColor,
                  ),
                ),
              ),
            ),
          // 🚫 모드: 배경 없는 가로 텍스트 오버레이 — quiet zone 안쪽
          if (_hasNoneTextOverlay(sticker))
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(contentInset),
                child: Center(
                  child: _NoneTextWidget(
                    text: sticker.logoText!,
                    qrSize: qrSize,
                  ),
                ),
              ),
            ),
          // quiet zone 테두리선 — QR 콘텐츠와 같은 z-level (최상위 레이어)
          if (borderEnabled)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor, width: borderWidth),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return AnimatedBuilder(
      animation: _flashController,
      builder: (_, __) => Stack(
        children: [
          Container(
            color: bgColor,
            child: qrSquare,
          ),
          // 배경 레이어 플래시 (전체 영역 — 텍스트 포함)
          if (_shouldFlash(ColorTargetMode.bgOnly))
            Positioned.fill(
              child: _buildFlashOverlay(ColorTargetMode.bgOnly),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomQr(QrResultState state, double qrSize) {
    final sticker = state.sticker;
    final hasBand = _hasBand(sticker);
    final hasTextCZ = _hasTextClearZone(sticker);

    // QR 매트릭스 생성 — 로고가 QR 위에 겹칠 때 error correction H 강제
    final hasLogo = state.logo.embedIcon &&
        centerImageProvider(state) != null;
    final embedCenter = hasLogo &&
        sticker.logoPosition == LogoPosition.center;
    final ecLevel =
        (hasLogo || hasBand || hasTextCZ)
            ? QrErrorCorrectLevel.H
            : QrErrorCorrectLevel.M;
    // 띠 사용 시 V5(37×37) 강제 — 짧은 데이터로 작은 QR 생성 시
    // 띠가 finder/timing pattern 침범하는 사고 방지.
    final minTypeNumber = hasBand ? 5 : 1;
    final qrImage = _qrImageFor(widget.deepLink, ecLevel, minTypeNumber: minTypeNumber);

    // 중앙 로고/이미지/텍스트(사각/원형) 뒤 QR 도트를 비울 영역
    // bottomRight 는 도트 비움 불필요 (EC H 로만 보호)
    final clearZone = computeLogoClearZone(
      qrSize: Size.square(qrSize),
      iconSize: widget.size * 0.22,
      sticker: sticker,
      embedIcon: embedCenter || hasTextCZ,
    );

    // band ClearZone (🚫 모드는 ClearZone 없이 단순 오버레이)
    // 배경색 alpha < 1.0 → QR 도트 유지 (반투명 배경 위로 도트가 비침)
    ClearZone? bandCZ;
    final bandBgAlpha = sticker.logoBackgroundColor?.a ?? 1.0;
    if (hasBand && bandBgAlpha >= 1.0) {
      bandCZ = computeBandClearZone(
        qrSize: Size.square(qrSize),
        bandMode: sticker.bandMode,
        fontSize: sticker.logoText!.fontSize *
            (widget.size * 0.22 / _LogoWidget._kRefIconSize),
      );
    }

    // 그라디언트 셰이더
    final activeGradient = state.template.templateGradient ?? state.style.customGradient;
    final color = activeGradient != null ? Colors.black : state.style.qrColor;

    // 애니메이션이 있으면 AnimatedBuilder로 감싸기
    Widget painterWidget;
    if (_animController != null) {
      painterWidget = AnimatedBuilder(
        animation: _animController!,
        builder: (_, __) => CustomPaint(
          size: Size.square(qrSize),
          painter: CustomQrPainter(
            qrImage: qrImage,
            color: color,
            dotParams: state.style.customDotParams ?? state.style.dotStyle.toDotShapeParams(),
            eyeParams: state.style.customEyeParams ?? eyeEnumsToParams(state.style.eyeOuter, state.style.eyeInner),
            boundaryParams: state.style.boundaryParams,
            animParams: state.style.animationParams,
            animValue: _animController!.value,
            clearZone: clearZone,
            bandClearZone: bandCZ,
          ),
        ),
      );
    } else {
      painterWidget = CustomPaint(
        size: Size.square(qrSize),
        painter: CustomQrPainter(
          qrImage: qrImage,
          color: color,
          dotParams: state.style.customDotParams ?? state.style.dotStyle.toDotShapeParams(),
          eyeParams: state.style.customEyeParams ?? eyeEnumsToParams(state.style.eyeOuter, state.style.eyeInner),
          boundaryParams: state.style.boundaryParams,
          animParams: state.style.animationParams,
          clearZone: clearZone,
          bandClearZone: bandCZ,
        ),
      );
    }

    // 그라디언트 적용
    if (activeGradient != null) {
      return SizedBox(
        width: qrSize,
        height: qrSize,
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) =>
              buildQrGradientShader(activeGradient, bounds),
          child: painterWidget,
        ),
      );
    }

    return SizedBox(width: qrSize, height: qrSize, child: painterWidget);
  }

  // ── 프레임 모드 렌더링 ──────────────────────────────────────────────
  Widget _buildFrameLayout(
    QrResultState state,
    StickerConfig sticker,
    ImageProvider? iconProvider,
    bool isTextLogo,
  ) {
    final totalSize = widget.size;
    final frameScale = state.style.boundaryParams.frameScale;
    final qrAreaSize = totalSize / frameScale;
    final quietPadding = (qrAreaSize * 0.05).clamp(4.0, 12.0);
    final effectiveQrSize = qrAreaSize - quietPadding * 2;

    final qrPainter = _buildFrameQrPainter(state, effectiveQrSize);

    final activeGradient =
        state.template.templateGradient ?? state.style.customGradient;
    final frameBounds = Rect.fromLTWH(0, 0, totalSize, totalSize);

    // ── QR 도트 색상/그라디언트 ──
    Widget qrWidget = qrPainter;
    if (activeGradient != null) {
      qrWidget = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) =>
            buildQrGradientShader(activeGradient, bounds),
        child: qrPainter,
      );
    }

    // ── 배경(패턴·테두리) 색상/그라디언트 ──
    // bgColor/bgGradient 가 설정되면 배경 독립 색상, 아니면 QR 색상 따라감
    final bgGradient = state.style.bgGradient
        ?? (state.style.bgColor != null ? null : activeGradient);
    final patternColor = state.style.bgColor ?? state.style.qrColor;
    final Shader? bgShader = bgGradient != null
        ? buildQrGradientShader(bgGradient, frameBounds)
        : null;

    final Widget frameAndQr = AnimatedBuilder(
      animation: _flashController,
      builder: (_, __) => SizedBox(
        width: totalSize,
        height: totalSize,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.hardEdge,
          children: [
            // Layer 0: 장식 프레임 + 마진 패턴
            CustomPaint(
              size: Size.square(totalSize),
              painter: DecorativeFramePainter(
                boundaryParams: state.style.boundaryParams,
                qrAreaSize: qrAreaSize,
                frameColor: state.style.quietZoneColor,
                patternColor: patternColor,
                patternShader: bgShader,
                borderColor: patternColor,
                borderShader: bgShader,
                dotParams: state.style.customDotParams ??
                    state.style.dotStyle.toDotShapeParams(),
              ),
            ),
            // 배경 레이어 플래시 (프레임 영역)
            if (_shouldFlash(ColorTargetMode.bgOnly))
              Positioned.fill(
                child: _buildFlashOverlay(ColorTargetMode.bgOnly),
              ),
            // Layer 1: QR 코드 (정사각형, 중앙)
            Container(
              width: qrAreaSize,
              height: qrAreaSize,
              color: state.style.quietZoneColor,
              padding: EdgeInsets.all(quietPadding),
              child: qrWidget,
            ),
            // QR 레이어 플래시 (QR 영역만)
            if (_shouldFlash(ColorTargetMode.qrOnly))
              SizedBox(
                width: qrAreaSize,
                height: qrAreaSize,
                child: _buildFlashOverlay(ColorTargetMode.qrOnly),
              ),
            // Layer 2: 로고/중앙 텍스트 (QR 영역 내)
            SizedBox(
              width: qrAreaSize,
              height: qrAreaSize,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // 로고 (logo/image 유형)
                  if (iconProvider != null)
                    _LogoWidget(
                      sticker: sticker,
                      iconProvider: iconProvider,
                      size: qrAreaSize,
                    )
                  // 중앙 텍스트 — 사각/원형 배경
                  else if (isTextLogo && !_hasBand(sticker) &&
                      sticker.logoBackground != LogoBackground.none &&
                      sticker.logoText != null &&
                      !sticker.logoText!.isEmpty)
                    _LogoWidget.text(
                      sticker: sticker,
                      size: qrAreaSize,
                    ),
                  // 중앙 텍스트 (band 모드) — quiet zone 안쪽에 배치
                  if (_hasBand(sticker))
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.all(quietPadding),
                        child: Center(
                          child: _BandTextWidget(
                            text: sticker.logoText!,
                            qrSize: effectiveQrSize,
                            bandMode: sticker.bandMode,
                            evenSpacing: sticker.centerTextEvenSpacing,
                            bgColor: sticker.logoBackgroundColor,
                          ),
                        ),
                      ),
                    ),
                  // 🚫 모드: 배경 없는 가로 텍스트 오버레이 — quiet zone 안쪽
                  if (_hasNoneTextOverlay(sticker))
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.all(quietPadding),
                        child: Center(
                          child: _NoneTextWidget(
                            text: sticker.logoText!,
                            qrSize: effectiveQrSize,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return frameAndQr;
  }

  static bool _hasBand(StickerConfig sticker) =>
      sticker.bandMode != BandMode.none &&
      sticker.logoType == LogoType.text &&
      sticker.logoText != null &&
      !sticker.logoText!.isEmpty;

  /// 🚫 모드 텍스트 오버레이: bandMode==none, logoBackground==none, 텍스트 있음
  static bool _hasNoneTextOverlay(StickerConfig sticker) =>
      sticker.bandMode == BandMode.none &&
      sticker.logoBackground == LogoBackground.none &&
      sticker.logoType == LogoType.text &&
      sticker.logoText != null &&
      !sticker.logoText!.isEmpty;

  /// 텍스트+사각/원형 배경: ClearZone 필요 (🚫 모드는 ClearZone 없음)
  static bool _hasTextClearZone(StickerConfig sticker) =>
      sticker.logoType == LogoType.text &&
      sticker.logoText != null &&
      !sticker.logoText!.isEmpty &&
      sticker.bandMode == BandMode.none &&
      (sticker.logoBackground == LogoBackground.square ||
       sticker.logoBackground == LogoBackground.circle);

  Widget _buildFrameQrPainter(QrResultState state, double qrSize) {
    final sticker = state.sticker;
    final hasBand = _hasBand(sticker);
    final hasTextCZ = _hasTextClearZone(sticker);

    final hasLogo = state.logo.embedIcon &&
        centerImageProvider(state) != null;
    final embedCenter = hasLogo &&
        sticker.logoPosition == LogoPosition.center;
    final ecLevel =
        (hasLogo || hasBand || hasTextCZ)
            ? QrErrorCorrectLevel.H
            : QrErrorCorrectLevel.M;
    // 띠 사용 시 V5 강제 — _buildCustomQr 와 동일 정책.
    final minTypeNumber = hasBand ? 5 : 1;
    final qrImage = _qrImageFor(widget.deepLink, ecLevel, minTypeNumber: minTypeNumber);

    final qrAreaSize = widget.size / state.style.boundaryParams.frameScale;
    final clearZone = computeLogoClearZone(
      qrSize: Size.square(qrSize),
      iconSize: qrAreaSize * 0.22,
      sticker: sticker,
      embedIcon: embedCenter || hasTextCZ,
    );

    ClearZone? bandCZ;
    final bandBgAlpha2 = sticker.logoBackgroundColor?.a ?? 1.0;
    if (hasBand && bandBgAlpha2 >= 1.0) {
      bandCZ = computeBandClearZone(
        qrSize: Size.square(qrSize),
        bandMode: sticker.bandMode,
        fontSize: sticker.logoText!.fontSize *
            (qrAreaSize * 0.22 / _LogoWidget._kRefIconSize),
      );
    }

    final activeGradient =
        state.template.templateGradient ?? state.style.customGradient;
    final color = activeGradient != null ? Colors.black : state.style.qrColor;

    Widget painterWidget;
    if (_animController != null) {
      painterWidget = AnimatedBuilder(
        animation: _animController!,
        builder: (_, __) => CustomPaint(
          size: Size.square(qrSize),
          painter: CustomQrPainter(
            qrImage: qrImage,
            color: color,
            dotParams: state.style.customDotParams ??
                state.style.dotStyle.toDotShapeParams(),
            eyeParams:
                state.style.customEyeParams ?? eyeEnumsToParams(state.style.eyeOuter, state.style.eyeInner),
            boundaryParams: state.style.boundaryParams,
            animParams: state.style.animationParams,
            animValue: _animController!.value,
            clearZone: clearZone,
            bandClearZone: bandCZ,
          ),
        ),
      );
    } else {
      painterWidget = CustomPaint(
        size: Size.square(qrSize),
        painter: CustomQrPainter(
          qrImage: qrImage,
          color: color,
          dotParams: state.style.customDotParams ??
              state.style.dotStyle.toDotShapeParams(),
          eyeParams:
              state.style.customEyeParams ?? eyeEnumsToParams(state.style.eyeOuter, state.style.eyeInner),
          boundaryParams: state.style.boundaryParams,
          animParams: state.style.animationParams,
          clearZone: clearZone,
          bandClearZone: bandCZ,
        ),
      );
    }

    return SizedBox(width: qrSize, height: qrSize, child: painterWidget);
  }
}


// ── 중앙 텍스트 띠(band) 위젯 ──────────────────────────────────────────────────

class _BandTextWidget extends StatelessWidget {
  final StickerText text;
  final double qrSize;
  final BandMode bandMode;
  final bool evenSpacing;
  final Color? bgColor;

  const _BandTextWidget({
    required this.text,
    required this.qrSize,
    required this.bandMode,
    this.evenSpacing = false,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    // 띠 두께 max 12% (이전 15% → burst error capacity 안쪽 + finder 보호)
    final maxBandDim = qrSize * 0.12;
    final availWidth = qrSize * 0.8;
    final availHeight = qrSize * 0.8;
    final n = text.content.length.clamp(1, 999);

    // 자동 피팅: 띠 영역 + 글자수로 최적 fontSize 계산
    final double autoFontSize;
    if (bandMode == BandMode.horizontal) {
      final byHeight = maxBandDim * 0.85;
      final byWidth = availWidth / n / 0.6;
      autoFontSize = min(byHeight, byWidth).clamp(4.0, 200.0);
    } else {
      final byWidth = maxBandDim * 0.85;
      final byHeight = availHeight / n / 1.2;
      autoFontSize = min(byWidth, byHeight).clamp(4.0, 200.0);
    }

    final style = TextStyle(
      color: text.color,
      fontSize: autoFontSize,
      fontWeight: FontWeight.w600,
      height: 1.0,
    );

    Widget content;
    if (bandMode == BandMode.vertical) {
      content = _buildVertical(style, availHeight, maxBandDim);
    } else {
      content = _buildHorizontal(style, availWidth, maxBandDim);
    }

    if (bgColor != null) {
      // 배경은 QR 전체 너비/높이로 채움 (텍스트는 내부 80% 영역에 배치)
      final w = bandMode == BandMode.vertical ? maxBandDim : qrSize;
      final h = bandMode == BandMode.vertical ? qrSize : maxBandDim;
      return Container(
        width: w,
        height: h,
        color: bgColor,
        child: Center(child: content),
      );
    }
    return content;
  }

  Widget _buildHorizontal(TextStyle style, double availWidth, double maxBandDim) {
    if (evenSpacing && text.content.length > 1) {
      final gap = availWidth / text.content.length;
      return SizedBox(
        width: availWidth,
        height: maxBandDim,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: text.content.characters.map((char) {
            return SizedBox(
              width: gap,
              child: Center(child: Text(char, style: style)),
            );
          }).toList(),
        ),
      );
    }

    return SizedBox(
      width: availWidth,
      height: maxBandDim,
      child: Center(
        child: Text(text.content, maxLines: 1, style: style),
      ),
    );
  }

  Widget _buildVertical(TextStyle style, double availHeight, double maxBandDim) {
    if (evenSpacing && text.content.length > 1) {
      final gap = availHeight / text.content.length;
      return SizedBox(
        width: maxBandDim,
        height: availHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: text.content.characters.map((char) {
            return SizedBox(
              height: gap,
              child: Center(child: Text(char, style: style)),
            );
          }).toList(),
        ),
      );
    }

    final charHeight = availHeight / text.content.length.clamp(1, 999);
    return SizedBox(
      width: maxBandDim,
      height: availHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: text.content.characters.map((char) {
          return SizedBox(
            height: charHeight,
            child: Center(child: Text(char, style: style)),
          );
        }).toList(),
      ),
    );
  }
}

// ── 🚫 모드 텍스트 (배경 없는 가로 오버레이, max 12%) ──────────────────────────

class _NoneTextWidget extends StatelessWidget {
  final StickerText text;
  final double qrSize;

  const _NoneTextWidget({
    required this.text,
    required this.qrSize,
  });

  @override
  Widget build(BuildContext context) {
    final maxFontSize = qrSize * 0.12;
    final availWidth = qrSize * 0.8;
    final n = text.content.length.clamp(1, 999);

    // 자동 피팅: max 12% 높이, 글자수 기반 너비 제한
    final byHeight = maxFontSize;
    final byWidth = availWidth / n / 0.6;
    final autoFontSize = min(byHeight, byWidth).clamp(4.0, 200.0);

    final style = TextStyle(
      color: text.color,
      fontSize: autoFontSize,
      fontWeight: FontWeight.w600,
      height: 1.0,
    );

    return SizedBox(
      width: availWidth,
      height: maxFontSize * 1.4,
      child: Center(
        child: Text(text.content, maxLines: 1, style: style),
      ),
    );
  }
}

// ── 로고 위젯 ──────────────────────────────────────────────────────────────────

class _LogoWidget extends StatelessWidget {
  final StickerConfig sticker;
  final ImageProvider? iconProvider;
  final double size;
  final bool isText;

  const _LogoWidget({
    required this.sticker,
    required this.iconProvider,
    required this.size,
  }) : isText = false;

  const _LogoWidget.text({
    required this.sticker,
    required this.size,
  })  : iconProvider = null,
        isText = true;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.22;
    final Widget iconWidget = _buildIconWithBackground(iconSize);

    if (sticker.logoPosition == LogoPosition.center) {
      return Positioned.fill(child: Center(child: iconWidget));
    } else {
      return Positioned(
        right: 8,
        bottom: 8,
        child: iconWidget,
      );
    }
  }

  /// 아이콘(이미지 or 텍스트) 컨텐츠 빌드.
  /// [wrapWidth] == true 이면 텍스트 폭에 맞춰 Intrinsic 으로 렌더 (rectangle 배경용).
  ///
  /// 텍스트 fontSize 는 기본 미리보기(QR size=160) 기준 절대값이므로,
  /// 확대보기/다른 크기에서는 iconSize 비례로 스케일링하여 비율을 유지한다.
  static const _kRefIconSize = 160.0 * 0.22; // 35.2 — 기본 미리보기 아이콘 크기

  Widget _buildContent(double iconSize, {bool wrapWidth = false}) {
    if (isText) {
      final t = sticker.logoText!;
      final scale = iconSize / _kRefIconSize;
      final hasBg = sticker.logoBackground == LogoBackground.square ||
          sticker.logoBackground == LogoBackground.circle;

      // 사각/원형 배경: 글자수 기반 자동 피팅
      final double fontSize;
      if (hasBg) {
        final n = t.content.length.clamp(1, 999);
        final byWidth = iconSize / n / 0.65;
        final byHeight = iconSize * 0.85;
        fontSize = min(byWidth, byHeight).clamp(4.0, 200.0);
      } else {
        fontSize = t.fontSize * scale;
      }

      final textStyle = TextStyle(
        color: t.color,
        fontFamily: t.fontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        height: 1.1,
      );
      if (wrapWidth) {
        // rectangle / roundedRectangle: 폭은 텍스트 자연 크기, height는 텍스트 기준.
        return Text(
          t.content,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        );
      }
      return SizedBox(
        width: iconSize,
        height: iconSize,
        child: Center(
          child: Text(
            t.content,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      );
    }
    return ClipOval(
      child: Image(
        image: iconProvider!,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildIconWithBackground(double iconSize) {
    // 로고 배경 fill 색상. null = 기본 흰색 (레거시 호환).
    final bgColor = sticker.logoBackgroundColor ?? Colors.white;
    // 반투명 배경일 때 그림자 비활성화 (그림자가 배경보다 진하게 보이는 문제 방지)
    final shadow = bgColor.a < 1.0
        ? null
        : const BoxShadow(color: Colors.black12, blurRadius: 2);

    switch (sticker.logoBackground) {
      case LogoBackground.none:
        return SizedBox(
          width: iconSize,
          height: iconSize,
          child: _buildContent(iconSize),
        );
      case LogoBackground.square:
        return Container(
          width: iconSize + 8,
          height: iconSize + 8,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            boxShadow: shadow != null ? [shadow] : null,
          ),
          padding: const EdgeInsets.all(4),
          child: _buildContent(iconSize),
        );
      case LogoBackground.circle:
        return Container(
          width: iconSize + 8,
          height: iconSize + 8,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: shadow != null ? [shadow] : null,
          ),
          padding: const EdgeInsets.all(4),
          child: _buildContent(iconSize),
        );
      case LogoBackground.rectangle:
      case LogoBackground.roundedRectangle:
        // 텍스트 폭에 맞추는 직사각형 배경.
        // 비-텍스트 타입에도 정의는 유효 (iconSize × iconSize+padding 기본 사각으로 렌더).
        final radius = sticker.logoBackground == LogoBackground.roundedRectangle
            ? 14.0
            : 4.0;
        // QR 가독성 보호: 로고 영역이 너무 커지지 않도록 maxWidth 제한 (QR 60%)
        final maxW = size * 0.6;
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: shadow != null ? [shadow] : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: isText
                ? _buildContent(iconSize, wrapWidth: true)
                : SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: _buildContent(iconSize),
                  ),
          ),
        );
    }
  }
}
