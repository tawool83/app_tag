# Design — Main Screen Redesign (만들기-중심 홈 + 작업=템플릿 통합)

> 생성일: 2026-04-23
> 최종 수정: 2026-04-23 (Do phase 구현 반영)
> Feature ID: `main-screen-redesign`
> Plan 문서: `docs/01-plan/features/main-screen-redesign.plan.md`
> Architecture: Flutter Dynamic x Clean Architecture x R-series Provider

---

## Executive Summary

| Perspective | Summary |
|-------------|---------|
| **Problem** | 홈이 입력 진입점 나열 중심. 홈/히스토리 동일 데이터 공유로 독립 관리 불가. 꾸미기 편집 후 홈 복귀 시 변경 미반영. debounce 타이머 flush 없이 dispose되어 마지막 변경 소실 |
| **Solution** | 홈을 `[새로 만들기]` CTA + QR 타일 갤러리 + 삭제 모드로 재구성. `showOnHome` 플래그로 홈/히스토리 분리. `flushPendingPush()` + `onChanged()` 로 편집 즉시 반영. 미리보기 220px + scale 1.15 여백 제거 |
| **Function UX Effect** | 홈 1-depth에 타일 갤러리. 탭→확대 미리보기+5액션. 삭제 모드에서 다중/전체 선택. 꾸미기 `<-`+`저장` 단순화 |
| **Core Value** | 앱 강점을 홈에 즉시 노출 + 자동 템플릿화 + 홈/히스토리 독립 + 편집 즉시 반영 보장 |

---

## 1. Open Decisions 확정

| ID | 결정 | 근거 |
|----|------|------|
| **D1** | **안A: AppBar에 스캐너 아이콘** | 스캐너는 "읽기" 기능이므로 "만들기" 팝업에 혼재 부적절. AppBar history 옆에 `Icons.qr_code_scanner` 배치 |
| **D2** | **안A: debounce 500ms 동기화** | 기존 `_captureThumbnailToState` 의 300ms 후 캡처 → QrTask 의 `thumbnailBytes` 에 persist. QrResultNotifier 의 `_schedulePush` 와 동일 주기 |
| **D3** | **안A: off-screen RenderRepaintBoundary** | 홈 목록에서 action 시 `qrServiceProvider.captureQrImage` 로 임시 off-screen 캡처. 썸네일은 저해상도 미리보기용으로만 사용 |
| **D4** | NFC 버튼 disabled + 툴팁 | 기존 `nfcAvailableProvider` 재사용. 미지원 시 `l10n.msgNfcUnsupportedDevice` 표시 |
| **D5** | **안A: lazy fallback** | `QrTask.fromPayloadMap` 에서 `name` 없으면 `DateFormat('yyyy-MM-dd HH:mm').format(createdAt)` 채움 |
| **D6** | **편집(숨기기) 기능 삭제** | pre-release 에서 사용 빈도 극히 낮음. 10개 타일 고정 표시. `SettingsService.hiddenTileKeys` 관련 코드 전체 제거 |

---

## 2. Architecture

### 2.1 영향 범위 요약

