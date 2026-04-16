import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/user_qr_template.dart';
import '../../domain/repositories/user_template_repository.dart';
import '../datasources/user_template_local_datasource.dart';
import '../models/user_qr_template_model.dart';

class UserTemplateRepositoryImpl implements UserTemplateRepository {
  final UserTemplateLocalDataSource _dataSource;
  const UserTemplateRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<UserQrTemplate>>> getAll() async {
    try {
      final models = _dataSource.readAll();
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e, st) {
      return Err(UnexpectedFailure('템플릿 로드 실패: $e',
          cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<UserQrTemplate?>> getById(String id) async {
    try {
      final model = _dataSource.readById(id);
      return Success(model?.toEntity());
    } catch (e, st) {
      return Err(UnexpectedFailure('템플릿 조회 실패: $e',
          cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<void>> save(UserQrTemplate template) async {
    try {
      await _dataSource.write(UserQrTemplateModel.fromEntity(template));
      return const Success(null);
    } catch (e, st) {
      return Err(UnexpectedFailure('템플릿 저장 실패: $e',
          cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _dataSource.delete(id);
      return const Success(null);
    } catch (e, st) {
      return Err(UnexpectedFailure('템플릿 삭제 실패: $e',
          cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<void>> clearAll() async {
    try {
      await _dataSource.clear();
      return const Success(null);
    } catch (e, st) {
      return Err(UnexpectedFailure('템플릿 전체 삭제 실패: $e',
          cause: e, stackTrace: st));
    }
  }
}
