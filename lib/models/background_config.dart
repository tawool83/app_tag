import 'dart:typed_data';
import 'package:flutter/material.dart';

const _bgSentinel = Object();

/// QR 배경 레이어 설정 (최하단 레이어).
/// 이미지가 없으면 흰 배경으로 렌더링됩니다.
class BackgroundConfig {
  final Uint8List? imageBytes; // null = 흰 배경
  final double scale;          // 1.0 ~ 3.0 (이미지 줌)
  final BoxFit fit;
  final double alignX;         // -1.0 ~ 1.0 (가로 위치)
  final double alignY;         // -1.0 ~ 1.0 (세로 위치)

  const BackgroundConfig({
    this.imageBytes,
    this.scale = 1.0,
    this.fit = BoxFit.cover,
    this.alignX = 0.0,
    this.alignY = 0.0,
  });

  bool get hasImage => imageBytes != null;

  BackgroundConfig copyWith({
    Object? imageBytes = _bgSentinel,
    double? scale,
    BoxFit? fit,
    double? alignX,
    double? alignY,
  }) =>
      BackgroundConfig(
        imageBytes: imageBytes == _bgSentinel
            ? this.imageBytes
            : imageBytes as Uint8List?,
        scale: scale ?? this.scale,
        fit: fit ?? this.fit,
        alignX: alignX ?? this.alignX,
        alignY: alignY ?? this.alignY,
      );
}
