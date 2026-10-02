import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'dart:ui' show PointMode;
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

  /// Face colour in dark mode; editions give each finish its own tone.
  final Color? darkDialFaceColor;

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
    this.darkDialFaceColor,
    this.drawHand = true,
  });

  final bool drawHand;

  Color get activeDialFaceColor =>
      isDark ? (darkDialFaceColor ?? const Color(0xFF16181B)) : (dialFaceColor ?? const Color(0xFFEBE8DF));

  bool get hasDarkDialFace =>
      isDark || activeDialFaceColor.computeLuminance() < 0.45;

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
      case HardwareTextureType.organicWalnut:
        return 0.10;
      case HardwareTextureType.forgedCarbon:
        return 0.13;
      case HardwareTextureType.glossCeramic:
        return 0.10;
      case HardwareTextureType.galvanizedSpangle:
        return 0.14;
      case HardwareTextureType.lacquer:
        return 0.10;
    }
  }

  Color get knurlColor => hasDarkDialFace
      ? Colors.white.withValues(alpha: _knurlAlpha)
      : Colors.black.withValues(alpha: _knurlAlpha * 0.75);

  Color get majorTickColor => hasDarkDialFace
      ? TaktColors.warmBone.withValues(alpha: 0.90)
      : const Color(0xFF1B1E23).withValues(alpha: 0.88);

  Color get minorTickColor => hasDarkDialFace
      ? TaktColors.warmBone.withValues(alpha: 0.32)
      : const Color(0xFF1B1E23).withValues(alpha: 0.38);

  Color get numeralColor => hasDarkDialFace
      ? TaktColors.warmBone.withValues(alpha: 0.65)
      : const Color(0xFF1B1E23).withValues(alpha: 0.78);

  Color get dishShadowColor => isDark
      ? Colors.black.withValues(alpha: 0.45)
      : Colors.black.withValues(alpha: 0.12);

  Color get hubCapColor =>
      isDark ? const Color(0xFF22252A) : const Color(0xFF2B2E34);

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

    // 1. Physical Ambient Occlusion Shadow (Subtle contact shadow)
    final ambientShadowPaint = Paint()
      ..color = isDark ? const Color(0x1F000000) : const Color(0x0A000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawCircle(center + const Offset(0, 1.5), outerRadius, ambientShadowPaint);

    // 2. Multi-Tiered Metallic Bezel (Braun Style)
    // 2a. Outer Chamfer Ring
    final outerBezelPaint = Paint()
      ..shader = RadialGradient(
        colors: outerBezelGradient,
        stops: const [0.85, 0.95, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));
    canvas.drawCircle(center, outerRadius, outerBezelPaint);

    // 2a'. Turned-metal sheen: alternating light/dark lobes around the ring read
    // as a lathe-turned bezel instead of a flat radial ring
    final bezelRect = Rect.fromCircle(center: center, radius: outerRadius);
    final lobe = isDark ? 0.10 : 0.22;
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..shader = SweepGradient(
          transform: const GradientRotation(-math.pi / 4),
          colors: [
            Colors.white.withValues(alpha: lobe),
            Colors.black.withValues(alpha: lobe * 0.8),
            Colors.white.withValues(alpha: lobe * 0.6),
            Colors.black.withValues(alpha: lobe),
            Colors.white.withValues(alpha: lobe),
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(bezelRect),
    );

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
    _paintFaceFinish(canvas, center, dialRadius);

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
          (minuteVal, hasDarkDialFace),
          () => getTextPainter(minuteVal.toString().padLeft(2, '0'), isDark: hasDarkDialFace),
        );
        final numRadius = dialRadius - 22;
        final numOffset = Offset(
          center.dx + numRadius * math.cos(angle) - tp.width / 2,
          center.dy + numRadius * math.sin(angle) - tp.height / 2,
        );
        tp.paint(canvas, numOffset);
      }
    }

    // 5b. Recessed Odometer Aperture Bezel Window Bed (6 o'clock position)
    final apertureRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + 40.0),
      width: 62.0,
      height: 22.0,
    );
    final apertureRRect = RRect.fromRectAndRadius(apertureRect, const Radius.circular(3.5));

    final apertureBedPaint = Paint()..color = const Color(0xFF0C0E10);
    canvas.drawRRect(apertureRRect, apertureBedPaint);

    final apertureBorderPaint = Paint()
      ..color = hasDarkDialFace
          ? const Color(0xFF2A2D34)
          : const Color(0xFFB5B0A4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(apertureRRect, apertureBorderPaint);

    if (!drawHand) {
      return;
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
  }

  /// Edition-specific dial finish, clipped to the face.
  void _paintFaceFinish(Canvas canvas, Offset center, double r) {
    final face = Rect.fromCircle(center: center, radius: r);
    final light = Colors.white.withValues(alpha: hasDarkDialFace ? 0.05 : 0.18);
    final shade = Colors.black.withValues(alpha: hasDarkDialFace ? 0.20 : 0.07);
    canvas.save();
    canvas.clipPath(Path()..addOval(face));

    switch (textureType) {
      case HardwareTextureType.brushedTitanium:
      case HardwareTextureType.galvanizedSpangle:
        // Sunburst: radial brushing that catches light in four lobes
        final ray = Paint()..strokeWidth = 0.6;
        for (int i = 0; i < 240; i++) {
          final a = i * 2 * math.pi / 240;
          ray.color = (i.isEven ? Colors.white : Colors.black).withValues(alpha: hasDarkDialFace ? 0.035 : 0.05);
          canvas.drawLine(center, center + Offset(math.cos(a), math.sin(a)) * r, ray);
        }
        canvas.drawRect(
          face,
          Paint()
            ..shader = SweepGradient(
              colors: [light, Colors.transparent, light, Colors.transparent, light],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              transform: const GradientRotation(-math.pi / 3),
            ).createShader(face),
        );
        break;
      case HardwareTextureType.burnishedBrass:
      case HardwareTextureType.forgedCarbon:
      case HardwareTextureType.matteAbsGrain:
      case HardwareTextureType.tubularChrome:
        // Fine grain (stronger and warmer on brass, flake-like on carbon)
        final n = textureType == HardwareTextureType.matteAbsGrain || textureType == HardwareTextureType.tubularChrome ? 900 : 1800;
        final w = textureType == HardwareTextureType.forgedCarbon ? 2.2 : 0.9;
        var seed = textureType.index * 92821 + 7;
        double rnd() {
          seed = (seed * 1103515245 + 12345) & 0x7fffffff;
          return seed / 0x7fffffff;
        }
        final hi = Paint()
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..color = (textureType == HardwareTextureType.burnishedBrass ? const Color(0xFFF2CF80) : Colors.white)
              .withValues(alpha: hasDarkDialFace ? 0.05 : 0.12);
        final lo = Paint()
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..color = Colors.black.withValues(alpha: hasDarkDialFace ? 0.12 : 0.05);
        for (int i = 0; i < n; i++) {
          final a = rnd() * 2 * math.pi;
          final d = math.sqrt(rnd()) * r;
          final p = center + Offset(math.cos(a), math.sin(a)) * d;
          canvas.drawPoints(PointMode.points, [p], rnd() < 0.5 ? hi : lo);
        }
        break;
      case HardwareTextureType.organicWalnut:
        // Enamel: soft glaze, a touch brighter towards the centre
        break;
      case HardwareTextureType.glossCeramic:
      case HardwareTextureType.lacquer:
        // Deep gloss: crescent reflection in the upper-left of the face
        final crescent = Path()
          ..addOval(Rect.fromCircle(center: center + Offset(-r * 0.18, -r * 0.22), radius: r * 0.95))
          ..fillType = PathFillType.evenOdd
          ..addOval(Rect.fromCircle(center: center + Offset(-r * 0.05, -r * 0.05), radius: r * 0.95));
        canvas.drawPath(
          crescent,
          Paint()
            ..color = Colors.white.withValues(alpha: hasDarkDialFace ? 0.06 : 0.20)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
        );
        break;
    }

    // Dome shading shared by every finish: lit centre, darker rim
    canvas.drawRect(
      face,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.3),
          radius: 0.95,
          colors: [light.withValues(alpha: light.a * 0.8), Colors.transparent, shade],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(face),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ChronoDialPainter oldDelegate) {
    // Without the hand the face never reads the time, so a running countdown
    // must not repaint the ticks, knurls and blurred shadows every frame.
    return (drawHand && oldDelegate.remainingSeconds != remainingSeconds) ||
        oldDelegate.targetMinutes != targetMinutes ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.needleColor != needleColor ||
        oldDelegate.filamentColor != filamentColor ||
        !listEquals(oldDelegate.outerBezelGradient, outerBezelGradient) ||
        oldDelegate.innerBezelColor != innerBezelColor ||
        oldDelegate.textureType != textureType ||
        oldDelegate.isDark != isDark ||
        oldDelegate.dialFaceColor != dialFaceColor ||
        oldDelegate.drawHand != drawHand;
  }
}

