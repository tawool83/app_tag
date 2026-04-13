import 'package:flutter/material.dart';
import '../../../models/qr_template.dart';
import '../widgets/template_thumbnail.dart';

/// [추천] 탭: 현재 tagType에 맞는 템플릿 표시.
class RecommendedTab extends StatelessWidget {
  final QrTemplateManifest manifest;
  final String? activeTemplateId;
  final String? tagType;
  final void Function(QrTemplate) onTemplateSelected;
  final VoidCallback onTemplateClear;

  const RecommendedTab({
    super.key,
    required this.manifest,
    required this.activeTemplateId,
    required this.tagType,
    required this.onTemplateSelected,
    required this.onTemplateClear,
  });

  List<QrTemplate> get _filtered {
    if (manifest.templates.isEmpty) return [];
    final typed = manifest.templates
        .where((t) =>
            t.tagTypes.contains(tagType) || t.tagTypes.contains('all'))
        .toList();
    return typed.isNotEmpty ? typed : manifest.templates.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    final templates = _filtered;

    if (templates.isEmpty) {
      return const Center(child: Text('추천 템플릿을 불러오는 중...'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.78,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: templates.length + 1, // +1: "스타일 없음" 항목
      itemBuilder: (_, i) {
        if (i == 0) {
          return _ClearTile(
            isSelected: activeTemplateId == null,
            onTap: onTemplateClear,
          );
        }
        final t = templates[i - 1];
        return TemplateThumbnail(
          template: t,
          isSelected: t.id == activeTemplateId,
          onTap: () => onTemplateSelected(t),
        );
      },
    );
  }
}

class _ClearTile extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _ClearTile({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 4),
            Text(
              '스타일\n없음',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
