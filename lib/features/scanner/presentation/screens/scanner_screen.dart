import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../l10n/app_localizations.dart';
import '../../scanner_provider.dart';
import '../widgets/permission_fallback_view.dart';
import '../widgets/result_bottom_sheet/result_sheet.dart';
import '../widgets/scanner_control_bar.dart';
import '../widgets/scanning_reticle.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  MobileScannerController? _controller;
  bool _detected = false;

  @override
  void initState() {
    super.initState();
    ref.read(scannerProvider.notifier).initialize();
  }

  void _ensureController() {
    if (_controller != null) return;
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _detected = true);
    HapticFeedback.mediumImpact();

    await ref.read(scannerProvider.notifier).onBarcodeDetected(barcode.rawValue!);

    if (!mounted) return;

    await _controller?.stop();

    final result = ref.read(scannerProvider).result.currentResult;
    if (result == null || !mounted) return;

    await showResultBottomSheet(context: context, result: result);

    ref.read(scannerProvider.notifier).dismissResult();
    setState(() => _detected = false);
    await _controller?.start();
  }

  Future<void> _onGalleryImport() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    // 카메라 없이도 동작하도록 임시 컨트롤러로 이미지 분석
    final tempController = MobileScannerController();
    try {
      final capture = await tempController.analyzeImage(file.path);
      if (!mounted) return;

      if (capture == null || capture.barcodes.isEmpty) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.scannerGalleryFail)),
        );
      } else {
        await _handleGalleryResult(capture);
      }
    } finally {
      tempController.dispose();
    }
  }

  Future<void> _handleGalleryResult(BarcodeCapture capture) async {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    HapticFeedback.mediumImpact();

    await ref.read(scannerProvider.notifier).onBarcodeDetected(barcode.rawValue!);

    if (!mounted) return;

    final result = ref.read(scannerProvider).result.currentResult;
    if (result == null || !mounted) return;

    await showResultBottomSheet(context: context, result: result);

    ref.read(scannerProvider.notifier).dismissResult();
  }

  void _onToggleFlash() {
    ref.read(scannerProvider.notifier).toggleFlash();
    _controller?.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scannerProvider);
    final cameraGranted = state.camera.permissionStatus == 'granted';

    if (cameraGranted) _ensureController();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: cameraGranted
          ? Stack(
              children: [
                MobileScanner(
                  controller: _controller!,
                  onDetect: _onDetect,
                ),
                ScanningReticle(detected: _detected),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ScannerControlBar(
                    flashOn: state.camera.flashOn,
                    onToggleFlash: _onToggleFlash,
                    onGalleryImport: _onGalleryImport,
                  ),
                ),
              ],
            )
          : PermissionFallbackView(
              onGalleryImport: _onGalleryImport,
            ),
    );
  }
}