/// Foreground painter specifically rendering the needle hand and center pivot cap
/// ON TOP of the embedded digital counter.
/// This guarantees the analog hand sweeps visibly over the numbers without clipping.
class ChronoDialHandPainter extends CustomPainter {
  final double _fixedSeconds;

  /// When set, the hand repaints straight from this listenable on every change
  /// (no widget rebuild) and [remainingSeconds] follows its value.
  final ValueListenable<double>? remaining;
  final Color needleColor;
  final Color hubCapColor;

  /// Faint domed-crystal reflection over the dial.
  final bool glare;

  ChronoDialHandPainter({
    double remainingSeconds = 0.0,
    this.remaining,
    required this.needleColor,
    required this.hubCapColor,
    this.glare = true,
  })  : _fixedSeconds = remainingSeconds,
        super(repaint: remaining);

  double get remainingSeconds => remaining?.value ?? _fixedSeconds;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2 - 8;
    final dialRadius = outerRadius - 14;

    // 1. Dynamic Cast Shadow of the Needle (Directional depth)
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

    // 2. Tapered Needle Hand (Muted Ochre / Braun AW Design)
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

    // Ridged hand: the half facing away from the top-left light is shaded, so the
    // needle reads as a folded metal blade rather than a flat sticker
    final shadedHalf = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(rightShoulder.dx, rightShoulder.dy)
      ..lineTo(counterTail.dx, counterTail.dy)
      ..close();
    canvas.drawPath(shadedHalf, Paint()..color = Colors.black.withValues(alpha: 0.22));
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..strokeWidth = 0.6,
    );

    // Counterweight teardrop disc
    canvas.drawCircle(counterTail, 3.8, needlePaint);

    // Center pivot cap: domed, lit from the top-left, with a specular point
    final capRect = Rect.fromCircle(center: center, radius: 5.5);
    canvas.drawCircle(
      center,
      5.5,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.45),
          colors: [Color.lerp(hubCapColor, Colors.white, 0.35)!, hubCapColor, Color.lerp(hubCapColor, Colors.black, 0.4)!],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(capRect),
    );
    final capCorePaint = Paint()..color = TaktColors.warmBone;
    canvas.drawCircle(center, 2.0, capCorePaint);
    canvas.drawCircle(center + const Offset(-1.6, -1.6), 0.8, Paint()..color = Colors.white.withValues(alpha: 0.7));

    // Domed crystal: a faint glare arc across the upper-left of the glass
    if (glare) {
      final glass = Rect.fromCircle(center: center, radius: dialRadius + 2);
      canvas.drawArc(
        glass.deflate(6),
        math.pi * 1.05,
        math.pi * 0.42,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ChronoDialHandPainter oldDelegate) {
    return oldDelegate.remaining != remaining ||
        oldDelegate.remainingSeconds != remainingSeconds ||
        oldDelegate.needleColor != needleColor ||
        oldDelegate.hubCapColor != hubCapColor ||
        oldDelegate.glare != glare;
  }
}

