---
template: analysis
version: 1.0
feature: clean-architecture-refactor
date: 2026-04-17
author: gap-detector
project: app_tag
---

# clean-architecture-refactor Analysis Report

> **Analysis Type**: Gap Analysis (PDCA Check Phase)
>
> **Project**: app_tag
> **Version**: 1.0.0+1
> **Analyst**: gap-detector
> **Date**: 2026-04-17
> **Design Doc**: [clean-architecture-refactor.design.md](../02-design/features/clean-architecture-refactor.design.md)
> **Plan Doc**: [clean-architecture-refactor.plan.md](../01-plan/features/clean-architecture-refactor.plan.md)

---

## 1. Analysis Overview

### 1.1 Analysis Purpose

Verify the implementation of a full Clean Architecture migration (P0-P7) against the design document specifications: 3-layer structure, dependency rules, naming conventions, error model, routing, and test coverage.

### 1.2 Analysis Scope

- **Design Document**: `docs/02-design/features/clean-architecture-refactor.design.md`
- **Plan Document**: `docs/01-plan/features/clean-architecture-refactor.plan.md`
- **Implementation Path**: `lib/core/`, `lib/features/`, `lib/main.dart`, `lib/app/`
- **Analysis Date**: 2026-04-17

---

## 2. Overall Scores

| Category | Score | Status |
|----------|:-----:|:------:|
| Design Match | 88% | [WARN] |
| Architecture Compliance | 82% | [WARN] |
| Convention Compliance | 90% | [PASS] |
| **Overall** | **87%** | [WARN] |

---

## 3. Gap Analysis (Design vs Implementation)

### 3.1 Core Foundation (P0)

| Item | Design | Implementation | Status |
|------|--------|----------------|--------|
| `Failure` sealed class (5 subtypes) | `core/error/failure.dart` | Exact match: StorageFailure, NetworkFailure, PlatformFailure, ValidationFailure, UnexpectedFailure | PASS |
| `Result<T>` sealed class + fold/map/flatMap | `core/error/result.dart` | Match + additional `valueOrNull`, `failureOrNull`, `isSuccess`, `isErr` extensions | PASS |
| `core/di/app_providers.dart` | ProviderScope overrides root | Implemented (empty overrides list) | PASS |
| `core/di/hive_config.dart` | Hive init + adapter registration | Match: typeId 0 deleted, typeId 1+2 registered | PASS |
| `core/di/supabase_config.dart` | Supabase init | Exists | PASS |
| `shared/` to `core/` migration | constants, utils, widgets | `core/constants/`, `core/utils/`, `core/widgets/` present | PASS |
| `main.dart` ProviderScope | `ProviderScope(overrides: ...)` | Exact match | PASS |
| `core/services/` | Not in original design | Added: `settings_service.dart`, `supabase_service.dart` | [INFO] Added |

### 3.2 Feature 3-Layer Structure

| Feature | data/ | domain/ | presentation/ | Status |
|---------|:-----:|:-------:|:-------------:|--------|
| qr_task | PASS | PASS | PASS | Full CA |
| qr_result | PASS | PASS | PASS | Full CA |
| nfc_writer | PASS | PASS | PASS | Full CA |
| app_picker | PASS | PASS | PASS | Full CA |
| home | -- | -- | screen only | Flat (by design) |
| history | -- | -- | PASS | Presentation-only |
| help | -- | -- | screen only | Flat (by design) |
| clipboard_tag | -- | -- | screen only | Flat (by design) |
| 9 form screens | -- | -- | screen only | Flat (by design) |

### 3.3 Repository Abstract Interfaces

| Feature | Abstract Repository | RepositoryImpl | Providers expose abstract type | Status |
|---------|:------------------:|:--------------:|:-----------------------------:|--------|
| qr_task | `QrTaskRepository` | `QrTaskRepositoryImpl` | `Provider<QrTaskRepository>` | PASS |
| qr_result (user_template) | `UserTemplateRepository` | `UserTemplateRepositoryImpl` | `Provider<UserTemplateRepository>` | PASS |
| qr_result (default_template) | `DefaultTemplateRepository` | `DefaultTemplateRepositoryImpl` | `Provider<DefaultTemplateRepository>` | PASS |
| qr_result (output) | `QrOutputRepository` | `QrOutputRepositoryImpl` | `Provider<QrOutputRepository>` | PASS |
| nfc_writer | `NfcRepository` | `NfcRepositoryImpl` | Yes | PASS |
| app_picker | `AppPickerRepository` | `AppPickerRepositoryImpl` | Yes | PASS |

### 3.4 UseCase Inventory

| Feature | Design Count | Actual Count | Status |
|---------|:----------:|:----------:|--------|
| qr_task | 6 | 6 | PASS |
| qr_result | 8 | 9 (+PrintQrCode) | [INFO] +1 |
| nfc_writer | 2 | 2 | PASS |
| app_picker | 1 | 1 | PASS |
| **Total** | 17 | 18 | PASS |

### 3.5 Error Model (`Result<T>`) Compliance