```
삭제 대상 (destructive):
├─ lib/features/output_selector/                          # output_selector_screen.dart + route
├─ lib/features/qr_result/domain/entities/user_qr_template.dart
├─ lib/features/qr_result/data/models/user_qr_template_model.dart + .g.dart
├─ lib/features/qr_result/data/datasources/hive_user_template_datasource.dart
├─ lib/features/qr_result/data/datasources/user_template_local_datasource.dart
├─ lib/features/qr_result/data/repositories/user_template_repository_impl.dart
├─ lib/features/qr_result/domain/usecases/save_user_template_usecase.dart
├─ lib/features/qr_result/domain/usecases/get_user_templates_usecase.dart
├─ lib/features/qr_result/domain/usecases/delete_user_template_usecase.dart
├─ lib/features/qr_result/domain/usecases/clear_user_templates_usecase.dart
├─ lib/features/qr_result/tabs/my_templates_tab.dart
├─ lib/features/qr_result/qr_result_screen/action_buttons.dart  # part file
├─ lib/core/widgets/output_action_buttons.dart            # QR/NFC 2버튼 위젯
└─ core/di/router.dart: /output-selector route 행 제거

수정 대상:
├─ lib/features/home/home_screen.dart                     # rewrite: CTA + 갤러리
├─ lib/features/qr_result/qr_result_screen.dart           # action_buttons part 제거, 탭 5→4
├─ lib/features/qr_result/tabs/all_templates_tab.dart     # UserQrTemplate → QrTask 기반
├─ lib/features/qr_task/domain/entities/qr_task.dart      # +name, +thumbnailBytes, schema v2
├─ lib/features/qr_task/data/models/qr_task_model.dart    # name field in payload
├─ lib/features/qr_task/presentation/providers/qr_task_providers.dart  # +2 usecase providers
├─ lib/core/di/router.dart                                # output-selector 제거
├─ lib/core/di/hive_config.dart                           # deleteBoxFromDisk('user_qr_templates')
├─ lib/features/*/website_tag_screen.dart (× 8 tag-screen + app_picker + ios_input)  # 단일 CTA
├─ lib/l10n/app_ko.arb                                    # +15~20 keys
└─ assets/default_templates.json                          # 10 → 3 templates

신규:
├─ lib/features/home/widgets/create_picker_sheet.dart      # 새로 만들기 bottom sheet
├─ lib/features/home/widgets/qr_task_action_sheet.dart     # 목록 아이템 액션 sheet
├─ lib/features/home/widgets/qr_task_gallery_card.dart     # 갤러리 카드 위젯
├─ lib/features/qr_task/domain/usecases/rename_qr_task_usecase.dart
├─ lib/features/qr_task/domain/usecases/update_qr_task_thumbnail_usecase.dart
└─ lib/features/qr_task/presentation/widgets/rename_dialog.dart
```

### 2.2 데이터 모델 변경

#### QrTask entity (v2) ✅ 구현 완료

```dart
// lib/features/qr_task/domain/entities/qr_task.dart
class QrTask {
  static const int currentSchemaVersion = 2;  // 1 → 2

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final QrTaskKind kind;
  final String name;                          // NEW: 작업 이름
  final QrTaskMeta meta;
  final QrCustomization customization;
  final bool isFavorite;
  final Uint8List? thumbnailBytes;            // NEW: 미리보기 PNG
  final bool showOnHome;                      // NEW: 홈 갤러리 표시 여부 (default: true)

  // toPayloadMap: +name, +thumbnailBytes (Base64), +showOnHome
  // fromPayloadMap: name fallback = DateFormat('yyyy-MM-dd HH:mm').format(createdAt)
  //                 thumbnailBytes fallback = null
  //                 showOnHome fallback = true
  // copyWith: +name, +thumbnailBytes, +showOnHome
}
```

**Hive 호환**: `QrTaskModel` 의 4 HiveField 는 불변 (id/createdAt/kind/payloadJson). `name`, `thumbnailBytes`, `showOnHome` 는 `payloadJson` 내 JSON 필드로 추가되므로 **Hive adapter 재생성 불필요**.

#### UserQrTemplate 삭제

- entity, model, datasource, repository, usecase, providers 전부 삭제
- `user_qr_templates` Hive box: `Hive.deleteBoxFromDisk('user_qr_templates')` in hive_config.dart — best-effort, 실패 swallow

### 2.3 화면 구조 변경

#### Home (rewrite) ✅ 구현 완료

