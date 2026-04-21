import 'dart:typed_data';

import '../../../../core/error/result.dart';
import '../entities/logo_source.dart';
import '../repositories/logo_manifest_repository.dart';

/// 로고 라이브러리에서 아이콘을 선택할 때의 처리:
///   1) 카테고리/아이콘 id 로 SVG 자산 확인
///   2) SVG → PNG 래스터화 (Repository 캐시 활용)
///   3) (LogoSourceLibrary source, Uint8List pngBytes) 반환
class LogoSelectionResult {
  final LogoSourceLibrary source;
  final Uint8List pngBytes;
  const LogoSelectionResult({required this.source, required this.pngBytes});
}

class SelectLogoAssetUseCase {
  final LogoManifestRepository _repo;

  const SelectLogoAssetUseCase(this._repo);

  Future<Result<LogoSelectionResult>> call({
    required String category,
    required String iconId,
  }) async {
    final compositeId = '$category/$iconId';
    final rasterRes = await _repo.rasterize(compositeId);
    return switch (rasterRes) {
      Success<Uint8List>(:final value) => Success(
          LogoSelectionResult(
            source: LogoSourceLibrary(
              assetId: compositeId,
              category: category,
              iconId: iconId,
            ),
            pngBytes: value,
          ),
        ),
      Err<Uint8List>(:final failure) => Err(failure),
    };
  }
}
