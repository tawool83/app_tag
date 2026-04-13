import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../../../models/qr_template.dart';
import '../qr_result_provider.dart' show QrResultState, qrResultProvider, QrEyeStyle;

/// 소형(160px) QR 미리보기 + 돋보기 확대 버튼.
/// RepaintBoundary를 포함하여 캡처 기준이 됩니다.
class QrPreviewSection extends ConsumerWidget {
  final GlobalKey repaintKey;
  final String deepLink;
  final String label;
  final String printTitle;

  const QrPreviewSection({
    super.key,
    required this.repaintKey,
    required this.deepLink,
    required this.label,
    required this.printTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qrResultProvider);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // 캡처 영역 (소형 QR)
            RepaintBoundary(
              key: repaintKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (printTitle.isNotEmpty) ...[
                      Text(
                        printTitle,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                    ],
                    buildPrettyQr(state, deepLink: deepLink, size: 160),
                    if (label.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // 돋보기 버튼 (우하단)
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _showZoomDialog(context, state),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.zoom_in, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          deepLink,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  void _showZoomDialog(BuildContext context, QrResultState state) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildPrettyQr(state, deepLink: deepLink, size: 300, isDialog: true),
              const SizedBox(height: 16),
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
}

/// QrResultState 기반 PrettyQrView 위젯 빌더.
/// QrPreviewSection과 확대 팝업에서 공용 사용.
Widget buildPrettyQr(
  QrResultState state, {
  required String deepLink,
  required double size,
  bool isDialog = false,
}) {
  final centerImage = _centerImageProvider(state);
  // 템플릿 그라디언트 우선, 없으면 사용자 커스텀 그라디언트
  final activeGradient = state.templateGradient ?? state.customGradient;
  final hasGradient = activeGradient != null;
  final ecLevel =
      centerImage != null ? QrErrorCorrectLevel.H : QrErrorCorrectLevel.M;
  final dotColor = hasGradient ? Colors.black : state.qrColor;

  final dotShape = PrettyQrSmoothSymbol(
    roundFactor: state.roundFactor,
    color: dotColor,
  );

  // eyeStyle에 따라 완전히 다른 symbol 타입으로 finder pattern 렌더링
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

  // ValueKey: decoration 관련 state가 변경될 때 위젯을 강제 재생성해
  // PrettyQrRenderView 내부 repaint boundary 이슈를 우회합니다.
  // isDialog: 팝업에서 같은 key 충돌 방지
  final qrKey = ValueKey(Object.hash(
    isDialog,
    deepLink,
    state.roundFactor,
    state.eyeStyle,
    state.qrColor,
    state.embedIcon,
    centerImage != null,
    state.templateGradient,
    state.customGradient,
    state.activeTemplateId,
  ));

  // 그라디언트 활성 시 아이콘을 ShaderMask 바깥으로 분리해야 함.
  // BlendMode.srcIn이 PrettyQrView 내부 이미지까지 그라디언트로 물들이기 때문.
  final useIconOverlay = hasGradient && centerImage != null;

  final qrWidget = PrettyQrView.data(
    key: qrKey,
    data: deepLink,
    errorCorrectLevel: ecLevel,
    decoration: PrettyQrDecoration(
      shape: qrShape,
      // 그라디언트+아이콘 조합 시 아이콘을 Stack으로 따로 올리므로 여기선 제외
      image: !useIconOverlay && centerImage != null
          ? PrettyQrDecorationImage(
              image: centerImage,
              position: PrettyQrDecorationImagePosition.embedded,
            )
          : null,
    ),
  );

  if (hasGradient) {
    Widget gradientQr = SizedBox(
      width: size,
      height: size,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => buildQrGradientShader(activeGradient!, bounds),
        child: qrWidget,
      ),
    );

    if (useIconOverlay) {
      // 아이콘을 흰 원형 배지로 중앙에 오버레이 (그라디언트 영향 없음)
      final iconSize = size * 0.22;
      gradientQr = Stack(
        alignment: Alignment.center,
        children: [
          gradientQr,
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 2),
              ],
            ),
            padding: EdgeInsets.all(iconSize * 0.08),
            child: ClipOval(
              child: Image(image: centerImage!, fit: BoxFit.contain),
            ),
          ),
        ],
      );
    }

    return gradientQr;
  }

  return SizedBox(width: size, height: size, child: qrWidget);
}

ImageProvider? _centerImageProvider(QrResultState state) {
  if (!state.embedIcon) return null;
  if (state.templateCenterIconBytes != null) {
    return MemoryImage(state.templateCenterIconBytes!);
  }
  if (state.emojiIconBytes != null) return MemoryImage(state.emojiIconBytes!);
  if (state.defaultIconBytes != null) return MemoryImage(state.defaultIconBytes!);
  return null;
}

/// 템플릿 썸네일에서도 공용 사용 가능한 그라디언트 셰이더 빌더.
Shader buildQrGradientShader(QrGradient gradient, Rect bounds) {
  final colors = gradient.colors;
  final stops = gradient.stops;

  if (gradient.type == 'radial') {
    return RadialGradient(
      colors: colors,
      stops: stops,
    ).createShader(bounds);
  }

  // linear (기본)
  final rad = gradient.angleDegrees * 3.14159 / 180;
  return LinearGradient(
    colors: colors,
    stops: stops,
    transform: GradientRotation(rad),
  ).createShader(bounds);
}
