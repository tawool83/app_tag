import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/error/result.dart';
import '../qr_task/domain/entities/qr_task_kind.dart';
import '../qr_task/domain/entities/qr_task_meta.dart';
import '../qr_task/presentation/providers/qr_task_providers.dart';
import '../../models/qr_template.dart';
import '../../models/sticker_config.dart' show StickerText;
import '../../services/qr_readability_service.dart';
import 'domain/entities/user_qr_template.dart';
import 'presentation/providers/qr_result_providers.dart';
import '../../core/services/settings_service.dart';
import '../../core/constants/app_config.dart' show validateQrData;
import 'qr_result_provider.dart';
import 'tabs/all_templates_tab.dart';
import 'tabs/qr_shape_tab.dart';
import 'tabs/qr_color_tab.dart';
import 'tabs/sticker_tab.dart';
import 'tabs/text_tab.dart';
import 'widgets/qr_preview_section.dart';

// 태그 타입별 아이콘/색상
(IconData, Color) _tagTypeIconColor(String? tagType) {
  switch (tagType) {
    case 'app':       return (Icons.apps, Colors.indigo);
    case 'clipboard': return (Icons.content_paste, Colors.blueGrey);
    case 'website':   return (Icons.language, Colors.blue);
    case 'contact':   return (Icons.contact_phone, Colors.green);
    case 'wifi':      return (Icons.wifi, Colors.teal);
    case 'location':  return (Icons.location_on, Colors.red);
    case 'event':     return (Icons.event, Colors.orange);
    case 'email':     return (Icons.email, Colors.deepPurple);
    case 'sms':       return (Icons.sms, Colors.pink);
    default:          return (Icons.qr_code, Colors.grey);
  }
}

// Material 아이콘 → PNG bytes 렌더링
Future<Uint8List> _renderMaterialIcon(IconData icon, Color color) async {
  const size = 96.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, size, size),
    Paint()..color = Colors.white,
  );
  canvas.drawCircle(
    const Offset(size / 2, size / 2),
    size / 2 - 4,
    Paint()..color = color.withValues(alpha: 0.15),
  );
  final tp = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        fontSize: 56,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size);
  tp.paint(canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2));
  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

// 이모지 → PNG bytes 렌더링
Future<Uint8List> _renderEmoji(String emoji) async {
  const size = 96.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, size, size),
    Paint()..color = Colors.white,
  );
  final tp = TextPainter(
    text: TextSpan(text: emoji, style: const TextStyle(fontSize: 68)),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size);
  tp.paint(canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2));
  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}


class QrResultScreen extends ConsumerStatefulWidget {
  const QrResultScreen({super.key});

  @override
  ConsumerState<QrResultScreen> createState() => _QrResultScreenState();
}

