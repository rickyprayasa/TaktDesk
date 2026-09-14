import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../takt_colors.dart';

/// Procedural vector painter rendering Liquid Glass edge caustics,
/// specular corner sweeps, and subtle chromatic glass refraction.
class GlassRimPainter extends CustomPainter {
  final double lightX;
  final double lightY;
  final double intensity;
  final BorderRadius borderRadius;
  final bool isDark;
  final double strokeWidth;

  const GlassRimPainter({
    required this.lightX,
    required this.lightY,
    required this.intensity,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.isDark = true,
    this.strokeWidth = 1.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    final lightAngle = math.atan2(lightY, lightX);
    final cosAngle = math.cos(lightAngle);
    final sinAngle = math.sin(lightAngle);

    // 1. Dynamic Surface Specular Sheen (Apple Liquid Glass surface reflection)
    final surfaceSheenPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment(cosAngle * 1.6, sinAngle * 1.6),
        end: Alignment(-cosAngle * 1.6, -sinAngle * 1.6),
        colors: [
          Colors.white.withValues(alpha: (0.10 * intensity).clamp(0.01, 0.20)),
          Colors.white.withValues(alpha: (0.03 * intensity).clamp(0.005, 0.08)),
          Colors.transparent,
          isDark
              ? TaktColors.filamentAmber.withValues(alpha: (0.04 * intensity).clamp(0.005, 0.08))
              : Colors.white.withValues(alpha: 0.05),
        ],
        stops: const [0.0, 0.30, 0.70, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, surfaceSheenPaint);

    // 2. Primary Specular Rim Sweep aligned with light vector

    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        begin: Alignment(cosAngle, sinAngle),
        end: Alignment(-cosAngle, -sinAngle),
        colors: [
          Colors.white.withValues(alpha: (0.65 * intensity).clamp(0.15, 0.90)),
          Colors.white.withValues(alpha: (0.22 * intensity).clamp(0.05, 0.40)),
          Colors.transparent,
          isDark
              ? TaktColors.filamentAmber.withValues(alpha: (0.20 * intensity).clamp(0.03, 0.35))
              : Colors.black.withValues(alpha: 0.12),
        ],
        stops: const [0.0, 0.28, 0.70, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, highlightPaint);

    // 3. Soft Refractive Inner Caustic Glow along illuminated corner
    final causticPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8)
      ..shader = RadialGradient(
        center: Alignment(lightX * 0.8, lightY * 0.8),
        radius: 0.85,
        colors: [
          Colors.white.withValues(alpha: (0.28 * intensity).clamp(0.08, 0.45)),
          Colors.transparent,
        ],
      ).createShader(rect);

    canvas.drawRRect(rrect, causticPaint);
  }

  @override
  bool shouldRepaint(covariant GlassRimPainter oldDelegate) {
    return (oldDelegate.lightX - lightX).abs() > 0.01 ||
        (oldDelegate.lightY - lightY).abs() > 0.01 ||
        (oldDelegate.intensity - intensity).abs() > 0.02 ||
        oldDelegate.isDark != isDark ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
