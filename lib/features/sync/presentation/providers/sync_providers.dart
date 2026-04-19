import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../../../core/di/supabase_config.dart';
import '../../../qr_result/presentation/providers/qr_result_providers.dart';
import '../../data/datasources/supabase_template_datasource.dart';
import '../../data/engine/sync_engine.dart';

// ── DataSource / Engine Providers ──────────────────────────────────────────

final supabaseTemplateDataSourceProvider =
    Provider<SupabaseTemplateDataSource?>((ref) {
  if (!isSupabaseConfigured) return null;
  return SupabaseTemplateDataSource(Supabase.instance.client);
});

final templateSyncEngineProvider = Provider<TemplateSyncEngine?>((ref) {
  final remote = ref.watch(supabaseTemplateDataSourceProvider);
  if (remote == null) return null;
  return TemplateSyncEngine(
    ref.watch(hiveUserTemplateDataSourceProvider),
    remote,
  );
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

  /// 전체 동기화 (앱 시작 시 / 수동 트리거).
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
