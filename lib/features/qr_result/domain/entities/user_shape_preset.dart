import 'qr_animation_params.dart';
import 'qr_boundary_params.dart';
import 'qr_shape_params.dart';

enum ShapePresetType { dot, eye, boundary, animation }

/// 사용자 저장 프리셋 (Hive 저장 단위).
class UserShapePreset {
  final String id; // UUID
  final String name; // 사용자 지정 이름
  final ShapePresetType type; // dot / eye / boundary / animation
  final DateTime createdAt;
  final DateTime lastUsedAt; // 최근 사용 시각 (정렬용)
  final int version; // 마이그레이션용

  // type별로 하나만 non-null
  final DotShapeParams? dotParams;
  final EyeShapeParams? eyeParams;
  final QrBoundaryParams? boundaryParams;
  final QrAnimationParams? animParams;

  UserShapePreset({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    DateTime? lastUsedAt,
    this.version = 1,
    this.dotParams,
    this.eyeParams,
    this.boundaryParams,
    this.animParams,
  }) : lastUsedAt = lastUsedAt ?? createdAt;

  /// lastUsedAt만 갱신한 복사본 반환.
  UserShapePreset withLastUsed(DateTime at) => UserShapePreset(
    id: id, name: name, type: type, createdAt: createdAt,
    lastUsedAt: at, version: version,
    dotParams: dotParams, eyeParams: eyeParams,
    boundaryParams: boundaryParams, animParams: animParams,
  );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'lastUsedAt': lastUsedAt.toIso8601String(),
        'version': version,
        if (dotParams != null) 'dotParams': dotParams!.toJson(),
        if (eyeParams != null) 'eyeParams': eyeParams!.toJson(),
        if (boundaryParams != null) 'boundaryParams': boundaryParams!.toJson(),
        if (animParams != null) 'animParams': animParams!.toJson(),
      };

  factory UserShapePreset.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'dot';
    return UserShapePreset(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ShapePresetType.values.firstWhere(
        (e) => e.name == typeName,
        orElse: () => ShapePresetType.dot,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      version: json['version'] as int? ?? 1,
      dotParams: json['dotParams'] != null
          ? DotShapeParams.fromJson(json['dotParams'] as Map<String, dynamic>)
          : null,
      eyeParams: json['eyeParams'] != null
          ? EyeShapeParams.fromJson(json['eyeParams'] as Map<String, dynamic>)
          : null,
      boundaryParams: json['boundaryParams'] != null
          ? QrBoundaryParams.fromJson(
              json['boundaryParams'] as Map<String, dynamic>)
          : null,
      animParams: json['animParams'] != null
          ? QrAnimationParams.fromJson(
              json['animParams'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserShapePreset &&
          id == other.id &&
          version == other.version;

  @override
  int get hashCode => Object.hash(id, version);

  @override
  String toString() =>
      'UserShapePreset($id, ${type.name}, "$name")';
}
