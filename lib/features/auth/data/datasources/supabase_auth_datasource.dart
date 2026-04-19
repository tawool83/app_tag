import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';

class SupabaseAuthDataSource {
  final SupabaseClient _client;
  const SupabaseAuthDataSource(this._client);

  User? get _currentUser => _client.auth.currentUser;

  AppUser? get currentUser {
    final u = _currentUser;
    if (u == null) return null;
    return _mapUser(u);
  }

  Stream<AppUser?> get onAuthStateChange =>
      _client.auth.onAuthStateChange.map((event) {
        final u = event.session?.user;
        return u != null ? _mapUser(u) : null;
      });

  // ── Google Sign-In (google_sign_in v7) ──────────────────────────────────

  Future<AuthResponse> signInWithGoogle() async {
    const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID',
        defaultValue: '');
    const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID',
        defaultValue: '');

    final gsi = GoogleSignIn.instance;
    await gsi.initialize(
      clientId: iosClientId.isNotEmpty ? iosClientId : null,
      serverClientId: webClientId.isNotEmpty ? webClientId : null,
    );

    final account = await gsi.authenticate();
    final idToken = account.authentication.idToken;

    if (idToken == null) {
      throw const AuthException('Google ID 토큰을 가져올 수 없습니다.');
    }

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  // ── Apple Sign-In ───────────────────────────────────────────────────────

  Future<AuthResponse> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException('Apple ID 토큰을 가져올 수 없습니다.');
    }

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  // ── Email Sign-In / Sign-Up ─────────────────────────────────────────────

  Future<AuthResponse> signInWithEmail(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUpWithEmail(
          String email, String password, String nickname) =>
      _client.auth.signUp(
        email: email,
        password: password,
        data: {'nickname': nickname},
      );

  // ── Sign-Out / Delete ───────────────────────────────────────────────────

  Future<void> signOut() => _client.auth.signOut();

  /// 계정 삭제. Supabase Edge Function 또는 서비스 키 필요 시 별도 구현.
  /// 현재는 RPC 호출 방식.
  Future<void> deleteAccount() async {
    final userId = _currentUser?.id;
    if (userId == null) throw const AuthException('로그인 상태가 아닙니다.');
    // Supabase에서 사용자 삭제는 service_role 권한 필요.
    // Edge Function 'delete-user' 호출 또는 RPC 사용.
    await _client.rpc('delete_user');
    await _client.auth.signOut();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  AppUser _mapUser(User u) {
    final provider = u.appMetadata['provider'] as String? ?? 'email';
    final meta = u.userMetadata ?? {};
    return AppUser(
      id: u.id,
      email: u.email ?? '',
      nickname: meta['nickname'] as String? ??
          meta['full_name'] as String? ??
          meta['name'] as String?,
      avatarUrl: meta['avatar_url'] as String? ??
          meta['picture'] as String?,
      provider: provider,
      createdAt: DateTime.tryParse(u.createdAt) ?? DateTime.now(),
    );
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }
}
