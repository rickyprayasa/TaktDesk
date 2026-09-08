import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme/takt_colors.dart';

class ChronoDialPainter extends CustomPainter {
  final double progressPercent;
  final int targetMinutes;
  final bool isRunning;

  ChronoDialPainter({
    required this.progressPercent,
    required this.targetMinutes,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;

    // 1. Basalt Slate housing bezel
    final housingPaint = Paint()
      ..color = TaktColors.basaltSlate
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 8, housingPaint);

    final borderPaint = Paint()
      ..color = TaktColors.slateBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius + 8, borderPaint);

    // 2. Amber halo ring if running
    if (isRunning) {
      final haloPaint = Paint()
        ..color = TaktColors.filamentAmber.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawCircle(center, radius + 4, haloPaint);
    }

    // 3. Dial Face
    final facePaint = Paint()
      ..color = const Color(0xFF1B1D21)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, facePaint);

    // 4. Tick Marks (60 ticks)
    final majorTickPaint = Paint()
      ..color = TaktColors.warmBone.withValues(alpha: 0.8)
      ..strokeWidth = 2.0;
    final minorTickPaint = Paint()
      ..color = TaktColors.warmBone.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 60; i++) {
      final angle = (i * 6) * math.pi / 180.0 - math.pi / 2;
      final isMajor = i % 5 == 0;
      final tickLength = isMajor ? 10.0 : 5.0;
      final start = Offset(
        center.dx + (radius - tickLength) * math.cos(angle),
        center.dy + (radius - tickLength) * math.sin(angle),
      );
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(start, end, isMajor ? majorTickPaint : minorTickPaint);
    }

    // 5. Sweep Hand (Muted Ochre)
    final handAngle = (progressPercent * 360.0) * math.pi / 180.0 - math.pi / 2;
    final handPaint = Paint()
      ..color = TaktColors.mutedOchre
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    final handEnd = Offset(
      center.dx + (radius - 16) * math.cos(handAngle),
      center.dy + (radius - 16) * math.sin(handAngle),
    );
    canvas.drawLine(center, handEnd, handPaint);

    // Center Cap
    final capPaint = Paint()..color = TaktColors.mutedOchre;
    canvas.drawCircle(center, 5.0, capPaint);
  }

  @override
  bool shouldRepaint(covariant ChronoDialPainter oldDelegate) {
    return oldDelegate.progressPercent != progressPercent ||
        oldDelegate.targetMinutes != targetMinutes ||
        oldDelegate.isRunning != isRunning;
  }
}
