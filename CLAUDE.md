# app_tag — Claude Code 프로젝트 지침

> 이 파일은 세션 시작 시 자동 로드됩니다. 모든 slash command / skill 실행 위에서 override 역할을 합니다.
>
> **프로젝트 성격**: Flutter 모바일 앱 / **pre-release** (일반 사용자 미공개) / 1인 개발 / 사용자는 코드를 읽지 않음

---

## 🔒 고정 규약 (Never Ask, Always Apply)

아래 항목들은 **사용자 선택지로 제시하지 않는다**. 예외 없이 기본값으로 적용한다.

### 1. 코드 구조 — R-series Provider 패턴 + Clean Architecture

**모든 신규 feature** 는 아래 구조를 따른다. 단, 필드 ≤ 3 & setter ≤ 3 인 trivial feature는 단일 `xxx_provider.dart` 로 축약 가능(이것도 자동 판단, 묻지 않음).

```
lib/features/{feature}/
├── {feature}_provider.dart          # library; + part + FeatureState + Notifier(lifecycle only)
├── domain/
│   ├── entities/                    # enums, value objects
│   └── state/                       # sub-states (single concern each)
├── data/
│   ├── models/                      # Hive / serialization models
│   ├── datasources/                 # I/O abstractions
│   └── repositories/                # repository impls
├── notifier/                        # mixin setters via `part of`
│   └── *_setters.dart               # mixin _XxxSetters on StateNotifier<State>
└── presentation/
    ├── screens/
    ├── widgets/
    └── providers/                   # view-layer providers (optional)
```

**하드 룰 (검증 대상)**:
1. composite state 외부 접근은 항상 `state.sub.field` 경로 (flat getter 금지)
2. nullable clearing 은 `clearXxx: bool` 플래그, `_sentinel` 금지
3. backward-compat 코드 금지 (pre-release)
4. re-export 금지 — 소비자가 직접 entities/state 임포트
5. mixin은 `_` prefix (library-private)
6. 각 sub-state = 단일 관심사
7. 메인 Notifier body 는 lifecycle only (생성자/dispose/persistence load·push)
8. 파일 크기: 메인 ≤ 200줄, mixin/sub-state ≤ 150줄, UI part ≤ 400줄

**상세**: [`~/.claude/projects/C--repository-app-tag/memory/feedback_provider_pattern.md`](auto-loaded)

### 2. 의사결정 기준 — Claude 가독성 최우선

- 하위 호환성 고려 **안 함** (pre-release)
- 사용자 가독성 기준 **무시** (사용자는 < 5% 코드만 봄)
- **"Claude가 일관된 코드 구조를 인식하기 쉬운 방향"** 만 판단 기준
- legacy compat shim / alternative access path / "just in case" 코드 전부 **삭제**
- 리팩터링 시 call-site 동시 마이그레이션 (브릿지 안 둠)

**상세**: [`~/.claude/projects/C--repository-app-tag/memory/feedback_code_decision_criteria.md`](auto-loaded)

### 3. l10n 기본 정책

- 신규 UI 문자열은 **`app_ko.arb` 에만 선반영**
- `app_en/fr/de/es/ja/pt/th/vi/zh.arb` 는 **ko fallback** (미번역 상태로 유지, 후속 번역 티켓 백로그)
- 번역 범위/언어는 매번 묻지 않음

### 4. 권한·플랫폼 API 기본 선택

- 런타임 권한 — `permission_handler` (거부 시 `openAppSettings()` 안내)
- 카메라/QR 스캔 — `mobile_scanner`
- 공유 — `share_plus`
- 이미지 저장 — `image_gallery_saver`
- 네트워크 — OS intent / `url_launcher` 우선, 필요 시에만 전용 패키지

---

## 📋 PDCA Skill 실행 시 Override

bkit `/pdca {plan|design|do|…}` skill 실행 시 아래 **고정 동작**을 적용한다. skill 본문의 Checkpoint 중 아키텍처 선택 관련 질문은 **건너뛴다**.

