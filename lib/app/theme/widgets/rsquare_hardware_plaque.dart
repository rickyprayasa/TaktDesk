import 'package:flutter/material.dart';
import '../takt_colors.dart';

/// A physical industrial hardware plaque for the RSQUARE emblem.
///
/// Crafted with brushed chamfered aluminum, precision micro-rivets in four corners,
/// subtle perimeter bevel with amber accent, and guaranteed high contrast
/// against any chassis material or background.
class RsquareHardwarePlaque extends StatelessWidget {
  const RsquareHardwarePlaque({
    super.key,
    this.size = 36.0,
    this.isDark,
    this.borderRadius = 6.0,
    this.showRivets,
    this.padding,
  });

  final double size;
  final bool? isDark;
  final double borderRadius;
  final bool? showRivets;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final effectiveShowRivets = showRivets ?? (size >= 28.0);
    final effectivePadding = padding ?? EdgeInsets.all(size * 0.12);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [
                  Color(0xFFFFFFFF),
                  Color(0xFFEBE8E1),
                ]
              : const [
                  Color(0xFFFFFFFF),
                  Color(0xFFF3F0E9),
                ],
        ),
        border: Border.all(
          color: TaktColors.filamentAmber.withValues(alpha: 0.65),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x38000000) : const Color(0x1C000000),
            offset: const Offset(0, 1.8),
            blurRadius: 3.5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Corner micro-rivets (authentic Braun / Dieter Rams hardware detail)
          if (effectiveShowRivets) ...[
            const Positioned(
              top: 2.0,
              left: 2.0,
              child: _MicroRivet(key: ValueKey('rsquare_plaque_rivet_tl')),
            ),
            const Positioned(
              top: 2.0,
              right: 2.0,
              child: _MicroRivet(key: ValueKey('rsquare_plaque_rivet_tr')),
            ),
            const Positioned(
              bottom: 2.0,
              left: 2.0,
              child: _MicroRivet(key: ValueKey('rsquare_plaque_rivet_bl')),
            ),
            const Positioned(
              bottom: 2.0,
              right: 2.0,
              child: _MicroRivet(key: ValueKey('rsquare_plaque_rivet_br')),
            ),
          ],
          // Emblem asset
          Padding(
            padding: effectivePadding,
            child: Image.asset(
              'assets/images/rsquare_logo.png',
              fit: BoxFit.contain,
              // Decode at the plaque's size, not the source's (2000 px square).
              cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MicroRivet extends StatelessWidget {
  const _MicroRivet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3.5,
      height: 3.5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFD4D0C7),
        border: Border.all(
          color: const Color(0xFF9E9B93),
          width: 0.6,
        ),
      ),
      child: Center(
        child: Container(
          width: 1.0,
          height: 1.0,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF6B6760),
          ),
        ),
      ),
    );
  }
}
