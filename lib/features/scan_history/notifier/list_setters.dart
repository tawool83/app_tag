part of '../scan_history_provider.dart';

mixin _ListSetters on StateNotifier<ScanHistoryState> {
  Ref get _ref;

  Future<void> _loadAll() async {
    state = state.copyWith(list: state.list.copyWith(isLoading: true));
    final datasource = _ref.read(scanHistoryDatasourceProvider);
    final entries = await datasource.getAll();
    state = state.copyWith(
      list: state.list.copyWith(items: entries, isLoading: false),
    );
  }

  Future<void> addEntry({
    required String rawValue,
    required ScanDetectedType detectedType,
    required Map<String, dynamic> parsedMeta,
  }) async {
    final entry = ScanHistoryEntry(
      id: const Uuid().v4(),
      scannedAt: DateTime.now(),
      rawValue: rawValue,
      detectedType: detectedType,
      parsedMeta: parsedMeta,
    );
    final datasource = _ref.read(scanHistoryDatasourceProvider);
    await datasource.save(entry);
    state = state.copyWith(
      list: state.list.copyWith(items: [entry, ...state.list.items]),
    );
  }

  Future<void> toggleFavorite(String id) async {
    final idx = state.list.items.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final updated = state.list.items[idx].copyWith(
      isFavorite: !state.list.items[idx].isFavorite,
    );
    final datasource = _ref.read(scanHistoryDatasourceProvider);
    await datasource.save(updated);
    final newList = [...state.list.items]..[idx] = updated;
    state = state.copyWith(list: state.list.copyWith(items: newList));
  }

  Future<void> deleteEntry(String id) async {
    final datasource = _ref.read(scanHistoryDatasourceProvider);
    await datasource.delete(id);
    state = state.copyWith(
      list: state.list.copyWith(
        items: state.list.items.where((e) => e.id != id).toList(),
      ),
    );
  }

  Future<void> clearAll() async {
    final datasource = _ref.read(scanHistoryDatasourceProvider);
    await datasource.clearAll();
    state = state.copyWith(list: const ScanHistoryListState());
  }
}
