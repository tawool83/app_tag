import '../../../../core/error/result.dart';
import '../entities/app_info.dart';
import '../repositories/app_picker_repository.dart';

class GetInstalledAppsUseCase {
  final AppPickerRepository _repository;
  const GetInstalledAppsUseCase(this._repository);

  Future<Result<List<AppInfo>>> call() => _repository.getInstalledApps();
}
