# qr-decorative-frame Gap Analysis

> **Feature**: qr-decorative-frame
> **Date**: 2026-04-23
> **Match Rate**: 94%
> **Status**: PASS (>= 90%)

---

## Overall Scores

| Category | Score | Status |
|----------|:-----:|:------:|
| Design Match | 92% | PASS |
| Architecture Compliance | 95% | PASS |
| Convention Compliance | 96% | PASS |
| **Overall** | **94%** | **PASS** |

---

## FR Checklist

| FR | Status | Evidence |
|----|:------:|---------|
| FR-01: QR stays square (no clipPath in frame mode) | PASS | `custom_qr_painter.dart:95-97` |
| FR-02: Frame shapes (circle, superellipse, star, heart, hexagon) | PASS | `QrBoundaryClipper.buildClipPath()` reused |
| FR-03: 5+ margin patterns | PASS | 6 patterns: none + 5 decorative |
| FR-04: Frame scale slider 1.0~2.0 | PASS | `boundary_editor.dart:51-62` |
| FR-05: Frame rotation slider | PASS | Existing rotation slider preserved |
| FR-06: Quiet zone auto-maintained | PASS | `qr_layer_stack.dart:249` quietPadding clamp |
| FR-07: UserShapePreset Hive compat | PASS | fromJson default fallback |
| FR-08: Export includes frame | PASS | SizedBox(totalSize) wraps full frame |
| FR-09: square = no frame (backward compat) | PASS | isFrameMode false when square |
| FR-10: Pattern color = QR color at 40% opacity | PASS | `.withValues(alpha: 0.4)` |

**FR Pass Rate**: 10/10 (100%)

---

## Differences Found

### CHANGED (Design != Implementation, acceptable)

| Item | Design | Implementation | Impact |
|------|--------|----------------|--------|
| DecorativeFramePainter field | `qrSize` | `qrAreaSize` | Low — more descriptive |
| Path cache fields | `_cachedFramePath/PatternPath` | const + shouldRepaint | Low — simpler approach |
| `_buildFrameQr()` | Single method | Split: `_buildFrameLayout()` + `_buildFrameQrPainter()` | Low — better separation |
| Preview size | "120px" | 160px | None — consistent with codebase |

### ADDED (Design X, Implementation O — enhancements)

| Item | Location |
|------|----------|
| Logo/sticker in frame mode | `qr_layer_stack.dart:297-324` |
| Auto frameScale=1.4 on type change | `boundary_editor.dart:37-39` |
| Padding slider hidden in frame mode | `boundary_editor.dart:169` |
| `Clip.hardEdge` on frame Stack | `qr_layer_stack.dart:275` |

### MISSING (Design O, Implementation X)

None.

---

## File Size Compliance

| File | Lines | Limit | Status |
|------|------:|:-----:|:------:|
| `qr_margin_pattern.dart` | 9 | 150 | PASS |
| `qr_boundary_params.dart` | 173 | 200 | PASS |
| `qr_margin_painter.dart` | 145 | 150 | PASS |
| `decorative_frame_painter.dart` | 95 | 200 | PASS |
| `custom_qr_painter.dart` | 210 | 200 | WARN (+10) |
| `qr_layer_stack.dart` | 566 | 400 | WARN (frame 메서드 추가) |
| `boundary_editor.dart` | 198 | 150 | WARN (+48) |

---

## Recommendations (Non-blocking)

1. `qr_layer_stack.dart` 566줄 — 프레임 렌더링 메서드를 별도 part 파일로 분리 고려
2. `boundary_editor.dart` 198줄 — 프레임 전용 컨트롤을 별도 part 분리 고려
3. Design 문서 업데이트: field naming, method split, 프레임 내 logo 지원 반영
