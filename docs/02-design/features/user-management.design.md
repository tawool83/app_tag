# Design: user-management

## Executive Summary

| Item | Detail |
|------|--------|
| Feature | user-management (사용자 관리 및 클라우드 동기화) |
| Plan Reference | `docs/01-plan/features/user-management.plan.md` |
| Design Created | 2026-04-17 |
| Architecture | Clean Architecture + Offline-First Sync |

### Value Delivered

| Perspective | Description |
|-------------|-------------|
| **Problem** | 앱 재설치/기기 변경 시 템플릿, 색상 등 개인화 데이터 전부 소실. Android↔iOS 간 이동 불가 |
| **Solution** | Supabase Auth 크로스플랫폼 계정 + 클라우드 DB 양방향 동기화 |
| **Function UX Effect** | 한 번 로그인하면 어떤 기기에서든 나의 템플릿/색상이 자동 복원 |
| **Core Value** | "내 스타일은 어디서든 나를 따라온다" — 플랫폼 무관 데이터 영속성 |

---

## 1. Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                       Presentation Layer                         │
│                                                                  │
│  LoginScreen  SignUpScreen  ProfileScreen  SettingsScreen(수정)   │
│       │            │            │               │                │
│       └────────────┴────────────┴───────────────┘                │
│                         │ Riverpod                               │
│                   AuthNotifier  SyncNotifier                     │
├──────────────────────────────────────────────────────────────────┤
│                        Domain Layer                              │
│                                                                  │
│  Entities:  AppUser │ UserColorPalette                           │
│  UseCases:  SignInWithGoogle │ SignInWithApple │ SignInWithEmail  │
│             SignUpWithEmail │ SignOut │ DeleteAccount             │
│             GetCurrentUser │ UpdateProfile                       │
│             SyncTemplates │ SyncPalettes                         │
│  Repos(I):  AuthRepository │ ProfileRepository                  │
│             TemplateSyncRepository │ PaletteSyncRepository       │
├──────────────────────────────────────────────────────────────────┤
│                         Data Layer                               │
│                                                                  │
│  ┌─────────────────────┐     ┌──────────────────────────┐       │
│  │  Local DataSources   │     │  Remote DataSources       │       │
│  │  (Hive — 기존 유지)   │     │  (Supabase)               │       │
│  │  HiveUserTemplate    │     │  SupabaseAuthDataSource   │       │
│  │  HiveColorPalette    │     │  SupabaseProfileDataSource│       │
│  │  (new)               │     │  SupabaseTemplateDS       │       │
│  └──────────┬──────────┘     │  SupabasePaletteDS        │       │
│             │                 └──────────┬───────────────┘       │
│             └────────┬──────────────────┘                        │
│                      │                                           │
│              SyncEngine (last-write-wins)                        │
├──────────────────────────────────────────────────────────────────┤
│                      Infrastructure                              │
│  SupabaseService (기존) │ Hive (기존) │ SharedPreferences (기존)  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2. Domain Entities

### 2.1 AppUser (신규)

```dart
// lib/features/auth/domain/entities/app_user.dart

/// 인증된 사용자 정보. Supabase auth.users 매핑.
class AppUser {
  final String id;            // Supabase auth UID
  final String email;
  final String? nickname;
  final String? avatarUrl;
  final String provider;      // 'google' | 'apple' | 'email'
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    this.nickname,
    this.avatarUrl,
    required this.provider,
    required this.createdAt,
  });
}
```

### 2.2 UserColorPalette (신규)

