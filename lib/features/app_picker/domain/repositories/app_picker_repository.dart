import '../../../../core/error/result.dart';
import '../entities/app_info.dart';

abstract class AppPickerRepository {
  Future<Result<List<AppInfo>>> getInstalledApps();
}
