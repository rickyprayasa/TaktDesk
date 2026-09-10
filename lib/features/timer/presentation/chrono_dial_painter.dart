import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/hardware_edition.dart';
import '../../../app/theme/takt_colors.dart';

class ChronoDialPainter extends CustomPainter {
  final double remainingSeconds;
  final double progressPercent;
  final int targetMinutes;
  final bool isRunning;
  final Color needleColor;
  final Color filamentColor;
  final List<Color> outerBezelGradient;
  final Color innerBezelColor;
  final HardwareTextureType textureType;
  final bool isDark;
  final Color? dialFaceColor;

  // Cached text painters for dial numbers
  static final Map<(int, bool), TextPainter> _numberPainters = {};

  ChronoDialPainter({
    required this.remainingSeconds,
    this.progressPercent = 0.0,
    required this.targetMinutes,
    required this.isRunning,
    this.needleColor = TaktColors.mutedOchre,
    this.filamentColor = TaktColors.filamentAmber,
    this.outerBezelGradient = const [
      Color(0xFF353940),
      Color(0xFF22252A),
      Color(0xFF181A1D),
    ],
    this.innerBezelColor = const Color(0xFF141517),
    this.textureType = HardwareTextureType.matteAbsGrain,
    this.isDark = true,
    this.dialFaceColor,
  });

  Color get activeDialFaceColor =>
      isDark ? const Color(0xFF16181B) : (dialFaceColor ?? const Color(0xFFEBE8DF));

  double get _knurlAlpha {
    switch (textureType) {
      case HardwareTextureType.burnishedBrass:
        return 0.14;
      case HardwareTextureType.brushedTitanium:
        return 0.12;
      case HardwareTextureType.tubularChrome:
        return 0.16;
      case HardwareTextureType.matteAbsGrain:
        return 0.08;
    }
  }

  Color get knurlColor => isDark
      ? Colors.white.withValues(alpha: _knurlAlpha)
      : Colors.black.withValues(alpha: _knurlAlpha * 0.75);

  Color get majorTickColor => isDark
      ? TaktColors.warmBone.withValues(alpha: 0.90)
      : const Color(0xFF1B1E23).withValues(alpha: 0.88);

  Color get minorTickColor => isDark
      ? TaktColors.warmBone.withValues(alpha: 0.32)
      : const Color(0xFF1B1E23).withValues(alpha: 0.38);

  Color get numeralColor => isDark
      ? TaktColors.warmBone.withValues(alpha: 0.65)
      : const Color(0xFF1B1E23).withValues(alpha: 0.78);

  Color get dishShadowColor => isDark
      ? Colors.black.withValues(alpha: 0.45)
      : Colors.black.withValues(alpha: 0.12);

  Color get hubCapColor =>
      isDark ? const Color(0xFF22252A) : const Color(0xFF2B2E34);

  List<double> get glassHighlightAlphas =>
      isDark ? const [0.15, 0.03] : const [0.28, 0.06];

  static TextPainter getTextPainter(String text, {bool isDark = true}) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w700,
          fontSize: 8.5,
          color: isDark
              ? TaktColors.warmBone.withValues(alpha: 0.65)
              : const Color(0xFF1B1E23).withValues(alpha: 0.78),
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
      ..shader = RadialGradient(
        colors: outerBezelGradient,
        stops: const [0.85, 0.95, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));
    canvas.drawCircle(center, outerRadius, outerBezelPaint);

    // 2b. Diamond Knurling Pattern on Outer Rim
    final knurlPaint = Paint()
      ..color = knurlColor
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
      ..color = innerBezelColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, dialRadius + 2, innerBezelStroke);

    // 3. Dial Face (Matte Deep Charcoal)
    final dialFacePaint = Paint()..color = activeDialFaceColor;
    canvas.drawCircle(center, dialRadius, dialFacePaint);

    // 3a. Deep Inner Shadow (recessed dish effect)
    final dishShadowPaint = Paint()
      ..color = dishShadowColor
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
      ..color = majorTickColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final minorTickPaint = Paint()
      ..color = minorTickColor
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
          (minuteVal, isDark),
          () => getTextPainter(minuteVal.toString().padLeft(2, '0'), isDark: isDark),
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
    final capBasePaint = Paint()..color = hubCapColor;
    canvas.drawCircle(center, 5.5, capBasePaint);

    final capCorePaint = Paint()..color = TaktColors.warmBone;
    canvas.drawCircle(center, 2.0, capCorePaint);

    // 8. Convex Curved Mineral Glass Glare (Optical Highlight)
    final highlights = glassHighlightAlphas;
    final glassGlarePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: highlights[0]),
          Colors.white.withValues(alpha: highlights[1]),
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
        oldDelegate.filamentColor != filamentColor ||
        !listEquals(oldDelegate.outerBezelGradient, outerBezelGradient) ||
        oldDelegate.innerBezelColor != innerBezelColor ||
        oldDelegate.textureType != textureType ||
        oldDelegate.isDark != isDark ||
        oldDelegate.dialFaceColor != dialFaceColor;
  }
}