```dart
// lib/features/color_palette/domain/entities/user_color_palette.dart

/// 사용자 저장 색상 팔레트 (단색 또는 그라디언트).
class UserColorPalette {
  final String id;             // UUID (로컬 생성)
  final String name;
  final PaletteType type;      // solid | gradient
  final int? solidColorArgb;   // type == solid일 때
  final List<int>? gradientColorArgbs; // type == gradient일 때 ARGB int 리스트
  final List<double>? gradientStops;
  final String? gradientType;  // 'linear' | 'radial'
  final int? gradientAngle;    // linear일 때 각도
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 동기화 메타
  final String? remoteId;      // Supabase UUID (null = 미동기화)
  final bool syncedToCloud;

  const UserColorPalette({
    required this.id,
    required this.name,
    required this.type,
    this.solidColorArgb,
    this.gradientColorArgbs,
    this.gradientStops,
    this.gradientType,
    this.gradientAngle,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.remoteId,
    this.syncedToCloud = false,
  });
}

enum PaletteType { solid, gradient }
```

### 2.3 UserQrTemplate 확장 (기존 수정)

기존 `UserQrTemplate` 엔티티에 `updatedAt` 필드 추가 (동기화 충돌 해결용):

```dart
// lib/features/qr_result/domain/entities/user_qr_template.dart — 추가 필드
final DateTime updatedAt;  // 마지막 수정 시간 (last-write-wins 기준)
```

기존 `UserQrTemplateModel` Hive 모델에 HiveField 추가:
```dart
@HiveField(29)
DateTime updatedAt;  // 신규 필드 — 기존 데이터는 createdAt 으로 폴백
```

---

## 3. Supabase Database Schema

### 3.1 테이블 정의

```sql
-- ========================================
-- 1. profiles
-- ========================================
CREATE TABLE public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nickname    TEXT,
  avatar_url  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 신규 유저 생성 시 자동 프로필 행 삽입
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, nickname)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.raw_user_meta_data ->> 'name', split_part(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ========================================
-- 2. user_templates
-- ========================================
CREATE TABLE public.user_templates (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  local_id         TEXT NOT NULL,
  name             TEXT NOT NULL,
  template_data    JSONB NOT NULL,
  thumbnail_base64 TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at       TIMESTAMPTZ,           -- soft delete
  UNIQUE(user_id, local_id)
);

CREATE INDEX idx_user_templates_user ON public.user_templates(user_id);
CREATE INDEX idx_user_templates_updated ON public.user_templates(user_id, updated_at);

-- ========================================
-- 3. user_color_palettes
-- ========================================
CREATE TABLE public.user_color_palettes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  type        TEXT NOT NULL CHECK (type IN ('solid', 'gradient')),
  color_data  JSONB NOT NULL,
  sort_order  INT NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at  TIMESTAMPTZ           -- soft delete
);

CREATE INDEX idx_user_palettes_user ON public.user_color_palettes(user_id);

-- ========================================
-- 4. RLS Policies
-- ========================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_color_palettes ENABLE ROW LEVEL SECURITY;

-- profiles: 자기 프로필만 조회/수정
CREATE POLICY "profiles_select_own" ON public.profiles
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- user_templates: 자기 템플릿만 CRUD
CREATE POLICY "templates_all_own" ON public.user_templates
  FOR ALL USING (auth.uid() = user_id);

-- user_color_palettes: 자기 팔레트만 CRUD
CREATE POLICY "palettes_all_own" ON public.user_color_palettes
  FOR ALL USING (auth.uid() = user_id);
```

### 3.2 template_data JSONB 구조

`UserQrTemplateModel`의 전체 스타일 필드를 JSONB로 직렬화:

```json
{
  "qrColorValue": 4278190080,
  "gradientJson": null,
  "roundFactor": 0.5,
  "dotStyleIndex": 1,
  "eyeOuterIndex": 2,
  "eyeInnerIndex": 0,
  "randomEyeSeed": null,
  "quietZoneColorValue": 4294967295,
  "logoPositionIndex": 0,
  "logoBackgroundIndex": 0,
  "topTextContent": "My QR",
  "topTextColorValue": 4278190080,
  "topTextFont": "sans-serif",
  "topTextSize": 14.0,
  "bottomTextContent": null,
  "bottomTextColorValue": null,
  "bottomTextFont": null,
  "bottomTextSize": null
}
```

