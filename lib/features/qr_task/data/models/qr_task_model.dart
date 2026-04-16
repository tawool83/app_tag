import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/qr_task.dart';
import '../../domain/entities/qr_task_kind.dart';

part 'qr_task_model.g.dart';

/// QrTask Hive DTO.
///
/// 핵심 설계: **4개 필드만 Hive 화** — 꾸미기 상세는 `payloadJson` 안 JSON 문자열에.
/// 향후 새 꾸미기 필드 추가 시 Hive 스키마 불변 (`.g.dart` 재생성해도 null-cast 위험 0).
@HiveType(typeId: 2)
class QrTaskModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime createdAt;

  /// QrTaskKind.name : 'qr' | 'nfc'
  @HiveField(2)
  final String kind;

  /// 전체 payload (schemaVersion + meta + customization + updatedAt).
  @HiveField(3)
  final String payloadJson;

  QrTaskModel({
    required this.id,
    required this.createdAt,
    required this.kind,
    required this.payloadJson,
  });

  /// payload JSON 을 파싱해 도메인 [QrTask] 로 복원.
  QrTask toEntity() {
    final map = jsonDecode(payloadJson) as Map<String, dynamic>;
    return QrTask.fromPayloadMap(
      id: id,
      createdAt: createdAt,
      kind: QrTaskKind.fromName(kind),
      map: map,
    );
  }

  /// 도메인 [QrTask] → DTO (payload 직렬화 포함).
  factory QrTaskModel.fromEntity(QrTask t) => QrTaskModel(
        id: t.id,
        createdAt: t.createdAt,
        kind: t.kind.name,
        payloadJson: t.toPayloadJson(),
      );
}
