import '../../../../core/error/result.dart';
import '../entities/user_qr_template.dart';

abstract class UserTemplateRepository {
  Future<Result<List<UserQrTemplate>>> getAll();
  Future<Result<UserQrTemplate?>> getById(String id);
  Future<Result<void>> save(UserQrTemplate template);
  Future<Result<void>> delete(String id);
  Future<Result<void>> clearAll();
}