> **Note**: `backgroundImageBytes`는 크기가 클 수 있어 JSONB에 포함하지 않음. Phase 2에서 Supabase Storage 사용.

### 3.3 color_data JSONB 구조

```json
// solid
{ "argb": 4278190335 }

// gradient
{
  "colors": [4278190335, 4294901760],
  "stops": [0.0, 1.0],
  "type": "linear",
  "angle": 45
}
```

---

## 4. Data Layer — DataSources

### 4.1 SupabaseAuthDataSource (신규)

```dart
// lib/features/auth/data/datasources/supabase_auth_datasource.dart

abstract class AuthRemoteDataSource {
  Future<AuthResponse> signInWithGoogle();
  Future<AuthResponse> signInWithApple();
  Future<AuthResponse> signInWithEmail(String email, String password);
  Future<AuthResponse> signUpWithEmail(String email, String password);
  Future<void> signOut();
  Future<void> deleteAccount();
  User? get currentUser;
  Stream<AuthState> get onAuthStateChange;
}
```

구현체: `SupabaseAuthDataSource`
- Google: `supabase.auth.signInWithOAuth(OAuthProvider.google)` (모바일은 `google_sign_in` 패키지로 idToken 취득 → `signInWithIdToken`)
- Apple: `sign_in_with_apple` 패키지로 credential 취득 → `supabase.auth.signInWithIdToken(provider: OAuthProvider.apple, idToken: ...)`
- Email: `supabase.auth.signUp()` / `supabase.auth.signInWithPassword()`

### 4.2 SupabaseProfileDataSource (신규)

```dart
// lib/features/profile/data/datasources/supabase_profile_datasource.dart

abstract class ProfileRemoteDataSource {
  Future<Map<String, dynamic>> getProfile(String userId);
  Future<void> updateProfile(String userId, {String? nickname, String? avatarUrl});
}
```

구현체: Supabase `from('profiles').select() / .update()`

### 4.3 SupabaseTemplateDataSource (신규)

```dart
// lib/features/sync/data/datasources/supabase_template_datasource.dart

abstract class TemplateRemoteDataSource {
  /// 서버에서 user의 모든 템플릿 조회 (soft-delete 포함).
  Future<List<Map<String, dynamic>>> fetchAll(String userId);

  /// updated_at > since 인 템플릿만 조회 (delta sync).
  Future<List<Map<String, dynamic>>> fetchUpdatedSince(String userId, DateTime since);

  /// 단일 템플릿 upsert (local_id 기준).
  Future<Map<String, dynamic>> upsert(String userId, Map<String, dynamic> data);

  /// soft delete (deleted_at 설정).
  Future<void> softDelete(String userId, String localId);
}
```

구현체: Supabase `from('user_templates')` 쿼리.

### 4.4 SupabasePaletteDataSource (신규)

`SupabaseTemplateDataSource`와 동일 패턴, `user_color_palettes` 테이블 대상.

### 4.5 HiveColorPaletteDataSource (신규)

```dart
// lib/features/color_palette/data/datasources/hive_color_palette_datasource.dart

// 기존 HiveUserTemplateDataSource 패턴 동일
// Box<UserColorPaletteModel> 기반 CRUD
// HiveType(typeId: 2)
```

---

## 5. Data Layer — Repositories

### 5.1 AuthRepositoryImpl

```dart
// lib/features/auth/data/repositories/auth_repository_impl.dart

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;

  @override
  Future<Result<AppUser>> signInWithGoogle() async {
    try {
      final response = await _remote.signInWithGoogle();
      return Success(_mapUser(response.user!, 'google'));
    } on AuthException catch (e) {
      return Err(NetworkFailure('Google 로그인 실패: ${e.message}'));
    }
  }
  // ... signInWithApple, signInWithEmail, signUp, signOut, deleteAccount 동일 패턴
}
```

### 5.2 TemplateSyncRepositoryImpl

