import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/tag_history.dart';
import '../../services/settings_service.dart';
import 'qr_result_provider.dart';

class QrResultScreen extends ConsumerStatefulWidget {
  const QrResultScreen({super.key});

  @override
  ConsumerState<QrResultScreen> createState() => _QrResultScreenState();
}

class _QrResultScreenState extends ConsumerState<QrResultScreen> {
  final _repaintKey = GlobalKey();
  bool _historySaved = false;
  bool _customizeExpanded = false;
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
      final notifier = ref.read(qrResultProvider.notifier);
      notifier.setPrintSizeCm(lastSize);
      notifier.setEyeShape(eyeShapeStr == 'circle' ? QrEyeShape.circle : QrEyeShape.square);
      notifier.setDataModuleShape(moduleShapeStr == 'circle' ? QrDataModuleShape.circle : QrDataModuleShape.square);
      notifier.setEmbedIcon(embedIcon);
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
                    QrImageView(
                      data: deepLink,
                      version: QrVersions.auto,
                      size: 240,
                      errorCorrectionLevel: state.embedIcon
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
                      embeddedImage: state.embedIcon &&
                              args['appIconBytes'] != null
                          ? MemoryImage(
                              args['appIconBytes'] as Uint8List)
                          : null,
                      embeddedImageStyle: state.embedIcon
                          ? const QrEmbeddedImageStyle(
                              size: Size(48, 48))
                          : null,
                    ),
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
              embedIcon: state.embedIcon,
              hasAppIcon: args['appIconBytes'] != null,
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
              onEmbedIconChanged: (embed) {
                ref.read(qrResultProvider.notifier).setEmbedIcon(embed);
                SettingsService.saveQrEmbedIcon(embed);
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
  final bool embedIcon;
  final bool hasAppIcon;
  final VoidCallback onToggle;
  final ValueChanged<String> onLabelChanged;
  final ValueChanged<String> onPrintTitleChanged;
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<double> onSizeChanged;
  final ValueChanged<QrEyeShape> onEyeShapeChanged;
  final ValueChanged<QrDataModuleShape> onDataModuleShapeChanged;
  final ValueChanged<bool> onEmbedIconChanged;

  const _CustomizePanel({
    required this.expanded,
    required this.labelController,
    required this.printTitleController,
    required this.selectedColor,
    required this.printSizeCm,
    required this.eyeShape,
    required this.dataModuleShape,
    required this.embedIcon,
    required this.hasAppIcon,
    required this.onToggle,
    required this.onLabelChanged,
    required this.onPrintTitleChanged,
    required this.onColorSelected,
    required this.onSizeChanged,
    required this.onEyeShapeChanged,
    required this.onDataModuleShapeChanged,
    required this.onEmbedIconChanged,
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

                  // 중앙 아이콘 (appIconBytes가 있을 때만)
                  if (hasAppIcon) ...[
                    const SizedBox(height: 16),
                    const Text('중앙 아이콘',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _ShapeToggle<bool>(
                      selected: embedIcon,
                      options: const [
                        (false, '없음'),
                        (true, '앱 아이콘'),
                      ],
                      onChanged: onEmbedIconChanged,
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