```
HomeScreen (ConsumerStatefulWidget)
  ├─ State: _tasks, _loading, _deleteMode, _selectedIds
  ├─ AppBar
  │   ├─ leading: Drawer 핸들러 (자동)
  │   └─ actions: [scanner, help, history, account]  // scanner 추가 (D1)
  ├─ Drawer: settings + app-info (기존 유지)
  └─ Body: Column
       ├─ CTA Row (Padding 16/12/16/8)
       │   ├─ Expanded: ElevatedButton.icon("새로 만들기", Icons.add) — 64px, primary, r:16
       │   └─ if _tasks.isNotEmpty:
       │       ├─ 비삭제 모드: IconButton.filled(Icons.delete_outline) → _enterDeleteMode
       │       └─ 삭제 모드: FilledButton("모두선택"/"확인") + IconButton(Icons.close)
       └─ Expanded: GridView.builder
            ├─ SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 120, ratio: 100/130)
            ├─ 빈 상태: Icon(qr_code, 64) + 안내 문구
            └─ QrTaskGalleryTile
                ├─ 비삭제 모드: onTap → _showActionSheet, onLongPress → _showActionSheet
                └─ 삭제 모드: onTap → _toggleSelection (체크 오버레이)
  ├─ _loadTasks: listHomeVisibleUseCaseProvider (showOnHome == true만)
  ├─ 삭제 모드 flow: trash → "모두선택" (전체 선택) → "확인" → 다이얼로그 → hideFromHomeUseCase × N
  └─ 홈 삭제 ≠ 영구 삭제: showOnHome=false 설정만 (히스토리 유지)
```

**삭제 항목**: `_editMode`, `_hiddenKeys`, `_showHiddenSection`, `_loadHiddenKeys()`, `_enterEditMode()`, `_exitEditMode()`, `_hideTile()`, `_restoreTile()`, `_buildTileWithBadge()`, `_buildHiddenSection()`, `_TileItem`, `_TileCard`, 배경 로고 Positioned.fill

#### 새로 만들기 Bottom Sheet (`create_picker_sheet.dart`)

```dart
// lib/features/home/widgets/create_picker_sheet.dart
class CreatePickerSheet extends StatelessWidget {
  // showModalBottomSheet(isScrollControlled: true)
  // 화면 높이 ~70%, DraggableScrollableSheet 또는 고정 높이
  // 10개 타일 GridView (2열 × 5행) — 기존 타일 정의 재사용
  // scanner 제외 (AppBar로 이동)
  // 타일 탭 → Navigator.pop → context.push('/xxx-tag')
  // D6 결정: 편집 기능 삭제 → 10개 고정
}
```

**타일 정의**: 기존 `_buildTiles()` 의 9개 타일 (scanner 제외) + `app_picker`/`ios_input` 플랫폼 분기 유지.

#### tag-screen CTA 단일화

**Before** (each tag-screen):
```dart
OutputActionButtons(onQrPressed: _onQr, onNfcPressed: _onNfc)
```

**After**:
```dart
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: _onQr,
    icon: const Icon(Icons.palette),
    label: Text(l10n.actionStartCustomize),
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
)
```

**영향 파일** (10개):
1. `website_tag_screen.dart` — `_onNfc()` 삭제, `OutputActionButtons` → 단일 버튼
2. `clipboard_tag_screen.dart` — 동일
3. `contact_tag_screen.dart` — 동일
4. `wifi_tag_screen.dart` — 동일
5. `location_tag_screen.dart` — 동일
6. `event_tag_screen.dart` — 동일
7. `email_tag_screen.dart` — 동일
8. `sms_tag_screen.dart` — 동일
9. `app_picker_screen.dart` — 동일
10. `ios_input_screen.dart` — 동일

각 파일에서:
- `import '../../core/widgets/output_action_buttons.dart'` 제거
- `_onNfc()` 메서드 삭제
- `OutputActionButtons(...)` → 단일 `ElevatedButton.icon`

#### QR 꾸미기 화면 (`qr_result_screen.dart`) ✅ 구현 완료

**AppBar 재구성**:
- leading: `IconButton(Icons.arrow_back)` — 편집기 활성 시 `_cancelActiveEditor`, 비활성 시 `_confirmAndPop`
- actions: 비편집기 모드일 때만 `TextButton(l10n.actionSave)` → `_confirmAndPop`
- title: 편집기 활성 시 편집기 라벨, 비활성 시 `l10n.screenQrResultTitle`

