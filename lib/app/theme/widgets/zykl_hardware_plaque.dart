import 'package:flutter/material.dart';
import '../takt_colors.dart';

/// A physical industrial hardware plaque showcasing the circular ZYKL chronometer emblem.
///
/// Features authentic Dieter Rams industrial aesthetic:
/// precision circular bezel, filament amber perimeter halo, and deep chassis shadow.
class ZyklHardwarePlaque extends StatelessWidget {
  const ZyklHardwarePlaque({
    super.key,
    this.size = 54.0,
    this.isDark,
    this.showRivets = true,
  });

  final double size;
  final bool? isDark;
  final bool showRivets;

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);

    return Container(
      key: const ValueKey('zykl_hardware_plaque'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF2C2F36), Color(0xFF1E2126)]
              : const [Color(0xFFFFFFFF), Color(0xFFE8E5DD)],
        ),
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x66000000) : const Color(0x28000000),
            offset: const Offset(0, 2.5),
            blurRadius: 4.5,
          ),
        ],
        border: Border.all(
          color: TaktColors.filamentAmber.withValues(alpha: 0.65),
          width: 1.2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 4 corner micro-rivets
          if (showRivets) ...[
            const Positioned(
              top: 3.5,
              left: 3.5,
              child: _MicroRivet(key: ValueKey('zykl_plaque_rivet_tl')),
            ),
            const Positioned(
              top: 3.5,
              right: 3.5,
              child: _MicroRivet(key: ValueKey('zykl_plaque_rivet_tr')),
            ),
            const Positioned(
              bottom: 3.5,
              left: 3.5,
              child: _MicroRivet(key: ValueKey('zykl_plaque_rivet_bl')),
            ),
            const Positioned(
              bottom: 3.5,
              right: 3.5,
              child: _MicroRivet(key: ValueKey('zykl_plaque_rivet_br')),
            ),
          ],
          // Clean circular ZYKL dial emblem
          Padding(
            padding: EdgeInsets.all(size * 0.12),
            child: Image.asset(
              'assets/images/zykl_icon.png',
              fit: BoxFit.contain,
              // Decode at the plaque's size, not the source's (512 px square).
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
