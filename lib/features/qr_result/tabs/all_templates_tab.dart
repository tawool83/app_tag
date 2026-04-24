import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/qr_template.dart';
import '../../../l10n/app_localizations.dart';
import '../../qr_task/domain/entities/qr_task.dart';
import '../../qr_task/presentation/providers/qr_task_providers.dart';
import '../widgets/template_thumbnail.dart';

/// [템플릿] 탭: 즐겨찾기 QR + 카테고리별 전체 템플릿.
class AllTemplatesTab extends ConsumerWidget {
  final QrTemplateManifest manifest;
  final String? activeTemplateId;
  final void Function(QrTemplate) onTemplateSelected;
  final void Function(QrTask) onFavoriteSelected;
  final VoidCallback onChanged;

  const AllTemplatesTab({
    super.key,
    required this.manifest,
    required this.activeTemplateId,
    required this.onTemplateSelected,
    required this.onFavoriteSelected,
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
    final l10n = AppLocalizations.of(context)!;
    final favoritesAsync = ref.watch(favoriteTasksProvider);

    return CustomScrollView(
      slivers: [
        // ── 즐겨찾기 섹션 (존재 시에만) ────────────────────────────────────
        ...favoritesAsync.maybeWhen(
          data: (tasks) => tasks.isEmpty
              ? const []
              : _buildFavoriteSliver(context, l10n, tasks),
          orElse: () => const [],
        ),

        // ── 카테고리별 전체 템플릿 ─────────────────────────────────────────
        for (final category in manifest.categories)
          ..._buildCategorySliver(context, category),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  List<Widget> _buildFavoriteSliver(
      BuildContext context, AppLocalizations l10n, List<QrTask> tasks) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: [
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 6),
              Text(
                l10n.templateSectionFavorites,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, i) => _FavoriteThumbnail(
              task: tasks[i],
              onTap: () => onFavoriteSelected(tasks[i]),
            ),
            childCount: tasks.length,
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

/// 즐겨찾기 QR Task 를 템플릿처럼 표시하는 썸네일. thumbnailBytes 우선.
class _FavoriteThumbnail extends StatelessWidget {
  final QrTask task;
  final VoidCallback onTap;

  const _FavoriteThumbnail({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bytes = task.thumbnailBytes;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: bytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.memory(bytes, fit: BoxFit.contain),
                      )
                    : const Icon(Icons.qr_code_2,
                        size: 48, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: Text(
                task.name,
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
