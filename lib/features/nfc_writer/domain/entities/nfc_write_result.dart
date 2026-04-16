/// NFC tag write operation result (domain entity).
/// NFC 태그 기록 결과 (도메인 엔티티).
class NfcWriteResult {
  /// Whether the tag already contained records from the other platform.
  /// 태그에 다른 플랫폼의 레코드가 이미 존재했는지 여부.
  final bool hasCrossPlatformRecord;

  const NfcWriteResult({this.hasCrossPlatformRecord = false});
}