```dart
// lib/features/sync/data/repositories/sync_repository_impl.dart

class TemplateSyncRepositoryImpl implements TemplateSyncRepository {
  final UserTemplateLocalDataSource _local;    // 기존 Hive
  final TemplateRemoteDataSource _remote;      // Supabase

  @override
  Future<Result<SyncResult>> syncAll(String userId) async {
    // 1. Remote에서 전체 fetch (또는 delta)
    // 2. Local 목록과 비교
    // 3. 충돌 해결 (last-write-wins)
    // 4. Local 업데이트 + Remote 업데이트
    // 5. SyncResult 반환 (pulled, pushed, conflicts)
  }
}
```

---

## 6. Sync Engine

### 6.1 동기화 흐름 상세

```
┌─────────────────────────────────────────────────────────┐
│                    SyncEngine.sync()                      │
├─────────────────────────────────────────────────────────┤
│ Step 1: Pull                                             │
│   remote.fetchUpdatedSince(lastSyncedAt)                │
│   ↓                                                      │
│   각 remote 레코드에 대해:                                │
│   ├─ local에 없음 → local에 삽입                         │
│   ├─ local에 있고 remote.updated > local.updated         │
│   │  → local 덮어쓰기                                    │
│   └─ local에 있고 local.updated >= remote.updated        │
│      → skip (push에서 처리)                              │
├─────────────────────────────────────────────────────────┤
│ Step 2: Push                                             │
│   local에서 syncedToCloud == false 인 레코드 조회        │
│   ↓                                                      │
│   각 local 레코드에 대해:                                │
│   ├─ remote에 없음 (remoteId == null)                   │
│   │  → remote.upsert() → remoteId 설정                  │
│   └─ remote에 있고 local.updated > remote.updated       │
│      → remote.upsert() 덮어쓰기                         │
├─────────────────────────────────────────────────────────┤
│ Step 3: Soft-Delete 처리                                 │
│   remote에서 deleted_at != null 인 레코드               │
│   → local에서도 삭제                                     │
│   local에서 삭제된 항목 (Hive에서 제거됨)               │
│   → remote.softDelete()                                  │
├─────────────────────────────────────────────────────────┤
│ Step 4: lastSyncedAt 갱신                                │
│   SharedPreferences에 'last_sync_templates' 저장         │
└─────────────────────────────────────────────────────────┘
```

### 6.2 SyncResult 모델

```dart
// lib/features/sync/data/engine/sync_engine.dart

class SyncResult {
  final int pulled;      // 서버→로컬 반영 건수
  final int pushed;      // 로컬→서버 반영 건수
  final int deleted;     // 양방향 삭제 건수
  final int conflicts;   // LWW로 해결된 충돌 건수
  final List<String> errors;

  const SyncResult({
    this.pulled = 0,
    this.pushed = 0,
    this.deleted = 0,
    this.conflicts = 0,
    this.errors = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
}
```

### 6.3 동기화 트리거

| Trigger | Action | 비고 |
|---------|--------|------|
| 앱 시작 (로그인 상태) | Full sync | `lastSyncedAt` 이후 delta |
| 템플릿 저장/삭제 | Immediate push | 해당 레코드만 |
| 팔레트 저장/삭제 | Immediate push | 해당 레코드만 |
| 설정 > 수동 동기화 | Full sync | 사용자 트리거 |
| 포그라운드 복귀 (>5분) | Delta sync | `lastSyncedAt` 비교 |

---

## 7. Presentation Layer — State Management

### 7.1 AuthNotifier

