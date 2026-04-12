import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/tag_history.dart';
import '../../services/settings_service.dart';
import 'qr_result_provider.dart';

// 중앙 아이콘 옵션
enum _QrCenterOption { none, defaultIcon, emoji }

// 이모지 카테고리 목록
const _kEmojiCategories = [
  ('스마일', ['😀', '😂', '🥰', '😎', '🤔', '🥳', '😴', '🤩']),
  ('제스처', ['👋', '👍', '🙌', '💪', '🤝', '🤙', '👏', '✌️']),
  ('사물', ['📱', '💻', '🖥️', '📷', '🎧', '📺', '⌚', '🔋']),
  ('장소', ['🏠', '🏢', '🏪', '🏨', '🏦', '🏥', '🏫', '⛪']),
  ('음식', ['🍕', '🍔', '🍜', '☕', '🍺', '🍰', '🍎', '🥗']),
  ('자연', ['🌸', '🌺', '🌈', '⭐', '🌙', '☀️', '🌊', '🍀']),
  ('활동', ['🎮', '🎵', '🎨', '⚽', '🎯', '🎲', '📚', '✏️']),
  ('교통', ['🚗', '✈️', '🚂', '🚢', '🚲', '🛵', '🚀', '🗺️']),
];

// 태그 타입별 아이콘/색상
(IconData, Color) _tagTypeIconColor(String? tagType) {
  switch (tagType) {
    case 'app': return (Icons.apps, Colors.indigo);
    case 'clipboard': return (Icons.content_paste, Colors.blueGrey);
    case 'website': return (Icons.language, Colors.blue);
    case 'contact': return (Icons.contact_phone, Colors.green);
    case 'wifi': return (Icons.wifi, Colors.teal);
    case 'location': return (Icons.location_on, Colors.red);
    case 'event': return (Icons.event, Colors.orange);
    case 'email': return (Icons.email, Colors.deepPurple);
    case 'sms': return (Icons.sms, Colors.pink);
    default: return (Icons.qr_code, Colors.grey);
  }
}

// Material 아이콘 → PNG bytes 렌더링 (둥근 배경 포함)
Future<Uint8List> _renderMaterialIcon(IconData icon, Color color) async {
  const size = 96.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  // 흰 바탕
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, size, size),
    Paint()..color = Colors.white,
  );
  // 색상 원형 배경
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

// 현재 상태에서 중앙 이미지 제공자 계산
ImageProvider? _centerImageProvider(QrResultState state) {
  if (!state.embedIcon) return null;
  if (state.centerEmoji != null && state.emojiIconBytes != null) {
    return MemoryImage(state.emojiIconBytes!);
  }
  if (state.defaultIconBytes != null) {
    return MemoryImage(state.defaultIconBytes!);
  }
  return null;
}


class QrResultScreen extends ConsumerStatefulWidget {
  const QrResultScreen({super.key});

  @override
  ConsumerState<QrResultScreen> createState() => _QrResultScreenState();
}

class _QrResultScreenState extends ConsumerState<QrResultScreen> {
  final _repaintKey = GlobalKey();
  bool _historySaved = false;
  bool _customizeExpanded = false;
  bool _emojiModeActive = false; // 이모지 모드 UI 상태 (state와 독립)
  late TextEditingController _labelController;
  late TextEditingController _printTitleController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
    _printTitleController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _labelController.text = args['appName'] as String;
      _printTitleController.text = args['appName'] as String;

      // 마지막 사용한 설정값 복원
      final lastSize = await SettingsService.getLastPrintSizeCm();
      final eyeShapeStr = await SettingsService.getQrEyeShape();
      final moduleShapeStr = await SettingsService.getQrDataModuleShape();
      final embedIcon = await SettingsService.getQrEmbedIcon();
      final savedEmoji = await SettingsService.getQrCenterEmoji();

