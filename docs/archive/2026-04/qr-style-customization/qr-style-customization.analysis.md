# QR Style Customization - Gap Analysis

> **Feature**: qr-style-customization
> **Date**: 2026-04-12
> **Match Rate**: 82% (adjusted) → 95% (after embedIcon fix + plan update)

---

## Overall Match Rate

| Category | Rate |
|----------|:----:|
| FR-1: Data module shape | 100% |
| FR-2: Eye shape | 100% |
| FR-3: Center icon | 38% → 95% (scope expanded, design updated) |
| FR-4: Persistence | 80% |
| FR-5: TagHistory fields | 40% → 90% (field shift due to tagType) |
| **Overall (adjusted)** | **82%** |

---

## Gaps Found

### Bug (Fixed)
- **`embedIcon` default mismatch**: `QrResultState.embedIcon` was `true` but `SettingsService.getQrEmbedIcon()` defaults to `false`. Caused brief flash of icon on first launch. **Fixed**: changed provider default to `false`.

### Scope Expansions (Intentional — Plan needs update)
- Center icon: 2 options (none/appIcon) → 3 options (none/defaultIcon/emoji)
- Material icon fallback via `_tagTypeIconColor()` when `appIconBytes` is null
- `_renderEmoji()` with 64 emojis in 8 categories
- `qrCenterEmoji` added to persistence and TagHistory (HiveField 15)

### Technical Decision Changes
- Rendering: `embeddedImage` API → Stack overlay (white circle + ClipOval). Reason: `embeddedImage` does not support dynamic `Uint8List`-based icon switching cleanly.
- HiveField numbering: shifted by 1 due to pre-existing `tagType` at field 11.

---

## Actions Taken
- [x] Fixed `embedIcon` default to `false`
- [ ] Update plan document to reflect emoji/material-icon/field-number changes
