import '../../../../core/error/result.dart';
import '../repositories/qr_output_repository.dart';

class SaveQrAsSvgUseCase {
  final QrOutputRepository _repository;
  const SaveQrAsSvgUseCase(this._repository);

  Future<Result<String>> call(String svgString, String appName) =>
      _repository.saveAsSvg(svgString, appName);
}
