import 'package:flutter/material.dart';

/// 스캔된 QR 원문의 자동 분류 타입 (9종).
enum ScanDetectedType {
  url,
  wifi,
  contact,
  sms,
  email,
  location,
  event,
  appDeepLink,
  text; // fallback

  IconData get icon => switch (this) {
        url => Icons.language,
        wifi => Icons.wifi,
        contact => Icons.contact_phone,
        sms => Icons.sms,
        email => Icons.email,
        location => Icons.location_on,
        event => Icons.event,
        appDeepLink => Icons.apps,
        text => Icons.text_snippet,
      };

  /// "꾸미기" 경유 시 이동할 태그 화면 라우트.
  String get tagRoute => switch (this) {
        url => '/website-tag',
        wifi => '/wifi-tag',
        contact => '/contact-manual',
        sms => '/sms-tag',
        email => '/email-tag',
        location => '/location-tag',
        event => '/event-tag',
        appDeepLink => '/clipboard-tag',
        text => '/clipboard-tag',
      };

  /// QrTask.meta.tagType 과 호환되는 문자열 변환.
  String get tagType => switch (this) {
        url => 'website',
        wifi => 'wifi',
        contact => 'contact',
        sms => 'sms',
        email => 'email',
        location => 'location',
        event => 'event',
        appDeepLink => 'clipboard',
        text => 'clipboard',
      };
}
