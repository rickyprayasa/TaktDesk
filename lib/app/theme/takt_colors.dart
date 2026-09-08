import 'package:flutter/material.dart';

class TaktColors {
  const TaktColors._();

  static const Color chassisObsidian = Color(0xFF141517);
  static const Color basaltSlate = Color(0xFF24272C);
  static const Color warmBone = Color(0xFFEFECE6);
  static const Color thermalCarbon = Color(0xFF1F2226);
  static const Color mutedOchre = Color(0xFFC85A32);
  static const Color filamentAmber = Color(0xFFD99B59);
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
