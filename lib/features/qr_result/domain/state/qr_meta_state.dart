/// QR 결과 화면 메타데이터 (태그 타입, 인쇄 크기, 편집기 모드 플래그).
class QrMetaState {
  final String? tagType;          // 현재 태그 타입 (추천 탭 필터링용)
  final double printSizeCm;       // 인쇄 크기 (cm)
  final bool shapeEditorMode;     // true 시 하단 액션 버튼 숨김

  const QrMetaState({
    this.tagType,
    this.printSizeCm = 5.0,
    this.shapeEditorMode = false,
  });

  QrMetaState copyWith({
    String? tagType,
    bool clearTagType = false,
    double? printSizeCm,
    bool? shapeEditorMode,
  }) =>
      QrMetaState(
        tagType: clearTagType ? null : (tagType ?? this.tagType),
        printSizeCm: printSizeCm ?? this.printSizeCm,
        shapeEditorMode: shapeEditorMode ?? this.shapeEditorMode,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrMetaState &&
          other.tagType == tagType &&
          other.printSizeCm == printSizeCm &&
          other.shapeEditorMode == shapeEditorMode;

  @override
  int get hashCode => Object.hash(tagType, printSizeCm, shapeEditorMode);
}
