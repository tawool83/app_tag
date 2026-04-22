library;

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/error/result.dart';
import '../../core/extensions/context_extensions.dart';
import '../qr_task/domain/entities/qr_task_kind.dart';
import '../qr_task/domain/entities/qr_task_meta.dart';
import '../qr_task/presentation/providers/qr_task_providers.dart';
import 'domain/entities/qr_action_status.dart';
import 'domain/entities/qr_template.dart';
import 'domain/entities/sticker_config.dart' show StickerText;
import 'data/services/qr_readability_service.dart';
import 'domain/entities/user_qr_template.dart';
import 'presentation/providers/qr_result_providers.dart';
import '../../core/services/settings_service.dart';
import '../../core/constants/app_config.dart' show validateQrData;
import 'qr_result_provider.dart';
import '../../l10n/app_localizations.dart';
import 'tabs/all_templates_tab.dart';
import 'tabs/qr_shape_tab.dart';
import 'tabs/qr_color_tab.dart';
import 'tabs/sticker_tab.dart';
import 'tabs/text_tab.dart';
import 'widgets/qr_preview_section.dart';

// ── 파트 분리: qr_result_screen/ 하위로 이동한 헬퍼/위젯 ───────────────────
part 'qr_result_screen/icon_renderer.dart';
part 'qr_result_screen/action_buttons.dart';

class QrResultScreen extends ConsumerStatefulWidget {
  const QrResultScreen({super.key});

  @override
  ConsumerState<QrResultScreen> createState() => _QrResultScreenState();
}

