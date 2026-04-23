import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/engine/sync_engine.dart';

// ── Engine Provider (stub — UserQrTemplate 삭제로 비활성) ─────────────────────

final templateSyncEngineProvider = Provider<TemplateSyncEngine?>((ref) {
  return null; // QrTask 기반 동기화 재구현 필요
});

// ── Sync State ─────────────────────────────────────────────────────────────

enum SyncStatus { idle, syncing, synced, error }

class SyncState {
  final SyncStatus templateSync;
  final SyncStatus paletteSync;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  const SyncState({
    this.templateSync = SyncStatus.idle,
    this.paletteSync = SyncStatus.idle,
    this.lastSyncedAt,
    this.errorMessage,
  });

  SyncState copyWith({
    SyncStatus? templateSync,
    SyncStatus? paletteSync,
    DateTime? lastSyncedAt,
    String? errorMessage,
  }) =>
      SyncState(
        templateSync: templateSync ?? this.templateSync,
        paletteSync: paletteSync ?? this.paletteSync,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        errorMessage: errorMessage,
      );
}

// ── SyncNotifier ───────────────────────────────────────────────────────────

class SyncNotifier extends StateNotifier<SyncState> {
  final TemplateSyncEngine? _templateEngine;

  SyncNotifier(this._templateEngine) : super(const SyncState());

  Future<void> syncAll(String userId) async {
    if (_templateEngine == null) return;
    state = state.copyWith(templateSync: SyncStatus.syncing);
    final result = await _templateEngine.sync(userId);
    if (result.hasErrors) {
      state = state.copyWith(
        templateSync: SyncStatus.error,
        errorMessage: result.errors.first,
      );
    } else {
      state = state.copyWith(
        templateSync: SyncStatus.synced,
        lastSyncedAt: DateTime.now(),
      );
    }
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref.watch(templateSyncEngineProvider));
});
