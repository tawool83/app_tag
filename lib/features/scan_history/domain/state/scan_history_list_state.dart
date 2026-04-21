import 'package:flutter/foundation.dart';

import '../entities/scan_history_entry.dart';

@immutable
class ScanHistoryListState {
  final List<ScanHistoryEntry> items;
  final bool isLoading;

  const ScanHistoryListState({
    this.items = const [],
    this.isLoading = false,
  });

  ScanHistoryListState copyWith({
    List<ScanHistoryEntry>? items,
    bool? isLoading,
  }) =>
      ScanHistoryListState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanHistoryListState &&
          listEquals(other.items, items) &&
          other.isLoading == isLoading;

  @override
  int get hashCode => Object.hash(items.length, isLoading);
}
