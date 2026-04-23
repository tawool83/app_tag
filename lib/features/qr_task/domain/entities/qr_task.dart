import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';

import 'qr_customization.dart';
import 'qr_task_kind.dart';
import 'qr_task_meta.dart';

/// QR/NFC 1건 작업 기록.
///
/// 영속 형식: `QrTaskModel` 의 `payloadJson` 에 [toPayloadJson] 결과를 저장.
class QrTask {
  /// 현재 JSON payload 스키마 버전.
  static const int currentSchemaVersion = 2;

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final QrTaskKind kind;
  final String name;
  final QrTaskMeta meta;
  final QrCustomization customization;
  final bool isFavorite;
  final Uint8List? thumbnailBytes;

  /// 홈 화면 타일에 표시 여부. false 면 홈에서 숨김 (히스토리엔 유지).
  final bool showOnHome;

  const QrTask({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.kind,
    required this.name,
    required this.meta,
    required this.customization,
    this.isFavorite = false,
    this.thumbnailBytes,
    this.showOnHome = true,
  });

  /// 최상위 payload Map (schemaVersion 포함).
  Map<String, dynamic> toPayloadMap() => {
        'schemaVersion': currentSchemaVersion,
        'taskId': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'kind': kind.name,
        'name': name,
        'meta': meta.toJson(),
        'customization': customization.toJson(),
        'isFavorite': isFavorite,
        'showOnHome': showOnHome,
        if (thumbnailBytes != null)
          'thumbnailBase64': base64Encode(thumbnailBytes!),
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
    final thumbB64 = map['thumbnailBase64'] as String?;
    return QrTask(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAtStr != null
          ? DateTime.tryParse(updatedAtStr) ?? createdAt
          : createdAt,
      kind: kind,
      name: map['name'] as String? ??
          DateFormat('yyyy-MM-dd HH:mm').format(createdAt),
      meta: QrTaskMeta.fromJson(map['meta'] as Map<String, dynamic>? ?? const {}),
      customization: QrCustomization.fromJson(
        map['customization'] as Map<String, dynamic>? ?? const {},
      ),
      isFavorite: map['isFavorite'] as bool? ?? false,
      showOnHome: map['showOnHome'] as bool? ?? true,
      thumbnailBytes: thumbB64 != null ? base64Decode(thumbB64) : null,
    );
  }

  QrTask copyWith({
    DateTime? updatedAt,
    String? name,
    QrTaskMeta? meta,
    QrCustomization? customization,
    bool? isFavorite,
    bool? showOnHome,
    Uint8List? thumbnailBytes,
    bool clearThumbnail = false,
  }) =>
      QrTask(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        kind: kind,
        name: name ?? this.name,
        meta: meta ?? this.meta,
        customization: customization ?? this.customization,
        isFavorite: isFavorite ?? this.isFavorite,
        showOnHome: showOnHome ?? this.showOnHome,
        thumbnailBytes:
            clearThumbnail ? null : (thumbnailBytes ?? this.thumbnailBytes),
      );
}
