import 'package:flutter/material.dart';

class TaktColors {
  const TaktColors._();

  static const Color chassisObsidian = Color(0xFF141517);
  static const Color basaltSlate = Color(0xFF24272C);
  static const Color warmBone = Color(0xFFEFECE6);
  static const Color thermalCarbon = Color(0xFF1F2226);
  static const Color mutedOchre = Color(0xFFC85A32);
  static const Color filamentAmber = Color(0xFFD99B59);

  /// Amber for TEXT on light surfaces. filamentAmber is only 1.9:1 on the light
  /// panels (WCAG AA needs 4.5:1 for small text); this ink is 4.9-6.2:1.
  static const Color amberInk = Color(0xFF7A4A12);

  /// Amber text colour for the current surface: glowing filament on dark,
  /// printed ink on light.
  static Color amberText(bool isDark) => isDark ? filamentAmber : amberInk;

  /// An edition's accent as text: as is on a dark chassis, darkened on a light one (light filaments such as #D99B59
  /// or steel #B0B4BC read at about 2:1 on bone; this keeps the hue and reaches about 4.5:1).
  static Color readableAccent(Color accent, {required bool onDark}) {
    if (onDark) return accent;
    final hsl = HSLColor.fromColor(accent);
    return hsl.lightness <= 0.32 ? accent : hsl.withLightness(0.32).toColor();
  }
  static const Color patinaOlive = Color(0xFF4D5D4B);

  // Surface variations for depth
  static const Color slateLight = Color(0xFF2E3238);
  static const Color slateBorder = Color(0xFF383D45);
  static const Color paperBorder = Color(0xFFD5D1C8);
  static const Color paperShadow = Color(0x33000000);

  // Braun Audio Light Finish Palette
  static const Color lightChassisCanvas = Color(0xFFD6D2C9);
  static const Color lightChassisBasalt = Color(0xFFE8E5DD);
  static const Color lightChassisFaceplate = Color(0xFFF4F2EC);
  static const Color lightChassisBorder = Color(0xFFBDB8AD);
}

/// Shorthand palette names matching Braun design tokens
abstract class TaktPalette {
  static const Color obsidian = TaktColors.chassisObsidian;
  static const Color basalt = TaktColors.basaltSlate;
  static const Color warmBone = TaktColors.warmBone;
  static const Color thermalCarbon = TaktColors.thermalCarbon;
  static const Color mutedOchre = TaktColors.mutedOchre;
  static const Color filamentAmber = TaktColors.filamentAmber;
  static const Color patinaOlive = TaktColors.patinaOlive;
}