**`_confirmAndPop` 흐름** (편집 후 홈 반영 핵심):
```dart
Future<void> _confirmAndPop() async {
  await ref.read(qrResultProvider.notifier).flushPendingPush(); // debounce 즉시 실행
  await _recapture();  // 썸네일 캡처 + persist
  if (mounted) Navigator.of(context).pop();
}
```

**`PopScope(canPop: false)`**: 모든 뒤로가기(시스템 + AppBar) 인터셉트. 편집기 활성 시 취소, 비활성 시 저장+pop.

**하단 3버튼 제거 완료**: action_buttons.dart, `_showSaveTemplateSheet` 등 삭제됨.
**탭 5개 유지**: 템플릿/모양/색상/로고/텍스트

#### 템플릿 탭 재구성 (`all_templates_tab.dart`)

**Before**: 나의 템플릿(UserQrTemplate 가로 스크롤) + "스타일 없음" + 카테고리별 빌트인
**After**: "스타일 없음" + 빌트인 3종 가로 스크롤 (카테고리 flat)

- `_myTemplates` 관련 코드 전부 삭제 (UserQrTemplate 제거됨)
- `_loadMyTemplates()`, `_applyUserTemplate()`, `_deleteUserTemplate()` 삭제
- 나의 템플릿 섹션 SliverToBoxAdapter 블록 삭제
- 빌트인 3종만 표시 (카테고리 헤더 제거, flat grid)

### 2.4 새로 만들기 → 꾸미기 플로우

```
Home
  ├─ [새로 만들기 +] tap
  │   └─ CreatePickerSheet (bottom sheet)
  │       └─ 타일 tap → context.push('/website-tag')
  │           └─ WebsiteTagScreen
  │               └─ [QR 꾸미기 시작] tap → context.push('/qr-result', extra: args)
  │                   └─ QrResultScreen (자동 QrTask 발급, debounced 저장)
  │                       └─ 뒤로가기 → Home 갤러리에 반영
  │
  ├─ 갤러리 카드 tap → QrTaskActionSheet
  │   ├─ 이미지 저장 → off-screen render → saveToGallery
  │   ├─ 공유 → off-screen render → shareImage
  │   ├─ NFC 쓰기 → context.push('/nfc-writer', extra: nfcArgs)
  │   └─ 다시 꾸미기 → context.push('/qr-result', extra: {editTaskId: task.id, ...meta})
  │
  └─ 갤러리 카드 long-press → overflow menu
      ├─ 이름 변경 → RenameDialog
      ├─ 삭제 → confirm → deleteQrTask
      └─ 즐겨찾기 토글
```

### 2.5 목록 아이템 액션 Sheet (`qr_task_action_sheet.dart`) ✅ 구현 완료

```dart
// lib/features/home/widgets/qr_task_action_sheet.dart
class QrTaskActionSheet extends ConsumerWidget {
  final QrTask task;
  final VoidCallback onChanged;  // 홈 갤러리 리로드 콜백

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 확대 미리보기: 최대 220px, Transform.scale(1.15)로 캡처 여백 제거
          Builder(builder: (context) {
            const maxSide = 220.0;
            const thumbScale = 1.15;  // 184px 캡처 중 160px QR → 여백 크롭
            return Container(
              width: maxSide, height: maxSide,
              clipBehavior: Clip.antiAlias,
              child: Transform.scale(scale: thumbScale,
                child: Image.memory(task.thumbnailBytes!, fit: BoxFit.contain)),
            );
          }),
          // 이름
          Text(task.name, fontWeight: w600, maxLines: 1),
          const Divider(),
          // 5개 액션 ListTile:
          ListTile(Icons.save_alt, "이미지 저장"),    // → saveQrToGalleryUseCaseProvider
          ListTile(Icons.share, "공유"),              // → shareQrImageUseCaseProvider
          ListTile(Icons.palette, "다시 꾸미기"),     // → await context.push + onChanged()
          ListTile(Icons.edit, "이름 변경"),          // → showRenameDialog + renameUseCase
          ListTile(Icons.delete_outline, "삭제", red), // → 확인 다이얼로그 + deleteUseCase
        ],
      ),
    );
  }
}
```

