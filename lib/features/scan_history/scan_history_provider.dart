library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../scanner/domain/entities/scan_detected_type.dart';
import 'data/datasources/hive_scan_history_datasource.dart';
import 'data/models/scan_history_model.dart';
import 'domain/entities/scan_history_entry.dart';
import 'domain/state/scan_history_filter_state.dart';
import 'domain/state/scan_history_list_state.dart';

part 'notifier/list_setters.dart';
part 'notifier/filter_setters.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final scanHistoryBoxProvider = Provider<Box<ScanHistoryModel>>(
  (ref) => Hive.box<ScanHistoryModel>(ScanHistoryModel.boxName),
);

final scanHistoryDatasourceProvider = Provider<HiveScanHistoryDatasource>(
  (ref) => HiveScanHistoryDatasource(ref.watch(scanHistoryBoxProvider)),
);

// ── State ────────────────────────────────────────────────────────────────────

class ScanHistoryState {
  final ScanHistoryListState list;
  final ScanHistoryFilterState filter;

  const ScanHistoryState({
    this.list = const ScanHistoryListState(),
    this.filter = const ScanHistoryFilterState(),
  });

  ScanHistoryState copyWith({
    ScanHistoryListState? list,
    ScanHistoryFilterState? filter,
  }) =>
      ScanHistoryState(
        list: list ?? this.list,
        filter: filter ?? this.filter,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanHistoryState &&
          other.list == list &&
          other.filter == filter;

  @override
  int get hashCode => Object.hash(list, filter);
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class ScanHistoryNotifier extends StateNotifier<ScanHistoryState>
    with _ListSetters, _FilterSetters {
  @override
  final Ref _ref;

  ScanHistoryNotifier(this._ref) : super(const ScanHistoryState()) {
    _loadAll();
  }
}

final scanHistoryProvider =
    StateNotifierProvider.autoDispose<ScanHistoryNotifier, ScanHistoryState>(
  (ref) => ScanHistoryNotifier(ref),
);
