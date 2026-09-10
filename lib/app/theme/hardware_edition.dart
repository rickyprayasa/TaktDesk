import 'package:flutter/material.dart';
import 'takt_colors.dart';

enum HardwareTextureType {
  matteAbsGrain,
  brushedTitanium,
  tubularChrome,
  burnishedBrass,
}

enum HardwareEditionType {
  braunClassic,
  titaniumStealth,
  bauhausHeritage,
  rawBrassPatina,
}

class HardwareEdition {
  final HardwareEditionType type;
  final HardwareTextureType textureType;
  final String title;
  final String subtitle;
  final String yearLabel;
  final bool isPremium;

  // Canvas & Module Tokens
  final Color darkCanvas;
  final Color lightCanvas;
  final Color darkModuleBg;
  final Color lightModuleBg;
  final Color darkBorder;
  final Color lightBorder;

  // Accents & Hardware Details
  final Color needleColor;
  final Color filamentColor;
  final Color accentColor;
  final List<Color> plateGradientDark;
  final List<Color> plateGradientLight;
  final Color rivetDark;
  final Color rivetLight;

  const HardwareEdition({
    required this.type,
    required this.textureType,
    required this.title,
    required this.subtitle,
    required this.yearLabel,
    required this.isPremium,
    required this.darkCanvas,
    required this.lightCanvas,
    required this.darkModuleBg,
    required this.lightModuleBg,
    required this.darkBorder,
    required this.lightBorder,
    required this.needleColor,
    required this.filamentColor,
    required this.accentColor,
    required this.plateGradientDark,
    required this.plateGradientLight,
    required this.rivetDark,
    required this.rivetLight,
  });

  static const HardwareEdition braunClassic = HardwareEdition(
    type: HardwareEditionType.braunClassic,
    textureType: HardwareTextureType.matteAbsGrain,
    title: 'BRAUN CLASSIC',
    subtitle: 'GERMANIC MINIMALISM',
    yearLabel: 'MOD. 01 · 1960',
    isPremium: false,
    darkCanvas: TaktColors.chassisObsidian,
    lightCanvas: TaktColors.lightChassisCanvas,
    darkModuleBg: TaktColors.basaltSlate,
    lightModuleBg: Color(0xFFCFCBC0),
    darkBorder: TaktColors.slateBorder,
    lightBorder: TaktColors.lightChassisBorder,
    needleColor: TaktColors.mutedOchre, // #C85A32
    filamentColor: TaktColors.filamentAmber, // #D99B59
    accentColor: TaktColors.patinaOlive, // #4D5D4B
    plateGradientDark: [Color(0xFF282B32), Color(0xFF1E2126), Color(0xFF17191C)],
    plateGradientLight: [Color(0xFFE4E1D9), Color(0xFFDDD9D0), Color(0xFFCFCAC0)],
    rivetDark: Color(0xFF101214),
    rivetLight: Color(0xFFA8A398),
  );

  static const HardwareEdition titaniumStealth = HardwareEdition(
    type: HardwareEditionType.titaniumStealth,
    textureType: HardwareTextureType.brushedTitanium,
    title: 'TITANIUM STEALTH',
    subtitle: 'AEROSPACE PVD GRADE 5',
    yearLabel: 'MOD. 02 · 2026',
    isPremium: true,
    darkCanvas: Color(0xFF111317),
    lightCanvas: Color(0xFFCBCED4),
    darkModuleBg: Color(0xFF1B1E24),
    lightModuleBg: Color(0xFFBFC4CD),
    darkBorder: Color(0xFF2C323D),
    lightBorder: Color(0xFFA2A7B2),
    needleColor: Color(0xFF3A86FF), // Electric Cobalt Cyan
    filamentColor: Color(0xFFFF9E00), // Vivid Amber Neon
    accentColor: Color(0xFF48CAE4),
    plateGradientDark: [Color(0xFF22262E), Color(0xFF181B20), Color(0xFF121417)],
    plateGradientLight: [Color(0xFFD6DAE2), Color(0xFFC8CCD4), Color(0xFFB8BCC6)],
    rivetDark: Color(0xFF0D0F12),
    rivetLight: Color(0xFF8E939E),
  );

  static const HardwareEdition bauhausHeritage = HardwareEdition(
    type: HardwareEditionType.bauhausHeritage,
    textureType: HardwareTextureType.tubularChrome,
    title: 'BAUHAUS HERITAGE',
    subtitle: 'TUBULAR CHROME & PRIMARY',
    yearLabel: 'MOD. 03 · 1925',
    isPremium: true,
    darkCanvas: Color(0xFF101114),
    lightCanvas: Color(0xFFDCDAD4),
    darkModuleBg: Color(0xFF1E2025),
    lightModuleBg: Color(0xFFD3CFC7),
    darkBorder: Color(0xFF4A4E58), // Tubular chrome highlight
    lightBorder: Color(0xFF9E9B93),
    needleColor: Color(0xFFD62828), // Bauhaus Crimson
    filamentColor: Color(0xFFFCBF49), // Bauhaus Primary Yellow
    accentColor: Color(0xFF003049), // Bauhaus Blue
    plateGradientDark: [Color(0xFF2A2D35), Color(0xFF1D2026), Color(0xFF14161B)],
    plateGradientLight: [Color(0xFFE8E6E0), Color(0xFFDDD9D0), Color(0xFFCEC9BE)],
    rivetDark: Color(0xFF4A4E58),
    rivetLight: Color(0xFF7A7870),
  );

  static const HardwareEdition rawBrassPatina = HardwareEdition(
    type: HardwareEditionType.rawBrassPatina,
    textureType: HardwareTextureType.burnishedBrass,
    title: 'RAW BRASS & PATINA',
    subtitle: 'BURNISHED MARINE CHRONO',
    yearLabel: 'MOD. 04 · 1954',
    isPremium: true,
    darkCanvas: Color(0xFF151815),
    lightCanvas: Color(0xFFD5D2C7),
    darkModuleBg: Color(0xFF202520),
    lightModuleBg: Color(0xFFCCC7B3),
    darkBorder: Color(0xFF5A5844), // Burnished Brass Border
    lightBorder: Color(0xFFB2AD97),
    needleColor: Color(0xFFE0B858), // Polished Brass Gold
    filamentColor: Color(0xFFE8A048), // Warm Candlelight Glow
    accentColor: Color(0xFF4D5D4B), // Patina Forest Olive
    plateGradientDark: [Color(0xFF2B2B22), Color(0xFF202018), Color(0xFF161611)],
    plateGradientLight: [Color(0xFFE2DEC8), Color(0xFFD6D1B8), Color(0xFFC6C0A6)],
    rivetDark: Color(0xFF7A6836),
    rivetLight: Color(0xFF968249),
  );

  static const List<HardwareEdition> all = [
    braunClassic,
    titaniumStealth,
    bauhausHeritage,
    rawBrassPatina,
  ];

  static HardwareEdition fromType(HardwareEditionType type) {
    switch (type) {
      case HardwareEditionType.braunClassic:
        return braunClassic;
      case HardwareEditionType.titaniumStealth:
        return titaniumStealth;
      case HardwareEditionType.bauhausHeritage:
        return bauhausHeritage;
      case HardwareEditionType.rawBrassPatina:
        return rawBrassPatina;
    }
  }

  static HardwareEdition fromString(String? key) {
    for (final e in all) {
      if (e.type.name == key) return e;
    }
    return braunClassic;
  }
}
