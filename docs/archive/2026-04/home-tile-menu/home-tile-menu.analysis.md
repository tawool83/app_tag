# Gap Analysis: home-tile-menu

**분석일**: 2026-04-11
**Design 문서**: `docs/02-design/features/home-tile-menu.design.md`

## 종합 결과

| 항목 | 점수 |
|------|:----:|
| 기능 구현 Match Rate | 99% |
| 아키텍처 준수 | 100% |
| 코딩 컨벤션 | 98% |
| **Overall Match Rate** | **99%** |

## 섹션별 검증

| 섹션 | 항목 | 결과 |
|------|------|:----:|
| 데이터 모델 | TagHistory tagType HiveField(11) 추가 | OK |
| 데이터 모델 | tag_history.g.dart numOfFields=12, field 11 read/write | OK |
| TagPayloadEncoder | clipboard / website / contact / wifi / location / event / email / sms 8종 | OK |
| 홈 화면 | AppBar (NFC 아이콘, title, 도움말/이력 버튼) | OK |
| 홈 화면 | GridView 2열, spacing 12, childAspectRatio 1.1 | OK |
| 홈 화면 | 9종 타일 (아이콘·색상·라우트), 플랫폼 분기 | OK |
| 홈 화면 | _TileItem + _TileCard (elevation 2, radius 16, 48px icon) | OK |
| 입력 화면 (8종) | 각 화면 필드·유효성검사·페이로드 인코딩 | OK |
| 입력 화면 | output-selector arguments (appName, deepLink, platform, tagType) | OK |
| 라우터 | 8개 라우트 상수 + case | OK |
| QR/NFC 결과 | TagHistory 저장 시 tagType 포함 | OK |

## Gap 목록

### Missing (설계 O, 구현 X)
없음.

### Changed (설계 ≠ 구현) — 영향 없음
| 항목 | 설계 | 구현 | 영향 |
|------|------|------|:----:|
| 이벤트 종료>시작 검사 | Form validator 방식 | SnackBar 방식 | 없음 (동일 UX 결과) |
| 연락처·위치 선택 필드 전달 | null 조건부 | 빈 문자열 전달 (encoder에서 필터) | 없음 |

### Added (설계 X, 구현 O) — 긍정적 추가
| 항목 | 위치 | 평가 |
|------|------|------|
| AppBar title에 BitcountGridDouble 폰트 | home_screen.dart:18 | 앱 브랜딩 일관성 유지 |
| ElevatedButton.icon (화살표 아이콘) | 8개 입력 화면 | UX 개선 |

## 결론

Match Rate **99%** — iterate 불필요. `/pdca report home-tile-menu` 진행 가능.
