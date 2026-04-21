import 'package:flutter/material.dart';

/// 스캐너 중앙 사각형 오버레이 + 인식 성공 애니메이션.
class ScanningReticle extends StatelessWidget {
  final bool detected;

  const ScanningReticle({super.key, this.detected = false});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width * 0.65;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: detected ? size * 0.95 : size,
        height: detected ? size * 0.95 : size,
        decoration: BoxDecoration(
          border: Border.all(
            color: detected ? Colors.greenAccent : Colors.white70,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomPaint(
          painter: _CornerPainter(
            color: detected ? Colors.greenAccent : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;

  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 24.0;

    // 좌상
    canvas.drawLine(Offset.zero, Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, len), paint);

    // 우상
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);

    // 좌하
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), paint);

    // 우하
    canvas.drawLine(
        Offset(size.width, size.height), Offset(size.width - len, size.height), paint);
    canvas.drawLine(
        Offset(size.width, size.height), Offset(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}
