import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../hardware_edition.dart';

/// CustomPainter that renders authentic procedural surface textures for hardware chassis:
/// - [HardwareTextureType.brushedTitanium]: Horizontal micro-hairline strokes with anisotropic sheen.
/// - [HardwareTextureType.burnishedBrass]: Warm golden striations with darker patina edge vignette.
/// - [HardwareTextureType.tubularChrome]: Dual specular 45-degree linear gradient bands.
/// - [HardwareTextureType.matteAbsGrain]: Granular micro-pebble thermoplastic stippling.
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

  @override
  bool shouldRepaint(covariant MaterialTexturePainter oldDelegate) {
    // chassisColor is checked so that when the base chassis tone changes,
    // the procedural texture is re-evaluated and repainted.
    return textureType != oldDelegate.textureType ||
        isDark != oldDelegate.isDark ||
        chassisColor != oldDelegate.chassisColor;
  }
}
