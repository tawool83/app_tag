import 'dart:typed_data';

/// QR 중앙 로고/아이콘 관련 상태.
///
/// 스티커 레이어의 `logoType`/`logoImageBytes`/`logoAssetPngBytes` 와는 별개로,
/// 태그 타입 기본 아이콘 + 사용자 선택 이모지의 렌더된 bytes 를 보관.
class QrLogoState {
  final bool embedIcon;
  final Uint8List? defaultIconBytes; // 태그 타입 기본 아이콘 (raster)
  final String? centerEmoji;
  final Uint8List? emojiIconBytes;

  const QrLogoState({
    this.embedIcon = false,
    this.defaultIconBytes,
    this.centerEmoji,
    this.emojiIconBytes,
  });

  QrLogoState copyWith({
    bool? embedIcon,
    Uint8List? defaultIconBytes,
    bool clearDefaultIconBytes = false,
    String? centerEmoji,
    bool clearCenterEmoji = false,
    Uint8List? emojiIconBytes,
    bool clearEmojiIconBytes = false,
  }) =>
      QrLogoState(
        embedIcon: embedIcon ?? this.embedIcon,
        defaultIconBytes: clearDefaultIconBytes
            ? null
            : (defaultIconBytes ?? this.defaultIconBytes),
        centerEmoji:
            clearCenterEmoji ? null : (centerEmoji ?? this.centerEmoji),
        emojiIconBytes: clearEmojiIconBytes
            ? null
            : (emojiIconBytes ?? this.emojiIconBytes),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrLogoState &&
          other.embedIcon == embedIcon &&
          other.defaultIconBytes == defaultIconBytes &&
          other.centerEmoji == centerEmoji &&
          other.emojiIconBytes == emojiIconBytes;

  @override
  int get hashCode =>
      Object.hash(embedIcon, defaultIconBytes, centerEmoji, emojiIconBytes);
}
