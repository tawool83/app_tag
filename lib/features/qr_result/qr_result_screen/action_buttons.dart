part of '../qr_result_screen.dart';

// ── 액션 버튼 영역 ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final QrResultState state;
  final VoidCallback onSaveGallery;
  final VoidCallback onSaveTemplate;
  final VoidCallback onShare;

  const _ActionButtons({
    required this.state,
    required this.onSaveGallery,
    required this.onSaveTemplate,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.save_alt,
                  label: l10n.actionSaveGallery,
                  status: state.action.saveStatus,
                  onTap: onSaveGallery,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.bookmark_add_outlined,
                  label: l10n.actionSaveTemplate,
                  status: QrActionStatus.idle,
                  onTap: onSaveTemplate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.share,
                  label: l10n.actionShare,
                  status: state.action.shareStatus,
                  onTap: onShare,
                ),
              ),
            ],
          ),
          if (state.action.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              state.action.errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 액션 버튼 단일 항목 ────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final QrActionStatus status;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = status == QrActionStatus.loading;
    final isSuccess = status == QrActionStatus.success;

    return ElevatedButton(
      onPressed: isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : icon,
                  size: 20,
                  color: isSuccess ? Colors.green : null,
                ),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(fontSize: 11)),
              ],
            ),
      );
  }
}
