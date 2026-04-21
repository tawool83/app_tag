import '../../../../core/utils/enum_from_name.dart';

/// QR/NFC 작업 종류.
enum QrTaskKind {
  qr,
  nfc;

  static QrTaskKind fromName(String? name) =>
      enumFromName(QrTaskKind.values, name, QrTaskKind.qr);
}
