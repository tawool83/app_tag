import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tag_history.dart';
import '../../services/history_service.dart';
import '../qr_result/qr_result_provider.dart';

class HistoryNotifier extends StateNotifier<List<TagHistory>> {
  final HistoryService _service;

  HistoryNotifier(this._service) : super([]) {
    _load();
  }

  void _load() {
    state = _service.getHistory();
  }

  Future<void> delete(String id) async {
    await _service.deleteHistory(id);
    _load();
  }

  Future<void> clearAll() async {
    await _service.clearAll();
    state = [];
  }
}

final historyNotifierProvider =
    StateNotifierProvider<HistoryNotifier, List<TagHistory>>(
  (ref) => HistoryNotifier(ref.read(historyServiceProvider)),
);
