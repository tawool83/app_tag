import 'dart:io';
import 'package:device_apps/device_apps.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../models/app_info.dart';

class NfcService {
  /// NFC 하드웨어 지원 여부
  Future<bool> isNfcAvailable() async {
    return NfcManager.instance.isAvailable();
  }

  /// iOS NFC 쓰기 지원: iPhone XS 이상 + iOS 13 이상
  /// Android는 항상 true (isNfcAvailable이 true면)
  Future<bool> isNfcWriteSupported() async {
    if (Platform.isAndroid) return true;
    // iOS: 런타임에서 정확한 모델 구분이 어려우므로
    // nfc_manager가 available이면 쓰기 지원으로 간주 (iOS 13+ & XS+)
    return NfcManager.instance.isAvailable();
  }

  /// NFC 태그에 딥링크 NDEF 레코드 기록
  Future<void> writeNdefTag({
    required String deepLink,
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            await NfcManager.instance.stopSession(
              errorMessage: '쓰기 불가능한 태그입니다.',
            );
            onError('쓰기 불가능한 태그입니다.');
            return;
          }
          final record = NdefRecord.createUri(Uri.parse(deepLink));
          await ndef.write(NdefMessage([record]));
          await NfcManager.instance.stopSession();
          onSuccess();
        } catch (e) {
          await NfcManager.instance.stopSession(
            errorMessage: '기록 실패: $e',
          );
          onError('NFC 기록에 실패했습니다.');
        }
      },
    );
  }

  Future<void> stopNfcSession() async {
    await NfcManager.instance.stopSession();
  }

  /// Android 설치 앱 목록 조회 (시스템 앱 제외)
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
