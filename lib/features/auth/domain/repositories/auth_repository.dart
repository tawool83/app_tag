import '../../../../core/error/result.dart';
import '../entities/app_user.dart';

abstract class AuthRepository {
  /// 현재 로그인 사용자 (없으면 null).
  AppUser? get currentUser;

  /// 인증 상태 변경 스트림.
  Stream<AppUser?> get onAuthStateChange;

  Future<Result<AppUser>> signInWithGoogle();
  Future<Result<AppUser>> signInWithApple();
  Future<Result<AppUser>> signInWithEmail(String email, String password);
  Future<Result<AppUser>> signUpWithEmail(
      String email, String password, String nickname);
  Future<Result<void>> signOut();
  Future<Result<void>> deleteAccount();
}
