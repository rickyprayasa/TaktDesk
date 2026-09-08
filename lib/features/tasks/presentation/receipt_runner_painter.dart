import 'package:flutter/material.dart';
import '../../../app/theme/takt_colors.dart';

class ReceiptRunnerPainter extends CustomPainter {
  final double tearProgress;

  ReceiptRunnerPainter({this.tearProgress = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw serrated bottom edge of receipt paper
    final paperPaint = Paint()
      ..color = TaktColors.warmBone
      ..style = PaintingStyle.fill;

    final path = Path()..moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - 10);

    // Serration teeth with exact proportional width
    const toothHeight = 6.0;
    final teethCount = (size.width / 8.0).floor().clamp(1, 100);
    final effectiveToothWidth = size.width / teethCount;

    for (int i = teethCount; i >= 0; i--) {
      final x = i * effectiveToothWidth;
      final y = (i % 2 == 0) ? size.height : size.height - toothHeight;
      path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(path, paperPaint);
  }

  @override
  bool shouldRepaint(covariant ReceiptRunnerPainter oldDelegate) {
    return oldDelegate.tearProgress != tearProgress;
  }
}
