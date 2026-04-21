import 'dart:typed_data';

import '../../../../core/error/result.dart';
import '../entities/logo_manifest.dart';

/// 번들된 로고 라이브러리(assets/logos/) 접근 인터페이스.
///
/// 구현체는 manifest.json 파싱 결과와 SVG → PNG 래스터화 결과를 캐시한다.
abstract class LogoManifestRepository {
  /// assets/logos/manifest.json 을 로드한다.
  /// 결과는 메모리에 캐시되어 반복 호출 시 즉시 반환.
  Future<Result<LogoManifest>> load();

  /// Composite id("social/twitter") 의 SVG 를 PNG bytes 로 래스터화한다.
  /// - [size] : 한 변 픽셀 (기본 96)
  /// - 결과는 LRU 캐시 (최대 32 개)
  Future<Result<Uint8List>> rasterize(String compositeId, {double size = 96});
}
