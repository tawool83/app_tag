import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/app_picker/app_picker_screen.dart';
import '../features/ios_input/ios_input_screen.dart';
import '../features/output_selector/output_selector_screen.dart';
import '../features/qr_result/qr_result_screen.dart';
import '../features/nfc_writer/nfc_writer_screen.dart';
import '../features/history/history_screen.dart';

class AppRouter {
  static const home = '/';
  static const appPicker = '/app-picker';
  static const iosInput = '/ios-input';
  static const outputSelector = '/output-selector';
  static const qrResult = '/qr-result';
  static const nfcWriter = '/nfc-writer';
  static const history = '/history';

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
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('페이지를 찾을 수 없습니다.')),
          ),
        );
    }
  }
}
