import 'package:hive_flutter/hive_flutter.dart';

import '../../features/qr_result/data/datasources/hive_user_template_datasource.dart';
import '../../features/qr_result/data/models/user_qr_template_model.dart';
import '../../features/qr_task/data/datasources/hive_qr_task_datasource.dart';
import '../../features/qr_task/data/models/qr_task_model.dart';

/// Hive 초기화 + 어댑터 등록 + 박스 오픈을 한 곳에서.
///
/// - typeId 0: (폐기됨 — 구 TagHistoryModel, 어댑터 등록하지 않음)
/// - typeId 1: UserQrTemplateModel  (스타일 템플릿, Clean Architecture DTO)
/// - typeId 2: QrTaskModel          (qr-task-json-storage)
///
/// ⚠ typeId/fieldId 는 절대 변경 금지 (기존 저장 데이터 호환성).
Future<void> initHive() async {
  await Hive.initFlutter();

  // typeId 0 (구 TagHistoryModel) — 폐기. 어댑터 미등록, box 삭제.
  await Hive.deleteBoxFromDisk('tag_history');

  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(UserQrTemplateModelAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(QrTaskModelAdapter());
  }

  if (!Hive.isBoxOpen(HiveUserTemplateDataSource.boxName)) {
    await Hive.openBox<UserQrTemplateModel>(
        HiveUserTemplateDataSource.boxName);
  }
  if (!Hive.isBoxOpen(HiveQrTaskDataSource.boxName)) {
    await Hive.openBox<QrTaskModel>(HiveQrTaskDataSource.boxName);
  }
}
