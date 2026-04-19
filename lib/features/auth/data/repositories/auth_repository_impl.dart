import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/supabase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseAuthDataSource _dataSource;
  const AuthRepositoryImpl(this._dataSource);

  @override
  AppUser? get currentUser => _dataSource.currentUser;

  @override
  Stream<AppUser?> get onAuthStateChange => _dataSource.onAuthStateChange;

  @override
  Future<Result<AppUser>> signInWithGoogle() async {
    try {
      await _dataSource.signInWithGoogle();
      final user = _dataSource.currentUser;
      if (user == null) return const Err(AuthFailure('Google 로그인 실패'));
      return Success(user);
    } on AuthException catch (e) {
      return Err(AuthFailure('Google 로그인 실패: ${e.message}',
          code: e.statusCode));
    } catch (e) {
      return Err(AuthFailure('Google 로그인 실패: $e'));
    }
  }

  @override
  Future<Result<AppUser>> signInWithApple() async {
    try {
      await _dataSource.signInWithApple();
      final user = _dataSource.currentUser;
      if (user == null) return const Err(AuthFailure('Apple 로그인 실패'));
      return Success(user);
    } on AuthException catch (e) {
      return Err(AuthFailure('Apple 로그인 실패: ${e.message}',
          code: e.statusCode));
    } catch (e) {
      return Err(AuthFailure('Apple 로그인 실패: $e'));
    }
  }

  @override
  Future<Result<AppUser>> signInWithEmail(String email, String password) async {
    try {
      await _dataSource.signInWithEmail(email, password);
      final user = _dataSource.currentUser;
      if (user == null) return const Err(AuthFailure('이메일 로그인 실패'));
      return Success(user);
    } on AuthException catch (e) {
      return Err(AuthFailure('이메일 로그인 실패: ${e.message}',
          code: e.statusCode));
    } catch (e) {
      return Err(AuthFailure('이메일 로그인 실패: $e'));
    }
  }

  @override
  Future<Result<AppUser>> signUpWithEmail(
      String email, String password, String nickname) async {
    try {
      await _dataSource.signUpWithEmail(email, password, nickname);
      final user = _dataSource.currentUser;
      if (user == null) return const Err(AuthFailure('회원가입 실패'));
      return Success(user);
    } on AuthException catch (e) {
      return Err(AuthFailure('회원가입 실패: ${e.message}',
          code: e.statusCode));
    } catch (e) {
      return Err(AuthFailure('회원가입 실패: $e'));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Success(null);
    } catch (e) {
      return Err(AuthFailure('로그아웃 실패: $e'));
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      await _dataSource.deleteAccount();
      return const Success(null);
    } catch (e) {
      return Err(AuthFailure('계정 삭제 실패: $e'));
    }
  }
}
