part of '../qr_result_provider.dart';

/// 로고/이모지 관련 setter — QR 중앙 아이콘 + 스티커의 logoType/이미지/텍스트.
mixin _LogoSetters on StateNotifier<QrResultState> {
  void _schedulePush();

  void setEmbedIcon(bool embed) {
    state = state.copyWith(logo: state.logo.copyWith(embedIcon: embed));
    _schedulePush();
  }

  void setDefaultIconBytes(Uint8List bytes) {
    // defaultIconBytes 는 재생성 가능 (tagType 기반 머티리얼 아이콘)
    // → JSON 저장 대상 아님, _schedulePush 호출 안 함
    state = state.copyWith(logo: state.logo.copyWith(defaultIconBytes: bytes));
  }

  void setCenterEmoji(String emoji, Uint8List rendered) {
    state = state.copyWith(
      logo: state.logo.copyWith(centerEmoji: emoji, emojiIconBytes: rendered),
    );
    _schedulePush();
  }

  void clearEmoji() {
    state = state.copyWith(
      logo: state.logo.copyWith(
        clearCenterEmoji: true,
        clearEmojiIconBytes: true,
      ),
    );
    _schedulePush();
  }

  /// 드롭다운에서 로고 타입 변경. "없음" 선택 시 embedIcon=false 동기화.
  /// `null` 은 레거시 데이터 경로이며 UI 에서는 직접 설정되지 않는다.
  ///
  /// 타입 전환 시 충돌 상태 정리:
  /// - text → 비text: bandMode 리셋 (띠 배경은 텍스트 전용)
  /// - 비text → text: logoBackground 리셋 (텍스트 전용 토글로 재선택)
  void setLogoType(LogoType? type) {
    final isRealType = type != null && type != LogoType.none;
    final prev = state.sticker.logoType;
    var sticker = state.sticker.copyWith(logoType: type);

    // 텍스트 → 비텍스트: bandMode 리셋
    if (prev == LogoType.text && type != LogoType.text) {
      sticker = sticker.copyWith(bandMode: BandMode.none);
    }
    // 비텍스트 → 텍스트: logoBackground 리셋 + 위치를 center 로 초기화
    // (텍스트 🚫 모드는 center 전용; 사각/원형 선택 후 사용자가 위치 변경 가능)
    if (prev != LogoType.text && type == LogoType.text) {
      sticker = sticker.copyWith(
        logoBackground: LogoBackground.none,
        logoPosition: LogoPosition.center,
      );
    }

    state = state.copyWith(
      sticker: sticker,
      logo: state.logo.copyWith(embedIcon: isRealType),
    );
    _schedulePush();
  }

  /// 로고 라이브러리에서 아이콘 선택 완료.
  void applyLogoLibrary({
    required String assetId,
    required Uint8List pngBytes,
  }) {
    state = state.copyWith(
      logo: state.logo.copyWith(embedIcon: true),
      sticker: state.sticker.copyWith(
        logoType: LogoType.logo,
        logoAssetId: assetId,
        logoAssetPngBytes: pngBytes,
      ),
    );
    _schedulePush();
  }

  /// 갤러리 이미지 크롭 적용.
  void applyLogoImage(Uint8List croppedBytes) {
    state = state.copyWith(
      logo: state.logo.copyWith(embedIcon: true),
      sticker: state.sticker.copyWith(
        logoType: LogoType.image,
        logoImageBytes: croppedBytes,
      ),
    );
    _schedulePush();
  }

  /// 로고 전용 텍스트 적용.
  void applyLogoText(StickerText? text) {
    state = state.copyWith(
      logo: state.logo.copyWith(embedIcon: true),
      sticker: state.sticker.copyWith(
        logoType: LogoType.text,
        logoText: text,
      ),
    );
    _schedulePush();
  }

  /// 로고 배경(square/circle)의 fill 색상. null = 기본 흰색.
  void setLogoBackgroundColor(Color? color) {
    state = state.copyWith(
      sticker: state.sticker.copyWith(logoBackgroundColor: color),
    );
    _schedulePush();
  }

  /// 중앙 텍스트 "띠(band)" 모드 변경.
  void setBandMode(BandMode mode) {
    state = state.copyWith(
      sticker: state.sticker.copyWith(bandMode: mode),
    );
    _schedulePush();
  }

  /// 중앙 텍스트 균등 분할 모드 토글.
  void setCenterTextEvenSpacing(bool enabled) {
    state = state.copyWith(
      sticker: state.sticker.copyWith(centerTextEvenSpacing: enabled),
    );
    _schedulePush();
  }
}
