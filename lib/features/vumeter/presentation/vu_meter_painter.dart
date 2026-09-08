import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme/takt_colors.dart';

/// CustomPainter rendering twin vintage galvanometer VU meters with amber phosphor backlight.
class VuMeterPainter extends CustomPainter {
  final double leftLevel; // 0.0 to 1.0
  final double rightLevel; // 0.0 to 1.0
  final bool peakLeft;
  final bool peakRight;

  const VuMeterPainter({
    required this.leftLevel,
    required this.rightLevel,
    required this.peakLeft,
    required this.peakRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 10.0;
    final gaugeWidth = (size.width - gap) / 2.0;

    // 1. Paint Left Channel Gauge
    _paintSingleGauge(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, gaugeWidth, size.height),
      level: leftLevel,
      isPeak: peakLeft,
      channelLabel: 'CH-L',
    );

    // 2. Paint Right Channel Gauge
    _paintSingleGauge(
      canvas: canvas,
      rect: Rect.fromLTWH(gaugeWidth + gap, 0, gaugeWidth, size.height),
      level: rightLevel,
      isPeak: peakRight,
      channelLabel: 'CH-R',
    );
  }

  void _paintSingleGauge({
    required Canvas canvas,
    required Rect rect,
    required double level,
    required bool isPeak,
    required String channelLabel,
  }) {
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6.0)));

    // 1. Recessed Gauge Background with Inner Shadow
    final bgPaint = Paint()..color = const Color(0xFF141619);
    canvas.drawRect(rect, bgPaint);

    // 2. Warm Amber Phosphor Backlight Diffusion Glow
    final backlightCenter = Offset(rect.center.dx, rect.top + rect.height * 0.25);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          TaktColors.filamentAmber.withValues(alpha: 0.22),
          TaktColors.filamentAmber.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: backlightCenter, radius: rect.width * 0.7));
    canvas.drawRect(rect, glowPaint);

    // 3. Calibrated Curved Scale Arc & Ticks
    // Pivot is placed below the bottom edge for realistic wide galvanometer swing
    final pivot = Offset(rect.center.dx, rect.bottom + 12.0);
    final scaleRadius = rect.height * 0.82;

    const startAngle = -math.pi * 0.72; // Leftmost (-20dB)
    const endAngle = -math.pi * 0.28; // Rightmost (+3dB)
    const zeroDbRatio = 0.74; // 0dB position (approx 74% of sweep)
    const zeroAngle = startAngle + (endAngle - startAngle) * zeroDbRatio;

    // Normal scale arc (-20dB to 0dB)
    final normalArcPaint = Paint()
      ..color = TaktColors.warmBone.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawArc(
      Rect.fromCircle(center: pivot, radius: scaleRadius),
      startAngle,
      zeroAngle - startAngle,
      false,
      normalArcPaint,
    );

    // Overload scale arc (0dB to +3dB)
    final overloadArcPaint = Paint()
      ..color = TaktColors.mutedOchre
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: pivot, radius: scaleRadius),
      zeroAngle,
      endAngle - zeroAngle,
      false,
      overloadArcPaint,
    );

    // Major dB scale tick marks: -20, -10, -7, -5, -3, 0, +1, +3
    const ticks = [
      (0.0, false),
      (0.25, false),
      (0.42, false),
      (0.56, false),
      (0.66, false),
      (0.74, false),
      (0.86, true),
      (1.0, true),
    ];

    final tickNormalPaint = Paint()
      ..color = TaktColors.warmBone.withValues(alpha: 0.7)
      ..strokeWidth = 1.0;
    final tickOverloadPaint = Paint()
      ..color = TaktColors.mutedOchre
      ..strokeWidth = 1.2;

    for (final (ratio, isOverload) in ticks) {
      final angle = startAngle + (endAngle - startAngle) * ratio;
      final innerP = pivot + Offset(math.cos(angle) * (scaleRadius - 4), math.sin(angle) * (scaleRadius - 4));
      final outerP = pivot + Offset(math.cos(angle) * (scaleRadius + 2), math.sin(angle) * (scaleRadius + 2));
      canvas.drawLine(innerP, outerP, isOverload ? tickOverloadPaint : tickNormalPaint);
    }

    // Channel label (CH-L / CH-R) and VU label
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: '$channelLabel // VU',
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 7.5,
        fontWeight: FontWeight.w700,
        color: TaktColors.warmBone.withValues(alpha: 0.45),
        letterSpacing: 0.8,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(rect.center.dx - textPainter.width / 2, rect.bottom - 22),
    );

    // 4. Galvanometer Needle
    final clampedLevel = level.clamp(0.0, 1.0);
    final needleAngle = startAngle + (endAngle - startAngle) * clampedLevel;
    final needleTip = pivot + Offset(math.cos(needleAngle) * scaleRadius, math.sin(needleAngle) * scaleRadius);

    // Needle drop shadow
    final needleShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawLine(pivot + const Offset(0, 1.5), needleTip + const Offset(0, 1.5), needleShadowPaint);

    // Main Hairline Needle (Tapered)
    final needlePaint = Paint()
      ..color = TaktColors.warmBone
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pivot, needleTip, needlePaint);

    // Needle Tip Accent (Amber indicator tip)
    final tipStart = pivot + Offset(math.cos(needleAngle) * (scaleRadius - 10), math.sin(needleAngle) * (scaleRadius - 10));
    final tipPaint = Paint()
      ..color = clampedLevel > zeroDbRatio ? TaktColors.mutedOchre : TaktColors.filamentAmber
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tipStart, needleTip, tipPaint);

    // Pivot screw cap
    final pivotScrewPaint = Paint()..color = const Color(0xFF26292F);
    canvas.drawCircle(pivot, 5.5, pivotScrewPaint);
    final pivotScrewCenter = Paint()..color = const Color(0xFF4A4F58);
    canvas.drawCircle(pivot, 2.0, pivotScrewCenter);

    // 5. Peak Overload Indicator LED (Top Right)
    final ledCenter = Offset(rect.right - 9, rect.top + 9);
    final ledPaint = Paint()
      ..color = isPeak ? TaktColors.mutedOchre : const Color(0xFF25282E);
    if (isPeak) {
      canvas.drawCircle(
        ledCenter,
        4.0,
        Paint()
          ..color = TaktColors.mutedOchre.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
      );
    }
    canvas.drawCircle(ledCenter, 2.5, ledPaint);

    canvas.restore();

    // 6. Bezel Border around Gauge Aperture
    final bezelPaint = Paint()
      ..color = const Color(0xFF2D323A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6.0)), bezelPaint);
  }

  @override
  bool shouldRepaint(covariant VuMeterPainter oldDelegate) {
    return oldDelegate.leftLevel != leftLevel ||
        oldDelegate.rightLevel != rightLevel ||
        oldDelegate.peakLeft != peakLeft ||
        oldDelegate.peakRight != peakRight;
  }
}
