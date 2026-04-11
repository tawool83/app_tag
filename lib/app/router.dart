import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/app_picker/app_picker_screen.dart';
import '../features/ios_input/ios_input_screen.dart';
import '../features/output_selector/output_selector_screen.dart';
import '../features/qr_result/qr_result_screen.dart';
import '../features/nfc_writer/nfc_writer_screen.dart';
import '../features/history/history_screen.dart';
import '../features/help/help_screen.dart';
import '../features/clipboard_tag/clipboard_tag_screen.dart';
import '../features/website_tag/website_tag_screen.dart';
import '../features/contact_tag/contact_tag_screen.dart';
import '../features/wifi_tag/wifi_tag_screen.dart';
import '../features/location_tag/location_tag_screen.dart';
import '../features/event_tag/event_tag_screen.dart';
import '../features/email_tag/email_tag_screen.dart';
import '../features/sms_tag/sms_tag_screen.dart';

class AppRouter {
  static const home           = '/';
  static const appPicker      = '/app-picker';
  static const iosInput       = '/ios-input';
  static const outputSelector = '/output-selector';
  static const qrResult       = '/qr-result';
  static const nfcWriter      = '/nfc-writer';
  static const history        = '/history';
  static const help           = '/help';
  static const clipboardTag   = '/clipboard-tag';
  static const websiteTag     = '/website-tag';
  static const contactTag     = '/contact-tag';
  static const wifiTag        = '/wifi-tag';
  static const locationTag    = '/location-tag';
  static const eventTag       = '/event-tag';
  static const emailTag       = '/email-tag';
  static const smsTag         = '/sms-tag';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case appPicker:
        return MaterialPageRoute(builder: (_) => const AppPickerScreen());
      case iosInput:
        return MaterialPageRoute(builder: (_) => const IosInputScreen());
      case outputSelector:
        return MaterialPageRoute(
          builder: (_) => const OutputSelectorScreen(),
          settings: settings,
        );
      case qrResult:
        return MaterialPageRoute(
          builder: (_) => const QrResultScreen(),
          settings: settings,
        );
      case nfcWriter:
        return MaterialPageRoute(
          builder: (_) => const NfcWriterScreen(),
          settings: settings,
        );
      case history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      case help:
        return MaterialPageRoute(builder: (_) => const HelpScreen());
      case clipboardTag:
        return MaterialPageRoute(builder: (_) => const ClipboardTagScreen());
      case websiteTag:
        return MaterialPageRoute(builder: (_) => const WebsiteTagScreen());
      case contactTag:
        return MaterialPageRoute(builder: (_) => const ContactTagScreen());
      case wifiTag:
        return MaterialPageRoute(builder: (_) => const WifiTagScreen());
      case locationTag:
        return MaterialPageRoute(builder: (_) => const LocationTagScreen());
      case eventTag:
        return MaterialPageRoute(builder: (_) => const EventTagScreen());
      case emailTag:
        return MaterialPageRoute(builder: (_) => const EmailTagScreen());
      case smsTag:
        return MaterialPageRoute(builder: (_) => const SmsTagScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('페이지를 찾을 수 없습니다.')),
          ),
        );
    }
  }
}
