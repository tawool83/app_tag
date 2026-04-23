import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/qr_template.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/template_thumbnail.dart';

/// [템플릿] 탭: 카테고리별 전체 템플릿.
class AllTemplatesTab extends ConsumerWidget {
  final QrTemplateManifest manifest;
  final String? activeTemplateId;
  final void Function(QrTemplate) onTemplateSelected;
  final VoidCallback onTemplateClear;
  final VoidCallback onChanged;

  const AllTemplatesTab({
    super.key,
    required this.manifest,
    required this.activeTemplateId,
    required this.onTemplateSelected,
    required this.onTemplateClear,
    required this.onChanged,
  });

  List<QrTemplate> _templatesForCategory(String categoryId) {
    return manifest.templates
        .where((t) => t.categoryId == categoryId)
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (manifest.templates.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        // ── "스타일 없음" 버튼 ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: OutlinedButton.icon(
              onPressed: onTemplateClear,
              icon: const Icon(Icons.block, size: 16),
              label: Text(AppLocalizations.of(context)!.actionNoStyle),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: activeTemplateId == null
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                  width: activeTemplateId == null ? 2 : 1,
                ),
              ),
            ),
          ),
        ),

        // ── 카테고리별 전체 템플릿 ─────────────────────────────────────────
        for (final category in manifest.categories)
          ..._buildCategorySliver(context, category),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  List<Widget> _buildCategorySliver(
      BuildContext context, QrTemplateCategory category) {
    final templates = _templatesForCategory(category.id);
    if (templates.isEmpty) return [];

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Text(
            category.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, i) => TemplateThumbnail(
              template: templates[i],
              isSelected: templates[i].id == activeTemplateId,
              onTap: () => onTemplateSelected(templates[i]),
            ),
            childCount: templates.length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.78,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
        ),
      ),
    ];
  }
}