**핵심 변경**: `_editAgain`이 `await context.push(...)` 후 `onChanged()` 호출 → 꾸미기 편집 후 홈 갤러리 즉시 반영.

**off-screen 렌더링**: 안1 (thumbnailBytes 직접 사용) 채택. 저장/공유에 `task.thumbnailBytes` 직접 전달.

### 2.6 갤러리 타일 (`qr_task_gallery_card.dart`) ✅ 구현 완료

```dart
// lib/features/home/widgets/qr_task_gallery_card.dart
class QrTaskGalleryTile extends StatelessWidget {
  final QrTask task;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool selectable;  // 삭제 모드 여부
  final bool selected;    // 선택 상태

  // Column:
  //   Stack:
  //     Container(100×100, r:12, border: selected ? primary 2.5px : grey 0.5px)
  //       ClipRRect(r:12) → Image.memory(task.thumbnailBytes, cover) or QR icon placeholder
  //     if selected: Positioned(top-right) → CircleAvatar(checkmark, primary)
  //     if selectable && !selected: Positioned(top-right) → 빈 원 테두리
  //   SizedBox(h:4)
  //   Text(task.name, fontSize: 11, maxLines: 1, overflow: ellipsis)
}
```

**GridView 설정**: `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 120, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 100/130)`

### 2.7 Rename Dialog (`rename_dialog.dart`)

```dart
// lib/features/qr_task/presentation/widgets/rename_dialog.dart
Future<String?> showRenameDialog(BuildContext context, String currentName) async {
  // AlertDialog with TextField(maxLength: 40, autofocus: true)
  // 취소 / 저장 actions
  // returns new name or null
}
```

### 2.8 UseCase 추가

```dart
// lib/features/qr_task/domain/usecases/rename_qr_task_usecase.dart
class RenameQrTaskUseCase {
  final QrTaskRepository _repo;
  RenameQrTaskUseCase(this._repo);

  Future<Result<void>> call(String taskId, String newName) async {
    final task = await _repo.getById(taskId);
    if (task == null) return Result.failure(Exception('Task not found'));
    final updated = task.copyWith(name: newName, updatedAt: DateTime.now());
    await _repo.update(updated);
    return Result.success(null);
  }
}

// lib/features/qr_task/domain/usecases/update_qr_task_thumbnail_usecase.dart
class UpdateQrTaskThumbnailUseCase {
  final QrTaskRepository _repo;
  UpdateQrTaskThumbnailUseCase(this._repo);

  Future<Result<void>> call(String taskId, Uint8List thumbnailBytes) async {
    final task = await _repo.getById(taskId);
    if (task == null) return Result.failure(Exception('Task not found'));
    final updated = task.copyWith(thumbnailBytes: thumbnailBytes, updatedAt: DateTime.now());
    await _repo.update(updated);
    return Result.success(null);
  }
}
```

**Provider 등록** (`qr_task_providers.dart`):

```dart
final renameQrTaskUseCaseProvider = Provider<RenameQrTaskUseCase>(
  (ref) => RenameQrTaskUseCase(ref.watch(qrTaskRepositoryProvider)),
);

final updateQrTaskThumbnailUseCaseProvider = Provider<UpdateQrTaskThumbnailUseCase>(
  (ref) => UpdateQrTaskThumbnailUseCase(ref.watch(qrTaskRepositoryProvider)),
);
```

### 2.9 QrTaskRepository 확장

기존 `QrTaskRepository` 에 `update(QrTask)` 메서드가 필요. 현재 `updateCustomization` 만 존재.

