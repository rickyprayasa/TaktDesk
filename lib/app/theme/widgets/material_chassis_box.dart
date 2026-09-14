import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sensors/parallax_controller.dart';
import '../theme_controller.dart';
import 'glass_rim_painter.dart';
import 'material_texture_painter.dart';

/// Paints a top-lit specular chamfer highlight rim along the top and left edges
/// of the chassis to simulate a machined 5mm metal slab edge.
class ChassisChamferPainter extends CustomPainter {
  final Color highlightColor;
  final BorderRadius borderRadius;
  final double strokeWidth;

  const ChassisChamferPainter({
    required this.highlightColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.strokeWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final topLeftRadius = borderRadius.topLeft;
    final rX = topLeftRadius.x.clamp(0.0, size.width / 2);
    final rY = topLeftRadius.y.clamp(0.0, size.height / 2);

    final path = Path();
    // Start along the left edge, moving upwards
    path.moveTo(strokeWidth / 2, size.height - borderRadius.bottomLeft.y);
    path.lineTo(strokeWidth / 2, rY > 0 ? rY : strokeWidth / 2);

    if (rX > 0 && rY > 0) {
      path.arcToPoint(
        Offset(rX, strokeWidth / 2),
        radius: Radius.elliptical(rX, rY),
      );
    }

    // Line along the top edge
    path.lineTo(size.width - borderRadius.topRight.x, strokeWidth / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ChassisChamferPainter oldDelegate) {
    return oldDelegate.highlightColor != highlightColor ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// A reusable hardware chassis container that applies procedural material texture,
/// outer bezel borders, corner rivets, and elevation depth around any instrument or component.
class MaterialChassisBox extends ConsumerWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final String? rivetKeyPrefix;
  final double borderWidth;
  final bool showRivets;
  final bool showTexture;
  final bool showChamfer;
  final bool showGlassRim;
  final bool enablePerspective;

  const MaterialChassisBox({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.rivetKeyPrefix,
    this.borderWidth = 1.2,
    this.showRivets = true,
    this.showTexture = true,
    this.showChamfer = true,
    this.showGlassRim = true,
    this.enablePerspective = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(chassisThemeProvider);
    final parallax = ref.watch(parallaxProvider);

    Widget chassis = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: themeState.moduleChassisColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: themeState.borderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: themeState.isDarkMode
                ? Colors.black.withValues(alpha: 0.45)
                : const Color(0x1F000000),
            blurRadius: 14,
            offset: Offset(
              (-parallax.tiltX * 20.0).clamp(-12.0, 12.0),
              6.0 + (-parallax.tiltY * 20.0).clamp(-12.0, 12.0),
            ),
          ),
          BoxShadow(
            color: themeState.isDarkMode
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0x0F000000),
            blurRadius: 4,
            offset: Offset(
              (-parallax.tiltX * 6.0).clamp(-4.0, 4.0),
              1.0 + (-parallax.tiltY * 6.0).clamp(-4.0, 4.0),
            ),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (showTexture || showChamfer)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: borderRadius,
                child: RepaintBoundary(
                  child: CustomPaint(
                    isComplex: true,
                    willChange: false,
                    painter: showTexture
                        ? MaterialTexturePainter(
                            textureType: themeState.textureType,
                            isDark: themeState.isDarkMode,
                            chassisColor: themeState.moduleChassisColor,
                          )
                        : null,
                    foregroundPainter: showChamfer
                        ? ChassisChamferPainter(
                            highlightColor: Colors.white.withValues(
                              alpha: themeState.isDarkMode ? 0.12 : 0.28,
                            ),
                            borderRadius: borderRadius,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          if (showGlassRim)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  foregroundPainter: GlassRimPainter(
                    lightX: parallax.lightX,
                    lightY: parallax.lightY,
                    intensity: parallax.lightIntensity,
                    borderRadius: borderRadius,
                    isDark: themeState.isDarkMode,
                  ),
                ),
              ),
            ),
          if (showRivets) ...[
            Positioned(
              top: 6,
              left: 6,
              child: _buildCornerRivet(0, themeState.rivetColor),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: _buildCornerRivet(1, themeState.rivetColor),
            ),
            Positioned(
              bottom: 6,
              left: 6,
              child: _buildCornerRivet(2, themeState.rivetColor),
            ),
            Positioned(
              bottom: 6,
              right: 6,
              child: _buildCornerRivet(3, themeState.rivetColor),
            ),
          ],
          Padding(
            padding: padding ?? EdgeInsets.zero,
            child: RepaintBoundary(
              child: child,
            ),
          ),
        ],
      ),
    );

    if (enablePerspective) {
      chassis = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateX(-parallax.tiltY)
          ..rotateY(parallax.tiltX),
        child: chassis,
      );
    }

    return chassis;
  }

  Widget _buildCornerRivet(int index, Color color) {
    return IgnorePointer(
      child: Container(
        key: rivetKeyPrefix != null ? ValueKey('${rivetKeyPrefix}_$index') : null,
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              offset: Offset(0, 0.5),
              blurRadius: 0.5,
            ),
          ],
        ),
      ),
    );
  }
}
