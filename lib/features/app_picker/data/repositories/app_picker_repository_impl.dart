import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/app_info.dart';
import '../../domain/repositories/app_picker_repository.dart';
import '../datasources/app_list_datasource.dart';

class AppPickerRepositoryImpl implements AppPickerRepository {
  final AppListDataSource _dataSource;
  const AppPickerRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<AppInfo>>> getInstalledApps() async {
    try {
      final apps = await _dataSource.getInstalledApps();
      return Success(apps);
    } catch (e, st) {
      return Err(UnexpectedFailure('Failed to load app list: $e',
          cause: e, stackTrace: st));
    }
  }
}