```dart
// lib/features/auth/presentation/providers/auth_providers.dart

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;
  const AuthState({this.status = AuthStatus.initial, this.user, this.errorMessage});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;
  final ProfileRepository _profileRepo;
  StreamSubscription? _authSub;

  AuthNotifier(this._authRepo, this._profileRepo) : super(const AuthState()) {
    _listenAuthState();
  }

  void _listenAuthState() {
    _authSub = _authRepo.onAuthStateChange.listen((event) {
      // AuthChangeEvent.signedIn → fetch profile → AuthStatus.authenticated
      // AuthChangeEvent.signedOut → AuthStatus.unauthenticated
    });
  }

  Future<void> signInWithGoogle() async { ... }
  Future<void> signInWithApple() async { ... }
  Future<void> signInWithEmail(String email, String password) async { ... }
  Future<void> signUpWithEmail(String email, String password, String nickname) async { ... }
  Future<void> signOut() async { ... }
  Future<void> deleteAccount() async { ... }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(profileRepositoryProvider),
  );
});
```

### 7.2 SyncNotifier

```dart
// lib/features/sync/presentation/providers/sync_providers.dart

enum SyncStatus { idle, syncing, synced, error }

class SyncState {
  final SyncStatus templateSync;
  final SyncStatus paletteSync;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
}

class SyncNotifier extends StateNotifier<SyncState> {
  final TemplateSyncRepository _templateSync;
  final PaletteSyncRepository _paletteSync;

  /// 앱 시작 시 또는 수동 트리거 시 호출
  Future<void> syncAll(String userId) async {
    state = state.copyWith(templateSync: SyncStatus.syncing);
    final result = await _templateSync.syncAll(userId);
    result.fold(
      (r) => state = state.copyWith(
        templateSync: SyncStatus.synced,
        lastSyncedAt: DateTime.now(),
      ),
      (f) => state = state.copyWith(
        templateSync: SyncStatus.error,
        errorMessage: f.message,
      ),
    );
    // palette sync 동일
  }

  /// 단일 템플릿 즉시 push
  Future<void> pushTemplate(String userId, UserQrTemplate template) async { ... }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(
    ref.watch(templateSyncRepositoryProvider),
    ref.watch(paletteSyncRepositoryProvider),
  );
});
```

### 7.3 Provider 의존성 그래프

```
authProvider
  ├── authRepositoryProvider
  │     └── supabaseAuthDataSourceProvider
  └── profileRepositoryProvider
        └── supabaseProfileDataSourceProvider

syncProvider
  ├── templateSyncRepositoryProvider
  │     ├── hiveUserTemplateDataSourceProvider  (기존)
  │     └── supabaseTemplateDataSourceProvider
  └── paletteSyncRepositoryProvider
        ├── hiveColorPaletteDataSourceProvider  (신규)
        └── supabasePaletteDataSourceProvider
```

---

## 8. UI Design

### 8.1 Navigation (GoRouter 추가)

```dart
// lib/core/di/router.dart — 추가 라우트

GoRoute(path: '/login',    builder: (_, _) => const LoginScreen()),
GoRoute(path: '/signup',   builder: (_, _) => const SignUpScreen()),
GoRoute(path: '/profile',  builder: (_, _) => const ProfileScreen()),
```

### 8.2 LoginScreen

```
┌──────────────────────────┐
│         AppTag            │
│      [앱 로고/아이콘]      │
│                           │
│  ┌──────────────────────┐ │
│  │  Google로 계속하기   │ │  ← Google Sign-In 버튼
│  └──────────────────────┘ │
│  ┌──────────────────────┐ │
│  │  Apple로 계속하기    │ │  ← Apple Sign-In (iOS만 표시)
│  └──────────────────────┘ │
│                           │
│  ──── 또는 ────           │
│                           │
│  ┌──────────────────────┐ │
│  │  이메일로 로그인     │ │  ← 이메일/비밀번호 입력 폼 전환
│  └──────────────────────┘ │
│                           │
│  계정이 없으신가요? 가입   │  ← /signup 이동
│                           │
│  ──────────────────       │
│  로그인 없이 사용하기 →    │  ← dismiss, 로컬 모드 유지
└──────────────────────────┘
```

**플랫폼별 분기**:
- iOS: Google + Apple + Email (3버튼)
- Android: Google + Email (2버튼, Apple 미노출)
- `dart:io`의 `Platform.isIOS`로 분기

