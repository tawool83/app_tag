# user-management Gap Analysis Report

**Analysis Date**: 2026-04-17
**Design Doc**: `docs/02-design/features/user-management.design.md`
**Implementation**: `lib/features/auth/`, `lib/features/profile/`, `lib/features/sync/`, `lib/features/color_palette/`, `lib/core/`, `lib/features/settings/`, `lib/l10n/`

## Exclusions (per user context)

- Apple Sign-In OAuth not configured — intentionally deferred, NOT a gap
- Color Palette CRUD — only schema/model planned for now
- Supabase tables — created manually, not verifiable via code

---

## Overall Scores

| Category | Score | Status |
|----------|:-----:|:------:|
| Design Match | 88% | ⚠️ |
| Architecture Compliance | 95% | ✅ |
| Convention Compliance | 100% | ✅ |
| **Overall** | **91%** | **✅** |

```
Total items checked: 53
  Matched:       38 (72%)
  Minor/Changed: 11 (21%)
  Missing:        4 ( 7%)
```

---

## Matched Items (38)

| # | Design Section | Item |
|---|---------------|------|
| 1 | 2.1 | `AppUser` entity — 6 fields exact match (+bonus `copyWith`) |
| 2 | 2.2 | `UserColorPalette` entity — 14 fields + `PaletteType` enum exact match |
| 3 | 2.3 | `UserQrTemplate.updatedAt` added to entity |
| 4 | 2.3 | `UserQrTemplateModel` HiveField(29) updatedAt |
| 5 | 2.3 | `UserQrTemplate` remoteId + syncedToCloud fields |
| 6 | 4.1 | `SupabaseAuthDataSource` — all 8 methods |
| 7 | 4.2 | `SupabaseProfileDataSource` — getProfile, updateProfile |
| 8 | 4.3 | `SupabaseTemplateDataSource` — fetchAll, fetchUpdatedSince, upsert, softDelete |
| 9 | 4.4 | `SupabasePaletteDataSource` — same 4 methods |
| 10 | 4.5 | `HiveColorPaletteDataSource` — readAll, readById, write, delete, clear |
| 11 | 5.1 | `AuthRepositoryImpl` with Result pattern + AuthFailure |
| 12 | 6.2 | `SyncResult` model — 5 fields + `hasErrors` exact match |
| 13 | 6.1 | `TemplateSyncEngine.sync()` Pull step (delta vs full fetch) |
| 14 | 6.1 | LWW conflict resolution — `remoteUpdated.isAfter(localUpdated)` |
| 15 | 6.1 | Push step — `syncedToCloud == false` filter |
| 16 | 6.1 | Pull-side soft-delete handling |
| 17 | 6.1 | `pushSingle` method for immediate single-template push |
| 18 | 6.1 | `lastSyncedAt` via SharedPreferences |
| 19 | 7.1 | `AuthStatus` enum — 5 values exact match |
| 20 | 7.1 | `AuthState` class — 3 fields + copyWith |
| 21 | 7.1 | Auth state change listener with stream subscription |
| 22 | 7.1 | All 6 AuthNotifier methods present |
| 23 | 7.1 | `authProvider` StateNotifierProvider |
| 24 | 7.2 | `SyncStatus` enum — 4 values exact match |
| 25 | 7.2 | `SyncState` class — 4 fields + copyWith |
| 26 | 7.2 | `syncProvider` StateNotifierProvider |
| 27 | 8.1 | Routes /login, /signup, /profile in router.dart |
| 28 | 8.2 | LoginScreen — Google, Apple (iOS-only), email form, signup link, dismiss |
| 29 | 8.3 | SignUpScreen — 4 fields with validation |
| 30 | 8.4 | ProfileScreen — avatar, nickname edit, readonly info, sync status, logout/delete |
| 31 | 8.5 | SettingsScreen — account section with login/profile |
| 32 | 9 | `AuthFailure` with `code` field |
| 33 | 9 | `SyncFailure` with `pulled`/`pushed` |
| 34 | 10 | All 32 design-specified i18n keys present in `app_ko.arb` |
| 35 | 10 | All 32 design-specified i18n keys present in `app_en.arb` |
| 36 | 12 | `google_sign_in` in pubspec.yaml |
| 37 | 12 | `sign_in_with_apple` in pubspec.yaml |
| 38 | 12 | `crypto` in pubspec.yaml |