class _QrResultScreenState extends ConsumerState<QrResultScreen>
    with SingleTickerProviderStateMixin {
  final _repaintKey = GlobalKey();
  final _colorTabKey = GlobalKey<QrColorTabState>();
  final _shapeTabKey = GlobalKey<QrShapeTabState>();
  late TabController _tabController;
  QrTemplateManifest _templateManifest = QrTemplateManifest.empty;

  // 나의 템플릿 갱신용 key (AllTemplatesTab 강제 재빌드)
  int _myTemplatesVersion = 0;

  // 편집기 모드 (탭/하단 버튼 숨김용)
  bool _colorEditorMode = false;
  bool _shapeEditorMode = false;

  /// 편집기 활성 여부
  bool get _isEditorActive => _colorEditorMode || _shapeEditorMode;

  @override
  void initState() {
    super.initState();
    // 탭: 템플릿 / 모양 / 색상 / 로고 / 텍스트
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args =
          GoRouterState.of(context).extra as Map<String, dynamic>;

      // 중앙 집중 deepLink 유효성 검사
      final deepLink = args['deepLink'] as String;
      final validationError = validateQrData(deepLink);
      if (validationError != null && mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(validationError),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }

      final tagType = args['tagType'] as String?;
      final appName = args['appName'] as String;
      final notifier = ref.read(qrResultProvider.notifier);

      // editTaskId 가 있으면 기존 QrTask 복원, 없으면 신규 발급.
      final editTaskId = args['editTaskId'] as String?;
      final isEditMode = editTaskId != null;

      if (isEditMode) {
        final result =
            await ref.read(getQrTaskByIdUseCaseProvider)(editTaskId);
        if (!mounted) return;
        final task = result.valueOrNull;
        if (task != null) {
          notifier.loadFromCustomization(task.customization);
          notifier.setCurrentTaskId(task.id);
          notifier.setTagType(task.meta.tagType);
        }
      } else {
        final platform = args['platform'] as String;
        final packageName = args['packageName'] as String?;
        final deepLinkArg = args['deepLink'] as String;
        final createResult =
            await ref.read(createQrTaskUseCaseProvider)(
          kind: QrTaskKind.qr,
          meta: QrTaskMeta(
            appName: appName,
            deepLink: deepLinkArg,
            platform: platform,
            packageName: packageName,
            tagType: tagType,
          ),
        );
        if (!mounted) return;
        final task = createResult.valueOrNull;
        if (task != null) notifier.setCurrentTaskId(task.id);
      }

      // 신규 발급일 때만 디폴트 설정 적용 (편집 복원에서는 JSON 값 우선)
      if (!isEditMode) {
        final lastSize = await SettingsService.getLastPrintSizeCm();
        final embedIcon = await SettingsService.getQrEmbedIcon();
        final savedEmoji = await SettingsService.getQrCenterEmoji();

        notifier.setPrintSizeCm(lastSize);
        notifier.setEmbedIcon(embedIcon);
        notifier.setTagType(tagType);

        // 하단 텍스트 기본값: 앱 이름으로 pre-fill (아직 설정되지 않은 경우)
        final currentState = ref.read(qrResultProvider);
        if (currentState.sticker.bottomText == null) {
          notifier.setSticker(
            currentState.sticker.copyWith(
              bottomText: StickerText(content: appName),
            ),
          );
        }

        if (savedEmoji != null && mounted) {
          final emojiBytes = await _renderEmoji(savedEmoji);
          if (mounted) notifier.setCenterEmoji(savedEmoji, emojiBytes);
        }
      }

      // defaultIconBytes 는 editMode 여부와 무관하게 항상 재생성 (캐시 안 함)
      final appIconBytes = args['appIconBytes'] as Uint8List?;
      if (appIconBytes != null) {
        notifier.setDefaultIconBytes(appIconBytes);
      } else {
        final (icon, color) = _tagTypeIconColor(tagType);
        final rendered = await _renderMaterialIcon(icon, color);
        if (mounted) notifier.setDefaultIconBytes(rendered);
      }

      // 이미지 캡처 (UI 미리보기용) — JSON 저장과 별개
      _captureThumbnailToState();

      ref.read(getDefaultTemplatesUseCaseProvider)().then((result) {
        final manifest = result.valueOrNull;
        if (manifest != null && mounted) {
          setState(() => _templateManifest = manifest);
        }
      });
    });
  }

  /// 탭 전환 시 편집기 모드 자동 확인(닫기)
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    // 모양 탭(index 1) 이외로 이동하면 모양 편집기를 확인 처리
    if (_shapeEditorMode && _tabController.index != 1) {
      _shapeTabKey.currentState?.confirmAndCloseEditor();
      setState(() => _shapeEditorMode = false);
    }
    // 색상 탭(index 2) 이외로 이동하면 색상 편집기를 확인 처리
    if (_colorEditorMode && _tabController.index != 2) {
      _colorTabKey.currentState?.confirmAndCloseEditor();
      setState(() => _colorEditorMode = false);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// 편집기 취소 — AppBar 뒤로가기 시 호출
  Future<void> _cancelActiveEditor() async {
    if (_shapeEditorMode) {
      final closed = await _shapeTabKey.currentState?.cancelAndCloseEditor() ?? true;
      if (closed && mounted) setState(() => _shapeEditorMode = false);
    } else if (_colorEditorMode) {
      _colorTabKey.currentState?.cancelAndCloseEditor();
      setState(() => _colorEditorMode = false);
    }
  }

  /// QR 위젯이 렌더링된 후 미리보기 이미지 캡처 (UI 보조).
  /// 실제 데이터 영속은 QrResultNotifier 의 debounced JSON 저장 책임.
  Future<void> _captureThumbnailToState() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final boundary = _repaintKey.currentContext
        ?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final bytes = await ref.read(qrServiceProvider).captureQrImage(boundary);
    if (bytes != null && mounted) {
      ref.read(qrResultProvider.notifier).setCapturedImage(bytes);
    }
  }

  Future<Uint8List?> _captureThumbnail() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final boundary = _repaintKey.currentContext
        ?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    return ref.read(qrServiceProvider).captureQrImage(boundary);
  }

  Future<void> _recapture() async {
    final bytes = await _captureThumbnail();
    if (bytes != null) {
      ref.read(qrResultProvider.notifier).setCapturedImage(bytes);
    }
  }

  Future<void> _showReadabilitySnackBarIfNeeded(ReadabilityScore score) async {
    final alertEnabled = await SettingsService.getReadabilityAlert();
    if (!alertEnabled || !score.shouldWarnOnSave || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    context.showSnack(
      '${l10n.dialogLowReadabilityTitle}: ${score.total}% — ${score.mainIssue}',
      backgroundColor: Colors.orange.shade700,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _showSaveTemplateSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    try {
      await _runSaveTemplateSheet(l10n, nameCtrl);
    } finally {
      nameCtrl.dispose();
    }
  }

  Future<void> _runSaveTemplateSheet(AppLocalizations l10n, TextEditingController nameCtrl) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24, 24, 24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dialogSaveTemplateTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              maxLength: 30,
              decoration: InputDecoration(
                labelText: l10n.labelTemplateName,
                hintText: l10n.hintTemplateName,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.actionCancel),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isNotEmpty) {
                      Navigator.pop(ctx, true);
                    }
                  },
                  child: Text(l10n.actionSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    final state = ref.read(qrResultProvider);
    final thumbnail = await _captureThumbnail();

    final template = UserQrTemplate(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
      // 배경 레이어 — 배경 이미지 기능 제거됨, Hive 스키마 호환을 위해 기본값만 저장
      // QR 레이어
      qrColorValue: state.style.qrColor.toARGB32(),
      gradientJson: state.style.customGradient != null
          ? jsonEncode(state.style.customGradient!.toJson())
          : null,
      roundFactor: state.style.roundFactor,
      dotStyleIndex: state.style.dotStyle.index,
      eyeOuterIndex: state.style.eyeOuter.index,
      eyeInnerIndex: state.style.eyeInner.index,
      randomEyeSeed: state.style.randomEyeSeed,
      quietZoneColorValue: state.style.quietZoneColor.toARGB32(),
      // 스티커 레이어
      logoPositionIndex: state.sticker.logoPosition.index,
      logoBackgroundIndex: state.sticker.logoBackground.index,
      topTextContent: state.sticker.topText?.content,
      topTextColorValue: state.sticker.topText?.color.toARGB32(),
      topTextFont: state.sticker.topText?.fontFamily,
      topTextSize: state.sticker.topText?.fontSize,
      bottomTextContent: state.sticker.bottomText?.content,
      bottomTextColorValue: state.sticker.bottomText?.color.toARGB32(),
      bottomTextFont: state.sticker.bottomText?.fontFamily,
      bottomTextSize: state.sticker.bottomText?.fontSize,
      thumbnailBytes: thumbnail,
    );

    await ref.read(saveUserTemplateUseCaseProvider)(template);

    if (mounted) {
      context.showSnack(l10n.msgTemplateSaved(name));
      // 템플릿 탭으로 이동 (새 key로 AllTemplatesTab 강제 재빌드)
      setState(() => _myTemplatesVersion++);
      _tabController.animateTo(0);
    }
  }

  Future<void> _onTemplateSelected(QrTemplate template) async {
    Uint8List? iconBytes;
    if (template.style.centerIcon.type == 'url' &&
        template.style.centerIcon.url != null) {
      final result = await ref
          .read(loadTemplateImageUseCaseProvider)(template.style.centerIcon.url!);
      iconBytes = result.valueOrNull;
    }
    if (!mounted) return;
    ref
        .read(qrResultProvider.notifier)
        .applyTemplate(template, centerIconBytes: iconBytes);
    SettingsService.saveActiveTemplateId(template.id);
    _recapture();
  }

  void _onTemplateClear() {
    ref.read(qrResultProvider.notifier).clearTemplate();
    SettingsService.saveActiveTemplateId(null);
    _recapture();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        GoRouterState.of(context).extra as Map<String, dynamic>;
    final appName = args['appName'] as String;
    final deepLink = args['deepLink'] as String;

    final state = ref.watch(qrResultProvider);
    final score = QrReadabilityService.calculate(state, deepLink);
    final l10n = AppLocalizations.of(context)!;

    // 편집기 활성 시 AppBar 타이틀
    final editorTitle = _shapeEditorMode
        ? _shapeTabKey.currentState?.activeEditorLabel(l10n)
        : _colorEditorMode
            ? l10n.labelCustomGradient
            : null;

    return PopScope(
      canPop: !_isEditorActive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isEditorActive) _cancelActiveEditor();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(editorTitle ?? l10n.screenQrResultTitle),
        leading: _isEditorActive
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _cancelActiveEditor,
              )
            : null,
        // 모든 편집기 (shape/color) 뒤로가기가 자동 저장 — [저장] 버튼 불필요.
        actions: const [],
      ),
      body: Column(
        children: [
          // ① QR 미리보기
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: QrPreviewSection(
              repaintKey: _repaintKey,
              deepLink: deepLink,
            ),
          ),

          // ② 탭 바: 편집기 모드에서는 숨김
          if (!_isEditorActive)
            TabBar(
              controller: _tabController,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: [
                Tab(text: l10n.tabTemplate),
                Tab(text: l10n.tabShape),
                Tab(text: l10n.tabColor),
                Tab(text: l10n.tabLogo),
                Tab(text: l10n.tabText),
              ],
            ),

          // ③ 탭 콘텐츠
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: _isEditorActive
                  ? const NeverScrollableScrollPhysics()
                  : null,
              children: [
                // 0: 템플릿 (나의 템플릿 + 전체 템플릿 통합)
                AllTemplatesTab(
                  key: ValueKey(_myTemplatesVersion),
                  manifest: _templateManifest,
                  activeTemplateId: state.template.activeTemplateId,
                  onTemplateSelected: _onTemplateSelected,
                  onTemplateClear: _onTemplateClear,
                  onChanged: _recapture,
                ),
                // 1: 모양 (도트 + 눈 + 외곽 + 애니메이션)
                QrShapeTab(
                  key: _shapeTabKey,
                  onEyeOuterChanged: (s) {
                    ref.read(qrResultProvider.notifier).setEyeOuter(s);
                    _recapture();
                  },
                  onEyeInnerChanged: (s) {
                    ref.read(qrResultProvider.notifier).setEyeInner(s);
                    _recapture();
                  },
                  onEditorModeChanged: (editing) {
                    setState(() => _shapeEditorMode = editing);
                  },
                ),
                // 3: 색상 (단색 + 그라디언트 서브탭)
                QrColorTab(
                  key: _colorTabKey,
                  onColorSelected: (c) {
                    ref.read(qrResultProvider.notifier).setQrColor(c);
                    _recapture();
                  },
                  onGradientChanged: (g) {
                    ref.read(qrResultProvider.notifier).setCustomGradient(g);
                    _recapture();
                  },
                  onEditorModeChanged: (editing) {
                    setState(() => _colorEditorMode = editing);
                  },
                ),
                // 4: 로고
                StickerTab(onChanged: _recapture),
                // 5: 텍스트
                TextTab(onChanged: _recapture),
              ],
            ),
          ),

          // ④ 액션 버튼 (편집기 모드일 때 숨김 — 편집기 자체에 확인/취소 버튼)
          if (!_colorEditorMode && !_shapeEditorMode) _ActionButtons(
            state: state,
            onSaveGallery: () async {
              await _showReadabilitySnackBarIfNeeded(score);
              ref.read(qrResultProvider.notifier).saveToGallery(appName);
            },
            onSaveTemplate: () async {
              await _showReadabilitySnackBarIfNeeded(score);
              _showSaveTemplateSheet();
            },
            onShare: () =>
                ref.read(qrResultProvider.notifier).shareImage(appName),
          ),
        ],
      ),
    ),
    );
  }
}

