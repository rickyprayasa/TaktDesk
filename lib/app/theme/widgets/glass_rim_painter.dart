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

    // 1. Primary Specular Rim Sweep aligned with light vector
    final lightAngle = math.atan2(lightY, lightX);
    final highlightStart = Offset(
      size.width / 2 + math.cos(lightAngle) * (size.width / 2),
      size.height / 2 + math.sin(lightAngle) * (size.height / 2),
    );
    final highlightEnd = Offset(
      size.width / 2 - math.cos(lightAngle) * (size.width / 2),
      size.height / 2 - math.sin(lightAngle) * (size.height / 2),
    );

    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        begin: Alignment(
          (highlightStart.dx / size.width) * 2 - 1,
          (highlightStart.dy / size.height) * 2 - 1,
        ),
        end: Alignment(
          (highlightEnd.dx / size.width) * 2 - 1,
          (highlightEnd.dy / size.height) * 2 - 1,
        ),
        colors: [
          Colors.white.withValues(alpha: (0.45 * intensity).clamp(0.1, 0.75)),
          Colors.white.withValues(alpha: (0.12 * intensity).clamp(0.02, 0.25)),
          Colors.transparent,
          isDark
              ? TaktColors.filamentAmber.withValues(alpha: (0.15 * intensity).clamp(0.02, 0.25))
              : Colors.black.withValues(alpha: 0.10),
        ],
        stops: const [0.0, 0.28, 0.70, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, highlightPaint);

    // 2. Soft Refractive Inner Caustic Glow along illuminated corner
    final causticPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
      ..shader = RadialGradient(
        center: Alignment(lightX * 0.8, lightY * 0.8),
        radius: 0.8,
        colors: [
          Colors.white.withValues(alpha: (0.20 * intensity).clamp(0.05, 0.35)),
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
