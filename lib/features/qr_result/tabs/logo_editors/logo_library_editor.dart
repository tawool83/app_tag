import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/error/result.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/logo_manifest.dart';
import '../../domain/usecases/select_logo_asset_usecase.dart';
import '../../presentation/providers/qr_result_providers.dart';
import '../../qr_result_provider.dart';

/// "로고" 드롭다운 타입의 편집기.
/// 카테고리 칩 + 아이콘 그리드 (번들 SVG).
class LogoLibraryEditor extends ConsumerStatefulWidget {
  final VoidCallback onChanged;

  const LogoLibraryEditor({super.key, required this.onChanged});

  @override
  ConsumerState<LogoLibraryEditor> createState() => _LogoLibraryEditorState();
}

class _LogoLibraryEditorState extends ConsumerState<LogoLibraryEditor> {
  String? _selectedCategoryId;

  String _categoryLabel(AppLocalizations l10n, String id) {
    switch (id) {
      case 'social': return l10n.categorySocial;
      case 'coin':   return l10n.categoryCoin;
      case 'brand':  return l10n.categoryBrand;
      case 'emoji':  return l10n.categoryEmoji;
      default:       return id;
    }
  }

  Future<void> _selectIcon(String category, String iconId) async {
    final useCase = ref.read(selectLogoAssetUseCaseProvider);
    final res = await useCase(category: category, iconId: iconId);
    if (!mounted) return;
    switch (res) {
      case Success<LogoSelectionResult>(:final value):
        ref.read(qrResultProvider.notifier).applyLogoLibrary(
              assetId: value.source.assetId,
              pngBytes: value.pngBytes,
            );
        widget.onChanged();
      case Err<LogoSelectionResult>():
        final l10n = AppLocalizations.of(context)!;
        context.showSnack(l10n.msgLogoLoadFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manifestAsync = ref.watch(logoManifestProvider);
    final l10n = AppLocalizations.of(context)!;
    final currentAssetId =
        ref.watch(qrResultProvider).sticker.logoAssetId;

    return manifestAsync.when(
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => SizedBox(
        height: 180,
        child: Center(
          child: Text(
            l10n.msgLogoLoadFailed,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ),
      data: (manifest) {
        if (manifest.categories.isEmpty) {
          return const SizedBox.shrink();
        }
        final catId = _selectedCategoryId ?? manifest.categories.first.id;
        final category = manifest.findCategory(catId) ??
            manifest.categories.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리 칩
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: manifest.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = manifest.categories[i];
                  final selected = c.id == category.id;
                  return _CategoryChip(
                    label: _categoryLabel(l10n, c.id),
                    selected: selected,
                    onTap: () => setState(() => _selectedCategoryId = c.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // 아이콘 그리드
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: category.icons.length,
              itemBuilder: (_, i) {
                final asset = category.icons[i];
                final composite = asset.compositeId(category.id);
                final isSelected = composite == currentAssetId;
                return _LogoTile(
                  asset: asset,
                  isSelected: isSelected,
                  onTap: () => _selectIcon(category.id, asset.id),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _LogoTile extends StatelessWidget {
  final LogoAsset asset;
  final bool isSelected;
  final VoidCallback onTap;

  const _LogoTile({
    required this.asset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: SvgPicture.asset(asset.assetPath, fit: BoxFit.contain),
      ),
    );
  }
}
