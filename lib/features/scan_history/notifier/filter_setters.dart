part of '../scan_history_provider.dart';

mixin _FilterSetters on StateNotifier<ScanHistoryState> {
  void setQuery(String query) {
    state = state.copyWith(
      filter: state.filter.copyWith(query: query),
    );
  }

  void setTypeFilter(ScanDetectedType? type) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        selectedType: type,
        clearSelectedType: type == null,
      ),
    );
  }

  void toggleFavoritesOnly() {
    state = state.copyWith(
      filter: state.filter.copyWith(
        favoritesOnly: !state.filter.favoritesOnly,
      ),
    );
  }

  void clearFilters() {
    state = state.copyWith(filter: const ScanHistoryFilterState());
  }
}
