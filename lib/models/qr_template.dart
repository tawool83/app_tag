import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

// ── 헬퍼 ──────────────────────────────────────────────────────────────────────

Color _hexToColor(String? hex) {
  if (hex == null || hex.isEmpty) return Colors.black;
  final clean = hex.replaceFirst('#', '');
  final argb = clean.length == 6 ? 'FF$clean' : clean;
  return Color(int.parse(argb, radix: 16));
}

// ── QrGradient ────────────────────────────────────────────────────────────────

class QrGradient {
  final String type; // 'linear' | 'radial' | 'sweep'
  final List<Color> colors;
  final List<double>? stops;
  final double angleDegrees; // linear 전용

  const QrGradient({
    required this.type,
    required this.colors,
    this.stops,
    this.angleDegrees = 45,
  });

  factory QrGradient.fromJson(Map<String, dynamic> json) => QrGradient(
        type: json['type'] as String? ?? 'linear',
        colors: (json['colors'] as List<dynamic>)
            .map((e) => _hexToColor(e as String?))
            .toList(),
        stops: (json['stops'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList(),
        angleDegrees: (json['angleDegrees'] as num?)?.toDouble() ?? 45,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrGradient &&
          type == other.type &&
          angleDegrees == other.angleDegrees;

  @override
  int get hashCode => Object.hash(type, angleDegrees);
}

// ── QrForeground ──────────────────────────────────────────────────────────────

class QrForeground {
  final String type; // 'solid' | 'gradient'
  final Color? solidColor;
  final QrGradient? gradient;

  const QrForeground({
    required this.type,
    this.solidColor,
    this.gradient,
  });

  factory QrForeground.fromJson(Map<String, dynamic> json) => QrForeground(
        type: json['type'] as String? ?? 'solid',
        solidColor: _hexToColor(json['solidColor'] as String?),
        gradient: json['gradient'] != null
            ? QrGradient.fromJson(json['gradient'] as Map<String, dynamic>)
            : null,
      );

  bool get isGradient => type == 'gradient' && gradient != null;
}

// ── QrCenterIconData ──────────────────────────────────────────────────────────

class QrCenterIconData {
  final String type; // 'url' | 'emoji' | 'none'
  final String? url;
  final String? emoji;
  final double sizeRatio;

  const QrCenterIconData({
    required this.type,
    this.url,
    this.emoji,
    this.sizeRatio = 0.20,
  });

  factory QrCenterIconData.fromJson(Map<String, dynamic> json) =>
      QrCenterIconData(
        type: json['type'] as String? ?? 'none',
        url: json['url'] as String?,
        emoji: json['emoji'] as String?,
        sizeRatio: (json['sizeRatio'] as num?)?.toDouble() ?? 0.20,
      );
}

// ── QrStyleData ───────────────────────────────────────────────────────────────

class QrStyleData {
  final QrDataModuleShape dataModuleShape;
  final QrEyeShape eyeShape;
  final Color backgroundColor;
  final QrForeground foreground;
  final QrForeground? eyeColor; // null = foreground 상속
  final QrCenterIconData centerIcon;

  const QrStyleData({
    required this.dataModuleShape,
    required this.eyeShape,
    required this.backgroundColor,
    required this.foreground,
    this.eyeColor,
    required this.centerIcon,
  });

  factory QrStyleData.fromJson(Map<String, dynamic> json) => QrStyleData(
        dataModuleShape: json['dataModuleShape'] == 'circle'
            ? QrDataModuleShape.circle
            : QrDataModuleShape.square,
        eyeShape: json['eyeShape'] == 'circle'
            ? QrEyeShape.circle
            : QrEyeShape.square,
        backgroundColor:
            _hexToColor(json['backgroundColor'] as String? ?? '#FFFFFF'),
        foreground: QrForeground.fromJson(
            json['foreground'] as Map<String, dynamic>? ??
                {'type': 'solid', 'solidColor': '#000000'}),
        eyeColor: json['eyeColor'] != null
            ? QrForeground.fromJson(json['eyeColor'] as Map<String, dynamic>)
            : null,
        centerIcon: json['centerIcon'] != null
            ? QrCenterIconData.fromJson(
                json['centerIcon'] as Map<String, dynamic>)
            : const QrCenterIconData(type: 'none'),
      );
}

// ── QrTemplateCategory ────────────────────────────────────────────────────────

class QrTemplateCategory {
  final String id;
  final String name;
  final int order;

  const QrTemplateCategory({
    required this.id,
    required this.name,
    required this.order,
  });

  factory QrTemplateCategory.fromJson(Map<String, dynamic> json) =>
      QrTemplateCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        order: json['order'] as int? ?? 0,
      );
}

// ── QrTemplate ────────────────────────────────────────────────────────────────

class QrTemplate {
  final String id;
  final int minEngineVersion;
  final String name;
  final String categoryId;
  final int order;
  final String? thumbnailUrl;
  final bool isPremium;
  final QrStyleData style;

  const QrTemplate({
    required this.id,
    required this.minEngineVersion,
    required this.name,
    required this.categoryId,
    required this.order,
    this.thumbnailUrl,
    this.isPremium = false,
    required this.style,
  });

  factory QrTemplate.fromJson(Map<String, dynamic> json) => QrTemplate(
        id: json['id'] as String,
        minEngineVersion: json['minEngineVersion'] as int? ?? 1,
        name: json['name'] as String,
        categoryId: json['categoryId'] as String,
        order: json['order'] as int? ?? 0,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        isPremium: json['isPremium'] as bool? ?? false,
        style: QrStyleData.fromJson(json['style'] as Map<String, dynamic>),
      );
}

// ── QrTemplateManifest ────────────────────────────────────────────────────────

class QrTemplateManifest {
  final int schemaVersion;
  final List<QrTemplateCategory> categories;
  final List<QrTemplate> templates;

  const QrTemplateManifest({
    required this.schemaVersion,
    required this.categories,
    required this.templates,
  });

  factory QrTemplateManifest.fromJson(Map<String, dynamic> json) =>
      QrTemplateManifest(
        schemaVersion: json['schemaVersion'] as int? ?? 1,
        categories: (json['categories'] as List<dynamic>? ?? [])
            .map((e) =>
                QrTemplateCategory.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order)),
        templates: (json['templates'] as List<dynamic>? ?? [])
            .map((e) => QrTemplate.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order)),
      );

  static const QrTemplateManifest empty = QrTemplateManifest(
    schemaVersion: 1,
    categories: [],
    templates: [],
  );
}
