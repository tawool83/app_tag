/// 인증된 사용자 정보. Supabase auth.users 매핑.
class AppUser {
  final String id;
  final String email;
  final String? nickname;
  final String? avatarUrl;
  final String provider; // 'google' | 'apple' | 'email'
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    this.nickname,
    this.avatarUrl,
    required this.provider,
    required this.createdAt,
  });

  AppUser copyWith({
    String? nickname,
    String? avatarUrl,
  }) =>
      AppUser(
        id: id,
        email: email,
        nickname: nickname ?? this.nickname,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        provider: provider,
        createdAt: createdAt,
      );
}
