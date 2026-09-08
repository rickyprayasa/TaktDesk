import 'package:flutter/material.dart';
import '../../../app/theme/takt_colors.dart';

class ReceiptRunnerPainter extends CustomPainter {
  final double tearProgress;

  ReceiptRunnerPainter({this.tearProgress = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw serrated bottom edge of receipt paper with dynamic tear angle/shear
    final paperPaint = Paint()
      ..color = TaktColors.warmBone
      ..style = PaintingStyle.fill;

    // Dynamic tear angle / shear displacement along the serrated edge
    final maxShear = 14.0 * tearProgress.clamp(0.0, 1.0);

    // Serration teeth with exact proportional width
    const toothHeight = 5.0;
    final teethCount = (size.width / 8.0).floor().clamp(1, 100);
    final effectiveToothWidth = size.width / teethCount;

    final path = Path()..moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - toothHeight);

    for (int i = teethCount; i >= 0; i--) {
      final x = i * effectiveToothWidth;
      final y = (i % 2 == 0) ? size.height : size.height - toothHeight;
      path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(path, paperPaint);

    // Subtle mechanical tear stress line along the shearing edge
    if (tearProgress > 0.05) {
      final stressPaint = Paint()
        ..color = TaktColors.chassisObsidian.withValues(alpha: 0.15 * tearProgress.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(0, size.height - toothHeight),
        Offset(size.width, size.height - toothHeight + maxShear),
        stressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ReceiptRunnerPainter oldDelegate) {
    return oldDelegate.tearProgress != tearProgress;
  }
}