### Plan phase (`/pdca plan`)
- "7.1 Project Level Selection" — 항상 **"Flutter Dynamic × Clean Architecture × R-series"** 로 자동 기재
- "7.2 Key Architectural Decisions" — Framework/State Management/로컬저장/라우팅 항목은 고정값 자동 기재 (Flutter / Riverpod StateNotifier / Hive / go_router)
- Checkpoint 1 (요구사항 이해) 와 Checkpoint 2 (도메인·엣지케이스 질문)만 수행. **아키텍처·코드 구조 관련 질문 금지**.

### Design phase (`/pdca design`)
- **Checkpoint 3 (3-options 아키텍처 비교) 건너뛰기** — "A.최소변경 / B.클린분리 / C.실용절충" 선택지 제시하지 않음
- 항상 **R-series Provider 패턴 + Clean Architecture** 로 Design 문서 작성
- Design 문서의 "Architecture" 섹션은 3-옵션 비교 대신 아래로 대체:
  - 신규 feature 의 디렉터리 트리
  - 각 State/sub-state/entity/mixin 의 세부 시그니처
  - 기존 feature 와의 데이터 흐름 연결도
- 세부 기술 선택(Hive typeId 할당, 라이브러리 버전 등) 은 근거와 함께 **자동 결정해서 기재**, 묻지 않음

### Do phase (`/pdca do`)
- Checkpoint 4 (구현 범위 승인) — **유지** (destructive 여부 판단 때문에 필요)
- 단, 코드 구조/아키텍처 옵션은 묻지 않음. 구현 순서와 변경 범위만 요약해서 승인 요청.

### Analyze / Iterate phase
- Checkpoint 5 (Critical/Important 수정 선택) — **유지** (사용자 의사결정 필요)

### 무엇을 물어도 되는가
✅ 도메인 요구사항 (기능 범위, UX 흐름, 데이터 모델 명세)
✅ 외부 시스템 연동 정책 (권한 거부 처리, OS intent 범위)
✅ 파괴적 변경 승인 (파일 삭제/대량 수정/의존성 제거)
✅ 기존 데이터 마이그레이션 방침

### 무엇을 묻지 말아야 하는가
❌ "Clean Architecture 쓸까요?" → 항상 Yes 고정
❌ "R-series 패턴 쓸까요?" → 항상 Yes 고정
❌ "3가지 아키텍처 옵션 중 골라주세요" → 건너뛰기, R-series 고정
❌ "상태 관리 뭐 쓸까요? Bloc/Riverpod/Provider?" → Riverpod 고정
❌ "파일을 어떻게 나눌까요?" → 메모리 패턴대로 자동 분할
❌ "ko만 지원할까요?" → 기본값 고정 (ko 선반영)
❌ "파일 크기 어디까지 허용?" → 위 하드 룰 8번 자동 적용

---

## 📚 메모리 우선 참조

세션 시작 시 아래가 auto-memory 로 로드됨. PDCA/code 작업 전 **반드시** 참조한다.

- `~/.claude/projects/C--repository-app-tag/memory/MEMORY.md` (인덱스)
- `feedback_provider_pattern.md` — R-series Provider 패턴 상세 (8 Hard Rules + 디렉터리 템플릿)
- `feedback_code_decision_criteria.md` — Claude 가독성 우선 의사결정 기준
- `feedback_pdca_phase_defaults.md` — PDCA Phase별 고정 override (본 문서 연동)

메모리 내용이 이 CLAUDE.md 와 충돌할 경우 **이 CLAUDE.md가 우선**. 메모리는 상세 레퍼런스, CLAUDE.md 는 강제 규약.

---

## 🛠 참조 구현

R-series 패턴의 canonical reference:
- `lib/features/qr_result/qr_result_provider.dart` — 234줄 메인 + 5 mixin + 5 sub-state + 4 entity
- Archived: `docs/archive/2026-04/refactor-qr-result-state/`, `refactor-qr-notifier-split/`
- UI 분할 레퍼런스: `docs/archive/2026-04/refactor-qr-shape-tab/`

신규 feature 는 위 구조와 **구조적으로 동형** 이어야 한다.
