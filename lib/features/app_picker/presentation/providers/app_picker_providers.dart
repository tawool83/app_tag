import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../nfc_writer/presentation/providers/nfc_writer_providers.dart';
import '../../data/datasources/app_list_datasource.dart';
import '../../data/repositories/app_picker_repository_impl.dart';
import '../../domain/entities/app_info.dart';
import '../../domain/repositories/app_picker_repository.dart';
import '../../domain/usecases/get_installed_apps_usecase.dart';

// ── Data layer ────────────────────────────────────────────────────────────────

final appListDataSourceProvider = Provider<AppListDataSource>((ref) {
  return const DeviceAppListDataSource();
});

final appPickerRepositoryProvider = Provider<AppPickerRepository>((ref) {
  return AppPickerRepositoryImpl(ref.watch(appListDataSourceProvider));
});

// ── UseCases ──────────────────────────────────────────────────────────────────

final getInstalledAppsUseCaseProvider =
    Provider<GetInstalledAppsUseCase>((ref) {
  return GetInstalledAppsUseCase(ref.watch(appPickerRepositoryProvider));
});

// ── UI Providers ──────────────────────────────────────────────────────────────

final appListProvider = FutureProvider<List<AppInfo>>((ref) async {
  final result = await ref.read(getInstalledAppsUseCaseProvider)();
  return result.fold(
    (apps) => apps,
    (failure) => throw Exception(failure.message),
  );
});

final searchQueryProvider = StateProvider<String>((ref) => '');

// ── NFC Availability (delegates to nfc_writer CA layer) ───────────────────

final nfcAvailableProvider = FutureProvider<bool>((ref) async {
  final result = await ref.read(checkNfcAvailabilityUseCaseProvider)();
  return result.fold((v) => v, (_) => false);
});

final nfcWriteSupportedProvider = FutureProvider<bool>((ref) async {
  final repo = ref.read(nfcRepositoryProvider);
  final result = await repo.checkWriteSupport();
  return result.fold((v) => v, (_) => false);
});

// ── Search & Filter ───────────────────────────────────────────────────────

final filteredAppsProvider = Provider<List<AppInfo>>((ref) {
  final appsAsync = ref.watch(appListProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  return appsAsync.when(
    data: (apps) {
      if (query.isEmpty) return apps;
      return apps
          .where((a) =>
              a.appName.toLowerCase().contains(query) ||
              a.packageName.toLowerCase().contains(query))
          .toList();
    },
    loading: () => [],
    error: (_, _) => [],
  );
});
