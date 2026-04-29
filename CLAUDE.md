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

### 5. QR 스펙 절대 준수 (ISO/IEC 18004)

**어떤 경우라도 QR 스펙에 벗어나는 구현은 하지 않는다.** 미관·UX·코드 단순화·사용자 요청 어떤 것도 스펙 위반의 사유가 될 수 없다. 스펙과 디자인이 충돌하면 **항상 스펙이 우선**이고, 디자인은 스펙 안에서 표현 가능한 범위로 변형한다.

**보호 대상 (절대 침범 금지)**:
- **Finder pattern (3 코너 7×7)** — 형태/비율(1:1:3:1:1)/위치 무결성. 외각·내각 커스터마이즈는 finder bbox 안쪽에서만 변형.
- **Timing pattern** — 6번째 행/열의 흑백 교차 격자. 띠/로고/그라디언트/clip 어떤 레이어도 침범 금지.
- **Quiet zone** — 최소 4 모듈 (코드 상수: `qrSize × 0.05`, min 8px / max 20px). 외각 모양·테두리선·로고 어떤 것도 quiet zone 침범 금지.
- **Module dimension 정수성** — 도트는 module grid 안에서만 변형. 셀 경계 가로지르는 sub-module 페인팅 금지.
- **Error correction 사양** — 로고/텍스트 띠 등 Data 모듈 침범 시 EC level 자동 상향 (M → H). 로고 사이즈는 EC capacity 계산 결과 안에서.
- **Burst error 한계** — 띠/clear-zone 두께는 동일 행/열의 EC capacity (`(n - k) / 2` per block) 를 절대 초과 금지. 현재 적용된 띠 두께 12% (V5 강제) 는 이 계산 결과의 보수적 임계값.
- **Version (typeNumber) 보존** — 자동 산출 typeNumber 가 데이터에 적합한 최소값. 임의 하향 금지. 띠/로고 등으로 burst 위험이 커지면 **상향만 허용** (예: V5 강제).

**스펙 충돌 시 처리 순서**:
1. 디자인 변형 범위를 스펙 안으로 축소 (예: 띠 15% → 12%)
2. EC level 강제 상향 (M → H)
3. 최소 typeNumber 강제 상향 (auto → V5)
4. 위 셋 다 안 되면 **기능 자체를 거부**하고 사용자에게 사유 설명

**검증 의무**:
- QR 관련 신규 기능 구현 시 위 보호 대상 각 항목에 대해 **침범 여부를 명시적으로 검토** (Plan 또는 Design 문서에 기재)
- 띠·로고·boundary clip·외각 모양 등 *데코레이션 레이어*는 항상 quiet zone 안쪽 + EC capacity 안쪽
- 미적 효과를 위해 module grid를 일부 흐리는 효과(스무딩, 그라디언트, 도트 변형)는 **인접 모듈 간 식별 가능성을 유지하는 한도** 내에서만

**참고 구현**:
- `lib/features/qr_result/utils/logo_clear_zone.dart` — clear zone 계산 로직
- `lib/features/qr_result/widgets/qr_layer_stack.dart` — V5 강제 (`minTypeNumber: hasBand ? 5 : 1`), EC H 강제 (로고/띠 시)
- `lib/features/qr_result/data/services/qr_readability_service.dart` — readability 검증

### 6. 렌더링 4-경로 완전 일치 (Preview · Zoom · PNG · SVG)

**QR 출력 4-경로의 비율·모양·색상은 픽셀 수준으로 완벽히 일치해야 한다.** 한 경로에만 적용되는 데코/색상/효과 금지. 신규 데코 추가 시 4-경로 모두 동일 사이클 안에서 반영.

**4-경로**: ① 미리보기 (`QrLayerStack` 인라인) ② 확대보기 (zoom dialog, 동일 위젯 재사용) ③ PNG (`RepaintBoundary` 캡처) ④ SVG (별도 빌더)

**핵심 룰**:
- 비율/모양/색상 계산은 **공유 util** 한 곳에서만 (`customization_mapper.dart` / `logo_clear_zone.dart`)
- PNG 은 preview RepaintBoundary 캡처로 자동 일치, **SVG 빌더만 별도 경로** → 가장 자주 누락되니 매번 점검
- 하드코딩 색상 금지 (모두 `QrCustomization` / sub-state 주입)
- QR 데코 관련 Plan/Design 문서에 **4-경로 일치 체크리스트** 필수

**상세** (체크리스트, 자주 발생하는 실수, 충돌 해결): [`feedback_qr_render_parity.md`](auto-loaded)

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
❌ "PNG/SVG 출력에도 반영할까요?" → 항상 Yes 고정 (4-경로 동시 반영)
❌ "미리보기에만 적용할까요?" → 금지, 4-경로 모두 반영

---

## 📚 메모리 우선 참조

세션 시작 시 아래가 auto-memory 로 로드됨. PDCA/code 작업 전 **반드시** 참조한다.

- `~/.claude/projects/C--repository-app-tag/memory/MEMORY.md` (인덱스)
- `feedback_provider_pattern.md` — R-series Provider 패턴 상세 (8 Hard Rules + 디렉터리 템플릿)
- `feedback_code_decision_criteria.md` — Claude 가독성 우선 의사결정 기준
- `feedback_pdca_phase_defaults.md` — PDCA Phase별 고정 override (본 문서 연동)
- `feedback_qr_render_parity.md` — QR 4-경로 (Preview/Zoom/PNG/SVG) 픽셀 일치 강제 (§6 상세)

메모리 내용이 이 CLAUDE.md 와 충돌할 경우 **이 CLAUDE.md가 우선**. 메모리는 상세 레퍼런스, CLAUDE.md 는 강제 규약.

---

## 🛠 참조 구현

R-series 패턴의 canonical reference:
- `lib/features/qr_result/qr_result_provider.dart` — 234줄 메인 + 5 mixin + 5 sub-state + 4 entity
- Archived: `docs/archive/2026-04/refactor-qr-result-state/`, `refactor-qr-notifier-split/`
- UI 분할 레퍼런스: `docs/archive/2026-04/refactor-qr-shape-tab/`

신규 feature 는 위 구조와 **구조적으로 동형** 이어야 한다.