### 8.3 SignUpScreen

```
┌──────────────────────────┐
│  ← 뒤로     회원가입      │
│                           │
│  닉네임                   │
│  ┌──────────────────────┐ │
│  │                      │ │
│  └──────────────────────┘ │
│  이메일                   │
│  ┌──────────────────────┐ │
│  │                      │ │
│  └──────────────────────┘ │
│  비밀번호 (8자 이상)      │
│  ┌──────────────────────┐ │
│  │                      │ │
│  └──────────────────────┘ │
│  비밀번호 확인            │
│  ┌──────────────────────┐ │
│  │                      │ │
│  └──────────────────────┘ │
│                           │
│  ┌──────────────────────┐ │
│  │      가입하기         │ │
│  └──────────────────────┘ │
└──────────────────────────┘
```

### 8.4 ProfileScreen

```
┌──────────────────────────┐
│  ← 뒤로     내 프로필     │
│                           │
│        [아바타]           │
│     사진 변경 버튼         │
│                           │
│  닉네임: ___________  ✏️  │
│  이메일: user@email.com   │  ← 읽기 전용
│  로그인: Google           │  ← 읽기 전용
│  가입일: 2026-04-17       │
│                           │
│  ──────────────────       │
│  동기화 상태: ✅ 동기화됨  │
│  마지막 동기화: 방금 전    │
│  [수동 동기화] 버튼        │
│                           │
│  ──────────────────       │
│  [로그아웃]               │
│  [계정 삭제] (빨간색)     │
└──────────────────────────┘
```

### 8.5 SettingsScreen 수정

기존 설정 화면 상단에 **계정 섹션** 추가:

```
┌──────────────────────────┐
│  설정                     │
│                           │
│  ── 계정 ──               │  ← 신규 섹션
│  [프로필 이미지] 닉네임    │
│  user@email.com      →    │  ← tap → /profile
│  또는                      │
│  [로그인하기]          →   │  ← 비로그인 시 표시, tap → /login
│                           │
│  ── 동기화 ──             │  ← 신규 섹션 (로그인 시만 표시)
│  클라우드 동기화  [토글]   │
│  마지막 동기화: 5분 전     │
│                           │
│  ── 언어 ──               │  ← 기존
│  ...                      │
└──────────────────────────┘
```

### 8.6 동기화 인디케이터

기존 나의 템플릿 탭 (`my_templates_tab.dart`)에 동기화 상태 표시:

```
┌──────────────────────────┐
│  나의 템플릿   ☁️ 동기화됨 │  ← 헤더에 sync 상태 배지
│  ┌────┐ ┌────┐ ┌────┐    │
│  │tmpl│ │tmpl│ │tmpl│    │
│  │ 1  │ │ 2  │ │ 3  │    │
│  └────┘ └────┘ └────┘    │
│  ┌────┐ ┌────┐           │
│  │tmpl│ │ +  │           │  ← + 버튼은 기존
│  │ 4  │ │    │           │
│  └────┘ └────┘           │
└──────────────────────────┘
```

동기화 상태 아이콘:
- `☁️` 동기화 완료 (synced)
- `🔄` 동기화 중 (syncing) — 회전 애니메이션
- `☁️❌` 동기화 실패 (error) — 탭 시 재시도
- 아이콘 없음: 비로그인 상태 (로컬 전용)

---

## 9. Failure Types 확장

기존 `lib/core/error/failure.dart`에 추가:

```dart
/// 인증 실패 (로그인, 회원가입, 토큰 등).
class AuthFailure extends Failure {
  final String? code;  // Supabase AuthException.statusCode
  const AuthFailure(super.message, {this.code});
}

/// 동기화 실패.
class SyncFailure extends Failure {
  final int pulled;
  final int pushed;
  const SyncFailure(super.message, {this.pulled = 0, this.pushed = 0});
}
```

---

## 10. Localization (i18n)

