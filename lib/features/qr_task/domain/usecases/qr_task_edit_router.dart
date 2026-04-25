import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../entities/qr_task.dart';

/// QrTask 편집 시 tagType 에 따라 데이터 입력 화면으로 라우팅.
///
/// 입력 화면이 있는 tagType → 해당 화면(prefill + editTaskId)
/// 입력 화면이 없는 tagType (app 등) → 바로 /qr-result
class QrTaskEditRouter {
  QrTaskEditRouter._();

  static Future<void> push(BuildContext context, QrTask task) {
    final route = _tagTypeToRoute(task.meta.tagType);
    if (route != null) {
      return context.push(route, extra: {
        ..._buildPrefillFromMeta(task),
        'editTaskId': task.id,
      });
    }
    return context.push('/qr-result', extra: {
      'editTaskId': task.id,
      'appName': task.meta.appName,
      'deepLink': task.meta.deepLink,
      'platform': task.meta.platform,
      'packageName': task.meta.packageName,
      'tagType': task.meta.tagType,
    });
  }

  static String? _tagTypeToRoute(String? tagType) => switch (tagType) {
    'clipboard' => '/clipboard-tag',
    'website' => '/website-tag',
    'contact' => '/contact-manual',
    'wifi' => '/wifi-tag',
    'location' => '/location-tag',
    'event' => '/event-tag',
    'email' => '/email-tag',
    'sms' => '/sms-tag',
    _ => null,
  };

  static Map<String, dynamic> _buildPrefillFromMeta(QrTask task) {
    final meta = task.meta;
    return switch (meta.tagType) {
      'clipboard' => {'text': meta.deepLink},
      'website' => {'url': meta.deepLink},
      'contact' => _parseContactPrefill(meta.deepLink),
      'wifi' => _parseWifiPrefill(meta.deepLink),
      'email' => _parseEmailPrefill(meta.deepLink),
      'sms' => _parseSmsPrefill(meta.deepLink),
      _ => {},
    };
  }

  static Map<String, dynamic> _parseEmailPrefill(String deepLink) {
    if (!deepLink.startsWith('mailto:')) return {};
    final uri = Uri.tryParse(deepLink);
    if (uri == null) return {};
    return {
      'address': uri.path,
      'subject': uri.queryParameters['subject'] ?? '',
      'body': uri.queryParameters['body'] ?? '',
    };
  }

  static Map<String, dynamic> _parseContactPrefill(String deepLink) {
    String? name, phone, email;
    for (final line in deepLink.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('FN:')) name = trimmed.substring(3);
      if (trimmed.startsWith('TEL:')) phone = trimmed.substring(4);
      if (trimmed.startsWith('EMAIL:')) email = trimmed.substring(6);
    }
    return {'name': name ?? '', 'phone': phone ?? '', 'email': email ?? ''};
  }

  static Map<String, dynamic> _parseWifiPrefill(String deepLink) {
    if (!deepLink.startsWith('WIFI:')) return {};
    String? ssid, secType, password;
    final body = deepLink.substring(5);
    for (final part in body.split(';')) {
      if (part.startsWith('S:')) ssid = part.substring(2);
      if (part.startsWith('T:')) secType = part.substring(2);
      if (part.startsWith('P:')) password = part.substring(2);
    }
    return {
      'ssid': ssid ?? '',
      'securityType': secType ?? 'WPA',
      'password': password ?? '',
    };
  }

  static Map<String, dynamic> _parseSmsPrefill(String deepLink) {
    if (deepLink.startsWith('smsto:')) {
      final parts = deepLink.substring(6).split(':');
      return {
        'phone': parts.isNotEmpty ? parts[0] : '',
        'message': parts.length > 1 ? parts.sublist(1).join(':') : '',
      };
    }
    if (deepLink.startsWith('sms:')) {
      return {'phone': deepLink.substring(4), 'message': ''};
    }
    return {};
  }
}
