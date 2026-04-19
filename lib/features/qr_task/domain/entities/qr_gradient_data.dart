/// QR 전경색 그라디언트 (도메인 순수 표현).
///
/// presentation 의 `QrGradient` 는 Flutter `Color` 사용.
/// 본 클래스는 ARGB int 만 사용 — 도메인 순수 유지.
class QrGradientData {
  /// 'linear' | 'radial' | 'sweep'
  final String type;

  /// ARGB int 리스트 (예: 0xFF0066CC).
  final List<int> colorsArgb;

  final List<double>? stops;

  /// linear 전용. 0~360.
  final double angleDegrees;

  /// radial 전용: 'center' | 'topLeft' | 'topRight' | 'bottomLeft' | 'bottomRight'
  final String? center;

  const QrGradientData({
    required this.type,
    required this.colorsArgb,
    this.stops,
    this.angleDegrees = 45,
    this.center,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'colorsArgb': colorsArgb,
        if (stops != null) 'stops': stops,
        'angleDegrees': angleDegrees,
        if (center != null) 'center': center,
      };

  factory QrGradientData.fromJson(Map<String, dynamic> json) => QrGradientData(
        type: json['type'] as String? ?? 'linear',
        colorsArgb: (json['colorsArgb'] as List<dynamic>? ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        stops: (json['stops'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList(),
        angleDegrees: (json['angleDegrees'] as num?)?.toDouble() ?? 45,
        center: json['center'] as String?,
      );
}
