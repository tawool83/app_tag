import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../qr_task/domain/entities/qr_task.dart';
import '../../qr_task/domain/usecases/qr_task_edit_router.dart';
import '../../qr_task/presentation/providers/qr_task_providers.dart';
import '../../qr_task/presentation/widgets/rename_dialog.dart';
import '../../qr_result/domain/entities/qr_boundary_params.dart';
import '../../qr_result/domain/entities/qr_dot_style.dart' show QrDotStyle, QrDotStyleToParams;
import '../../qr_result/domain/entities/qr_shape_params.dart';
import '../../qr_result/domain/entities/svg_logo_params.dart';
import '../../qr_result/presentation/providers/qr_result_providers.dart';
import '../../qr_result/utils/qr_svg_generator.dart';
import '../../../core/error/result.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../l10n/app_localizations.dart';

/// 홈 갤러리에서 QrTask 항목을 길게 누르면 열리는 액션 시트.
class QrTaskActionSheet extends ConsumerStatefulWidget {
  final QrTask task;
  final VoidCallback onChanged;

  const QrTaskActionSheet({
    super.key,
    required this.task,
    required this.onChanged,
  });

  @override
  ConsumerState<QrTaskActionSheet> createState() => _QrTaskActionSheetState();
}

class _QrTaskActionSheetState extends ConsumerState<QrTaskActionSheet> {
  late bool _isFav = widget.task.isFavorite;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 확대 미리보기 + 즐겨찾기 별 토글
        _PreviewWithStar(
          task: task,
          onChanged: widget.onChanged,
          onFavoriteChanged: (isFav) => setState(() => _isFav = isFav),
        ),
        // 이름 + 연필 아이콘 (이름 변경)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  task.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _rename(context),
                child: Icon(Icons.edit, size: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(),
        // 편집하기 (즐겨찾기 시 비활성화)
        ListTile(
          leading: Icon(Icons.palette,
              color: _isFav ? Colors.grey.shade300 : null),
          title: Text(l10n.actionEditAgain,
              style: _isFav
                  ? TextStyle(color: Colors.grey.shade400)
                  : null),
          enabled: !_isFav,
          onTap: _isFav ? null : () => _editAgain(context),
        ),
        // NFC 기록
        ListTile(
          leading: const Icon(Icons.nfc),
          title: Text(l10n.actionNfcWrite),
          onTap: () => _writeNfc(context),
        ),
        // 갤러리(PNG) 저장
        ListTile(
          leading: const Icon(Icons.save_alt),
          title: Text(l10n.actionSaveGallery),
          onTap: () => _saveToGallery(context),
        ),
        // SVG 저장
        ListTile(
          leading: const Icon(Icons.image_outlined),
          title: Text(l10n.actionSaveSvg),
          onTap: () => _saveAsSvg(context),
        ),
        // 공유
        ListTile(
          leading: const Icon(Icons.share),
          title: Text(l10n.actionShare),
          onTap: () => _share(context),
        ),
        // 삭제
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: Text(l10n.actionDelete, style: const TextStyle(color: Colors.red)),
          onTap: () => _delete(context),
        ),
        const SizedBox(height: 8),
      ],
    ),
    );
  }

  void _saveToGallery(BuildContext context) {
    final task = widget.task;
    Navigator.pop(context);
    if (task.thumbnailBytes == null) {
      context.showSnack(AppLocalizations.of(context)!.msgNoThumbnail);
      return;
    }
    ref.read(saveQrToGalleryUseCaseProvider)(task.thumbnailBytes!, task.name);
    context.showSnack(AppLocalizations.of(context)!.msgSavedToGallery);
  }

  Future<void> _saveAsSvg(BuildContext context) async {
    final task = widget.task;
    Navigator.pop(context);
    final l10n = AppLocalizations.of(context)!;
    if (task.meta.deepLink.isEmpty) {
      context.showSnack(l10n.msgNoThumbnail);
      return;
    }

    final c = task.customization;
    final s = c.sticker;
    final dotParams = c.customDotParams != null
        ? DotShapeParams.fromJson(c.customDotParams!)
        : _dotStyleToParams(c.dotStyle);
    final eyeParams = c.customEyeParams != null
        ? EyeShapeParams.fromJson(c.customEyeParams!)
        : const EyeShapeParams();
    final boundaryParams = c.boundaryParams != null
        ? QrBoundaryParams.fromJson(c.boundaryParams!)
        : const QrBoundaryParams();

    // ── 로고 데이터 추출 ──
    String? logoSvgContent;
    String? logoBase64Png;
    SvgLogoText? logoText;
    SvgLogoStyle? logoStyle;

    if (c.embedIcon && s.logoType != null && s.logoType != 'none') {
      logoStyle = SvgLogoStyle(
        position: s.logoPosition,
        background: s.logoBackground,
        backgroundColorArgb: s.logoBackgroundColorArgb,
      );

      switch (s.logoType) {
        case 'logo':
          if (s.logoAssetId != null) {
            final loader = ref.read(svgAssetLoaderProvider);
            logoSvgContent = await loader.load(s.logoAssetId!);
          }
        case 'image':
          logoBase64Png = c.centerIconBase64;
        case 'text':
          if (s.logoText != null) {
            logoText = SvgLogoText(
              content: s.logoText!.content,
              colorArgb: s.logoText!.colorArgb,
              fontFamily: s.logoText!.fontFamily,
              fontSize: s.logoText!.fontSize,
            );
          }
      }
    }

    // ── 상/하단 텍스트 ──
    SvgStickerText? topText;
    SvgStickerText? bottomText;
    if (s.topText != null && s.topText!.content.isNotEmpty) {
      topText = SvgStickerText(
        content: s.topText!.content,
        colorArgb: s.topText!.colorArgb,
        fontFamily: s.topText!.fontFamily,
        fontSize: s.topText!.fontSize,
      );
    }
    if (s.bottomText != null && s.bottomText!.content.isNotEmpty) {
      bottomText = SvgStickerText(
        content: s.bottomText!.content,
        colorArgb: s.bottomText!.colorArgb,
        fontFamily: s.bottomText!.fontFamily,
        fontSize: s.bottomText!.fontSize,
      );
    }

    // 띠 사용 시 V5 강제 — 화면 렌더와 동일 정책 (qr_layer_stack 참조).
    final hasBand = s.bandMode != 'none' &&
        s.logoType == 'text' &&
        s.logoText != null &&
        s.logoText!.content.isNotEmpty;
    final minTypeNumber = hasBand ? 5 : 1;

    final svgString = QrSvgGenerator.generate(
      data: task.meta.deepLink,
      dotParams: dotParams,
      eyeParams: eyeParams,
      boundaryParams: boundaryParams,
      colorArgb: c.qrColorArgb,
      gradient: c.gradient,
      minTypeNumber: minTypeNumber,
      logoSvgContent: logoSvgContent,
      logoBase64Png: logoBase64Png,
      logoText: logoText,
      logoStyle: logoStyle,
      topText: topText,
      bottomText: bottomText,
    );

    final result = await ref.read(saveQrAsSvgUseCaseProvider)(svgString, task.name);
    if (!context.mounted) return;
    result.fold(
      (path) => context.showSnack(l10n.msgSvgSaved),
      (failure) => context.showSnack('SVG 저장 실패'),
    );
  }

  void _share(BuildContext context) {
    final task = widget.task;
    Navigator.pop(context);
    if (task.thumbnailBytes == null) {
      context.showSnack(AppLocalizations.of(context)!.msgNoThumbnail);
      return;
    }
    ref.read(shareQrImageUseCaseProvider)(task.thumbnailBytes!, task.name);
  }

  void _writeNfc(BuildContext context) {
    final task = widget.task;
    Navigator.pop(context);
    context.push('/nfc-writer', extra: {
      'deepLink': task.meta.deepLink,
      'appName': task.meta.appName,
      'platform': task.meta.platform,
      'packageName': task.meta.packageName,
      'tagType': task.meta.tagType,
    });
  }

  Future<void> _editAgain(BuildContext context) async {
    final task = widget.task;
    Navigator.pop(context);
    await QrTaskEditRouter.push(context, task);
    widget.onChanged();
  }

  Future<void> _rename(BuildContext context) async {
    final task = widget.task;
    final newName = await showRenameDialog(context, task.name);
    if (newName != null && newName != task.name) {
      if (context.mounted) Navigator.pop(context);
      await ref.read(renameQrTaskUseCaseProvider)(task.id, newName);
      widget.onChanged();
    }
  }

  Future<void> _delete(BuildContext context) async {
    final task = widget.task;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogDeleteTitle),
        content: Text(l10n.dialogDeleteContent(task.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionDelete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (context.mounted && confirmed == true) {
      Navigator.pop(context);
      await ref.read(deleteQrTaskUseCaseProvider)(task.id);
      widget.onChanged();
    }
  }

  /// dotStyle enum 문자열 → DotShapeParams 변환.
  static DotShapeParams _dotStyleToParams(String dotStyleName) {
    final style = QrDotStyle.values.where((e) => e.name == dotStyleName).firstOrNull;
    return style?.toDotShapeParams() ?? const DotShapeParams();
  }
}

