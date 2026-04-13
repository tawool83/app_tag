import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/tag_history.dart';
import '../../models/qr_template.dart';
import '../../repositories/template_repository.dart';
import '../../services/settings_service.dart';
import '../../services/history_service.dart' show historyServiceProvider;
import '../../services/qr_service.dart' show qrServiceProvider;
import '../../shared/constants/app_config.dart' show validateQrData;
import 'qr_result_provider.dart';
import 'tabs/recommended_tab.dart';
import 'tabs/customize_tab.dart';
import 'tabs/all_templates_tab.dart';
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
  bool _emojiModeActive = false;
  late TabController _tabController;
  late TextEditingController _labelController;
  late TextEditingController _printTitleController;
  QrTemplateManifest _templateManifest = QrTemplateManifest.empty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _labelController = TextEditingController();
    _printTitleController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

      // 중앙 집중 deepLink 유효성 검사 — 모든 진입 경로 공통 처리.
      // 각 입력 화면을 수정하지 않고도 150자 제한이 일괄 적용된다.
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

      _labelController.text = args['appName'] as String;
      _printTitleController.text = args['appName'] as String;

      final tagType = args['tagType'] as String?;
      final notifier = ref.read(qrResultProvider.notifier);

      // 마지막 사용 설정값 복원
      final lastSize = await SettingsService.getLastPrintSizeCm();
      final embedIcon = await SettingsService.getQrEmbedIcon();
      final savedEmoji = await SettingsService.getQrCenterEmoji();

      notifier.setPrintSizeCm(lastSize);
      notifier.setEmbedIcon(embedIcon);
      notifier.setTagType(tagType);

      // 기본 아이콘 렌더링
      final appIconBytes = args['appIconBytes'] as Uint8List?;
      if (appIconBytes != null) {
        notifier.setDefaultIconBytes(appIconBytes);
      } else {
        final (icon, color) = _tagTypeIconColor(tagType);
        final rendered = await _renderMaterialIcon(icon, color);
        if (mounted) notifier.setDefaultIconBytes(rendered);
      }

      // 저장된 이모지 복원
      if (savedEmoji != null && mounted) {
        final emojiBytes = await _renderEmoji(savedEmoji);
        if (mounted) {
          notifier.setCenterEmoji(savedEmoji, emojiBytes);
          setState(() => _emojiModeActive = true);
        }
      }

      _captureAndSaveHistory(args);

      // 템플릿 로드 (로컬 우선, 백그라운드 Supabase 동기화)
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
    _labelController.dispose();
    _printTitleController.dispose();
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
      qrLabel: state.customLabel,
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

  Future<void> _recapture() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final boundary = _repaintKey.currentContext
        ?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      final bytes =
          await ref.read(qrServiceProvider).captureQrImage(boundary);
      if (bytes != null) {
        ref.read(qrResultProvider.notifier).setCapturedImage(bytes);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final appName = args['appName'] as String;
    final deepLink = args['deepLink'] as String;

    final state = ref.watch(qrResultProvider);
    final label = state.customLabel ?? appName;
    final printTitle = state.printTitle ?? appName;

    final centerOption = !state.embedIcon
        ? QrCenterOption.none
        : _emojiModeActive
            ? QrCenterOption.emoji
            : QrCenterOption.defaultIcon;

    return Scaffold(
      appBar: AppBar(title: const Text('QR 코드')),
      body: Column(
        children: [
          // ① 소형 QR 미리보기 (항상 고정)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: QrPreviewSection(
              repaintKey: _repaintKey,
              deepLink: deepLink,
              label: label,
              printTitle: printTitle,
            ),
          ),

          // ② 탭 바
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '추천'),
              Tab(text: '꾸미기'),
              Tab(text: '전체 템플릿'),
            ],
          ),

          // ③ 탭 콘텐츠 (Expanded)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 추천 탭
                RecommendedTab(
                  manifest: _templateManifest,
                  activeTemplateId: state.activeTemplateId,
                  tagType: state.tagType,
                  onTemplateSelected: _onTemplateSelected,
                  onTemplateClear: _onTemplateClear,
                ),
                // 꾸미기 탭
                CustomizeTab(
                  labelController: _labelController,
                  printTitleController: _printTitleController,
                  selectedColor: state.qrColor,
                  customGradient: state.customGradient,
                  printSizeCm: state.printSizeCm,
                  roundFactor: state.roundFactor,
                  eyeStyle: state.eyeStyle,
                  centerOption: centerOption,
                  centerEmoji: state.centerEmoji,
                  hasDefaultIcon: state.defaultIconBytes != null,
                  onLabelChanged: (v) {
                    ref.read(qrResultProvider.notifier).setCustomLabel(v);
                    _recapture();
                  },
                  onPrintTitleChanged: (v) {
                    ref.read(qrResultProvider.notifier).setPrintTitle(v);
                  },
                  onColorSelected: (c) {
                    ref.read(qrResultProvider.notifier).setQrColor(c);
                    _recapture();
                  },
                  onGradientChanged: (g) {
                    ref.read(qrResultProvider.notifier).setCustomGradient(g);
                    _recapture();
                  },
                  onSizeChanged: (s) {
                    ref.read(qrResultProvider.notifier).setPrintSizeCm(s);
                  },
                  onRoundFactorChanged: (f) {
                    ref.read(qrResultProvider.notifier).setRoundFactor(f);
                    _recapture();
                  },
                  onEyeStyleChanged: (s) {
                    ref.read(qrResultProvider.notifier).setEyeStyle(s);
                    _recapture();
                  },
                  onCenterOptionChanged: (option) {
                    final notifier = ref.read(qrResultProvider.notifier);
                    setState(() =>
                        _emojiModeActive = option == QrCenterOption.emoji);
                    switch (option) {
                      case QrCenterOption.none:
                        notifier.setEmbedIcon(false);
                        SettingsService.saveQrEmbedIcon(false);
                        break;
                      case QrCenterOption.defaultIcon:
                        notifier.setEmbedIcon(true);
                        notifier.clearEmoji();
                        SettingsService.saveQrEmbedIcon(true);
                        SettingsService.saveQrCenterEmoji(null);
                        break;
                      case QrCenterOption.emoji:
                        notifier.setEmbedIcon(true);
                        SettingsService.saveQrEmbedIcon(true);
                        break;
                    }
                    _recapture();
                  },
                  onEmojiSelected: (emoji) async {
                    final bytes = await _renderEmoji(emoji);
                    if (!mounted) return;
                    ref
                        .read(qrResultProvider.notifier)
                        .setCenterEmoji(emoji, bytes);
                    SettingsService.saveQrCenterEmoji(emoji);
                    _recapture();
                  },
                ),
                // 전체 템플릿 탭
                AllTemplatesTab(
                  manifest: _templateManifest,
                  activeTemplateId: state.activeTemplateId,
                  onTemplateSelected: _onTemplateSelected,
                  onTemplateClear: _onTemplateClear,
                ),
              ],
            ),
          ),

          // ④ 액션 버튼 (항상 하단 고정)
          _ActionButtons(
            state: state,
            appName: label,
            onSave: () =>
                ref.read(qrResultProvider.notifier).saveToGallery(label),
            onShare: () =>
                ref.read(qrResultProvider.notifier).shareImage(label),
            onPrint: () async {
              await SettingsService.saveLastPrintSizeCm(state.printSizeCm);
              ref.read(qrResultProvider.notifier).printQrCode(
                    label,
                    sizeCm: state.printSizeCm,
                    printTitle: state.printTitle,
                  );
            },
            onDone: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
    );
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
}

// ── 액션 버튼 영역 ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final QrResultState state;
  final String appName;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onPrint;
  final VoidCallback onDone;

  const _ActionButtons({
    required this.state,
    required this.appName,
    required this.onSave,
    required this.onShare,
    required this.onPrint,
    required this.onDone,
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
                  onTap: onSave,
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
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.print,
                  label: '인쇄',
                  status: state.printStatus,
                  onTap: onPrint,
                ),
              ),
            ],
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              state.errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('완료'),
            ),
          ),
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