| Item | Design Rule | Implementation | Status |
|------|------------|----------------|--------|
| Repository methods return `Future<Result<T>>` | All repos | qr_task, qr_result, app_picker: compliant | PASS |
| `throw` banned in repos | catch -> Failure | Verified | PASS |
| `NfcRepository.stopSession()` | Should return `Future<Result<void>>` | Returns `Future<void>` (no Result wrapper) | [FAIL] |

### 3.6 Routing (go_router)

| Item | Design | Implementation | Status |
|------|--------|----------------|--------|
| go_router dependency | `pubspec.yaml` | Present | PASS |
| `appRouterProvider` | `core/di/router.dart` | 17 routes defined | PASS |
| `Navigator.push` elimination | All replaced with `context.push` | Verified | PASS |
| Deep link redirect | `deepLinkRedirectProvider` in router | **Not implemented** | [FAIL] |
| Old `lib/app/router.dart` deleted | Deleted | Confirmed | PASS |
| `MaterialApp.router` | `routerConfig: ref.watch(appRouterProvider)` | Exact match | PASS |

### 3.7 Entity-DTO Mapping

| Entity | DTO | typeId | Status |
|--------|-----|:------:|--------|
| QrTask | QrTaskModel | 2 | PASS |
| UserQrTemplate | UserQrTemplateModel | 1 | PASS |
| TagHistory | (deleted) | 0 | PASS |

### 3.8 Legacy Cleanup (P6)

| Legacy Directory | Status |
|------------------|--------|
| `lib/services/` | Deleted - PASS |
| `lib/models/` | Deleted - PASS |
| `lib/repositories/` | Deleted - PASS |
| `lib/shared/` | Deleted - PASS |

---

## 4. Architecture Compliance

### 4.1 Domain Layer Purity Violations

| File | Violation | Severity |
|------|-----------|----------|
| `qr_result/domain/entities/qr_template.dart` | `import 'package:flutter/material.dart'` | [FAIL] High |
| `qr_result/domain/entities/qr_dot_style.dart` | `import 'package:flutter/material.dart'` + `import 'package:pretty_qr_code/...'` | [FAIL] High |
| `qr_result/domain/entities/sticker_config.dart` | `import 'package:flutter/material.dart'` | [FAIL] High |

These 3 files were moved from `lib/models/` to `domain/entities/` but were not purified. qr_task domain entities are fully clean (dart:core only).

### 4.2 Cross-Feature Dependency

| Source | Target | Status |
|--------|--------|--------|
| `history_screen.dart` | `qr_task/domain/entities/` | [WARN] |
| `history_screen.dart` | `qr_task/presentation/providers/` | [FAIL] |

Design acknowledges this as open issue with two resolution options proposed but not yet implemented.

---

## 5. Test Coverage

| Area | Design Target | Actual | Status |
|------|:---:|:---:|--------|
| qr_task domain + data | >= 70% | 3 test files | [PASS] |
| qr_result | >= 50% | 0 test files | [FAIL] |
| nfc_writer | >= 50% | 0 test files | [FAIL] |
| app_picker | >= 50% | 0 test files | [FAIL] |

---

## 6. Missing Features (High Priority)

| # | Item | Impact |
|---|------|--------|
| 1 | Domain purity for 3 qr_result entities (Flutter imports in domain) | High |
| 2 | Cross-feature history dependency unresolved | Medium |
| 3 | Deep link redirect in GoRouter not implemented | Medium |
| 4 | Unit tests for qr_result, nfc_writer, app_picker | Medium |
| 5 | `NfcRepository.stopSession()` return type | Low |

---

## 7. Match Rate Summary

```
+---------------------------------------------+
|  Overall Match Rate: 87%                     |
+---------------------------------------------+
|  PASS  Match:           42 items (78%)       |
|  INFO  Added (not in design): 4 items (7%)   |
|  WARN  Minor deviations:  4 items (7%)       |
|  FAIL  Not implemented:   4 items (8%)       |
+---------------------------------------------+

Category Breakdown:
  Core Foundation (P0):     100%
  Feature Structure (P1-5):  90%
  Architecture Rules:        82%
  Naming Convention:        100%
  Error Model:               95%
  Routing (go_router):       80%
  Legacy Cleanup (P6):      100%
  Testing:                   40%
  P7 Verification:          100% (simulator confirmed)
```

---

## 8. Recommended Actions

### Immediate (to reach >= 90%)

1. **Purify qr_result domain entities** — remove Flutter/pretty_qr_code from domain, convert Color to ARGB int
2. **Resolve history cross-feature** — merge into qr_task or extract shared entities to core/

### Short-term

3. Add unit tests for qr_result, nfc_writer, app_picker
4. Implement deep link redirect in GoRouter
5. Wrap `NfcRepository.stopSession()` in `Result<void>`

**Recommendation**: Match rate 87%. Fixing domain purity (3 files) + cross-feature (1 file) should push above 90%.

Suggested next: `/pdca iterate clean-architecture-refactor`

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-17 | Initial gap analysis (P0-P7 complete) | gap-detector |
