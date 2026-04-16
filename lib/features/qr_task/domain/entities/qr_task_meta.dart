/// QrTask 의 메타 정보 (불변).
/// JSON 직렬화는 모두 primitive (Flutter 의존 0).
class QrTaskMeta {
  final String appName;
  final String deepLink;
  final String platform;
  final String? packageName;

  /// Android 앱 아이콘 PNG bytes 의 Base64 (옵션).
  final String? appIconBase64;

  /// 'app' | 'clipboard' | 'website' | 'contact' | 'wifi' | 'location' |
  /// 'event' | 'email' | 'sms' | null
  final String? tagType;

  const QrTaskMeta({
    required this.appName,
    required this.deepLink,
    required this.platform,
    this.packageName,
    this.appIconBase64,
    this.tagType,
  });

  Map<String, dynamic> toJson() => {
        'appName': appName,
        'deepLink': deepLink,
        'platform': platform,
        'packageName': packageName,
        'appIconBase64': appIconBase64,
        'tagType': tagType,
      };

  factory QrTaskMeta.fromJson(Map<String, dynamic> json) => QrTaskMeta(
        appName: json['appName'] as String? ?? '',
        deepLink: json['deepLink'] as String? ?? '',
        platform: json['platform'] as String? ?? 'universal',
        packageName: json['packageName'] as String?,
        appIconBase64: json['appIconBase64'] as String?,
        tagType: json['tagType'] as String?,
      );

  QrTaskMeta copyWith({
    String? appName,
    String? deepLink,
    String? platform,
    String? packageName,
    String? appIconBase64,
    String? tagType,
  }) =>
      QrTaskMeta(
        appName: appName ?? this.appName,
        deepLink: deepLink ?? this.deepLink,
        platform: platform ?? this.platform,
        packageName: packageName ?? this.packageName,
        appIconBase64: appIconBase64 ?? this.appIconBase64,
        tagType: tagType ?? this.tagType,
      );
}
