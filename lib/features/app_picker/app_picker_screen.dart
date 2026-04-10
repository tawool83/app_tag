import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_info.dart';
import '../../shared/constants/deep_link_constants.dart';
import 'app_picker_provider.dart';

class AppPickerScreen extends ConsumerWidget {
  const AppPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(appListProvider);
    final filtered = ref.watch(filteredAppsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('앱 선택'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '앱 검색...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).state = value,
            ),
          ),
        ),
      ),
      body: appsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text('앱 목록을 불러올 수 없습니다.'),
              const SizedBox(height: 8),
              Text('$e', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        data: (_) => filtered.isEmpty
            ? const Center(child: Text('검색 결과가 없습니다.'))
            : ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final app = filtered[index];
                  return _AppListTile(app: app);
                },
              ),
      ),
    );
  }
}

class _AppListTile extends StatelessWidget {
  final AppInfo app;
  const _AppListTile({required this.app});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: app.icon != null
          ? Image.memory(app.icon!, width: 40, height: 40)
          : const Icon(Icons.android, size: 40),
      title: Text(app.appName),
      subtitle: Text(
        app.packageName,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => Navigator.pushNamed(
        context,
        '/output-selector',
        arguments: {
          'appName': app.appName,
          'deepLink': DeepLinkConstants.androidIntentLink(app.packageName),
          'packageName': app.packageName,
          'platform': 'android',
          'appIconBytes': app.icon,
        },
      ),
    );
  }
}
