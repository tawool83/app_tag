# Plan: user-management

## Executive Summary

| Item | Detail |
|------|--------|
| Feature | user-management (사용자 관리 및 클라우드 동기화) |
| Plan Created | 2026-04-17 |
| Estimated Scope | Major Feature |
| Priority | P0 — 개인화 기능 전체의 기반 |

### Value Delivered

| Perspective | Description |
|-------------|-------------|
| **Problem** | 앱을 재설치하거나 기기를 변경하면 사용자가 저장한 템플릿, 색상 팔레트 등 개인화 데이터가 모두 사라진다. Android/iOS 간 데이터 이동도 불가하다. |
| **Solution** | Supabase Auth 기반 크로스플랫폼 계정 시스템 + 클라우드 DB 동기화를 통해 플랫폼 무관하게 개인화 데이터를 영구 보존한다. |
| **Function UX Effect** | 한 번 로그인하면 어떤 기기에서든 나의 템플릿과 색상 팔레트가 자동으로 복원되어, 재설치/기기 변경 시에도 끊김 없는 경험을 제공한다. |
| **Core Value** | "내 스타일은 어디서든 나를 따라온다" — 플랫폼과 기기에 종속되지 않는 개인화 데이터 영속성 |

---

## 1. Background & Motivation

### 1.1 현재 상태
- 모든 사용자 데이터(QR 작업, 나의 템플릿)는 **Hive 로컬 저장소**에만 저장됨
- `UserQrTemplate` 엔티티에 `remoteId`, `syncedToCloud` 필드가 이미 존재하지만 미사용
- `supabase_flutter: ^2.5.0` 의존성이 이미 추가되어 있고, `SupabaseService` 초기화 코드 존재
- Supabase URL/Key는 `dart-define`으로 주입하는 구조 완성
- **인증(Auth) 기능은 아직 없음** — 계정 개념 자체가 존재하지 않음

### 1.2 문제점
1. **데이터 휘발성**: 앱 삭제 시 모든 개인화 데이터 소실
2. **플랫폼 고립**: Android ↔ iOS 간 데이터 이동 불가
3. **기기 종속**: 새 기기에서 기존 설정 복원 불가
4. **확장성 제한**: 향후 구독, 공유 등의 기능 기반 부재

### 1.3 목표
- 사용자 계정 시스템 구축 (소셜 로그인 + 이메일)
- 크로스플랫폼 개인화 데이터 클라우드 동기화
- 향후 "나의 색상 팔레트" 등 추가 개인화 기능의 DB 기반 마련

---

## 2. Requirements

### 2.1 Functional Requirements

| ID | Priority | Requirement | Description |
|----|----------|-------------|-------------|
| FR-01 | P0 | 소셜 로그인 | Google, Apple Sign-In으로 가입/로그인 (플랫폼 무관 동일 계정) |
| FR-02 | P1 | 이메일 로그인 | 이메일 + 비밀번호 가입/로그인 (소셜 미사용자용 대안) |
| FR-03 | P0 | 프로필 관리 | 닉네임, 프로필 이미지 설정/수정 |
| FR-04 | P0 | 나의 템플릿 동기화 | UserQrTemplate를 Supabase DB에 CRUD + 로컬↔클라우드 양방향 동기화 |
| FR-05 | P1 | 나의 색상 팔레트 | 단색/그라디언트 색상을 저장·관리하는 클라우드 컬렉션 (추가 개발 예정 — 스키마만 선 설계) |
| FR-06 | P0 | 오프라인 우선 | 로그인 없이도 기존과 동일하게 로컬 사용 가능, 로그인 시 클라우드 동기화 활성화 |
| FR-07 | P1 | 로그아웃/탈퇴 | 로그아웃 시 로컬 데이터 유지, 탈퇴 시 클라우드 데이터 삭제 |
| FR-08 | P2 | 동기화 충돌 해결 | 동일 템플릿이 로컬/클라우드에서 동시 수정 시 최종 수정 시간(last-write-wins) 기준 병합 |

