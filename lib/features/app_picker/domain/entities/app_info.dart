import 'dart:typed_data';

class AppInfo {
  final String appName;
  final String packageName;
  final Uint8List? icon;

  const AppInfo({
    required this.appName,
    required this.packageName,
    this.icon,
  });
}