```dart
// domain/repositories/qr_task_repository.dart — 추가
Future<Result<void>> update(QrTask task);

// data/repositories/qr_task_repository_impl.dart — 추가
@override
Future<Result<void>> update(QrTask task) async {
  try {
    final model = QrTaskModel.fromEntity(task);
    await _datasource.put(model);
    return Result.success(null);
  } catch (e) {
    return Result.failure(e as Exception);
  }
}
```

### 2.10 홈/히스토리 데이터 분리 ✅ 구현 완료

**QrTaskRepository 확장** (3개 메서드 추가):
```dart
Future<Result<void>> hideFromHome(String id);       // showOnHome = false
Future<Result<List<QrTask>>> listHomeVisible();      // showOnHome == true, updatedAt desc
Future<Result<void>> hideAllFromHome();              // 전체 showOnHome = false
```

**UseCase 3개 신규**:
- `HideFromHomeUseCase` — 홈 갤러리에서 제거 (히스토리 유지)
- `ListHomeVisibleUseCase` — 홈 갤러리 목록 조회
- `HideAllFromHomeUseCase` — 전체 홈 갤러리 숨기기

**Provider 등록** (`qr_task_providers.dart`):
```dart
final hideFromHomeUseCaseProvider = Provider<HideFromHomeUseCase>(...);
final listHomeVisibleUseCaseProvider = Provider<ListHomeVisibleUseCase>(...);
final hideAllFromHomeUseCaseProvider = Provider<HideAllFromHomeUseCase>(...);
```

### 2.11 flushPendingPush (debounce 즉시 실행) ✅ 구현 완료

**문제**: `QrResultNotifier`의 커스터마이제이션 저장이 500ms debounce. pop 시 `autoDispose` → `dispose()` → 타이머 취소 → 마지막 변경 소실.

**해결**: `flushPendingPush()` 메서드 추가:
```dart
// lib/features/qr_result/qr_result_provider.dart
Future<void> flushPendingPush() async {
  if (_debounceTimer?.isActive ?? false) {
    _debounceTimer!.cancel();
    await _pushNow();
  }
}
```

**호출 위치**: `_confirmAndPop()` 에서 pop 직전 호출 → 모든 변경 Hive 영속 보장.

### 2.12 Thumbnail Capture 연동 (`qr_result_screen.dart`) ✅ 구현 완료

썸네일 캡처 + QrTask 영속 흐름:
```dart
_captureThumbnailToState() → 300ms delay → RepaintBoundary 캡처
  → setCapturedImage(bytes)
  → _persistThumbnail(bytes) → updateQrTaskThumbnailUseCaseProvider(taskId, bytes)

_recapture() → 100ms delay → 캡처 → setCapturedImage + _persistThumbnail
```

**`_confirmAndPop` 전체 흐름**:
```
flushPendingPush() → _recapture() → pop → [액션시트의 onChanged() → _loadTasks()]
```

### 2.11 default_templates.json 축소

```json
{
  "schemaVersion": 1,
  "updatedAt": "2026-04-23T00:00:00Z",
  "categories": [
    { "id": "default", "name": "기본", "order": 1 }
  ],
  "templates": [
    {
      "id": "minimal_black",
      "minEngineVersion": 1,
      "name": "블랙",
      "categoryId": "default",
      "order": 1,
      "tagTypes": ["all"],
      "roundFactor": 0.0,
      "thumbnailUrl": null,
      "isPremium": false,
      "style": {
        "dataModuleShape": "square",
        "eyeShape": "square",
        "backgroundColor": "#FFFFFF",
        "foreground": { "type": "solid", "solidColor": "#000000" },
        "eyeColor": { "type": "solid", "solidColor": "#000000" },
        "centerIcon": { "type": "none" }
      }
    },
    {
      "id": "minimal_red",
      "minEngineVersion": 1,
      "name": "레드",
      "categoryId": "default",
      "order": 2,
      "tagTypes": ["all"],
      "roundFactor": 0.0,
      "thumbnailUrl": null,
      "isPremium": false,
      "style": {
        "dataModuleShape": "square",
        "eyeShape": "square",
        "backgroundColor": "#FFFFFF",
        "foreground": { "type": "solid", "solidColor": "#E53935" },
        "eyeColor": { "type": "solid", "solidColor": "#E53935" },
        "centerIcon": { "type": "none" }
      }
    },
    {
      "id": "social_instagram",
      "minEngineVersion": 1,
      "name": "인스타그램",
      "categoryId": "default",
      "order": 3,
      "tagTypes": ["all"],
      "roundFactor": 1.0,
      "thumbnailUrl": null,
      "isPremium": false,
      "style": {
        "dataModuleShape": "circle",
        "eyeShape": "circle",
        "backgroundColor": "#FFFFFF",
        "foreground": {
          "type": "gradient",
          "gradient": {
            "type": "linear",
            "colors": ["#F58529", "#DD2A7B", "#8134AF", "#515BD4"],
            "stops": [0.0, 0.33, 0.66, 1.0],
            "angleDegrees": 45
          }
        },
        "eyeColor": { "type": "solid", "solidColor": "#8134AF" },
        "centerIcon": { "type": "none" }
      }
    }
  ]
}
```

