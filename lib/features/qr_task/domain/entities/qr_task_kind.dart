/// QR/NFC 작업 종류.
enum QrTaskKind {
  qr,
  nfc;

  static QrTaskKind fromName(String? name) {
    if (name == null) return QrTaskKind.qr;
    for (final v in QrTaskKind.values) {
      if (v.name == name) return v;
    }
    return QrTaskKind.qr;
  }
}
