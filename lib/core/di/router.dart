import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/app_picker/app_picker_screen.dart';
import '../../features/ios_input/ios_input_screen.dart';
import '../../features/qr_result/qr_result_screen.dart';
import '../../features/nfc_writer/nfc_writer_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/help/help_screen.dart';
import '../../features/clipboard_tag/clipboard_tag_screen.dart';
import '../../features/website_tag/website_tag_screen.dart';
import '../../features/contact_tag/contact_tag_screen.dart';
import '../../features/contact_tag/contact_manual_form.dart';
import '../../features/wifi_tag/wifi_tag_screen.dart';
import '../../features/location_tag/location_tag_screen.dart';
import '../../features/event_tag/event_tag_screen.dart';
import '../../features/email_tag/email_tag_screen.dart';
import '../../features/sms_tag/sms_tag_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/scanner/presentation/screens/scanner_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/svg_storage/svg_storage_screen.dart';

/// 향후 외부 deep link 수신 시 라우트 리다이렉션 처리.
/// 현재는 no-op (앱이 deep link를 생성만 하고 수신하지 않음).
String? _deepLinkRedirect(BuildContext context, GoRouterState state) => null;

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: _deepLinkRedirect,
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/home', builder: (_, state) => HomeScreen(key: ValueKey(state.extra))),
      GoRoute(path: '/app-picker', builder: (_, _) => const AppPickerScreen()),
      GoRoute(path: '/ios-input', builder: (_, _) => const IosInputScreen()),
GoRoute(
        path: '/qr-result',
        builder: (_, _) => const QrResultScreen(),
      ),
      GoRoute(
        path: '/nfc-writer',
        builder: (_, _) => const NfcWriterScreen(),
      ),
      GoRoute(path: '/scanner', builder: (_, _) => const ScannerScreen()),
      GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
      GoRoute(path: '/help', builder: (_, _) => const HelpScreen()),
      GoRoute(
        path: '/clipboard-tag',
        builder: (_, state) => ClipboardTagScreen(
          prefill: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/website-tag',
        builder: (_, state) => WebsiteTagScreen(
          prefill: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/contact-tag',
        builder: (_, state) => ContactTagScreen(
          prefill: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/contact-manual',
        builder: (_, state) => ContactManualFormScreen(
          prefill: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/wifi-tag',
        builder: (_, state) => WifiTagScreen(
          prefill: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/location-tag',
        builder: (_, state) => LocationTagScreen(
          prefill: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/event-tag',
        builder: (_, state) => EventTagScreen(
          prefill: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/email-tag',
        builder: (_, state) => EmailTagScreen(
          prefill: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/sms-tag',
        builder: (_, state) => SmsTagScreen(
          prefill: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/svg-storage', builder: (_, _) => const SvgStorageScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignUpScreen()),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
    ],
    errorBuilder: (_, _) => const Scaffold(
      body: Center(child: Text('페이지를 찾을 수 없습니다.')),
    ),
  );
});
