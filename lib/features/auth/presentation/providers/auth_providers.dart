import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../../../core/di/supabase_config.dart';
import '../../../../core/error/result.dart';

import '../../data/datasources/supabase_auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

// ── DataSource / Repository Providers ──────────────────────────────────────

final supabaseAuthDataSourceProvider =
    Provider<SupabaseAuthDataSource?>((ref) {
  if (!isSupabaseConfigured) return null;
  return SupabaseAuthDataSource(Supabase.instance.client);
});

final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  final ds = ref.watch(supabaseAuthDataSourceProvider);
  if (ds == null) return null;
  return AuthRepositoryImpl(ds);
});

// ── Auth State ─────────────────────────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        errorMessage: errorMessage,
      );
}

// ── AuthNotifier ───────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository? _repo;
  StreamSubscription<AppUser?>? _authSub;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _init();
  }

  void _init() {
    if (_repo == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    // 현재 로그인 상태 확인
    final current = _repo.currentUser;
    if (current != null) {
      state = AuthState(status: AuthStatus.authenticated, user: current);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }

    // 인증 상태 변경 구독
    _authSub = _repo.onAuthStateChange.listen((user) {
      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  Future<void> signInWithGoogle() async {
    if (_repo == null) return;
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _repo.signInWithGoogle();
    result.fold(
      (user) =>
          state = AuthState(status: AuthStatus.authenticated, user: user),
      (failure) => state = AuthState(
          status: AuthStatus.error, errorMessage: failure.message),
    );
  }

  Future<void> signInWithApple() async {
    if (_repo == null) return;
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _repo.signInWithApple();
    result.fold(
      (user) =>
          state = AuthState(status: AuthStatus.authenticated, user: user),
      (failure) => state = AuthState(
          status: AuthStatus.error, errorMessage: failure.message),
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    if (_repo == null) return;
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _repo.signInWithEmail(email, password);
    result.fold(
      (user) =>
          state = AuthState(status: AuthStatus.authenticated, user: user),
      (failure) => state = AuthState(
          status: AuthStatus.error, errorMessage: failure.message),
    );
  }

  Future<void> signUpWithEmail(
      String email, String password, String nickname) async {
    if (_repo == null) return;
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _repo.signUpWithEmail(email, password, nickname);
    result.fold(
      (user) =>
          state = AuthState(status: AuthStatus.authenticated, user: user),
      (failure) => state = AuthState(
          status: AuthStatus.error, errorMessage: failure.message),
    );
  }

  Future<void> signOut() async {
    await _repo?.signOut();
  }

  Future<void> deleteAccount() async {
    if (_repo == null) return;
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _repo.deleteAccount();
    result.fold(
      (_) => state = const AuthState(status: AuthStatus.unauthenticated),
      (failure) => state = AuthState(
          status: AuthStatus.error, errorMessage: failure.message),
    );
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      state = state.copyWith(
        status: state.user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        errorMessage: null,
      );
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

/// 편의 접근: 현재 로그인 사용자 (null 가능).
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).user;
});
