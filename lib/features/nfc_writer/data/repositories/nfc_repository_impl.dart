import 'dart:async';
import 'dart:io';

import 'package:nfc_manager/nfc_manager.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/nfc_write_result.dart';
import '../../domain/repositories/nfc_repository.dart';
import '../datasources/nfc_datasource.dart';
import '../ndef_record_helper.dart';

class NfcRepositoryImpl implements NfcRepository {
  final NfcDataSource _dataSource;
  const NfcRepositoryImpl(this._dataSource);

  @override
  Future<Result<bool>> checkAvailability() async {
    try {
      return Success(await _dataSource.isAvailable());
    } catch (e, st) {
      return Err(
          UnexpectedFailure('NFC 확인 실패: $e', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<bool>> checkWriteSupport() async {
    try {
      return Success(await _dataSource.isWriteSupported());
    } catch (e, st) {
      return Err(UnexpectedFailure('NFC 쓰기 지원 확인 실패: $e',
          cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<NfcWriteResult>> writeTag({
    required String deepLink,
    String? iosShortcutName,
  }) async {
    final completer = Completer<Result<NfcWriteResult>>();

    _dataSource.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          // 1. Read existing records
          final existing = await _dataSource.readRecords(tag);

          // 2. Check cross-platform records
          final isAndroid = Platform.isAndroid;
          final hasCross = existing.any(
            (r) => isAndroid
                ? NdefRecordHelper.isIosRecord(r)
                : NdefRecordHelper.isAndroidRecord(r),
          );

          // 3. Create current platform record
          final myRecord = NdefRecord.createUri(Uri.parse(deepLink));

          // 4. Merge: replace current platform, preserve others
          var records = NdefRecordHelper.merge(
            existing: existing,
            newRecord: myRecord,
            isAndroid: isAndroid,
          );

          // 5. Add iOS shortcut record on Android if requested
          if (isAndroid &&
              iosShortcutName != null &&
              iosShortcutName.isNotEmpty) {
            final iosUri =
                'shortcuts://run-shortcut?name=${Uri.encodeComponent(iosShortcutName)}';
            final iosRecord = NdefRecord.createUri(Uri.parse(iosUri));
            records = NdefRecordHelper.merge(
              existing: records,
              newRecord: iosRecord,
              isAndroid: false,
            );
          }

          // 6. Write merged records
          await _dataSource.writeRecords(tag, records);
          await _dataSource.stopSession();

          if (!completer.isCompleted) {
            completer.complete(
              Success(NfcWriteResult(hasCrossPlatformRecord: hasCross)),
            );
          }
        } catch (e) {
          await _dataSource.stopSession(errorMessage: '$e');
          if (!completer.isCompleted) {
            completer.complete(
              Err(PlatformFailure(_resolveErrorMessage('$e'))),
            );
          }
        }
      },
    );

    return completer.future;
  }

  @override
  Future<Result<void>> stopSession() async {
    try {
      await _dataSource.stopSession();
      return const Success(null);
    } catch (e) {
      return Err(PlatformFailure('NFC 세션 종료 실패: $e'));
    }
  }

  String _resolveErrorMessage(String error) {
    if (error.contains('쓰기 불가능') || error.contains('not writable')) {
      return '쓰기 불가능한 태그입니다.';
    }
    if (error.contains('capacity') ||
        error.contains('overflow') ||
        error.contains('too large') ||
        error.contains('size')) {
      return '태그 용량이 부족합니다. 더 큰 용량의 태그를 사용해주세요.';
    }
    return 'NFC 기록에 실패했습니다.';
  }
}
