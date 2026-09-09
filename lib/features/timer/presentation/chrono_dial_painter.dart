import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme/takt_colors.dart';

class ChronoDialPainter extends CustomPainter {
  final double remainingSeconds;
  final double progressPercent;
  final int targetMinutes;
  final bool isRunning;
  final Color needleColor;
  final Color filamentColor;

  // Cached text painters for dial numbers
  static final Map<int, TextPainter> _numberPainters = {};

  ChronoDialPainter({
    required this.remainingSeconds,
    this.progressPercent = 0.0,
    required this.targetMinutes,
    required this.isRunning,
    this.needleColor = TaktColors.mutedOchre,
    this.filamentColor = TaktColors.filamentAmber,
  });

  static TextPainter _getTextPainter(String text) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w700,
          fontSize: 8.5,
          color: TaktColors.warmBone.withValues(alpha: 0.65),
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2 - 8;
    final dialRadius = outerRadius - 14;

    // 1. Physical Ambient Occlusion Shadow
    final ambientShadowPaint = Paint()
      ..color = const Color(0x77000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    canvas.drawCircle(center + const Offset(0, 8), outerRadius, ambientShadowPaint);

    // 2. Multi-Tiered Metallic Bezel (Braun Style)
    // 2a. Outer Chamfer Ring
    final outerBezelPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF353940),
          Color(0xFF22252A),
          Color(0xFF181A1D),
        ],
        stops: [0.85, 0.95, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));
    canvas.drawCircle(center, outerRadius, outerBezelPaint);

    // 2b. Diamond Knurling Pattern on Outer Rim
    final knurlPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 90; i++) {
      final angle = (i * 4) * math.pi / 180.0;
      final p1 = Offset(
        center.dx + (outerRadius - 4) * math.cos(angle),
        center.dy + (outerRadius - 4) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );
      canvas.drawLine(p1, p2, knurlPaint);
    }

    // 2c. Inner Bezel Stepped Border
    final innerBezelStroke = Paint()
      ..color = const Color(0xFF141517)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, dialRadius + 2, innerBezelStroke);

    // 3. Dial Face (Matte Deep Charcoal)
    final dialFacePaint = Paint()..color = const Color(0xFF16181B);
    canvas.drawCircle(center, dialRadius, dialFacePaint);

    // 3a. Deep Inner Shadow (recessed dish effect)
    final dishShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawCircle(center, dialRadius - 2, dishShadowPaint);

    // 4. Amber Halo Ring (if running)
    if (isRunning) {
      final haloPaint = Paint()
        ..color = filamentColor.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
      canvas.drawCircle(center, dialRadius - 6, haloPaint);
    }

    // 5. Precision Tick Marks & Numeric Indices (60 ticks)
    final majorTickPaint = Paint()
      ..color = TaktColors.warmBone.withValues(alpha: 0.90)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final minorTickPaint = Paint()
      ..color = TaktColors.warmBone.withValues(alpha: 0.32)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 60; i++) {
      final angle = (i * 6) * math.pi / 180.0 - math.pi / 2;
      final isMajor = i % 5 == 0;
      final tickLength = isMajor ? 8.0 : 4.0;

      final start = Offset(
        center.dx + (dialRadius - 6 - tickLength) * math.cos(angle),
        center.dy + (dialRadius - 6 - tickLength) * math.sin(angle),
      );
      final end = Offset(
        center.dx + (dialRadius - 6) * math.cos(angle),
        center.dy + (dialRadius - 6) * math.sin(angle),
      );
      canvas.drawLine(start, end, isMajor ? majorTickPaint : minorTickPaint);

      // Draw numbers for every 5-minute major interval
      if (isMajor) {
        final minuteVal = (i == 0) ? 60 : i;
        final tp = _numberPainters.putIfAbsent(
          minuteVal,
          () => _getTextPainter(minuteVal.toString().padLeft(2, '0')),
        );
        final numRadius = dialRadius - 22;
        final numOffset = Offset(
          center.dx + numRadius * math.cos(angle) - tp.width / 2,
          center.dy + numRadius * math.sin(angle) - tp.height / 2,
        );
        tp.paint(canvas, numOffset);
      }
    }

    // 6. Dynamic Cast Shadow of the Needle (Directional depth)
    // Synchronize needle directly with the 60-minute dial marks:
    final currentMinutes = (remainingSeconds / 60.0);
    final handAngle = (currentMinutes / 60.0) * 2 * math.pi - math.pi / 2;
    final shadowOffset = Offset(
      3.0 * math.cos(handAngle + math.pi / 4),
      3.5 * math.sin(handAngle + math.pi / 4),
    );

    final needleLength = dialRadius - 16;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.40)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    final shadowStart = center + shadowOffset - Offset(10 * math.cos(handAngle), 10 * math.sin(handAngle));
    final shadowEnd = center + shadowOffset + Offset(needleLength * math.cos(handAngle), needleLength * math.sin(handAngle));
    canvas.drawLine(shadowStart, shadowEnd, shadowPaint);

    // 7. Tapered Needle Hand (Muted Ochre / Braun AW Design)
    final needlePaint = Paint()
      ..color = needleColor
      ..style = PaintingStyle.fill;

    final handPath = Path();
    final tip = center + Offset(needleLength * math.cos(handAngle), needleLength * math.sin(handAngle));
    final leftShoulder = center + Offset(2.8 * math.cos(handAngle - math.pi / 2), 2.8 * math.sin(handAngle - math.pi / 2));
    final rightShoulder = center + Offset(2.8 * math.cos(handAngle + math.pi / 2), 2.8 * math.sin(handAngle + math.pi / 2));
    final counterTail = center - Offset(14.0 * math.cos(handAngle), 14.0 * math.sin(handAngle));

    handPath.moveTo(leftShoulder.dx, leftShoulder.dy);
    handPath.lineTo(tip.dx, tip.dy);
    handPath.lineTo(rightShoulder.dx, rightShoulder.dy);
    handPath.lineTo(counterTail.dx, counterTail.dy);
    handPath.close();
    canvas.drawPath(handPath, needlePaint);

    // Counterweight teardrop disc
    canvas.drawCircle(counterTail, 3.8, needlePaint);

    // Center Pivot Cap (metallic brass/slate core)
    final capBasePaint = Paint()..color = const Color(0xFF24272C);
    canvas.drawCircle(center, 5.5, capBasePaint);

    final capCorePaint = Paint()..color = TaktColors.warmBone;
    canvas.drawCircle(center, 2.0, capCorePaint);

    // 8. Convex Curved Mineral Glass Glare (Optical Highlight)
    final glassGlarePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.70],
      ).createShader(Rect.fromCircle(center: center, radius: dialRadius));

    final glassPath = Path();
    glassPath.addArc(
      Rect.fromCircle(center: center, radius: dialRadius - 1),
      -math.pi * 0.85,
      math.pi * 0.70,
    );
    glassPath.quadraticBezierTo(
      center.dx,
      center.dy - dialRadius * 0.15,
      center.dx + (dialRadius - 1) * math.cos(-math.pi * 0.85),
      center.dy + (dialRadius - 1) * math.sin(-math.pi * 0.85),
    );
    canvas.drawPath(glassPath, glassGlarePaint);
  }

  @override
  bool shouldRepaint(covariant ChronoDialPainter oldDelegate) {
    return oldDelegate.remainingSeconds != remainingSeconds ||
        oldDelegate.targetMinutes != targetMinutes ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.needleColor != needleColor ||
        oldDelegate.filamentColor != filamentColor;
  }
}
