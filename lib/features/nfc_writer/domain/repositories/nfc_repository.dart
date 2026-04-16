import '../../../../core/error/result.dart';
import '../entities/nfc_write_result.dart';

/// NFC operations repository (domain contract).
/// NFC 작업 레포지토리 (도메인 계약).
abstract class NfcRepository {
  Future<Result<bool>> checkAvailability();
  Future<Result<bool>> checkWriteSupport();

  /// Start NFC session, wait for tag, read-merge-write, return result.
  /// NFC 세션 시작, 태그 대기, 읽기-병합-쓰기, 결과 반환.
  Future<Result<NfcWriteResult>> writeTag({
    required String deepLink,
    String? iosShortcutName,
  });

  Future<void> stopSession();
}
