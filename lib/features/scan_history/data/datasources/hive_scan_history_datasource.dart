import 'package:hive/hive.dart';

import '../../domain/entities/scan_history_entry.dart';
import '../models/scan_history_model.dart';

class HiveScanHistoryDatasource {
  final Box<ScanHistoryModel> _box;

  HiveScanHistoryDatasource(this._box);

  Future<List<ScanHistoryEntry>> getAll() async {
    final models = _box.values.toList()
      ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return models.map((m) => m.toEntity()).toList();
  }

  Future<void> save(ScanHistoryEntry entry) async {
    final model = ScanHistoryModel.fromEntity(entry);
    await _box.put(entry.id, model);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
