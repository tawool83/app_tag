/// 사용자 저장 색상 팔레트 (단색 또는 그라디언트).
class UserColorPalette {
  final String id;
  final String name;
  final PaletteType type;
  final int? solidColorArgb;
  final List<int>? gradientColorArgbs;
  final List<double>? gradientStops;
  final String? gradientType; // 'linear' | 'radial'
  final int? gradientAngle;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 동기화 메타
  final String? remoteId;
  final bool syncedToCloud;

  const UserColorPalette({
    required this.id,
    required this.name,
    required this.type,
    this.solidColorArgb,
    this.gradientColorArgbs,
    this.gradientStops,
    this.gradientType,
    this.gradientAngle,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.remoteId,
    this.syncedToCloud = false,
  });
}

enum PaletteType { solid, gradient }
