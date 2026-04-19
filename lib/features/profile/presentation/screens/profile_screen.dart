import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../sync/presentation/providers/sync_providers.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nicknameController = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final syncState = ref.watch(syncProvider);
    final user = authState.user;

    if (user == null) {
      // 비로그인 상태에서 접근 시 로그인으로 리다이렉트
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_editing) {
      _nicknameController.text = user.nickname ?? '';
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── 아바타 ──
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundImage:
                  user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? const Icon(Icons.person, size: 48)
                  : null,
            ),
          ),
          const SizedBox(height: 24),

          // ── 닉네임 ──
          TextFormField(
            controller: _nicknameController,
            decoration: InputDecoration(
              labelText: l10n.nickname,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_editing ? Icons.check : Icons.edit),
                onPressed: _editing ? _saveNickname : _startEditing,
              ),
            ),
            readOnly: !_editing,
          ),
          const SizedBox(height: 16),

          // ── 읽기 전용 정보 ──
          _InfoTile(label: l10n.email, value: user.email),
          _InfoTile(label: l10n.loginMethod, value: user.provider),
          _InfoTile(
            label: l10n.joinDate,
            value:
                '${user.createdAt.year}-${user.createdAt.month.toString().padLeft(2, '0')}-${user.createdAt.day.toString().padLeft(2, '0')}',
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // ── 동기화 상태 ──
          _InfoTile(
            label: l10n.syncStatus,
            value: _syncStatusText(syncState, l10n),
          ),
          if (syncState.lastSyncedAt != null)
            _InfoTile(
              label: l10n.lastSynced,
              value: _formatTime(syncState.lastSyncedAt!),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: syncState.templateSync == SyncStatus.syncing
                ? null
                : () => ref.read(syncProvider.notifier).syncAll(user.id),
            icon: const Icon(Icons.sync),
            label: Text(l10n.manualSync),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // ── 로그아웃 ──
          OutlinedButton(
            onPressed: () => _confirmSignOut(l10n),
            child: Text(l10n.logout),
          ),
          const SizedBox(height: 12),

          // ── 계정 삭제 ──
          TextButton(
            onPressed: () => _confirmDeleteAccount(l10n),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
  }

  void _startEditing() => setState(() => _editing = true);

  Future<void> _saveNickname() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;

    await ref
        .read(profileRepositoryProvider)
        ?.updateProfile(user.id, nickname: nickname);
    setState(() => _editing = false);
  }

  void _confirmSignOut(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).signOut();
              context.go('/home');
            },
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).deleteAccount();
              context.go('/home');
            },
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
  }

  String _syncStatusText(SyncState state, AppLocalizations l10n) {
    return switch (state.templateSync) {
      SyncStatus.synced => l10n.synced,
      SyncStatus.syncing => l10n.syncing,
      SyncStatus.error => l10n.syncError,
      SyncStatus.idle => '-',
    };
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.month}/${dt.day}';
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
