import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart' show BuildContext, Colors;
import 'package:image/image.dart' as img_pkg;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/logo_source.dart';

/// 갤러리에서 이미지를 선택하고 정사각으로 크롭한 뒤 로고 소스로 변환.
///
/// 흐름:
///   1) [existingBytes] 가 주어지면 picker 단계를 건너뛰고 해당 bytes 를 임시 파일로
///      저장해 바로 cropper 에 전달 (Re-crop 시나리오).
///      없으면 image_picker 로 gallery 이미지 선택 (maxWidth 1024).
///   2) image_cropper 로 1:1 정사각 크롭 (전체화면 모달)
///   3) package:image 로 256×256 JPEG Q85 재인코딩 (JSON 저장 크기 최적화)
///   4) LogoSourceImage(croppedBytes) 반환
///
/// 사용자가 도중 취소 시 Success(null) 로 반환 (오류 아님).
class CropLogoImageUseCase {
  final ImagePicker _picker;
  final ImageCropper _cropper;

  CropLogoImageUseCase({ImagePicker? picker, ImageCropper? cropper})
      : _picker = picker ?? ImagePicker(),
        _cropper = cropper ?? ImageCropper();

  Future<Result<LogoSourceImage?>> call({
    required BuildContext context,
    Uint8List? existingBytes,
  }) async {
    try {
      // 1) 소스 경로 결정: Re-crop 이면 기존 bytes 를 temp 파일로, 아니면 gallery picker.
      final String sourcePath;
      if (existingBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tmpFile = File(
            '${tempDir.path}/relogo_${DateTime.now().millisecondsSinceEpoch}.png');
        await tmpFile.writeAsBytes(existingBytes, flush: true);
        sourcePath = tmpFile.path;
      } else {
        final xfile = await _picker.pickImage(
            source: ImageSource.gallery, maxWidth: 1024);
        if (xfile == null) return const Success(null);
        sourcePath = xfile.path;
      }

      // I1 fix: cropper는 무손실(PNG)로 중간 결과 받고, 최종 재인코딩에서만
      // Q85 JPEG 로 변환 → 이중 압축으로 인한 품질 손실 방지.
      final cropped = await _cropper.cropImage(
        sourcePath: sourcePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.png,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop',
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      if (cropped == null) return const Success(null);

      final rawBytes = await File(cropped.path).readAsBytes();
      final bytes = _reencodeToJpeg256(rawBytes);
      if (bytes == null) {
        return const Err(
            UnexpectedFailure('Failed to re-encode cropped logo image'));
      }
      return Success(LogoSourceImage(bytes));
    } catch (e, st) {
      return Err(UnexpectedFailure(
        'Failed to crop logo image: $e',
        cause: e,
        stackTrace: st,
      ));
    }
  }

  /// 원본 bytes → 256×256 JPEG Q85.
  /// 실패 시 null.
  Uint8List? _reencodeToJpeg256(Uint8List rawBytes) {
    final decoded = img_pkg.decodeImage(rawBytes);
    if (decoded == null) return null;
    final resized = img_pkg.copyResize(
      decoded,
      width: 256,
      height: 256,
      interpolation: img_pkg.Interpolation.linear,
    );
    final jpg = img_pkg.encodeJpg(resized, quality: 85);
    return Uint8List.fromList(jpg);
  }
}
