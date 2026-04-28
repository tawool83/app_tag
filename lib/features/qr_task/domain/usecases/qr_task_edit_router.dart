import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../entities/qr_task.dart';

/// QrTask 편집 시 tagType 에 따라 데이터 입력 화면으로 라우팅.
///
/// 입력 화면이 있는 tagType → 해당 화면(prefill + editTaskId)
/// 앱 실행(Android 'null' / iOS 'app') → /app-picker, /ios-input 거치지 않고
///   바로 /qr-result 로 진입 (이미 선택된 앱·단축어 정보가 task.meta 에 보존됨).
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

  /// tagType → 편집 시 진입할 데이터 입력 화면 경로.
  /// null 반환 시 호출자가 /qr-result 로 직행.
  /// 앱 실행 태그(null/'app')는 명시적으로 picker/input 화면 우회.
  static String? _tagTypeToRoute(String? tagType) => switch (tagType) {
    'clipboard' => '/clipboard-tag',
    'website' => '/website-tag',
    'contact' => '/contact-manual',
    'wifi' => '/wifi-tag',
    'location' => '/location-tag',
    'event' => '/event-tag',
    'email' => '/email-tag',
    'sms' => '/sms-tag',
    // 앱 실행 — 편집 시 picker/input 거치지 않음
    'app' => null,
    null => null,
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
      'event' => _parseEventPrefill(meta.deepLink),
      'location' => _parseLocationPrefill(meta.deepLink),
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

  static Map<String, dynamic> _parseEventPrefill(String deepLink) {
    String? title, location, description;
    DateTime? start, end;
    for (final line in deepLink.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('SUMMARY:')) title = trimmed.substring(8);
      if (trimmed.startsWith('LOCATION:')) location = trimmed.substring(9);
      if (trimmed.startsWith('DESCRIPTION:')) {
        description = trimmed.substring(12);
      }
      if (trimmed.startsWith('DTSTART:')) {
        start = _parseVEventDateTime(trimmed.substring(8));
      }
      if (trimmed.startsWith('DTEND:')) {
        end = _parseVEventDateTime(trimmed.substring(6));
      }
    }
    return {
      'title': title ?? '',
      'location': location ?? '',
      'description': description ?? '',
      if (start != null) 'start': start.toIso8601String(),
      if (end != null) 'end': end.toIso8601String(),
    };
  }

  static Map<String, dynamic> _parseLocationPrefill(String deepLink) {
    // geo:lat,lng
    if (deepLink.startsWith('geo:')) {
      final parts = deepLink.substring(4).split(',');
      if (parts.length >= 2) {
        return {
          'lat': double.tryParse(parts[0]),
          'lng': double.tryParse(parts[1]),
        };
      }
    }
    // https://maps.google.com/?q=label&ll=lat,lng
    final uri = Uri.tryParse(deepLink);
    if (uri != null && uri.queryParameters.containsKey('ll')) {
      final ll = uri.queryParameters['ll']!.split(',');
      final q = uri.queryParameters['q'];
      if (ll.length >= 2) {
        return {
          'lat': double.tryParse(ll[0]),
          'lng': double.tryParse(ll[1]),
          if (q != null) 'label': q,
        };
      }
    }
    return {};
  }

  /// VEVENT 날짜/시간 형식 파싱: "20260426T153000"
  static DateTime? _parseVEventDateTime(String s) {
    if (s.length < 15) return null;
    final year = int.tryParse(s.substring(0, 4));
    final month = int.tryParse(s.substring(4, 6));
    final day = int.tryParse(s.substring(6, 8));
    final hour = int.tryParse(s.substring(9, 11));
    final minute = int.tryParse(s.substring(11, 13));
    if (year == null || month == null || day == null || hour == null || minute == null) {
      return null;
    }
    return DateTime(year, month, day, hour, minute);
  }
}
