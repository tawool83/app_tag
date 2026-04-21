part of '../qr_result_provider.dart';

/// 메타(tagType/printSize/editorMode) + sticker 전체 교체 setter.
mixin _MetaSetters on StateNotifier<QrResultState> {
  void _schedulePush();

  void setPrintSizeCm(double sizeCm) {
    state = state.copyWith(meta: state.meta.copyWith(printSizeCm: sizeCm));
    _schedulePush();
  }

  void setTagType(String? tagType) {
    state = state.copyWith(
      meta: state.meta.copyWith(
        tagType: tagType,
        clearTagType: tagType == null,
      ),
    );
  }

  void setShapeEditorMode(bool active) {
    state = state.copyWith(meta: state.meta.copyWith(shapeEditorMode: active));
  }

  void setSticker(StickerConfig config) {
    state = state.copyWith(sticker: config);
    _schedulePush();
  }
}
