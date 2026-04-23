library;

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/error/result.dart';
import '../qr_task/domain/entities/qr_task_kind.dart';
import '../qr_task/domain/entities/qr_task_meta.dart';
import '../qr_task/presentation/providers/qr_task_providers.dart';
import 'domain/entities/qr_template.dart';
import 'domain/entities/sticker_config.dart' show StickerText;
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

  /// 뒤로가기 — 커스터마이제이션 flush + 썸네일 캡처 후 pop.
  Future<void> _confirmAndPop() async {
    await ref.read(qrResultProvider.notifier).flushPendingPush();
    await _recapture();
    if (mounted) Navigator.of(context).pop();
  }

  /// 저장 — 커스터마이제이션 flush + 썸네일 캡처 완료 후 홈으로 이동.
  Future<void> _saveAndGoHome() async {
    await ref.read(qrResultProvider.notifier).flushPendingPush();
    final bytes = await _captureThumbnail();
    if (bytes != null) {
      ref.read(qrResultProvider.notifier).setCapturedImage(bytes);
      await _persistThumbnailAsync(bytes);
    }
    if (mounted) context.go('/home', extra: DateTime.now().millisecondsSinceEpoch);
  }

  /// QR 위젯이 렌더링된 후 미리보기 이미지 캡처 + QrTask에 영속.
  Future<void> _captureThumbnailToState() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final boundary = _repaintKey.currentContext
        ?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final bytes = await ref.read(qrServiceProvider).captureQrImage(boundary);
    if (bytes != null && mounted) {
      ref.read(qrResultProvider.notifier).setCapturedImage(bytes);
      _persistThumbnail(bytes);
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
      _persistThumbnail(bytes);
    }
  }

  void _persistThumbnail(Uint8List bytes) {
    final taskId = ref.read(qrResultProvider.notifier).currentTaskId;
    if (taskId != null) {
      ref.read(updateQrTaskThumbnailUseCaseProvider)(taskId, bytes);
    }
  }

  Future<void> _persistThumbnailAsync(Uint8List bytes) async {
    final taskId = ref.read(qrResultProvider.notifier).currentTaskId;
    if (taskId != null) {
      await ref.read(updateQrTaskThumbnailUseCaseProvider)(taskId, bytes);
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
    final deepLink = args['deepLink'] as String;

    final state = ref.watch(qrResultProvider);
    final l10n = AppLocalizations.of(context)!;

    // 편집기 활성 시 AppBar 타이틀
    final editorTitle = _shapeEditorMode
        ? _shapeTabKey.currentState?.activeEditorLabel(l10n)
        : _colorEditorMode
            ? l10n.labelCustomGradient
            : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isEditorActive) {
          _cancelActiveEditor();
        } else {
          _confirmAndPop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(editorTitle ?? l10n.screenQrResultTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isEditorActive ? _cancelActiveEditor : _confirmAndPop,
        ),
        actions: _isEditorActive
            ? const []
            : [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilledButton(
                    onPressed: _saveAndGoHome,
                    child: Text(l10n.actionSave),
                  ),
                ),
              ],
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

        ],
      ),
    ),
    );
  }
}

