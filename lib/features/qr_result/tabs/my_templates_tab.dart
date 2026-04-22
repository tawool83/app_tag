import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/result.dart';
import '../../../core/extensions/context_extensions.dart';
import '../domain/entities/template_engine_version.dart';
import '../domain/entities/user_qr_template.dart';
import '../presentation/providers/qr_result_providers.dart';
import '../qr_result_provider.dart';

/// [나의 템플릿] 탭: 저장된 QR 템플릿 그리드 표시 + 적용/삭제.
class MyTemplatesTab extends ConsumerStatefulWidget {
  final VoidCallback onChanged;

  const MyTemplatesTab({super.key, required this.onChanged});

  @override
  ConsumerState<MyTemplatesTab> createState() => _MyTemplatesTabState();
}

class _MyTemplatesTabState extends ConsumerState<MyTemplatesTab> {
  List<UserQrTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await ref.read(getUserTemplatesUseCaseProvider)();
    if (mounted) {
      setState(() {
        _templates = result.valueOrNull ?? [];
      });
    }
  }

  Future<void> _apply(UserQrTemplate t) async {
    if (!isTemplateCompatible(t.minEngineVersion)) {
      if (mounted) {
        context.showSnack('이 템플릿은 최신 버전의 앱이 필요합니다.');
      }
      return;
    }
    ref.read(qrResultProvider.notifier).applyUserTemplate(t);
    widget.onChanged();
    if (mounted) {
      context.showSnack('「${t.name}」 템플릿이 적용되었습니다.');
    }
  }

  Future<void> _delete(UserQrTemplate t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('템플릿 삭제'),
        content: Text('「${t.name}」을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(deleteUserTemplateUseCaseProvider)(t.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              '저장된 템플릿이 없습니다.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              '하단 [템플릿 저장] 버튼으로 현재 스타일을 저장하세요.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _templates.length,
      itemBuilder: (context, i) {
        final t = _templates[i];
        return _TemplateCard(
          template: t,
          onApply: () => _apply(t),
          onDelete: () => _delete(t),
        );
      },
    );
  }
}

// ── 템플릿 카드 ──────────────────────────────────────────────────────────────────

class _TemplateCard extends StatelessWidget {
  final UserQrTemplate template;
  final VoidCallback onApply;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.onApply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final compatible = isTemplateCompatible(template.minEngineVersion);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onApply,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 썸네일 영역
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    template.thumbnailBytes != null
                        ? Image.memory(
                            template.thumbnailBytes!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: Icon(Icons.qr_code, size: 48, color: Colors.grey),
                            ),
                          ),
                    if (!compatible)
                      Container(
                        color: Colors.black38,
                        child: const Center(
                          child: Icon(Icons.lock_outline, size: 32, color: Colors.white70),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // 이름 + 삭제 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