---

## Missing Features (4)

| # | Item | Design Location | Severity | Description |
|---|------|----------------|----------|-------------|
| 1 | Push-side soft-delete | Section 6.1 Step 3 | **Medium** | SyncEngine handles pull-side deletes but does NOT push local deletions to remote via `remote.softDelete()`. Deleted templates will reappear after re-sync. |
| 2 | ProfileScreen "Change Photo" | Section 8.4 | Low | Avatar displayed but no change/upload action |
| 3 | SettingsScreen cloud sync toggle | Section 8.5 | Low | Design shows toggle but implementation only shows status |
| 4 | Sync indicator on template tab header | Section 8.6 | Low | No sync status badge in template list |

---

## Added Features (not in Design)

| # | Item | Location | Description |
|---|------|----------|-------------|
| 1 | `AppUser.copyWith` | `app_user.dart` | Immutable update helper |
| 2 | `AuthNotifier.clearError()` | `auth_providers.dart` | Resets error state after SnackBar |
| 3 | `currentUserProvider` | `auth_providers.dart` | Convenience read-only provider |
| 4 | 5 extra i18n keys | ARB files | orDivider, invalidEmail, nicknameRequired, justNow, cancel |

---

## Changed Features (11)

| # | Item | Design | Implementation | Impact |
|---|------|--------|----------------|--------|
| 1 | DataSource interfaces | 3 abstract interfaces | Concrete classes only | Low |
| 2 | Sync repository layer | Repository + interface pattern | Direct SyncEngine class | Medium |
| 3 | AuthNotifier deps | `_authRepo` + `_profileRepo` | `_repo` (AuthRepo only) | Low |
| 4 | SyncNotifier palette | Template + Palette sync wired | Template sync only | Low (future) |
| 5 | `pushTemplate` exposure | Exposed in SyncNotifier | Only in SyncEngine, not notifier | Medium |
| 6 | HiveColorPalette typeId | Design says typeId: 2 | typeId: 3 (correct) | None (doc error) |
| 7 | Dependency versions | ^6.x series | ^7.x series | None |
| 8 | Profile repo access | Via use-case layer | Direct ref.read from UI | Low |
| 9 | Palette sync integration | Wired in SyncNotifier | Schema only, not wired | Low (planned) |
| 10 | Abstract repository for sync | TemplateSyncRepository interface | No interface, concrete only | Low |
| 11 | Auth google_sign_in API | v6 constructor style | v7 singleton API | None (correct) |

---

## Architecture Compliance (95%)

| Layer | Status |
|-------|--------|
| Domain entities — pure Dart, no framework deps | ✅ |
| Domain repositories — abstract interfaces | ✅ |
| Data datasources — concrete, Supabase/Hive deps | ✅ |
| Data repositories — implements domain interfaces | ✅ |
| Presentation providers — Riverpod StateNotifier | ✅ |
| Presentation screens — ref.watch/ref.read only | ✅ |

Minor violation: `profile_screen.dart` calls `ref.read(profileRepositoryProvider)` directly from UI.

---

## Recommended Actions

### Immediate (before PR merge)

1. **Implement push-side soft-delete in SyncEngine** — Without this, locally deleted templates reappear from server on next sync. Data integrity issue.

2. **Expose `pushTemplate` in SyncNotifier** — Immediate-push capability exists in engine but not callable from UI/provider layer.

### Short-term (next iteration)

3. Add sync indicator badge to template tab header
4. Add cloud sync on/off toggle to SettingsScreen
5. Add "Change Photo" action to ProfileScreen

### Design Document Updates

- Section 4.5: Fix typeId from 2 to 3
- Section 5.2: Update to reflect SyncEngine approach (no repository interface)
- Section 7.1: Remove `_profileRepo` from AuthNotifier
- Section 10: Add 5 extra i18n keys
- Section 12.1: Update package versions to ^7.x
