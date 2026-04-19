import '../../../../core/error/result.dart';

abstract class ProfileRepository {
  Future<Result<Map<String, dynamic>>> getProfile(String userId);
  Future<Result<void>> updateProfile(String userId,
      {String? nickname, String? avatarUrl});
}