### 2.2 Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-01 | 인증 응답 시간 | < 3초 (소셜 로그인 리다이렉트 제외) |
| NFR-02 | 동기화 지연 | < 5초 (템플릿 10개 기준) |
| NFR-03 | 오프라인 복원력 | 네트워크 없이 모든 로컬 기능 정상 동작 |
| NFR-04 | 보안 | Supabase RLS(Row Level Security)로 사용자 간 데이터 격리 |
| NFR-05 | 저장 용량 | 사용자당 템플릿 최대 100개, 색상 팔레트 최대 50개 |

---

## 3. Scope

### 3.1 In Scope (이번 피처)
- Supabase Auth 통합 (Google, Apple, Email)
- 사용자 프로필 테이블 + CRUD
- 나의 템플릿 클라우드 테이블 + 양방향 동기화
- 나의 색상 팔레트 테이블 스키마 정의 (CRUD는 후속 피처)
- 로그인/회원가입 UI
- 설정 화면에 계정 섹션 추가
- 동기화 상태 표시 (syncing/synced/error)

### 3.2 Out of Scope (향후)
- 색상 팔레트 UI 및 색상 추가/편집 인터랙션
- 템플릿 공유 (다른 사용자에게 공유)
- 구독/결제 시스템
- 실시간 동기화 (Supabase Realtime) — 초기에는 pull-on-open 방식
- 소셜 기능 (팔로우, 좋아요)

---

## 4. Technical Approach

### 4.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                     │
│  LoginScreen │ SignUpScreen │ ProfileScreen │ SettingsScreen │
│                   (flutter_riverpod)                     │
├─────────────────────────────────────────────────────────┤
│                     Domain Layer                         │
│  Entities: AppUser, UserQrTemplate, UserColorPalette     │
│  UseCases: SignIn, SignUp, SignOut, SyncTemplates, ...    │
│  Repos(interface): AuthRepository, UserSyncRepository    │
├─────────────────────────────────────────────────────────┤
│                      Data Layer                          │
│  ┌──────────────┐    ┌───────────────────┐              │
│  │ Local (Hive) │◄──►│ Remote (Supabase) │              │
│  │ - templates  │    │ - auth            │              │
│  │ - palettes   │    │ - profiles        │              │
│  │ - settings   │    │ - templates       │              │
│  └──────────────┘    │ - palettes        │              │
│         ▲            └───────────────────┘              │
│         │       SyncEngine (conflict resolution)         │
├─────────────────────────────────────────────────────────┤
│                    Infrastructure                        │
│  SupabaseService (기존) │ HiveService (기존)              │
└─────────────────────────────────────────────────────────┘
```

### 4.2 Supabase DB Schema

```sql
-- 1. profiles (사용자 프로필)
CREATE TABLE profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nickname    TEXT,
  avatar_url  TEXT,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

-- 2. user_templates (나의 템플릿)
CREATE TABLE user_templates (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  local_id          TEXT NOT NULL,           -- Hive 로컬 ID 매핑
  name              TEXT NOT NULL,
  template_data     JSONB NOT NULL,          -- QR 스타일 전체 직렬화
  thumbnail_base64  TEXT,                    -- 미리보기 이미지
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, local_id)
);

-- 3. user_color_palettes (나의 색상 팔레트 — 스키마 선 정의)
CREATE TABLE user_color_palettes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  type        TEXT NOT NULL CHECK (type IN ('solid', 'gradient')),
  color_data  JSONB NOT NULL,               -- solid: {"argb": 0xFF...}, gradient: {"colors":[...], "stops":[...], "type":"linear"|"radial"}
  sort_order  INT DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

-- RLS 정책
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_color_palettes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own profile"
  ON profiles FOR ALL USING (auth.uid() = id);

