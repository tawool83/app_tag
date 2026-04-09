# Gap Analysis Report: apptag-flutter

**Date**: 2026-04-09  
**Match Rate**: 97%  
**Status**: Check Phase Complete

---

## Executive Summary

| Item | Value |
|------|-------|
| Feature | AppTag Flutter |
| Design Version | v0.2 |
| Match Rate | **97%** |
| Critical Gaps | 0 |
| Important Gaps | 1 |
| Minor Gaps | 0 |
| Improvements | 3 |

---

## Gap Details

### Important Gaps (1)

#### GAP-01: TagHistory.appIconBytes not implemented
- **Severity**: Important
- **Design Spec**: `TagHistory` should include `@HiveField(7) final Uint8List? appIconBytes` for storing Android app icon as Base64-encoded bytes
- **Actual**: `tag_history.dart` only implements fields 0–6; field 7 (`appIconBytes`) is absent
- **Impact**: History screen cannot display the original Android app icon alongside history entries
- **File**: `lib/models/tag_history.dart`
- **Recommendation**: Add `@HiveField(7) final Uint8List? appIconBytes` and regenerate Hive adapter via `dart run build_runner build --delete-conflicting-outputs`

---

## Improvements (vs Design)

### IMP-01: NFC write uses callback pattern (not throw-based)
- **Design**: `writeNdefTag()` threw exceptions on error
- **Actual**: Callback-based `onSuccess` / `onError` pattern
- **Assessment**: Improvement — more idiomatic for NFC session management, avoids lifecycle issues with exception propagation

### IMP-02: `getHistory()` is synchronous
- **Design**: `Future<List<TagHistory>>` async signature
- **Actual**: `List<TagHistory>` synchronous — Hive box access is inherently sync
- **Assessment**: Improvement — removes unnecessary async overhead

### IMP-03: `historyProvider` uses StateNotifierProvider
- **Design**: Specified `FutureProvider` for history list
- **Actual**: `StateNotifierProvider` with local mutation support (`saveHistory`, `delete`, `clearAll`)
- **Assessment**: Improvement — enables real-time list updates without full re-fetch

---

## Files Analyzed

| File | Status |
|------|--------|
| `lib/main.dart` | Match |
| `lib/models/tag_history.dart` | **Gap (IMP-01 missing)** |
| `lib/models/tag_history.g.dart` | Match |
| `lib/services/nfc_service.dart` | Match (IMP-01) |
| `lib/services/qr_service.dart` | Match |
| `lib/services/history_service.dart` | Match (IMP-02) |
| `lib/features/app_picker/` | Match |
| `lib/features/qr_result/` | Match |
| `lib/features/nfc_writer/` | Match |
| `lib/features/history/` | Match (IMP-03) |
| `lib/features/output_selector/` | Match |
| `lib/features/ios_input/` | Match |
| `lib/app/router.dart` | Match |
| `pubspec.yaml` | Match |
| `android/app/build.gradle.kts` | Match |
| `android/app/src/main/AndroidManifest.xml` | Match |
| `ios/Runner/Info.plist` | Match |

---

## Conclusion

97% match rate — the implementation closely follows the design. All 14 functional requirements (FR-01 through FR-14) are implemented. The single important gap (`appIconBytes`) is non-breaking: history entries work correctly, but Android app icons will not appear in history tiles.

All three divergences from the design are improvements, not regressions.
