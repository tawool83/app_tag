import 'package:flutter/material.dart';
import '../../qr_task/domain/entities/qr_task.dart';

/// 홈 갤러리의 QrTask 타일 카드 — 사용자 템플릿 스타일.
class QrTaskGalleryTile extends StatelessWidget {
  final QrTask task;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool selectable;
  final bool selected;

  const QrTaskGalleryTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onLongPress,
    this.selectable = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 썸네일
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    width: selected ? 2.5 : 1,
                  ),
                  color: Colors.grey.shade50,
                ),
                clipBehavior: Clip.antiAlias,
                child: task.thumbnailBytes != null
                    ? Image.memory(task.thumbnailBytes!, fit: BoxFit.cover)
                    : const Center(
                        child: Icon(Icons.qr_code, size: 40, color: Colors.grey),
                      ),
              ),
              // 즐겨찾기 별 배지 (좌측 상단)
              if (task.isFavorite)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star, size: 16, color: Colors.amber),
                  ),
                ),
              // 선택 체크마크
              if (selectable)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white.withValues(alpha: 0.8),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade400,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // 이름
          SizedBox(
            width: 100,
            child: Text(
              task.name,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
