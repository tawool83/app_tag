import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/supabase_profile_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final SupabaseProfileDataSource _dataSource;
  const ProfileRepositoryImpl(this._dataSource);

  @override
  Future<Result<Map<String, dynamic>>> getProfile(String userId) async {
    try {
      final data = await _dataSource.getProfile(userId);
      return Success(data);
    } catch (e) {
      return Err(NetworkFailure('프로필 조회 실패: $e'));
    }
  }

  @override
  Future<Result<void>> updateProfile(String userId,
      {String? nickname, String? avatarUrl}) async {
    try {
      await _dataSource.updateProfile(userId,
          nickname: nickname, avatarUrl: avatarUrl);
      return const Success(null);
    } catch (e) {
      return Err(NetworkFailure('프로필 수정 실패: $e'));
    }
  }
}
