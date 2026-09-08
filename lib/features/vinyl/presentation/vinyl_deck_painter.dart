import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme/takt_colors.dart';

class VinylDeckPainter extends CustomPainter {
  final double rotationAngle;
  final bool needleOnRecord;
  final Color labelColor;

  VinylDeckPainter({
    required this.rotationAngle,
    required this.needleOnRecord,
    this.labelColor = TaktColors.mutedOchre,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.45, size.height * 0.5);
    final radius = math.min(size.width, size.height) * 0.4;

    // 1. Turntable Platter
    final platterPaint = Paint()..color = const Color(0xFF181A1D);
    canvas.drawCircle(center, radius + 4, platterPaint);

    final platterBezelPaint = Paint()
      ..color = TaktColors.slateBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius + 4, platterBezelPaint);

    // 2. Vinyl Record with Micro-Grooves and Rotational Label
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    // Vinyl Record disc
    final vinylPaint = Paint()..color = const Color(0xFF0F1012);
    canvas.drawCircle(Offset.zero, radius, vinylPaint);

    // Micro-grooves
    final groovePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (double r = radius * 0.4; r < radius; r += 6.0) {
      canvas.drawCircle(Offset.zero, r, groovePaint);
    }

    // Run-out groove
    final runOutPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset.zero, radius * 0.35, runOutPaint);

    // Center Label
    final labelPaint = Paint()..color = labelColor;
    canvas.drawCircle(Offset.zero, radius * 0.3, labelPaint);

    // Center Label inner ring & typography accent
    final labelRingPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset.zero, radius * 0.2, labelRingPaint);

    final labelAccentPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(-radius * 0.22, 0),
      Offset(radius * 0.22, 0),
      labelAccentPaint,
    );

    // Spindle
    final spindlePaint = Paint()..color = TaktColors.warmBone;
    canvas.drawCircle(Offset.zero, 4.0, spindlePaint);

    canvas.restore();

    // 3. Tonearm Assembly (Fixed pivot, swings according to needleOnRecord)
    final tonearmBase = Offset(size.width * 0.88, size.height * 0.2);
    final armTarget = needleOnRecord
        ? center + Offset(radius * 0.5, 0)
        : tonearmBase + const Offset(-10, 50);

    // Tonearm Arm
    final armPaint = Paint()
      ..color = TaktColors.warmBone.withValues(alpha: 0.85)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tonearmBase, armTarget, armPaint);

    // Cartridge / Stylus Head
    final cartridgePaint = Paint()
      ..color = TaktColors.filamentAmber
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.square;
    final headOffset = needleOnRecord ? const Offset(0, 5) : const Offset(-2, 5);
    canvas.drawLine(armTarget, armTarget + headOffset, cartridgePaint);

    // Tonearm Rest (when lifted)
    final restBase = tonearmBase + const Offset(-10, 50);
    final restPaint = Paint()
      ..color = TaktColors.slateBorder
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(restBase + const Offset(-4, 0), restBase + const Offset(4, 0), restPaint);

    // Tonearm Pivot
    final pivotPaint = Paint()..color = TaktColors.basaltSlate;
    canvas.drawCircle(tonearmBase, 10.0, pivotPaint);

    final pivotBorderPaint = Paint()
      ..color = TaktColors.slateBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(tonearmBase, 10.0, pivotBorderPaint);
  }

  @override
  bool shouldRepaint(covariant VinylDeckPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.needleOnRecord != needleOnRecord ||
        oldDelegate.labelColor != labelColor;
  }
}
