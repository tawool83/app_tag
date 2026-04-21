part of '../qr_result_screen.dart';

// 태그 타입별 아이콘/색상
(IconData, Color) _tagTypeIconColor(String? tagType) {
  switch (tagType) {
    case 'app':       return (Icons.apps, Colors.indigo);
    case 'clipboard': return (Icons.content_paste, Colors.blueGrey);
    case 'website':   return (Icons.language, Colors.blue);
    case 'contact':   return (Icons.contact_phone, Colors.green);
    case 'wifi':      return (Icons.wifi, Colors.teal);
    case 'location':  return (Icons.location_on, Colors.red);
    case 'event':     return (Icons.event, Colors.orange);
    case 'email':     return (Icons.email, Colors.deepPurple);
    case 'sms':       return (Icons.sms, Colors.pink);
    default:          return (Icons.qr_code, Colors.grey);
  }
}

// Material 아이콘 → PNG bytes 렌더링
Future<Uint8List> _renderMaterialIcon(IconData icon, Color color) async {
  const size = 96.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, size, size),
    Paint()..color = Colors.white,
  );
  canvas.drawCircle(
    const Offset(size / 2, size / 2),
    size / 2 - 4,
    Paint()..color = color.withValues(alpha: 0.15),
  );
  final tp = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        fontSize: 56,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size);
  tp.paint(canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2));
  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

// 이모지 → PNG bytes 렌더링
Future<Uint8List> _renderEmoji(String emoji) async {
  const size = 96.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, size, size),
    Paint()..color = Colors.white,
  );
  final tp = TextPainter(
    text: TextSpan(text: emoji, style: const TextStyle(fontSize: 68)),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size);
  tp.paint(canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2));
  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}