기존 ARB 파일에 추가할 키:

```json
{
  "loginTitle": "로그인",
  "signupTitle": "회원가입",
  "continueWithGoogle": "Google로 계속하기",
  "continueWithApple": "Apple로 계속하기",
  "loginWithEmail": "이메일로 로그인",
  "useWithoutLogin": "로그인 없이 사용하기",
  "noAccountYet": "계정이 없으신가요?",
  "signUp": "가입",
  "nickname": "닉네임",
  "email": "이메일",
  "password": "비밀번호",
  "passwordConfirm": "비밀번호 확인",
  "passwordMinLength": "비밀번호는 8자 이상이어야 합니다",
  "passwordMismatch": "비밀번호가 일치하지 않습니다",
  "profileTitle": "내 프로필",
  "changePhoto": "사진 변경",
  "loginMethod": "로그인 방법",
  "joinDate": "가입일",
  "syncStatus": "동기화 상태",
  "synced": "동기화됨",
  "syncing": "동기화 중...",
  "syncError": "동기화 실패",
  "lastSynced": "마지막 동기화",
  "manualSync": "수동 동기화",
  "logout": "로그아웃",
  "deleteAccount": "계정 삭제",
  "deleteAccountConfirm": "정말 계정을 삭제하시겠습니까? 클라우드 데이터가 모두 삭제됩니다.",
  "logoutConfirm": "로그아웃하시겠습니까? 로컬 데이터는 유지됩니다.",
  "accountSection": "계정",
  "syncSection": "동기화",
  "loginPrompt": "로그인하기",
  "cloudSync": "클라우드 동기화"
}
```

---

## 11. Platform Configuration

### 11.1 Google Sign-In

**Android** (`android/app/build.gradle`):
- SHA-1 인증서 등록 (Firebase/Google Cloud Console)
- `google-services.json` 불필요 (Supabase 직접 사용)

**iOS** (`ios/Runner/Info.plist`):
- `GIDClientID` 추가 (Google Cloud Console에서 발급한 iOS Client ID)
- URL Scheme 추가: `com.googleusercontent.apps.{CLIENT_ID}`

### 11.2 Apple Sign-In

**iOS** (`ios/Runner/Runner.entitlements`):
- `com.apple.developer.applesignin` → `Default` 추가

**Supabase Dashboard**:
- Apple Provider 활성화
- Service ID, Team ID, Key ID, p8 Key 등록

### 11.3 Supabase Auth 설정

**Dashboard > Authentication > Providers**:
- Email: 활성화 (Confirm email = OFF — 초기에는 즉시 로그인 허용)
- Google: 활성화 + Client ID/Secret 등록
- Apple: 활성화 + Service ID/Secret/p8 등록

**Dashboard > Authentication > URL Configuration**:
- Site URL: `io.supabase.apptag://login-callback`
- Redirect URLs: `io.supabase.apptag://login-callback`

---

## 12. Dependencies

### 12.1 신규 추가

```yaml
# pubspec.yaml — dependencies 추가
google_sign_in: ^6.2.0          # Google 소셜 로그인
sign_in_with_apple: ^6.1.0      # Apple 소셜 로그인
crypto: ^3.0.3                   # Apple Sign-In nonce SHA256 해싱
```

### 12.2 기존 유지 (이미 있음)

```yaml
supabase_flutter: ^2.5.0        # Supabase 클라이언트 (Auth + DB)
shared_preferences: ^2.3.0      # lastSyncedAt 저장
uuid: ^4.4.0                    # 로컬 ID 생성
hive: ^2.2.3                    # 로컬 저장소
```

---

## 13. Implementation Order (상세)

