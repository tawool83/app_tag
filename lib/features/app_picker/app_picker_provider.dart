import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_info.dart';
import '../../services/nfc_service.dart';

final nfcServiceProvider = Provider<NfcService>((ref) => NfcService());

final appListProvider = FutureProvider<List<AppInfo>>((ref) async {
  return ref.read(nfcServiceProvider).getInstalledApps();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

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
    error: (_, e) => [],
  );
});

final nfcAvailableProvider = FutureProvider<bool>((ref) async {
  return ref.read(nfcServiceProvider).isNfcAvailable();
});

final nfcWriteSupportedProvider = FutureProvider<bool>((ref) async {
  return ref.read(nfcServiceProvider).isNfcWriteSupported();
});
