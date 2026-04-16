import 'dart:io';

import 'package:device_apps/device_apps.dart';

import '../../domain/entities/app_info.dart';

abstract class AppListDataSource {
  Future<List<AppInfo>> getInstalledApps();
}

class DeviceAppListDataSource implements AppListDataSource {
  const DeviceAppListDataSource();

  @override
  Future<List<AppInfo>> getInstalledApps() async {
    if (!Platform.isAndroid) return [];
    final apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );
    return apps
        .map((app) => AppInfo(
              appName: app.appName,
              packageName: app.packageName,
              icon: app is ApplicationWithIcon ? app.icon : null,
            ))
        .toList()
      ..sort((a, b) => a.appName.compareTo(b.appName));
  }
}
