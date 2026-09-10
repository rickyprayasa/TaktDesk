import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme_controller.dart';
import 'material_texture_painter.dart';

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
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(chassisThemeProvider);

    return Container(
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
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: themeState.isDarkMode
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0x0F000000),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (showTexture)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: borderRadius,
                child: RepaintBoundary(
                  child: CustomPaint(
                    isComplex: true,
                    willChange: false,
                    painter: MaterialTexturePainter(
                      textureType: themeState.textureType,
                      isDark: themeState.isDarkMode,
                      chassisColor: themeState.moduleChassisColor,
                    ),
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
            child: child,
          ),
        ],
      ),
    );
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
