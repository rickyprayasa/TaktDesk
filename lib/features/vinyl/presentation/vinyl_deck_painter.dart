import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/takt_colors.dart';

/// Which part of the deck a [VinylDeckPainter] draws. The player paints [base] once, caches [disc] in its own
/// layer and spins that layer with a transform (no repaint per frame), and repaints [arm] only while it moves.
enum VinylDeckLayer { all, base, disc, arm }

class VinylDeckPainter extends CustomPainter {
  final VinylDeckLayer layer;
  final double rotationAngle;
  final bool needleOnRecord;
  final Color labelColor;
  final double armProgress; // 0.0 (rest cradle) to 1.0 (on record)
  final List<Color>? tonearmGradient;
  final Color? armPivotBorderColor;

  VinylDeckPainter({
    this.layer = VinylDeckLayer.all,
    required this.rotationAngle,
    required this.needleOnRecord,
    this.labelColor = TaktColors.mutedOchre,
    double? armProgress,
    this.tonearmGradient,
    this.armPivotBorderColor,
  }) : armProgress = armProgress ?? (needleOnRecord ? 1.0 : 0.0);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.44, size.height * 0.5);
    final radius = math.min(size.width, size.height) * 0.41;

    // ==========================================
    // 0. Recessed Platter Well (Machined Chassis Cavity)
    // ==========================================
    final platterRadius = radius + 5;
    final wellRadius = platterRadius + 3.0;
    final drawBase = layer == VinylDeckLayer.all || layer == VinylDeckLayer.base;
    final drawDisc = layer == VinylDeckLayer.all || layer == VinylDeckLayer.disc;
    final drawArm = layer == VinylDeckLayer.all || layer == VinylDeckLayer.arm;

    if (drawBase) {

      // Recessed circular well inner shadow fading inward
      final innerStop = math.max(0.0, (platterRadius - 4.0) / wellRadius);
      final wellShadowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.35),
          ],
          stops: [innerStop, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: wellRadius));
      canvas.drawCircle(center, wellRadius, wellShadowPaint);

      // Subtle well outer lip contour
      final wellLipPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, wellRadius, wellLipPaint);

      // ==========================================
      // 1. Turntable Platter with Stroboscope Rim
      // ==========================================
      // Platter ambient drop shadow onto turntable base
      final platterShadow = Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawCircle(center + const Offset(0, 4), platterRadius, platterShadow);

      // Platter main body
      final platterPaint = Paint()
        ..shader = const RadialGradient(
          colors: [
            Color(0xFF25282E),
            Color(0xFF1A1C20),
            Color(0xFF121417),
          ],
          stops: [0.8, 0.96, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: platterRadius));
      canvas.drawCircle(center, platterRadius, platterPaint);

      // Platter outer metallic bezel rim
      final platterBezelPaint = Paint()
        ..color = const Color(0xFF3E434C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, platterRadius, platterBezelPaint);
    }

    if (drawDisc) {
      // Stroboscope calibrated speed dots on platter rim (33 1/3 RPM strobe)
      final strobePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill;
      const strobeCount = 54;
      for (int i = 0; i < strobeCount; i++) {
        final angle = (i * (2 * math.pi / strobeCount)) + rotationAngle;
        final dotPos = center + Offset(math.cos(angle) * (platterRadius - 2), math.sin(angle) * (platterRadius - 2));
        canvas.drawCircle(dotPos, 0.8, strobePaint);
    }

    // ==========================================
    // 2. Vinyl Record with Micro-Grooves & Sheen
    // ==========================================
    // Vinyl Base Disc
    final vinylPaint = Paint()..color = const Color(0xFF0D0E11);
    canvas.drawCircle(center, radius, vinylPaint);

    // Anisotropic "Butterfly" Light Reflection Sheen (microgroove light refraction)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    // Full 360-degree continuous anisotropic sheen rotation tracking turntable platter
    canvas.rotate(rotationAngle);

    final sheenPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Colors.transparent,
          Color(0x18FFFFFF),
          Colors.transparent,
          Colors.transparent,
          Color(0x18FFFFFF),
          Colors.transparent,
        ],
        stops: [0.0, 0.12, 0.25, 0.5, 0.62, 0.75],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawCircle(Offset.zero, radius - 2, sheenPaint);
    canvas.restore();

    // Concentric Micro-Grooves
    final groovePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (double r = radius * 0.42; r < radius - 2; r += 4.5) {
      canvas.drawCircle(center, r, groovePaint);
    }

    // Run-out groove (lead-in to center label)
    final runOutPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 0.36, runOutPaint);

    // Rotating Center Label with Spindle
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    // Center label disc
    final labelRadius = radius * 0.32;
    final labelPaint = Paint()..color = labelColor;
    canvas.drawCircle(Offset.zero, labelRadius, labelPaint);

    // Center label inner accent rings
    final labelRingPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(Offset.zero, labelRadius * 0.75, labelRingPaint);
    canvas.drawCircle(Offset.zero, labelRadius * 0.45, labelRingPaint);

    // Center label design line (Braun minimalist division)
    final labelAccentPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(-labelRadius * 0.75, 0),
      Offset(labelRadius * 0.75, 0),
      labelAccentPaint,
    );

    // Asymmetrical 360° rotation indicator (Braun index pip and radial mark)
    canvas.drawCircle(
      Offset(0, -labelRadius * 0.58),
      2.0,
      labelAccentPaint,
    );
    canvas.drawLine(
      Offset(0, -labelRadius * 0.45),
      Offset(0, -labelRadius * 0.75),
      labelAccentPaint,
    );

    // Spindle hole
    final spindleHole = Paint()..color = const Color(0xFF141517);
    canvas.drawCircle(Offset.zero, 5.0, spindleHole);

    // Polished Silver Spindle Cap
    final spindlePaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFCBD0D8),
          Color(0xFF6A707C),
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: const Offset(-0.8, -0.8), radius: 3.5));
    canvas.drawCircle(Offset.zero, 3.5, spindlePaint);

    canvas.restore();
    }

    if (!drawArm) return;

    // ==========================================
    // 3. Tonearm Assembly with 3D Height Shadow
    // ==========================================
    final tonearmBase = Offset(size.width * 0.86, size.height * 0.22);
    final restTarget = tonearmBase + const Offset(-12, 54);
    final playTarget = center + Offset(radius * 0.52, 0);

    // Smooth mechanical arm position based on armProgress (0.0 rest to 1.0 play)
    final armTarget = Offset.lerp(restTarget, playTarget, armProgress)!;

    // Height offset: when lifted (armProgress near 0), needle hovers higher above platter
    final heightElevation = (1.0 - armProgress) * 7.0;

    // 3a. Dynamic Tonearm Cast Shadow
    final shadowBase = tonearmBase + Offset(0, 3 + heightElevation * 0.5);
    final shadowTarget = armTarget + Offset(0, 4 + heightElevation);
    final armShadowPaint = Paint()
      ..color = Color.lerp(
        const Color(0x35000000),
        const Color(0x75000000),
        armProgress,
      )!
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0 + heightElevation * 0.5);
    canvas.drawLine(shadowBase, shadowTarget, armShadowPaint);

    // 3b. Tonearm Rest Post (Cradle)
    final restPaint = Paint()
      ..color = const Color(0xFF383C44)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(restTarget + const Offset(-5, 0), restTarget + const Offset(5, 0), restPaint);

    final restPostPaint = Paint()..color = const Color(0xFF22252A);
    canvas.drawCircle(restTarget, 3.0, restPostPaint);

    // 3c. Tonearm Counterweight (Extends behind pivot gimbal)
    final counterweightVector = (tonearmBase - armTarget);
    final counterweightAngle = math.atan2(counterweightVector.dy, counterweightVector.dx);
    final counterweightPos = tonearmBase + Offset(math.cos(counterweightAngle) * 14, math.sin(counterweightAngle) * 14);

    final counterweightPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF4A4E58),
          Color(0xFF2B2E35),
          Color(0xFF1E2025),
        ],
      ).createShader(Rect.fromCircle(center: counterweightPos, radius: 6.0));
    canvas.drawCircle(counterweightPos, 6.0, counterweightPaint);

    // Counterweight calibration line
    final calibPaint = Paint()
      ..color = TaktColors.filamentAmber.withValues(alpha: 0.7)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      counterweightPos + Offset(math.cos(counterweightAngle + math.pi / 2) * 5, math.sin(counterweightAngle + math.pi / 2) * 5),
      counterweightPos - Offset(math.cos(counterweightAngle + math.pi / 2) * 5, math.sin(counterweightAngle + math.pi / 2) * 5),
      calibPaint,
    );

    // 3d. Tonearm Metallic Wand
    final armPaint = Paint()
      ..shader = LinearGradient(
        colors: tonearmGradient ?? const [
          Color(0xFFF0ECE3),
          Color(0xFFBDC3CC),
          Color(0xFF8E95A0),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromPoints(tonearmBase, armTarget))
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tonearmBase, armTarget, armPaint);

    // 3e. Tonearm Pivot Gimbal (Dual-ring metallic bearing)
    final pivotOuter = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF454A54),
          Color(0xFF282B31),
          Color(0xFF181A1D),
        ],
      ).createShader(Rect.fromCircle(center: tonearmBase, radius: 11.0));
    canvas.drawCircle(tonearmBase, 11.0, pivotOuter);

    final pivotBorder = Paint()
      ..color = armPivotBorderColor ?? const Color(0xFF555B66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(tonearmBase, 11.0, pivotBorder);

    final pivotCenter = Paint()..color = const Color(0xFF0F1114);
    canvas.drawCircle(tonearmBase, 4.5, pivotCenter);

    // 3f. Cartridge / Stylus Head
    final cartridgePaint = Paint()
      ..color = TaktColors.filamentAmber
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.square;
    final headOffset = needleOnRecord ? const Offset(0, 5) : const Offset(-2, 5);
    canvas.drawLine(armTarget, armTarget + headOffset, cartridgePaint);

    // Diamond needle tip dot
    final needleTipPaint = Paint()..color = Colors.white;
    canvas.drawCircle(armTarget + headOffset, 0.8, needleTipPaint);
  }

  @override
  bool shouldRepaint(covariant VinylDeckPainter oldDelegate) {
    final spins = layer == VinylDeckLayer.all || layer == VinylDeckLayer.disc;
    return oldDelegate.layer != layer ||
        (spins && oldDelegate.rotationAngle != rotationAngle) ||
        oldDelegate.needleOnRecord != needleOnRecord ||
        oldDelegate.armProgress != armProgress ||
        oldDelegate.labelColor != labelColor ||
        !listEquals(oldDelegate.tonearmGradient, tonearmGradient) ||
        oldDelegate.armPivotBorderColor != armPivotBorderColor;
  }
}
