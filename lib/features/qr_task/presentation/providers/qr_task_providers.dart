import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

export 'qr_task_list_notifier.dart' show qrTaskListNotifierProvider, QrTaskListNotifier;

import '../../data/datasources/hive_qr_task_datasource.dart';
import '../../data/datasources/qr_task_local_datasource.dart';
import '../../data/models/qr_task_model.dart';
import '../../data/repositories/qr_task_repository_impl.dart';
import '../../domain/repositories/qr_task_repository.dart';
import '../../domain/usecases/clear_qr_tasks_usecase.dart';
import '../../domain/usecases/create_qr_task_usecase.dart';
import '../../domain/usecases/delete_qr_task_usecase.dart';
import '../../domain/usecases/get_qr_task_by_id_usecase.dart';
import '../../domain/usecases/hide_all_from_home_usecase.dart';
import '../../domain/usecases/hide_from_home_usecase.dart';
import '../../domain/usecases/list_home_visible_usecase.dart';
import '../../domain/usecases/list_qr_tasks_usecase.dart';
import '../../domain/usecases/rename_qr_task_usecase.dart';
import '../../domain/usecases/toggle_favorite_usecase.dart';
import '../../domain/usecases/update_qr_task_customization_usecase.dart';
import '../../domain/usecases/update_qr_task_thumbnail_usecase.dart';

/// Hive [Box] of [QrTaskModel] (오픈은 core/di/hive_config.dart 에서).
final qrTaskBoxProvider = Provider<Box<QrTaskModel>>(
  (ref) => Hive.box<QrTaskModel>(HiveQrTaskDataSource.boxName),
);

final qrTaskLocalDataSourceProvider = Provider<QrTaskLocalDataSource>(
  (ref) => HiveQrTaskDataSource(ref.watch(qrTaskBoxProvider)),
);

final qrTaskRepositoryProvider = Provider<QrTaskRepository>(
  (ref) => QrTaskRepositoryImpl(ref.watch(qrTaskLocalDataSourceProvider)),
);

final createQrTaskUseCaseProvider = Provider<CreateQrTaskUseCase>(
  (ref) => CreateQrTaskUseCase(ref.watch(qrTaskRepositoryProvider)),
);

final getQrTaskByIdUseCaseProvider = Provider<GetQrTaskByIdUseCase>(
  (ref) => GetQrTaskByIdUseCase(ref.watch(qrTaskRepositoryProvider)),
);

final listQrTasksUseCaseProvider = Provider<ListQrTasksUseCase>(
  (ref) => ListQrTasksUseCase(ref.watch(qrTaskRepositoryProvider)),
);

final updateQrTaskCustomizationUseCaseProvider =
    Provider<UpdateQrTaskCustomizationUseCase>(
  (ref) => UpdateQrTaskCustomizationUseCase(ref.watch(qrTaskRepositoryProvider)),
);

final deleteQrTaskUseCaseProvider = Provider<DeleteQrTaskUseCase>(
  (ref) => DeleteQrTaskUseCase(ref.watch(qrTaskRepositoryProvider)),
);

final clearQrTasksUseCaseProvider = Provider<ClearQrTasksUseCase>(
  (ref) => ClearQrTasksUseCase(ref.watch(qrTaskRepositoryProvider)),
);

final toggleFavoriteUseCaseProvider = Provider<ToggleFavoriteUseCase>(
  (ref) => ToggleFavoriteUseCase(ref.watch(qrTaskRepositoryProvider)),
);

final renameQrTaskUseCaseProvider = Provider<RenameQrTaskUseCase>(
  (ref) => RenameQrTaskUseCase(ref.watch(qrTaskRepositoryProvider)),
);

final updateQrTaskThumbnailUseCaseProvider =
    Provider<UpdateQrTaskThumbnailUseCase>(
  (ref) => UpdateQrTaskThumbnailUseCase(ref.watch(qrTaskRepositoryProvider)),
);

final hideFromHomeUseCaseProvider = Provider<HideFromHomeUseCase>(
  (ref) => HideFromHomeUseCase(ref.watch(qrTaskRepositoryProvider)),
);

final listHomeVisibleUseCaseProvider = Provider<ListHomeVisibleUseCase>(
  (ref) => ListHomeVisibleUseCase(ref.watch(qrTaskRepositoryProvider)),
);

final hideAllFromHomeUseCaseProvider = Provider<HideAllFromHomeUseCase>(
  (ref) => HideAllFromHomeUseCase(ref.watch(qrTaskRepositoryProvider)),
);