      final notifier = ref.read(qrResultProvider.notifier);
      notifier.setPrintSizeCm(lastSize);
      notifier.setEyeShape(
          eyeShapeStr == 'circle' ? QrEyeShape.circle : QrEyeShape.square);
      notifier.setDataModuleShape(moduleShapeStr == 'circle'
          ? QrDataModuleShape.circle
          : QrDataModuleShape.square);
      notifier.setEmbedIcon(embedIcon);

      // 기본 아이콘 렌더링 (앱 아이콘 또는 태그 타입 Material 아이콘)
      final appIconBytes = args['appIconBytes'] as Uint8List?;
      final tagType = args['tagType'] as String?;
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
    });
  }

  @override
  void dispose() {
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
    final boundary =
        _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      final bytes = await ref.read(qrServiceProvider).captureQrImage(boundary);
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
      qrEyeShape: state.eyeShape == QrEyeShape.circle ? 'circle' : 'square',
      qrDataModuleShape: state.dataModuleShape == QrDataModuleShape.circle ? 'circle' : 'square',
      qrEmbedIcon: state.embedIcon,
      qrCenterEmoji: state.centerEmoji,
    );
    await ref.read(historyServiceProvider).saveHistory(history);
  }

  // 라벨/색상 변경 후 이미지 재캡처 (저장·공유·인쇄에 반영)
  Future<void> _recapture() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final boundary =
        _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
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
    // null = 앱 이름 사용, "" = 표시 안 함
    final label = state.customLabel ?? appName;

    return Scaffold(
      appBar: AppBar(title: const Text('QR 코드')),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Column(
              children: [
            // QR 미리보기 (캡처 영역)
            RepaintBoundary(
              key: _repaintKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Builder(builder: (context) {
                      final centerImage = _centerImageProvider(state);
                      return SizedBox(
                        width: 240,
                        height: 240,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // QR 코드 (도트만 렌더링 — 중앙 아이콘 없음)
                            QrImageView(
                              data: deepLink,
                              version: QrVersions.auto,
                              size: 240,
                              // 아이콘이 있으면 H(30%) 오류정정으로 중앙 도트 손실 보완
                              errorCorrectionLevel: centerImage != null
                                  ? QrErrorCorrectLevel.H
                                  : QrErrorCorrectLevel.M,
                              eyeStyle: QrEyeStyle(
                                eyeShape: state.eyeShape,
                                color: state.qrColor,
                              ),
                              dataModuleStyle: QrDataModuleStyle(
                                dataModuleShape: state.dataModuleShape,
                                color: state.qrColor,
                              ),
                            ),
                            // 중앙 clear zone: 흰 원으로 QR 도트 가림
                            if (centerImage != null)
                              Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            // 아이콘/이모지 오버레이
                            if (centerImage != null)
                              ClipOval(
                                child: Image(
                                  image: centerImage,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    if (label.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              deepLink,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // 커스터마이징 패널
            _CustomizePanel(
              expanded: _customizeExpanded,
              labelController: _labelController,
              printTitleController: _printTitleController,
              selectedColor: state.qrColor,
              printSizeCm: state.printSizeCm,
              eyeShape: state.eyeShape,
              dataModuleShape: state.dataModuleShape,
              // _emojiModeActive: 이모지 탭 후 아직 이모지 미선택 상태도 emoji 모드 유지
              centerOption: !state.embedIcon
                  ? _QrCenterOption.none
                  : _emojiModeActive
                      ? _QrCenterOption.emoji
                      : _QrCenterOption.defaultIcon,
              centerEmoji: state.centerEmoji,
              hasDefaultIcon: state.defaultIconBytes != null,
              onToggle: () =>
                  setState(() => _customizeExpanded = !_customizeExpanded),
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
              onSizeChanged: (s) {
                ref.read(qrResultProvider.notifier).setPrintSizeCm(s);
              },
              onEyeShapeChanged: (shape) {
                ref.read(qrResultProvider.notifier).setEyeShape(shape);
                SettingsService.saveQrEyeShape(
                    shape == QrEyeShape.circle ? 'circle' : 'square');
                _recapture();
              },
              onDataModuleShapeChanged: (shape) {
                ref.read(qrResultProvider.notifier).setDataModuleShape(shape);
                SettingsService.saveQrDataModuleShape(
                    shape == QrDataModuleShape.circle ? 'circle' : 'square');
                _recapture();
              },
              onCenterOptionChanged: (option) {
                final notifier = ref.read(qrResultProvider.notifier);
                setState(() => _emojiModeActive = option == _QrCenterOption.emoji);
                switch (option) {
                  case _QrCenterOption.none:
                    notifier.setEmbedIcon(false);
                    SettingsService.saveQrEmbedIcon(false);
                    break;
                  case _QrCenterOption.defaultIcon:
                    notifier.setEmbedIcon(true);
                    notifier.clearEmoji();
                    SettingsService.saveQrEmbedIcon(true);
                    SettingsService.saveQrCenterEmoji(null);
                    break;
                  case _QrCenterOption.emoji:
                    notifier.setEmbedIcon(true);
                    SettingsService.saveQrEmbedIcon(true);
                    // centerEmoji는 그리드에서 선택 시 설정됨
                    break;
                }
                _recapture();
              },
              onEmojiSelected: (emoji) async {
                final bytes = await _renderEmoji(emoji);
                if (!mounted) return;
                ref.read(qrResultProvider.notifier).setCenterEmoji(emoji, bytes);
                SettingsService.saveQrCenterEmoji(emoji);
                _recapture();
              },
            ),

            const SizedBox(height: 16),

            // 액션 버튼들
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.save_alt,
                    label: '갤러리 저장',
                    status: state.saveStatus,
                    onTap: () => ref
                        .read(qrResultProvider.notifier)
                        .saveToGallery(label),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.share,
                    label: '공유',
                    status: state.shareStatus,
                    onTap: () =>
                        ref.read(qrResultProvider.notifier).shareImage(label),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.print,
                    label: '인쇄',
                    status: state.printStatus,
                    onTap: () async {
                      await SettingsService.saveLastPrintSizeCm(
                          state.printSizeCm);
                      ref.read(qrResultProvider.notifier).printQrCode(
                            label,
                            sizeCm: state.printSizeCm,
                            printTitle: state.printTitle,
                          );
                    },
                  ),
                ),
              ],
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('완료'),
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}

// ── 커스터마이징 패널 ─────────────────────────────────────────────────────────

const _kMinPrintSize = 2.5;
const _kMaxPrintSize = 20.0;
const _kSizeStep = 0.5;

class _CustomizePanel extends StatelessWidget {
  final bool expanded;
  final TextEditingController labelController;
  final TextEditingController printTitleController;
  final Color selectedColor;
  final double printSizeCm;
  final QrEyeShape eyeShape;
  final QrDataModuleShape dataModuleShape;
  final _QrCenterOption centerOption;
  final String? centerEmoji;
  final bool hasDefaultIcon;
  final VoidCallback onToggle;
  final ValueChanged<String> onLabelChanged;
  final ValueChanged<String> onPrintTitleChanged;
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<double> onSizeChanged;
  final ValueChanged<QrEyeShape> onEyeShapeChanged;
  final ValueChanged<QrDataModuleShape> onDataModuleShapeChanged;
  final ValueChanged<_QrCenterOption> onCenterOptionChanged;
  final ValueChanged<String> onEmojiSelected;

  const _CustomizePanel({
    required this.expanded,
    required this.labelController,
    required this.printTitleController,
    required this.selectedColor,
    required this.printSizeCm,
    required this.eyeShape,
    required this.dataModuleShape,
    required this.centerOption,
    required this.centerEmoji,
    required this.hasDefaultIcon,
    required this.onToggle,
    required this.onLabelChanged,
    required this.onPrintTitleChanged,
    required this.onColorSelected,
    required this.onSizeChanged,
    required this.onEyeShapeChanged,
    required this.onDataModuleShapeChanged,
    required this.onCenterOptionChanged,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 헤더 (탭하여 펼치기/접기)
          InkWell(
            borderRadius: expanded
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : BorderRadius.circular(12),
            onTap: onToggle,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.tune, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text('QR 커스터마이징',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // 펼쳐진 내용
          if (expanded) ...[
            Divider(height: 1, color: Colors.grey.shade300),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 인쇄 상단 문구
                  const Text('인쇄 상단 문구',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: printTitleController,
                    onChanged: onPrintTitleChanged,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '비워두면 표시 안 함',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // QR 하단 문구
                  const Text('QR 하단 문구',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: labelController,
                    onChanged: onLabelChanged,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '비워두면 표시 안 함',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 색상 팔레트
                  const Text('QR 색상',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: qrSafeColors
                        .map((c) => _ColorChip(
                              color: c,
                              isSelected: c.toARGB32() == selectedColor.toARGB32(),
                              onTap: () => onColorSelected(c),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  // 인쇄 크기 슬라이더
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('인쇄 크기 (정사각형)',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(
                        '${printSizeCm.toStringAsFixed(1)} cm',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: printSizeCm,
                    min: _kMinPrintSize,
                    max: _kMaxPrintSize,
                    divisions: ((_kMaxPrintSize - _kMinPrintSize) / _kSizeStep)
                        .round(),
                    label: '${printSizeCm.toStringAsFixed(1)} cm',
                    onChanged: onSizeChanged,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_kMinPrintSize.toStringAsFixed(1)} cm',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        '${_kMaxPrintSize.toStringAsFixed(0)} cm',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 도트 모양
                  const Text('데이터 도트 모양',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  _ShapeToggle<QrDataModuleShape>(
                    selected: dataModuleShape,
                    options: const [
                      (QrDataModuleShape.square, '■ 사각형'),
                      (QrDataModuleShape.circle, '● 원형'),
                    ],
                    onChanged: onDataModuleShapeChanged,
                  ),
                  const SizedBox(height: 16),

                  // 눈(finder) 모양
                  const Text('눈(코너) 모양',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  _ShapeToggle<QrEyeShape>(
                    selected: eyeShape,
                    options: const [
                      (QrEyeShape.square, '■ 사각형'),
                      (QrEyeShape.circle, '● 원형'),
                    ],
                    onChanged: onEyeShapeChanged,
                  ),

                  // 중앙 아이콘
                  const SizedBox(height: 16),
                  const Text('중앙 아이콘',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  _ShapeToggle<_QrCenterOption>(
                    selected: centerOption,
                    options: [
                      (_QrCenterOption.none, '없음'),
                      if (hasDefaultIcon)
                        (_QrCenterOption.defaultIcon, '기본 아이콘'),
                      (_QrCenterOption.emoji, '이모지'),
                    ],
                    onChanged: onCenterOptionChanged,
                  ),

                  // 이모지 선택 그리드
                  if (centerOption == _QrCenterOption.emoji) ...[
                    const SizedBox(height: 12),
                    _EmojiGrid(
                      selectedEmoji: centerEmoji,
                      onEmojiTap: onEmojiSelected,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 이모지 그리드 ──────────────────────────────────────────────────────────────

class _EmojiGrid extends StatelessWidget {
  final String? selectedEmoji;
  final ValueChanged<String> onEmojiTap;

  const _EmojiGrid({required this.selectedEmoji, required this.onEmojiTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _kEmojiCategories.map((cat) {
        final (name, emojis) = cat;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: emojis.map((emoji) {
                final isSelected = selectedEmoji == emoji;
                return GestureDetector(
                  onTap: () => onEmojiTap(emoji),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
        );
      }).toList(),
    );
  }
}

// ── 모양 선택 토글 ────────────────────────────────────────────────────────────

class _ShapeToggle<T> extends StatelessWidget {
  final T selected;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  const _ShapeToggle({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final (value, label) = opt;
        final isSelected = selected == value;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ColorChip extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorChip({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}

// ── 액션 버튼 ────────────────────────────────────────────────────────────────

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
    final isDone = status == QrActionStatus.success;

    return ElevatedButton(
      onPressed: isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: isDone ? Colors.green.shade100 : null,
      ),
      child: Column(
        children: [
          isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(isDone ? Icons.check : icon, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
