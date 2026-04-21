import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/sticker_config.dart' show StickerText;

/// 로고 영역(중앙/우하단)에 들어가는 텍스트를 PNG bytes 로 래스터화.
///
/// 탭 미리보기는 Widget 오버레이로 충분하지만, 저장/공유/인쇄 시 이미지 파이프라인이
/// 일관된 PNG 를 요구하는 경우에 사용 (옵션 기능).
class RasterizeTextLogoUseCase {
  const RasterizeTextLogoUseCase();

  Future<Result<Uint8List>> call(StickerText text, {double size = 96}) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 배경: 투명
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size, size),
        Paint()..color = const Color(0x00000000),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: text.content,
          style: TextStyle(
            color: text.color,
            fontFamily: text.fontFamily,
            fontSize: text.fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 2,
      )..layout(maxWidth: size);

      tp.paint(
        canvas,
        Offset((size - tp.width) / 2, (size - tp.height) / 2),
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return const Err(UnexpectedFailure('Failed to encode text logo PNG'));
      }
      return Success(byteData.buffer.asUint8List());
    } catch (e, st) {
      return Err(UnexpectedFailure(
        'Failed to rasterize text logo: $e',
        cause: e,
        stackTrace: st,
      ));
    }
  }
}
