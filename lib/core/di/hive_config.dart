import 'package:hive_flutter/hive_flutter.dart';

import '../../features/color_palette/data/datasources/hive_color_palette_datasource.dart';
import '../../features/color_palette/data/models/user_color_palette_model.dart';
import '../../features/qr_task/data/datasources/hive_qr_task_datasource.dart';
import '../../features/qr_task/data/models/qr_task_model.dart';
import '../../features/scan_history/data/models/scan_history_model.dart';

/// Hive 초기화 + 어댑터 등록 + 박스 오픈을 한 곳에서.
///
/// - typeId 0: (폐기됨 — 구 TagHistoryModel)
/// - typeId 1: (폐기됨 — 구 UserQrTemplateModel)
/// - typeId 2: QrTaskModel
/// - typeId 3: UserColorPaletteModel
/// - typeId 4: ScanHistoryModel
///
/// ⚠ typeId/fieldId 는 절대 변경 금지 (기존 저장 데이터 호환성).
Future<void> initHive() async {
  await Hive.initFlutter();

  // 폐기된 box 삭제 (best-effort)
  await Hive.deleteBoxFromDisk('tag_history');
  await Hive.deleteBoxFromDisk('user_qr_templates');

  // typeId 1 (UserQrTemplateModel) — 폐기. 어댑터 미등록.
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(QrTaskModelAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(UserColorPaletteModelAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(ScanHistoryModelAdapter());
  }

  if (!Hive.isBoxOpen(HiveQrTaskDataSource.boxName)) {
    await Hive.openBox<QrTaskModel>(HiveQrTaskDataSource.boxName);
  }
  if (!Hive.isBoxOpen(HiveColorPaletteDataSource.boxName)) {
    await Hive.openBox<UserColorPaletteModel>(
        HiveColorPaletteDataSource.boxName);
  }
  if (!Hive.isBoxOpen(ScanHistoryModel.boxName)) {
    await Hive.openBox<ScanHistoryModel>(ScanHistoryModel.boxName);
  }
}
