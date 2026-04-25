import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../qr_task/domain/entities/qr_task.dart';
import '../../qr_task/presentation/providers/qr_task_providers.dart';

/// [템플릿] 탭: 즐겨찾기 QR 표시. 향후 원격 템플릿 추가 예정.
class AllTemplatesTab extends ConsumerWidget {
  final void Function(QrTask) onFavoriteSelected;
  final VoidCallback onChanged;

  const AllTemplatesTab({
    super.key,
    required this.onFavoriteSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final favoritesAsync = ref.watch(favoriteTasksProvider);

    return favoritesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_border, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  l10n.templateEmptyFavorites,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text(
                      l10n.templateSectionFavorites,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
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
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        );
      },
    );
  }
}

/// 즐겨찾기 QR Task 를 템플릿처럼 표시하는 썸네일.
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: bytes != null
                    ? Transform.scale(
                        scale: 1.35,
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