CREATE POLICY "Users can CRUD own templates"
  ON user_templates FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can CRUD own palettes"
  ON user_color_palettes FOR ALL USING (auth.uid() = user_id);
```

### 4.3 Authentication Strategy

| Provider | Android | iOS | 비고 |
|----------|---------|-----|------|
| Google Sign-In | `google_sign_in` | `google_sign_in` | 동일 Google 계정 → 동일 Supabase user |
| Apple Sign-In | — | `sign_in_with_apple` | iOS 필수 (App Store 정책), Android는 미노출 |
| Email + Password | Supabase Auth | Supabase Auth | 소셜 미사용자용 |

- Supabase Auth의 **링크 기능**으로 동일 이메일의 Google/Apple/Email 계정을 하나로 통합
- 로그인 상태는 `supabase_flutter`의 `onAuthStateChange` 스트림으로 관리

### 4.4 Sync Strategy (Offline-First)

```
앱 시작 → 로컬 데이터 즉시 표시
       → 로그인 상태 확인
       → 로그인됨? → Pull (서버 → 로컬 병합)
                   → Push (로컬 미동기화 항목 → 서버)
       → 비로그인? → 로컬 전용 모드 유지
```

- **충돌 해결**: `updated_at` 타임스탬프 기반 Last-Write-Wins
- **동기화 단위**: 템플릿/팔레트 개별 레코드 단위
- **동기화 트리거**: 앱 시작 시(pull-on-open), 저장/삭제 시(immediate push)
- **thumbnailBytes**: Base64 인코딩하여 `thumbnail_base64` 컬럼에 저장 (소형 이미지)
- **backgroundImageBytes**: 크기가 클 수 있으므로 Supabase Storage 사용 검토 (Phase 2)

### 4.5 New Dependencies

```yaml
dependencies:
  google_sign_in: ^6.2.0          # Google 소셜 로그인
  sign_in_with_apple: ^6.1.0      # Apple 소셜 로그인
  crypto: ^3.0.3                   # Apple Sign-In nonce 해싱
```

---

## 5. Implementation Order

| Phase | Task | Files/Components | Dependency |
|-------|------|------------------|------------|
| P0 | Supabase 테이블 생성 + RLS | Supabase Dashboard / Migration SQL | — |
| P1 | Domain 엔티티 정의 | `AppUser`, `UserColorPalette` entities | P0 |
| P2 | Auth Repository + DataSource | `auth_repository.dart`, `supabase_auth_datasource.dart` | P1 |
| P3 | 로그인/회원가입 UI | `login_screen.dart`, `signup_screen.dart` | P2 |
| P4 | 프로필 관리 | `profile_screen.dart`, `profiles` CRUD | P3 |
| P5 | 템플릿 동기화 엔진 | `sync_engine.dart`, `supabase_template_datasource.dart` | P2, P4 |
| P6 | 설정 화면 계정 섹션 | `settings_screen.dart` 수정 | P3, P4 |
| P7 | 색상 팔레트 엔티티 + Remote DataSource | `UserColorPalette`, `supabase_palette_datasource.dart` | P1 |
| P8 | 동기화 상태 UI | 동기화 인디케이터, 에러 핸들링 | P5 |

---

## 6. File Structure (Planned)

```
lib/features/auth/
├── domain/
│   ├── entities/
│   │   └── app_user.dart
│   ├── repositories/
│   │   └── auth_repository.dart
│   └── usecases/
│       ├── sign_in_with_google_usecase.dart
│       ├── sign_in_with_apple_usecase.dart
│       ├── sign_in_with_email_usecase.dart
│       ├── sign_up_with_email_usecase.dart
│       ├── sign_out_usecase.dart
│       └── get_current_user_usecase.dart
├── data/
│   ├── datasources/
│   │   └── supabase_auth_datasource.dart
│   └── repositories/
│       └── auth_repository_impl.dart
└── presentation/
    ├── providers/
    │   └── auth_providers.dart
    └── screens/
        ├── login_screen.dart
        └── signup_screen.dart

