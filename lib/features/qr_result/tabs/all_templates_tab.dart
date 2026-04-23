import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/result.dart';
import '../domain/entities/qr_template.dart';
import '../domain/entities/user_qr_template.dart';
import '../presentation/providers/qr_result_providers.dart';
import '../qr_result_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/template_thumbnail.dart';

/// [템플릿] 탭: 나의 템플릿(상단) + 카테고리별 전체 템플릿(하단).
class AllTemplatesTab extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<AllTemplatesTab> createState() => _AllTemplatesTabState();
}

class _AllTemplatesTabState extends ConsumerState<AllTemplatesTab> {
  List<UserQrTemplate> _myTemplates = [];

  @override
  void initState() {
    super.initState();
    _loadMyTemplates();
  }

  Future<void> _loadMyTemplates() async {
    final result =
        await ref.read(getUserTemplatesUseCaseProvider)();
    if (mounted) {
      setState(() {
        _myTemplates = result.valueOrNull ?? [];
      });
    }
  }

  Future<void> _applyUserTemplate(UserQrTemplate t) async {
    ref.read(qrResultProvider.notifier).applyUserTemplate(t);
    widget.onChanged();
  }

  Future<void> _deleteUserTemplate(UserQrTemplate t) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogDeleteTemplateTitle),
        content: Text(l10n.dialogDeleteTemplateContent(t.name)),
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
    if (confirmed == true) {
      await ref.read(deleteUserTemplateUseCaseProvider)(t.id);
      _loadMyTemplates();
    }
  }

  List<QrTemplate> _templatesForCategory(String categoryId) {
    return widget.manifest.templates
        .where((t) => t.categoryId == categoryId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.manifest.templates.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        // ── 나의 템플릿 섹션 (저장된 템플릿이 있을 때만 표시) ────────────────
        if (_myTemplates.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.screenTemplateMyTemplates,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_myTemplates.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: _myTemplates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final t = _myTemplates[i];
                  return _MyTemplateCard(
                    template: t,
                    onApply: () => _applyUserTemplate(t),
                    onDelete: () => _deleteUserTemplate(t),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 16, 12, 0),
              child: Divider(height: 1),
            ),
          ),
        ],

        // ── "스타일 없음" 버튼 ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: OutlinedButton.icon(
              onPressed: widget.onTemplateClear,
              icon: const Icon(Icons.block, size: 16),
              label: Text(AppLocalizations.of(context)!.actionNoStyle),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: widget.activeTemplateId == null
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                  width: widget.activeTemplateId == null ? 2 : 1,
                ),
              ),
            ),
          ),
        ),

        // ── 카테고리별 전체 템플릿 ─────────────────────────────────────────
        for (final category in widget.manifest.categories)
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
              isSelected: templates[i].id == widget.activeTemplateId,
              onTap: () => widget.onTemplateSelected(templates[i]),
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

// ── 나의 템플릿 카드 (가로 스크롤용 compact 카드) ─────────────────────────────────

class _MyTemplateCard extends StatelessWidget {
  final UserQrTemplate template;
  final VoidCallback onApply;
  final VoidCallback onDelete;

  const _MyTemplateCard({
    required this.template,
    required this.onApply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          onTap: onApply,
          onLongPress: onDelete,
          borderRadius: BorderRadius.circular(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 썸네일
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                  child: template.thumbnailBytes != null
                      ? Image.memory(
                          template.thumbnailBytes!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: Icon(Icons.qr_code,
                                size: 36, color: Colors.grey),
                          ),
                        ),
                ),
              ),
              // 이름 + 삭제
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 2, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        template.name,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: onDelete,
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.delete_outline,
                            size: 15, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
