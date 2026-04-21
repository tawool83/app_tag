import 'dart:typed_data';

import '../entities/qr_template.dart' show QrGradient;

/// 선택된 QR 템플릿 관련 UI state.
class QrTemplateState {
  final String? activeTemplateId;
  final QrGradient? templateGradient;
  final Uint8List? templateCenterIconBytes;

  const QrTemplateState({
    this.activeTemplateId,
    this.templateGradient,
    this.templateCenterIconBytes,
  });

  bool get hasActiveTemplate => activeTemplateId != null;

  QrTemplateState copyWith({
    String? activeTemplateId,
    bool clearActiveTemplateId = false,
    QrGradient? templateGradient,
    bool clearTemplateGradient = false,
    Uint8List? templateCenterIconBytes,
    bool clearTemplateCenterIconBytes = false,
  }) =>
      QrTemplateState(
        activeTemplateId: clearActiveTemplateId
            ? null
            : (activeTemplateId ?? this.activeTemplateId),
        templateGradient: clearTemplateGradient
            ? null
            : (templateGradient ?? this.templateGradient),
        templateCenterIconBytes: clearTemplateCenterIconBytes
            ? null
            : (templateCenterIconBytes ?? this.templateCenterIconBytes),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrTemplateState &&
          other.activeTemplateId == activeTemplateId &&
          other.templateGradient == templateGradient &&
          other.templateCenterIconBytes == templateCenterIconBytes;

  @override
  int get hashCode =>
      Object.hash(activeTemplateId, templateGradient, templateCenterIconBytes);
}
