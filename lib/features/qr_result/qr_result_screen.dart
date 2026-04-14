import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/tag_history.dart';
import '../../models/qr_template.dart';
import '../../models/sticker_config.dart' show StickerText;
import '../../models/user_qr_template.dart';
import '../../repositories/template_repository.dart';
import '../../repositories/user_template_repository.dart';
import '../../services/settings_service.dart';
import '../../shared/constants/app_config.dart' show validateQrData;
import 'qr_result_provider.dart';
import 'tabs/all_templates_tab.dart';
import 'tabs/background_tab.dart';
import 'tabs/qr_shape_tab.dart';
import 'tabs/qr_color_tab.dart';
import 'tabs/sticker_tab.dart';
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
  bool _historySaved = false;
  late TabController _tabController;
  QrTemplateManifest _templateManifest = QrTemplateManifest.empty;
  final _templateRepo = UserTemplateRepository();

  // 나의 템플릿 갱신용 key (AllTemplatesTab 강제 재빌드)
  int _myTemplatesVersion = 0;

  @override
  void initState() {
    super.initState();
    // 탭: 템플릿 / 배경화면 / 모양 / 색상 / 로고
    _tabController = TabController(length: 5, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

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

      final appIconBytes = args['appIconBytes'] as Uint8List?;
      if (appIconBytes != null) {
        notifier.setDefaultIconBytes(appIconBytes);
      } else {
        final (icon, color) = _tagTypeIconColor(tagType);
        final rendered = await _renderMaterialIcon(icon, color);
        if (mounted) notifier.setDefaultIconBytes(rendered);
      }

      if (savedEmoji != null && mounted) {
        final emojiBytes = await _renderEmoji(savedEmoji);
        if (mounted) notifier.setCenterEmoji(savedEmoji, emojiBytes);
      }

      _captureAndSaveHistory(args);

      TemplateRepository.getTemplates(
        onRefresh: (updated) {
          if (mounted) setState(() => _templateManifest = updated);
        },
      ).then((manifest) {
        if (mounted) setState(() => _templateManifest = manifest);
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _captureAndSaveHistory(Map<String, dynamic> args) async {
    if (_historySaved) return;
    _historySaved = true;

    final appName = args['appName'] as String;
    final deepLink = args['deepLink'] as String;
    final packageName = args['packageName'] as String?;
    final platform = args['platform'] as String;
    final appIconBytes = args['appIconBytes'] as Uint8List?;
    final tagType = args['tagType'] as String?;
    final state = ref.read(qrResultProvider);

    await Future.delayed(const Duration(milliseconds: 300));
    final boundary = _repaintKey.currentContext
        ?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      final bytes =
          await ref.read(qrServiceProvider).captureQrImage(boundary);
      if (bytes != null) {
        ref.read(qrResultProvider.notifier).setCapturedImage(bytes);
      }
    }

    final history = TagHistory(
      id: const Uuid().v4(),
      appName: appName,
      deepLink: deepLink,
      platform: platform,
      outputType: 'qr',
      createdAt: DateTime.now(),
      packageName: packageName,
      appIconBytes: appIconBytes,
      qrLabel: null,
      qrColor: state.qrColor.toARGB32(),
      printSizeCm: state.printSizeCm,
      tagType: tagType,
      qrEyeShape: null,
      qrDataModuleShape: null,
      qrEmbedIcon: state.embedIcon,
      qrCenterEmoji: state.centerEmoji,
      qrRoundFactor: state.roundFactor,
    );
    await ref.read(historyServiceProvider).saveHistory(history);
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
      // 배경 레이어
      backgroundImageBytes: state.background.imageBytes,
      backgroundScale: state.background.scale,
      // QR 레이어
      qrColorValue: state.qrColor.toARGB32(),
      gradientJson: state.customGradient != null
          ? jsonEncode(state.customGradient!.toJson())
          : null,
      roundFactor: state.roundFactor,
      dotStyleIndex: state.dotStyle.index,
      eyeStyleIndex: state.eyeStyle.index,
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

    await _templateRepo.save(template);

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
      iconBytes = await TemplateRepository.loadImageBytes(
          template.style.centerIcon.url!);
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
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final appName = args['appName'] as String;
    final deepLink = args['deepLink'] as String;

    final state = ref.watch(qrResultProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('QR 코드')),
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

          // ② 탭 바: 템플릿 / 배경화면 / 모양 / 색상 / 로고
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: '템플릿'),
              Tab(text: '배경화면'),
              Tab(text: '모양'),
              Tab(text: '색상'),
              Tab(text: '로고'),
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
                // 1: 배경화면
                BackgroundTab(onChanged: _recapture),
                // 2: 모양 (도트 + 눈)
                QrShapeTab(
                  onDotStyleChanged: (s) {
                    ref.read(qrResultProvider.notifier).setDotStyle(s);
                    _recapture();
                  },
                  onEyeStyleChanged: (s) {
                    ref.read(qrResultProvider.notifier).setEyeStyle(s);
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
              ],
            ),
          ),

          // ④ 액션 버튼
          _ActionButtons(
            state: state,
            onSaveGallery: () =>
                ref.read(qrResultProvider.notifier).saveToGallery(appName),
            onSaveTemplate: _showSaveTemplateSheet,
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