class _QrResultScreenState extends ConsumerState<QrResultScreen>
    with SingleTickerProviderStateMixin {
  final _repaintKey = GlobalKey();
  late TabController _tabController;
  QrTemplateManifest _templateManifest = QrTemplateManifest.empty;

  // 나의 템플릿 갱신용 key (AllTemplatesTab 강제 재빌드)
  int _myTemplatesVersion = 0;

  @override
  void initState() {
    super.initState();
    // 탭: 템플릿 / 모양 / 색상 / 로고 / 텍스트
    _tabController = TabController(length: 5, vsync: this);

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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<bool> _showLowReadabilityWarning(ReadabilityScore score) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('인식률이 낮습니다'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '현재 인식률: ${score.total}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('QR 코드가 일부 스캐너에서\n인식되지 않을 수 있습니다.'),
            const SizedBox(height: 8),
            Text(
              '주요 원인: ${score.mainIssue}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('그래도 저장'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _showSaveTemplateSheet() async {
    final nameCtrl = TextEditingController();
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
            const Text(
              '템플릿 저장',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              maxLength: 30,
              decoration: InputDecoration(
                labelText: '템플릿 이름',
                hintText: '예: 파란 배경 QR',
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
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isNotEmpty) {
                      Navigator.pop(ctx, true);
                    }
                  },
                  child: const Text('저장'),
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
      qrColorValue: state.qrColor.toARGB32(),
      gradientJson: state.customGradient != null
          ? jsonEncode(state.customGradient!.toJson())
          : null,
      roundFactor: state.roundFactor,
      dotStyleIndex: state.dotStyle.index,
      eyeOuterIndex: state.eyeOuter.index,
      eyeInnerIndex: state.eyeInner.index,
      randomEyeSeed: state.randomEyeSeed,
      quietZoneColorValue: state.quietZoneColor.toARGB32(),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('「$name」 템플릿이 저장되었습니다.'),
          duration: const Duration(seconds: 2),
        ),
      );
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

    return Scaffold(
      appBar: AppBar(title: const Text('QR 코드')),
      body: Column(
        children: [
          // ① QR 미리보기 + 인식률 배지
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: QrPreviewSection(
              repaintKey: _repaintKey,
              deepLink: deepLink,
              score: score,
            ),
          ),

          // ② 탭 바: 템플릿 / 모양 / 색상 / 로고 / 텍스트
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            tabs: const [
              Tab(text: '템플릿'),
              Tab(text: '모양'),
              Tab(text: '색상'),
              Tab(text: '로고'),
              Tab(text: '텍스트'),
            ],
          ),

          // ③ 탭 콘텐츠
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 0: 템플릿 (나의 템플릿 + 전체 템플릿 통합)
                AllTemplatesTab(
                  key: ValueKey(_myTemplatesVersion),
                  manifest: _templateManifest,
                  activeTemplateId: state.activeTemplateId,
                  onTemplateSelected: _onTemplateSelected,
                  onTemplateClear: _onTemplateClear,
                  onChanged: _recapture,
                ),
                // 1: 모양 (도트 + 눈)
                QrShapeTab(
                  onDotStyleChanged: (s) {
                    ref.read(qrResultProvider.notifier).setDotStyle(s);
                    _recapture();
                  },
                  onEyeOuterChanged: (s) {
                    ref.read(qrResultProvider.notifier).setEyeOuter(s);
                    _recapture();
                  },
                  onEyeInnerChanged: (s) {
                    ref.read(qrResultProvider.notifier).setEyeInner(s);
                    _recapture();
                  },
                  onRandomEyeRequested: () {
                    ref.read(qrResultProvider.notifier).regenerateEyeSeed();
                    _recapture();
                  },
                  onRandomEyeCleared: () {
                    ref.read(qrResultProvider.notifier).clearRandomEye();
                    _recapture();
                  },
                ),
                // 3: 색상 (단색 + 그라디언트 서브탭)
                QrColorTab(
                  onColorSelected: (c) {
                    ref.read(qrResultProvider.notifier).setQrColor(c);
                    _recapture();
                  },
                  onGradientChanged: (g) {
                    ref.read(qrResultProvider.notifier).setCustomGradient(g);
                    _recapture();
                  },
                ),
                // 4: 로고
                StickerTab(onChanged: _recapture),
                // 5: 텍스트
                TextTab(onChanged: _recapture),
              ],
            ),
          ),

          // ④ 액션 버튼
          _ActionButtons(
            state: state,
            onSaveGallery: () async {
              if (score.shouldWarnOnSave) {
                final proceed = await _showLowReadabilityWarning(score);
                if (!proceed || !mounted) return;
              }
              ref.read(qrResultProvider.notifier).saveToGallery(appName);
            },
            onSaveTemplate: () async {
              if (score.shouldWarnOnSave) {
                final proceed = await _showLowReadabilityWarning(score);
                if (!proceed || !mounted) return;
              }
              _showSaveTemplateSheet();
            },
            onShare: () =>
                ref.read(qrResultProvider.notifier).shareImage(appName),
          ),
        ],
      ),
    );
  }
}

// ── 액션 버튼 영역 ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final QrResultState state;
  final VoidCallback onSaveGallery;
  final VoidCallback onSaveTemplate;
  final VoidCallback onShare;

  const _ActionButtons({
    required this.state,
    required this.onSaveGallery,
    required this.onSaveTemplate,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.save_alt,
                  label: '갤러리 저장',
                  status: state.saveStatus,
                  onTap: onSaveGallery,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.bookmark_add_outlined,
                  label: '템플릿 저장',
                  status: QrActionStatus.idle,
                  onTap: onSaveTemplate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.share,
                  label: '공유',
                  status: state.shareStatus,
                  onTap: onShare,
                ),
              ),
            ],
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              state.errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 액션 버튼 단일 항목 ────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final QrActionStatus status;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = status == QrActionStatus.loading;
    final isSuccess = status == QrActionStatus.success;

    return ElevatedButton(
      onPressed: isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : icon,
                  size: 20,
                  color: isSuccess ? Colors.green : null,
                ),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(fontSize: 11)),
              ],
            ),
    );
  }
}
