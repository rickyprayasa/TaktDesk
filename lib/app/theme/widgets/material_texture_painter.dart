import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../hardware_edition.dart';

/// CustomPainter that renders authentic procedural surface textures for hardware chassis:
/// - [HardwareTextureType.brushedTitanium]: Horizontal micro-hairline strokes with anisotropic sheen.
/// - [HardwareTextureType.burnishedBrass]: Warm golden striations with darker patina edge vignette.
/// - [HardwareTextureType.tubularChrome]: Dual specular 45-degree linear gradient bands.
/// - [HardwareTextureType.matteAbsGrain]: Granular micro-pebble thermoplastic stippling.
/// - [HardwareTextureType.organicWalnut]: Mathematical sinusoidal wood grain growth rings with vessel stippling and lacquer sheen.
/// - [HardwareTextureType.forgedCarbon]: Procedural anisotropic chopped carbon flake mosaic with diagonal sheen.
class MaterialTexturePainter extends CustomPainter {
  final HardwareTextureType textureType;
  final bool isDark;
  final Color chassisColor;

  const MaterialTexturePainter({
    required this.textureType,
    required this.isDark,
    required this.chassisColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    switch (textureType) {
      case HardwareTextureType.brushedTitanium:
        _paintBrushedTitanium(canvas, size);
        break;
      case HardwareTextureType.burnishedBrass:
        _paintBurnishedBrass(canvas, size);
        break;
      case HardwareTextureType.tubularChrome:
        _paintTubularChrome(canvas, size);
        break;
      case HardwareTextureType.matteAbsGrain:
        _paintMatteAbsGrain(canvas, size);
        break;
      case HardwareTextureType.organicWalnut:
        _paintOrganicWalnut(canvas, size);
        break;
      case HardwareTextureType.forgedCarbon:
        _paintForgedCarbon(canvas, size);
        break;
    }
  }

  void _paintBrushedTitanium(Canvas canvas, Size size) {
    final lightPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.05 : 0.08)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final darkPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.07 : 0.04)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Horizontal micro-hairline strokes every 2.5px
    for (double y = 0.5; y < size.height; y += 2.5) {
      final isEvenStroke = (y ~/ 2.5) % 2 == 0;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isEvenStroke ? lightPaint : darkPaint,
      );
    }

    // Subtle anisotropic gradient reflection
    final Rect rect = Offset.zero & size;
    final sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-0.8, -1.0),
        end: const Alignment(0.8, 1.0),
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: isDark ? 0.03 : 0.06),
          Colors.transparent,
          Colors.white.withValues(alpha: isDark ? 0.05 : 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, sheenPaint);
  }

  void _paintBurnishedBrass(Canvas canvas, Size size) {
    final goldPaint = Paint()
      ..color = const Color(0xFFE0B858).withValues(alpha: isDark ? 0.06 : 0.08)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    final darkPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.08 : 0.05)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Horizontal hairline striations with warm golden tint
    for (double y = 0.5; y < size.height; y += 2.5) {
      final isGold = (y ~/ 2.5) % 2 == 0;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isGold ? goldPaint : darkPaint,
      );
    }

    // Perimeter darker patina vignette
    final Rect rect = Offset.zero & size;
    final patinaPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.85,
        colors: [
          Colors.transparent,
          const Color(0xFF151815).withValues(alpha: 0.0),
          const Color(0xFF151815).withValues(alpha: isDark ? 0.35 : 0.20),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, patinaPaint);
  }

  void _paintTubularChrome(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    // Dual specular linear gradient bands at 45 degrees simulating chrome reflection
    final chromePaint = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-1.0, -1.0),
        end: const Alignment(1.0, 1.0),
        colors: [
          Colors.transparent,
          const Color(0xFFF8F9FA).withValues(alpha: isDark ? 0.12 : 0.22),
          const Color(0xFF7D8390).withValues(alpha: isDark ? 0.06 : 0.10),
          Colors.transparent,
          const Color(0xFFF8F9FA).withValues(alpha: isDark ? 0.14 : 0.25),
          const Color(0xFF7D8390).withValues(alpha: isDark ? 0.06 : 0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.22, 0.30, 0.48, 0.72, 0.80, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, chromePaint);
  }

  void _paintMatteAbsGrain(Canvas canvas, Size size) {
    final lightPoints = <Offset>[];
    final darkPoints = <Offset>[];

    const double step = 4.0;
    int rowIndex = 0;
    for (double y = 1.0; y < size.height; y += step) {
      final double xOffset = (rowIndex % 2 == 1) ? step / 2 : 0.0;
      for (double x = 1.0 + xOffset; x < size.width; x += step) {
        final hash = (x.toInt() + y.toInt()) % 3;
        if (hash == 0) {
          lightPoints.add(Offset(x, y));
        } else if (hash == 1) {
          darkPoints.add(Offset(x, y));
        }
      }
      rowIndex++;
    }

    if (lightPoints.isNotEmpty) {
      final lightPaint = Paint()
        ..color = Colors.white.withValues(alpha: isDark ? 0.04 : 0.07)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;
      canvas.drawPoints(ui.PointMode.points, lightPoints, lightPaint);
    }

    if (darkPoints.isNotEmpty) {
      final darkPaint = Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.06 : 0.04)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;
      canvas.drawPoints(ui.PointMode.points, darkPoints, darkPaint);
    }
  }

  void _paintOrganicWalnut(Canvas canvas, Size size) {
    // 1. Alternating wavy wood grain lines (growth rings)
    final heartwoodPaint = Paint()
      ..color = const Color(0xFF1C140E).withValues(alpha: isDark ? 0.12 : 0.16)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final sapwoodPaint = Paint()
      ..color = const Color(0xFFD49B55).withValues(alpha: isDark ? 0.07 : 0.10)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    final heartwoodPath = Path();
    final sapwoodPath = Path();

    const double step = 3.2;
    for (double y = 1.0; y < size.height; y += step) {
      final isHeartwood = (y ~/ step) % 2 == 0;
      final targetPath = isHeartwood ? heartwoodPath : sapwoodPath;
      targetPath.moveTo(0, y);

      // Sinusoidal grain path with variable frequency extending across right edge
      for (double x = 0; x <= size.width + 6.0; x += 6.0) {
        final curX = math.min(x, size.width);
        final wave = math.sin(curX * 0.018) * 2.2 + math.sin(curX * 0.045) * 1.1;
        targetPath.lineTo(curX, (y + wave).clamp(0.0, size.height));
        if (curX >= size.width) break;
      }
    }

    canvas.drawPath(heartwoodPath, heartwoodPaint);
    canvas.drawPath(sapwoodPath, sapwoodPaint);

    // 2. Micro-pore wood vessel stippling
    final vesselPaint = Paint()
      ..color = isDark
          ? Colors.black.withValues(alpha: 0.10)
          : const Color(0xFF3E2714).withValues(alpha: 0.08)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;

    final vesselPoints = <Offset>[];
    for (double y = 4.0; y < size.height; y += 9.0) {
      final xOffset = (y.toInt() % 7) * 4.0;
      for (double x = 4.0 + xOffset; x < size.width; x += 18.0) {
        vesselPoints.add(Offset(x, y));
      }
    }
    if (vesselPoints.isNotEmpty) {
      canvas.drawPoints(ui.PointMode.points, vesselPoints, vesselPaint);
    }

    // 3. Satin polyurethane lacquer sheen (35-degree linear gradient)
    final Rect rect = Offset.zero & size;
    final sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-0.9, -0.6),
        end: const Alignment(0.9, 0.6),
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: isDark ? 0.03 : 0.07),
          Colors.transparent,
          Colors.white.withValues(alpha: isDark ? 0.05 : 0.09),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.55, 0.75, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, sheenPaint);

    // 4. Perimeter vignette
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.0),
          Colors.black.withValues(alpha: isDark ? 0.28 : 0.15),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, vignettePaint);
  }

  void _paintForgedCarbon(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    // 1. Anisotropic chopped carbon flakes grid
    final highlightPaint = Paint()
      ..color = const Color(0xFFE0E5EC).withValues(alpha: isDark ? 0.09 : 0.14)
      ..style = PaintingStyle.fill;

    final darkAbsorbPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.16 : 0.10)
      ..style = PaintingStyle.fill;

    final highlightPath = Path();
    final darkAbsorbPath = Path();

    const double flakeW = 16.0;
    const double flakeH = 8.0;

    for (double y = 0; y < size.height; y += flakeH) {
      final row = (y / flakeH).toInt();
      final xOffset = (row % 2 == 1) ? flakeW * 0.5 : 0.0;
      for (double x = xOffset - flakeW; x < size.width; x += flakeW) {
        final hash = (x.toInt().abs() * 13 + y.toInt().abs() * 37) % 5;
        if (hash == 0) {
          // Highlight flake
          highlightPath.moveTo(x, y + 2);
          highlightPath.lineTo(x + flakeW - 2, y);
          highlightPath.lineTo(x + flakeW, y + flakeH - 2);
          highlightPath.lineTo(x + 2, y + flakeH);
          highlightPath.close();
        } else if (hash == 1 || hash == 2) {
          // Dark absorbing flake
          darkAbsorbPath.moveTo(x + 1, y);
          darkAbsorbPath.lineTo(x + flakeW, y + 3);
          darkAbsorbPath.lineTo(x + flakeW - 3, y + flakeH);
          darkAbsorbPath.lineTo(x, y + flakeH - 1);
          darkAbsorbPath.close();
        }
      }
    }

    canvas.drawPath(highlightPath, highlightPaint);
    canvas.drawPath(darkAbsorbPath, darkAbsorbPaint);

    // 2. Anisotropic diagonal sheen
    final sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-1.0, -1.0),
        end: const Alignment(1.0, 1.0),
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: isDark ? 0.04 : 0.08),
          Colors.transparent,
          Colors.white.withValues(alpha: isDark ? 0.06 : 0.11),
          Colors.transparent,
        ],
        stops: const [0.0, 0.28, 0.5, 0.72, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, sheenPaint);
  }

  @override
  bool shouldRepaint(covariant MaterialTexturePainter oldDelegate) {
    // chassisColor is checked so that when the base chassis tone changes,
    // the procedural texture is re-evaluated and repainted.
    return textureType != oldDelegate.textureType ||
        isDark != oldDelegate.isDark ||
        chassisColor != oldDelegate.chassisColor;
  }
}
