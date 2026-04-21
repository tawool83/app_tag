import '../entities/scan_detected_type.dart';
import '../entities/scan_result.dart';
import 'app_deeplink_parser.dart';
import 'email_parser.dart';
import 'geo_parser.dart';
import 'sms_parser.dart';
import 'url_parser.dart';
import 'vcard_parser.dart';
import 'vevent_parser.dart';
import 'wifi_parser.dart';

/// 스캔 원문을 9종 타입으로 자동 분류하는 우선순위 체인 디스패처.
///
/// 순서: appDeepLink → wifi → contact → event → email → sms → geo → url → text
///
/// 구체적인 스키마부터 매칭하고, URL(http/https)은 후순위로 배치하여
/// 딥링크를 URL로 잘못 분류하는 것을 방지.
class ScanPayloadParser {
  ScanPayloadParser._();

  static ScanResult parse(String raw) {
    return tryParseAppDeepLink(raw) ??
        tryParseWifi(raw) ??
        tryParseContact(raw) ??
        tryParseEvent(raw) ??
        tryParseEmail(raw) ??
        tryParseSms(raw) ??
        tryParseLocation(raw) ??
        tryParseUrl(raw) ??
        ScanResult(
          rawValue: raw,
          detectedType: ScanDetectedType.text,
          parsedMeta: {'text': raw},
        );
  }
}
