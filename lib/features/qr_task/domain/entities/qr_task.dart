import 'dart:convert';

import 'qr_customization.dart';
import 'qr_task_kind.dart';
import 'qr_task_meta.dart';

/// QR/NFC 1건 작업 기록.
///
/// 영속 형식: `QrTaskModel` 의 `payloadJson` 에 [toPayloadJson] 결과를 저장.
class QrTask {
  /// 현재 JSON payload 스키마 버전.
  static const int currentSchemaVersion = 1;

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final QrTaskKind kind;
  final QrTaskMeta meta;
  final QrCustomization customization;
  final bool isFavorite;

  const QrTask({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.kind,
    required this.meta,
    required this.customization,
    this.isFavorite = false,
  });

  /// 최상위 payload Map (schemaVersion 포함).
  Map<String, dynamic> toPayloadMap() => {
        'schemaVersion': currentSchemaVersion,
        'taskId': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'kind': kind.name,
        'meta': meta.toJson(),
        'customization': customization.toJson(),
        'isFavorite': isFavorite,
      };

  String toPayloadJson() => jsonEncode(toPayloadMap());

  /// payload Map 으로부터 복원. `id`/`createdAt`/`kind` 는 외부에서 (Hive 필드) 주입.
  factory QrTask.fromPayloadMap({
    required String id,
    required DateTime createdAt,
    required QrTaskKind kind,
    required Map<String, dynamic> map,
  }) {
    final updatedAtStr = map['updatedAt'] as String?;
    return QrTask(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAtStr != null
          ? DateTime.tryParse(updatedAtStr) ?? createdAt
          : createdAt,
      kind: kind,
      meta: QrTaskMeta.fromJson(map['meta'] as Map<String, dynamic>? ?? const {}),
      customization: QrCustomization.fromJson(
        map['customization'] as Map<String, dynamic>? ?? const {},
      ),
      isFavorite: map['isFavorite'] as bool? ?? false,
    );
  }

  QrTask copyWith({
    DateTime? updatedAt,
    QrTaskMeta? meta,
    QrCustomization? customization,
    bool? isFavorite,
  }) =>
      QrTask(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        kind: kind,
        meta: meta ?? this.meta,
        customization: customization ?? this.customization,
        isFavorite: isFavorite ?? this.isFavorite,
      );
}