/// 확대 미리보기 + 우상단 즐겨찾기 별 토글.
/// 별 상태를 로컬 State 에 보관하여 탭 즉시 UI 반영 (StatefulBuilder 로는
/// 매 builder 재실행 시 초기값이 복원되어 토글이 무효화됨).
class _PreviewWithStar extends ConsumerStatefulWidget {
  final QrTask task;
  final VoidCallback onChanged;
  final ValueChanged<bool> onFavoriteChanged;

  const _PreviewWithStar({
    required this.task,
    required this.onChanged,
    required this.onFavoriteChanged,
  });

  @override
  ConsumerState<_PreviewWithStar> createState() => _PreviewWithStarState();
}

class _PreviewWithStarState extends ConsumerState<_PreviewWithStar> {
  late bool _isFav = widget.task.isFavorite;

  @override
  Widget build(BuildContext context) {
    const maxSide = 220.0;
    const thumbScale = 2.0;
    final task = widget.task;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 8),
          child: Center(
            child: Container(
              width: maxSide,
              height: maxSide,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              clipBehavior: Clip.antiAlias,
              child: task.thumbnailBytes != null
                  ? Transform.scale(
                      scale: thumbScale,
                      child: Image.memory(task.thumbnailBytes!,
                          fit: BoxFit.contain),
                    )
                  : Center(
                      child: Icon(Icons.qr_code,
                          size: maxSide * 0.4, color: Colors.grey),
                    ),
            ),
          ),
        ),
        // 별 아이콘 — 미리보기 우측 상단
        Positioned(
          top: 16,
          right: 32,
          child: GestureDetector(
            onTap: () async {
              await ref.read(toggleFavoriteUseCaseProvider)(task.id);
              if (!mounted) return;
              setState(() => _isFav = !_isFav);
              widget.onFavoriteChanged(_isFav);
              widget.onChanged();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _isFav
                    ? Colors.amber
                    : Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isFav ? Icons.star : Icons.star_border,
                color: _isFav ? Colors.white : Colors.grey,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
