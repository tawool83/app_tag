# qr-scanner-ui-ux Gap Analysis Report

> **Feature**: QR 스캐너 기능 신규 도입 + 스캔 결과 Bottom Sheet + History 2-탭 확장
> **Design**: `docs/02-design/features/qr-scanner-ui-ux.design.md`
> **Analysis Date**: 2026-04-21
> **Match Rate**: 92%

---

## Overall Scores

| Category | Score | Status |
|----------|:-----:|:------:|
| Design Match | 92% | PASS |
| Architecture Compliance | 100% (8/8 rules) | PASS |
| File Size Compliance | 100% | PASS |
| **Overall** | **92%** | **PASS** |

---

## Match Summary

| Category | Matched | Accepted Deviation | Gap | Changed | Extra |
|----------|:-------:|:------------------:|:---:|:-------:|:-----:|
| Entities | 6 | 0 | 1 | 0 | 1 |
| Parsers | 9 | 0 | 0 | 0 | 0 |
| Sub-States | 5 | 0 | 0 | 0 | 0 |
| Provider/Notifier | 7 | 3 | 0 | 0 | 2 |
| Mixin Setters | 14 | 0 | 0 | 1 | 0 |
| UI Widgets | 12 | 1 | 2 | 1 | 0 |
| Modified Files | 16 | 0 | 1 | 0 | 1 |
| l10n | 4 | 0 | 1 | 0 | 0 |
| **Total** | **73** | **4** | **5** | **2** | **4** |

---

## Gaps (Design specified, not implemented)

| # | Item | Impact | Description |
|---|------|:------:|-------------|
| 1 | `ScanDetectedType.l10nKey` getter | Low | `DataTypeTag`가 `.name.toUpperCase()` 사용 중. 한국어 라벨 미적용 |
| 2 | `gallery_qr_decoder_datasource.dart` | Low | 갤러리 디코드 로직이 `ScannerScreen`에 inline 처리됨. 기능은 동작 |
| 3 | `scanner_providers.dart` (view-layer) | Low | 프로바이더가 메인 provider 파일에 통합됨 |
| 4 | `scan_history_repository_impl.dart` | Low | 데이터소스를 프로바이더에서 직접 사용. Repository 레이어 생략 |
| 5 | 10개 l10n 키 미등록 | Medium | `scanTypeUrl`~`scanTypeText` 9개 + `wifiPasswordMasked` 1개 |

## Changed (Design != Implementation)

| # | Item | Design | Implementation | Impact |
|---|------|--------|----------------|:------:|
| 1 | `onBarcodeDetected` history save | `await addEntry(...)` | fire-and-forget | Low |
| 2 | `DataTypeTag` label source | l10nKey 기반 한국어 | `type.name.toUpperCase()` 영문 | Medium |

## Extra (Implementation only)

| # | Item | Description |
|---|------|-------------|
| 1 | `ScanDetectedType.tagType` getter | QrTask 호환 태그 타입 문자열 매핑 |
| 2 | `ScanHistoryEntry.displayTitle` getter | 타입별 프리뷰 제목 편의 getter |
| 3 | `scanHistoryBoxProvider` + `scanHistoryDatasourceProvider` | Riverpod inline 프로바이더 |
| 4 | `history_tile.dart` standalone widget | 생성되었으나 `HistoryListView`에서 미사용 |

---

## R-series Hard Rules Compliance

| # | Rule | scanner | scan_history | qr_task |
|---|------|:-------:|:------------:|:-------:|
| 1 | No flat fields on composite state | PASS | PASS | N/A |
| 2 | No `_sentinel`, use `clearXxx: bool` | PASS | PASS | N/A |
| 3 | No backward-compat getters | PASS | PASS | PASS |
| 4 | No re-exports | PASS | PASS | N/A |
| 5 | Mixin `_` prefix | PASS | PASS | N/A |
| 6 | Each sub-state = single concern | PASS | PASS | N/A |
| 7 | Notifier body = lifecycle only | PASS | PASS | N/A |
| 8 | File size limits | PASS | PASS | N/A |

---

## Recommended Actions

### Immediate (l10n Gap 해소)

1. `app_ko.arb`에 `scanTypeUrl`~`scanTypeText` 9개 키 추가
2. `DataTypeTag`에서 `l10nKey` 기반 라벨 사용으로 변경
3. `wifiPasswordMasked` 키 추가

### Low Priority

4. `history_tile.dart` 미사용 파일 정리 또는 `HistoryListView` 통합
5. Design 문서에 `tagType`, `displayTitle` getter 반영
6. Design 문서에 `gallery_qr_decoder_datasource.dart` inline 처리 반영

---

## Conclusion

Match Rate 92%로 PDCA 기준(90%)을 충족합니다. 아키텍처 규약(R-series 8개 하드 룰)은 100% 준수. 주요 Gap은 l10n 키 10개 미등록과 `DataTypeTag` 한국어 라벨 미적용으로, 기능 동작에는 영향 없으나 UI 국제화 품질 향상을 위해 후속 조치 권장.