lib/features/profile/
├── domain/
│   ├── entities/
│   │   └── user_profile.dart       (profiles 테이블 매핑)
│   ├── repositories/
│   │   └── profile_repository.dart
│   └── usecases/
│       ├── get_profile_usecase.dart
│       └── update_profile_usecase.dart
├── data/
│   ├── datasources/
│   │   └── supabase_profile_datasource.dart
│   └── repositories/
│       └── profile_repository_impl.dart
└── presentation/
    ├── providers/
    │   └── profile_providers.dart
    └── screens/
        └── profile_screen.dart

lib/features/sync/
├── domain/
│   ├── repositories/
│   │   └── sync_repository.dart
│   └── usecases/
│       ├── sync_templates_usecase.dart
│       └── sync_palettes_usecase.dart
├── data/
│   ├── datasources/
│   │   ├── supabase_template_datasource.dart
│   │   └── supabase_palette_datasource.dart
│   ├── repositories/
│   │   └── sync_repository_impl.dart
│   └── engine/
│       └── sync_engine.dart         (충돌 해결 로직)
└── presentation/
    └── providers/
        └── sync_providers.dart

lib/features/color_palette/
├── domain/
│   ├── entities/
│   │   └── user_color_palette.dart
│   ├── repositories/
│   │   └── color_palette_repository.dart
│   └── usecases/
│       └── (Phase 2에서 추가)
├── data/
│   ├── models/
│   │   └── user_color_palette_model.dart   (Hive)
│   ├── datasources/
│   │   ├── hive_color_palette_datasource.dart
│   │   └── supabase_palette_datasource.dart
│   └── repositories/
│       └── color_palette_repository_impl.dart
└── presentation/
    └── (Phase 2에서 추가)
```

---

## 7. Risk & Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Apple Sign-In 설정 복잡도 | High | Medium | Apple Developer 설정 가이드 사전 준비, Supabase 문서 참조 |
| 동기화 충돌 데이터 손실 | High | Low | Last-Write-Wins + 로컬 백업 유지, 삭제 시 soft-delete |
| 대용량 이미지(배경) 동기화 지연 | Medium | Medium | Phase 1은 thumbnail만 동기화, 배경 이미지는 Phase 2 (Storage) |
| Supabase 무료 티어 한도 초과 | Medium | Low | 사용자당 템플릿 100개 제한, 이미지 압축 |
| 기존 로컬 전용 사용자 마이그레이션 | Medium | High | 로그인 시 기존 Hive 데이터 자동 업로드 (초기 동기화) |

---

## 8. Success Criteria

| Criteria | Metric |
|----------|--------|
| Google/Apple 로그인 성공률 | >= 95% |
| 로그인 후 템플릿 동기화 완료 | < 5초 (10개 기준) |
| 기기 변경 후 데이터 복원율 | 100% (동기화된 항목) |
| 비로그인 사용자 기존 기능 정상 | 기존 테스트 전체 통과 |
| 크로스플랫폼 계정 통합 | 동일 이메일 → 동일 계정 |

---

## 9. Open Questions

| # | Question | Status |
|---|----------|--------|
| Q1 | Supabase 프로젝트가 이미 생성되어 있는가? (URL/Key 발급 상태) | TBD |
| Q2 | Apple Developer 계정에서 Sign in with Apple 설정 완료 여부 | TBD |
| Q3 | Google Cloud Console에서 OAuth 2.0 Client ID 발급 완료 여부 | TBD |
| Q4 | 색상 팔레트 UI/UX 상세 요구사항 (이번 피처에서는 스키마만 선 정의) | 후속 피처에서 결정 |
| Q5 | 배경 이미지 클라우드 저장소 사용 여부 (Supabase Storage vs 외부) | Phase 2에서 결정 |