### 2.12 Hive Box 정리

```dart
// lib/core/di/hive_config.dart — initHive() 또는 bootstrap 에서:
try {
  await Hive.deleteBoxFromDisk('user_qr_templates');
} catch (_) {
  // best-effort: pre-release — 실패해도 무시
}
```

### 2.13 Router 변경

```dart
// lib/core/di/router.dart — 삭제:
import '../../features/output_selector/output_selector_screen.dart';  // 삭제
GoRoute(path: '/output-selector', builder: (_, _) => const OutputSelectorScreen()),  // 삭제
```

---

## 3. l10n 신규 키 (`app_ko.arb`)

```json
"actionStartCustomize": "QR 꾸미기 시작",
"actionEditAgain": "다시 꾸미기",
"actionCreateNew": "새로 만들기",
"homeEmptyTitle": "첫 QR을 만들어 보세요",
"homeEmptySubtitle": "위 버튼을 눌러 시작하세요",
"sheetCreateTitle": "새로 만들기",
"actionRename": "이름 변경",
"dialogRenameTitle": "이름 변경",
"dialogRenameHint": "새 이름 입력",
"actionToggleFavorite": "즐겨찾기",
"dialogDeleteTaskTitle": "작업 삭제",
"dialogDeleteTaskContent": "「{name}」을(를) 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.",
"labelUpdatedAt": "수정: {date}",
"tooltipScanner": "QR 스캔",
"actionNfcWriteFromList": "NFC 쓰기"
```

---

## 4. Implementation Order (구현 상태 반영)

| 순서 | 작업 | 파일 | 상태 |
|:----:|------|------|:----:|
| 1 | QrTask entity v2 (name + thumbnailBytes + showOnHome) | `qr_task.dart` | ✅ |
| 2 | QrTaskRepository 확장 (hideFromHome, listHomeVisible, hideAllFromHome) | `qr_task_repository.dart`, `qr_task_repository_impl.dart` | ✅ |
| 3 | UseCase 5개 (Rename + Thumbnail + Hide×3) | `domain/usecases/` × 5 | ✅ |
| 4 | Provider 등록 (5개) | `qr_task_providers.dart` | ✅ |
| 5 | flushPendingPush 추가 | `qr_result_provider.dart` | ✅ |
| 6 | 꾸미기 AppBar 재구성 (← + 저장) | `qr_result_screen.dart` | ✅ |
| 7 | Thumbnail persist 연동 | `qr_result_screen.dart` | ✅ |
| 8 | RenameDialog | `rename_dialog.dart` | ✅ |
| 9 | QrTaskGalleryTile (삭제 모드 지원) | `qr_task_gallery_card.dart` | ✅ |
| 10 | QrTaskActionSheet (미리보기 + 5액션 + onChanged) | `qr_task_action_sheet.dart` | ✅ |
| 11 | CreatePickerSheet | `create_picker_sheet.dart` | ✅ |
| 12 | HomeScreen rewrite (갤러리 + 삭제 모드) | `home_screen.dart` | ✅ |
| 13 | l10n 키 추가 + gen-l10n | `app_ko.arb` | ✅ |
| 14 | 테스트 수정 (schemaVersion) | `qr_customization_test.dart` | ✅ |
| 15 | UserQrTemplate 계층 삭제 | entity, model, datasource, repo, usecase × 4 | 미착수 |
| 16 | Hive box 삭제 로직 | `hive_config.dart` | 미착수 |
| 17 | output_selector 삭제 + router 정리 | `output_selector/`, `router.dart` | 미착수 |
| 18 | default_templates.json 축소 | `assets/default_templates.json` | 미착수 |