| Phase | Task | New/Modified Files | Dependency |
|-------|------|-------------------|------------|
| **P0** | Supabase 테이블 + RLS + trigger 생성 | Supabase Dashboard SQL | — |
| **P1** | `AppUser` 엔티티 + `AuthFailure`/`SyncFailure` 추가 | `auth/domain/entities/app_user.dart`, `core/error/failure.dart` | P0 |
| **P2** | `AuthRemoteDataSource` + `AuthRepository` | `auth/data/datasources/supabase_auth_datasource.dart`, `auth/data/repositories/auth_repository_impl.dart`, `auth/domain/repositories/auth_repository.dart` | P1 |
| **P3** | `AuthNotifier` + `authProvider` | `auth/presentation/providers/auth_providers.dart` | P2 |
| **P4** | LoginScreen + SignUpScreen + 라우트 추가 | `auth/presentation/screens/login_screen.dart`, `auth/presentation/screens/signup_screen.dart`, `core/di/router.dart` | P3 |
| **P5** | Google/Apple 네이티브 설정 + 패키지 추가 | `pubspec.yaml`, `android/`, `ios/` 설정 파일 | P4 |
| **P6** | `ProfileRemoteDataSource` + `ProfileRepository` + ProfileScreen | `profile/` 전체 | P3 |
| **P7** | `UserQrTemplate` updatedAt 필드 추가 + Hive migration | `user_qr_template.dart`, `user_qr_template_model.dart` | — |
| **P8** | `SupabaseTemplateDataSource` + `TemplateSyncRepository` + SyncEngine | `sync/` 전체 | P2, P7 |
| **P9** | `SyncNotifier` + 동기화 트리거 연결 | `sync/presentation/providers/sync_providers.dart`, `main.dart` 수정 | P8 |
| **P10** | SettingsScreen 계정 섹션 + 동기화 인디케이터 | `settings/settings_screen.dart`, `qr_result/tabs/my_templates_tab.dart` | P3, P9 |
| **P11** | `UserColorPalette` 엔티티 + Hive 모델 + Remote DS (스키마만) | `color_palette/` 도메인+데이터 | P1 |
| **P12** | i18n 키 추가 (11개 ARB 파일) | `lib/l10n/app_*.arb` | P4 |

---

## 14. Testing Strategy

| Layer | Target | Method |
|-------|--------|--------|
| Domain | AppUser, UserColorPalette 생성/검증 | Unit test |
| Data | AuthRepository, SyncRepository | Unit test (Supabase mock) |
| Sync | SyncEngine conflict resolution | Unit test (시나리오별 LWW 검증) |
| UI | LoginScreen, SignUpScreen 렌더링 | Widget test |
| Integration | 로그인→동기화→데이터 복원 전체 흐름 | Manual + Zero Script QA (로그 기반) |

### 핵심 테스트 시나리오

1. **신규 사용자 가입** → 프로필 자동 생성 확인
2. **기존 로컬 데이터 → 첫 로그인** → 로컬 템플릿 전부 push 확인
3. **기기 B에서 로그인** → 기기 A 데이터 pull 확인
4. **오프라인 수정 → 온라인 복귀** → 자동 push 확인
5. **양방향 충돌** → LWW(updated_at 비교) 정상 동작 확인
6. **로그아웃** → 로컬 데이터 유지, UI에서 계정 섹션 변경 확인
7. **계정 삭제** → 클라우드 데이터 CASCADE 삭제, 로컬 데이터 유지 확인

---

## 15. Security Considerations

| Item | Policy |
|------|--------|
| RLS | 모든 테이블에 `auth.uid() = user_id` 정책 적용 |
| Token | Supabase JWT 자동 관리 (`supabase_flutter`), refresh token 안전 저장 |
| Password | Supabase Auth의 bcrypt 해싱 (서버 측) |
| Apple Nonce | `crypto` 패키지로 SHA-256 해싱 후 전달 |
| 계정 삭제 | `ON DELETE CASCADE` — profiles 삭제 시 templates, palettes 연쇄 삭제 |
| 네트워크 | HTTPS only (Supabase 기본) |
| 로컬 저장소 | Hive 평문 저장 (앱 샌드박스 내, 민감 데이터 없음) |
