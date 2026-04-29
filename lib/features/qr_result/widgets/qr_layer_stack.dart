import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr/qr.dart';
import '../domain/entities/color_target_mode.dart';
import '../domain/entities/logo_source.dart' show LogoType;
import '../domain/entities/qr_dot_style.dart' show QrDotStyleToParams;
import '../domain/entities/qr_eye_shapes.dart' show eyeEnumsToParams;
import '../domain/entities/quiet_zone_border_style.dart';
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
/// quiet-zone 테두리 두께 슬라이더의 최대값 (style_setters.dart 의 `width.clamp(1.0, 4.0)` 와 일치).
/// 외각에 이만큼의 reserve 영역을 항상 확보 → 두께 조절 시 quiet zone 영역 절대 불변.
const double _kMaxBorderWidth = 4.0;

class QrLayerStack extends ConsumerStatefulWidget {
  final String deepLink;
  final double size;

  const QrLayerStack({
    super.key,
    required this.deepLink,
    this.size = 160,
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

    // quiet zone 테두리선 — QR 사양상의 quiet-zone 경계 시각화.
    // 외각 모양(boundaryParams.type) 과 무관하게 항상 직사각형으로 그려짐.
    final borderEnabled = state.style.quietZoneBorderEnabled;
    final borderColor = state.style.bgColor ?? state.style.qrColor;
    final borderWidth = state.style.quietZoneBorderWidth;
    final borderStyle = state.style.quietZoneBorderStyle;

    // 렌더링 순서 (안쪽 → 바깥): QR → quiet zone → 테두리 → 배경.
    //   - QR 스펙 4 모듈 quiet zone 보장 (12% 비율, V5 기준 ≈ 4.4 모듈, CLAUDE.md §5).
    //   - 테두리: 안쪽 가장자리 = quiet zone 외곽(고정), 외곽 가장자리 = 두께만큼 *바깥(배경 방향)* 확장.
    //   - 두께 조절 시 quiet zone 절대 불변 — 슬라이더 max(=4.0) 만큼의 reserve 영역을 미리 외곽에 확보.
    final quietPadding = (widget.size * 0.12).clamp(12.0, 32.0);
    final borderReserve = borderEnabled ? _kMaxBorderWidth : 0.0;
    final contentInset = quietPadding + borderReserve;
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
          // quiet zone 테두리선 — 안쪽 가장자리 = quiet zone 외곽(고정), 외곽 가장자리 = 두께만큼 바깥 확장.
          // Padding 으로 painter 영역을 (kMaxBorderWidth - borderWidth) 만큼 inset →
          //   stroke 외곽이 widget.size 외곽으로부터 (kMaxBorderWidth - borderWidth) 안쪽에 위치.
          //   stroke 안쪽 가장자리는 항상 (widget.size 외곽 - kMaxBorderWidth) 위치 = quiet zone 외곽 (고정).
          // 두께 max(=4) → 외곽이 widget.size 외곽 닿음. 두께 < max → 외곽 너머 배경 영역 (quietZoneColor).
          if (borderEnabled)
            Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.all(_kMaxBorderWidth - borderWidth),
                  child: CustomPaint(
                    painter: _QuietZoneBorderPainter(
                      color: borderColor,
                      width: borderWidth,
                      style: borderStyle,
                    ),
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
    // QR 스펙 4 모듈 quiet zone 보장 — 12% 비율 + min 8 / max 24 px (frame 안쪽 영역이라 일반 모드보다 작게).
    final quietPadding = (qrAreaSize * 0.12).clamp(8.0, 24.0);
    // border reserve: 슬라이더 max(=4) 만큼 외부 여백 항상 확보 → 두께 조절 시 quiet zone 절대 불변.
    final borderReserve =
        state.style.quietZoneBorderEnabled ? _kMaxBorderWidth : 0.0;
    final innerInset = quietPadding + borderReserve;
    final effectiveQrSize = qrAreaSize - innerInset * 2;

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
            // Layer 1: QR 코드 (정사각형, 중앙). padding = quiet zone + border reserve.
            Container(
              width: qrAreaSize,
              height: qrAreaSize,
              color: state.style.quietZoneColor,
              padding: EdgeInsets.all(innerInset),
              child: qrWidget,
            ),
            // QR 레이어 플래시 (QR 영역만)
            if (_shouldFlash(ColorTargetMode.qrOnly))
              SizedBox(
                width: qrAreaSize,
                height: qrAreaSize,
                child: _buildFlashOverlay(ColorTargetMode.qrOnly),
              ),
            // Layer 1.5: quiet zone 테두리선 — 외각(frame) 모양과 별개로 동작.
            // 안쪽 가장자리 = quiet zone 외곽(고정), 외곽 가장자리 = 두께만큼 바깥(qrAreaSize 외곽 방향) 확장.
            // SizedBox(qrAreaSize) 위에 Padding(_kMaxBorderWidth - currentWidth) 으로 painter 영역 inset.
            // 두께 max → 외곽이 qrAreaSize 외곽 닿음. 두께 < max → 외곽 너머 quietZoneColor 영역.
            if (state.style.quietZoneBorderEnabled)
              IgnorePointer(
                child: SizedBox(
                  width: qrAreaSize,
                  height: qrAreaSize,
                  child: Padding(
                    padding: EdgeInsets.all(
                      _kMaxBorderWidth - state.style.quietZoneBorderWidth,
                    ),
                    child: CustomPaint(
                      painter: _QuietZoneBorderPainter(
                        color: state.style.bgColor ?? state.style.qrColor,
                        width: state.style.quietZoneBorderWidth,
                        style: state.style.quietZoneBorderStyle,
                      ),
                    ),
                  ),
                ),
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
                        padding: EdgeInsets.all(innerInset),
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
                        padding: EdgeInsets.all(innerInset),
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

// ── Quiet-zone 테두리선 painter ──────────────────────────────────────────────
//
// QR 사양상의 quiet-zone 경계를 시각적으로 표시한다.
// 외각 모양(boundaryParams.type) 과 무관하게 항상 직사각형.
// dashed/dotted 는 사각형 4변 각각 line drawing 으로 처리 (PathMetric 미사용).
class _QuietZoneBorderPainter extends CustomPainter {
  final Color color;
  final double width;
  final QuietZoneBorderStyle style;

  const _QuietZoneBorderPainter({
    required this.color,
    required this.width,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // stroke 가 path 양쪽으로 그려지므로 width/2 inset 으로 외부 cropping 방지.
    final rect = Rect.fromLTWH(
      width / 2, width / 2,
      size.width - width, size.height - width,
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..isAntiAlias = true;

    switch (style) {
      case QuietZoneBorderStyle.solid:
        canvas.drawRect(rect, paint);
      case QuietZoneBorderStyle.dashed:
        paint.strokeCap = StrokeCap.butt;
        _drawDashedRect(canvas, rect, paint,
            dashLength: width * 4, gapLength: width * 2);
      case QuietZoneBorderStyle.dotted:
        paint.strokeCap = StrokeCap.round;
        _drawDashedRect(canvas, rect, paint,
            dashLength: width, gapLength: width * 2);
    }
  }

  void _drawDashedRect(Canvas canvas, Rect r, Paint paint,
      {required double dashLength, required double gapLength}) {
    _drawDashedLine(canvas, r.topLeft, r.topRight, paint, dashLength, gapLength);
    _drawDashedLine(canvas, r.topRight, r.bottomRight, paint, dashLength, gapLength);
    _drawDashedLine(canvas, r.bottomRight, r.bottomLeft, paint, dashLength, gapLength);
    _drawDashedLine(canvas, r.bottomLeft, r.topLeft, paint, dashLength, gapLength);
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint,
      double dashLength, double gapLength) {
    final total = (b - a).distance;
    if (total <= 0) return;
    final dir = (b - a) / total;
    double drawn = 0;
    while (drawn < total) {
      final segLen = min(dashLength, total - drawn);
      final start = a + dir * drawn;
      final end = a + dir * (drawn + segLen);
      canvas.drawLine(start, end, paint);
      drawn += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(_QuietZoneBorderPainter old) =>
      color != old.color || width != old.width || style != old.style;
}
