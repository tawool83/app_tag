import 'package:flutter/foundation.dart';

import '../../../scanner/domain/entities/scan_detected_type.dart';

@immutable
class ScanHistoryFilterState {
  final String query;
  final ScanDetectedType? selectedType;
  final bool favoritesOnly;

  const ScanHistoryFilterState({
    this.query = '',
    this.selectedType,
    this.favoritesOnly = false,
  });

  ScanHistoryFilterState copyWith({
    String? query,
    ScanDetectedType? selectedType,
    bool? favoritesOnly,
    bool clearSelectedType = false,
  }) =>
      ScanHistoryFilterState(
        query: query ?? this.query,
        selectedType:
            clearSelectedType ? null : (selectedType ?? this.selectedType),
        favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanHistoryFilterState &&
          other.query == query &&
          other.selectedType == selectedType &&
          other.favoritesOnly == favoritesOnly;

  @override
  int get hashCode => Object.hash(query, selectedType, favoritesOnly);
}
