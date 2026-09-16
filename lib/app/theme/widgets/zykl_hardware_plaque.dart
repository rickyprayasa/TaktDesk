import 'package:flutter/material.dart';
import '../takt_colors.dart';

/// A physical industrial hardware plaque showcasing the circular ZYKL chronometer emblem.
///
/// Features authentic Dieter Rams industrial aesthetic:
/// precision circular bezel, filament amber perimeter halo, and deep chassis shadow.
class ZyklHardwarePlaque extends StatelessWidget {
  const ZyklHardwarePlaque({
    super.key,
    this.size = 44.0,
    this.isDark,
  });

  final double size;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);

    return Container(
      key: const ValueKey('zykl_hardware_plaque'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF2C2F36), Color(0xFF181A1E)]
              : const [Color(0xFFF2EFE9), Color(0xFFD6D2C4)],
        ),
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x66000000) : const Color(0x28000000),
            offset: const Offset(0, 2.5),
            blurRadius: 4.5,
          ),
        ],
        border: Border.all(
          color: TaktColors.filamentAmber.withValues(alpha: 0.75),
          width: 1.2,
        ),
      ),
      child: ClipOval(
        child: Padding(
          padding: EdgeInsets.all(size * 0.04),
          child: Image.asset(
            'assets/images/zykl_icon.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