**완료**: 14/18 항목 (그룹 A+C 완료). **잔여**: 그룹 B (삭제 작업 4개)

---

## 5. File Size Compliance

| 파일 | 예상 줄 수 | 제한 | 비고 |
|------|--------:|:----:|------|
| `home_screen.dart` | ~150 | 400 | rewrite (기존 534줄 → 대폭 축소) |
| `create_picker_sheet.dart` | ~120 | 400 | 신규 |
| `qr_task_action_sheet.dart` | ~100 | 400 | 신규 |
| `qr_task_gallery_card.dart` | ~80 | 400 | 신규 |
| `rename_dialog.dart` | ~40 | 150 | 신규 |
| `rename_qr_task_usecase.dart` | ~20 | 150 | 신규 |
| `update_qr_task_thumbnail_usecase.dart` | ~20 | 150 | 신규 |
| `qr_task.dart` | ~110 | 200 | 기존 85 → +25 |
| `all_templates_tab.dart` | ~120 | 400 | 기존 290 → 축소 |
| `qr_result_screen.dart` | ~400 | 400 | 기존 538 → -138 (action 제거) |

---

## 6. Edge Cases

| 상황 | 처리 |
|------|------|
| 기존 QrTask에 name 필드 없음 | `fromPayloadMap` 에서 `DateFormat('yyyy-MM-dd HH:mm').format(createdAt)` 폴백 |
| 기��� QrTask에 thumbnailBytes 없음 | null → 갤러리 타일에서 QR icon placeholder 표시 |
| 기존 QrTask에 showOnHome 없음 | `fromPayloadMap` 에서 `true` 폴백 → 모든 기존 작업이 홈에 표시 |
| 홈 삭제 후 히스토리 데이터 | `showOnHome = false` 만 설정, QrTask 자체는 유지 → 히스토리에서 계속 접근 가능 |
| 꾸미기 편집 후 500ms 내 뒤로가기 | `flushPendingPush()` 가 debounce 즉시 실행 → 마지막 변경 보장 |
| 꾸미기에서 돌아온 후 홈 갤러리 | `_editAgain`이 `await context.push` 후 `onChanged()` 호출 → `_loadTasks()` 리로드 |
| 썸네일 캡처 여백 (12px padding) | `Transform.scale(1.15)` + `Clip.antiAlias` 로 크롭하여 QR이 미리보기를 가득 채움 |
| 액션시트 메뉴가 스크롤로 가려짐 | 미리보기 최대 220px 제한 + `SingleChildScrollView` 안전장치 |
| UserQrTemplate box 삭제 실패 | catch + 무시 (pre-release) |
| activeTemplateId 가 삭제�� 빌트인 id 참조 | null 취급 — customization 내 ���제 값 우선 (기존 동작) |
| rename 시 빈 문자열 | TextField validator — trim ��� 비어있으면 저장 버튼 disabled |
| 갤러리 200개 + 스크롤 성능 | `GridView.builder` lazy 빌드 + `Image.memory` 자동 decode |

---

_이 Design 은 CLAUDE.md 고정 규약(R-series Provider 패턴 + Clean Architecture + l10n ko 선반영)을 기반으로 작성되었습니다. 3-옵션 아키텍처 비교는 건너뛰고 R-series 고정 구조를 적용합니다._
