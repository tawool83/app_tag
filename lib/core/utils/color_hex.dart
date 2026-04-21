import 'dart:ui';

/// Hex 문자열(`#RRGGBB` | `#AARRGGBB` | `RRGGBB` | `AARRGGBB`)을 Color 로 변환.
/// 잘못된 입력 시 [fallback] 반환.
Color colorFromHex(String? hex, {Color fallback = const Color(0xFF000000)}) {
  if (hex == null || hex.isEmpty) return fallback;
  var s = hex.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return fallback;
  final parsed = int.tryParse(s, radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

/// Color 를 hex 문자열로 변환.
/// [includeAlpha]=true 면 `#AARRGGBB`, false(기본)면 `#RRGGBB` 반환.
String colorToHex(Color color, {bool includeAlpha = false, bool uppercase = true}) {
  final argb = color.toARGB32().toRadixString(16).padLeft(8, '0');
  final body = includeAlpha ? argb : argb.substring(2);
  return '#${uppercase ? body.toUpperCase() : body.toLowerCase()}';
}
