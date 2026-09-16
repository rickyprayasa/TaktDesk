import 'package:flutter/material.dart';
import 'takt_colors.dart';

enum HardwareTextureType {
  matteAbsGrain,
  brushedTitanium,
  tubularChrome,
  burnishedBrass,
  organicWalnut,
  forgedCarbon,
}

enum HardwareEditionType {
  braunClassic,
  braunAtelierCream,
  titaniumStealth,
  bauhausHeritage,
  rawBrassPatina,
  midCenturyWalnut,
  forgedCarbon,
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

  static const HardwareEdition braunAtelierCream = HardwareEdition(
    type: HardwareEditionType.braunAtelierCream,
    textureType: HardwareTextureType.matteAbsGrain,
    title: 'BRAUN ATELIER CREAM',
    subtitle: 'WARM BONE & SIGNAL ORANGE',
    yearLabel: 'MOD. 05 · 1965',
    isPremium: false,
    darkCanvas: Color(0xFF242321),
    lightCanvas: Color(0xFFEAE6DC),
    darkModuleBg: Color(0xFF1E1D1B),
    lightModuleBg: Color(0xFFDDD9CE),
    darkBorder: Color(0xFF3A3835),
    lightBorder: Color(0xFFBDB8AB),
    needleColor: Color(0xFFFF5500), // Braun Signal Orange
    filamentColor: Color(0xFFFFB703), // Warm Amber Glow
    accentColor: Color(0xFF4A5568),
    plateGradientDark: [Color(0xFF2C2A27), Color(0xFF211F1D), Color(0xFF181716)],
    plateGradientLight: [Color(0xFFF4F1EA), Color(0xFFEAE6DC), Color(0xFFDFDBD0)],
    rivetDark: Color(0xFF4D4944),
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

  static const HardwareEdition midCenturyWalnut = HardwareEdition(
    type: HardwareEditionType.midCenturyWalnut,
    textureType: HardwareTextureType.organicWalnut,
    title: 'MID-CENTURY WALNUT',
    subtitle: 'NATURAL TIMBER & SATIN GOLD',
    yearLabel: 'MOD. 06 · 1958',
    isPremium: true,
    darkCanvas: Color(0xFF1C140E),
    lightCanvas: Color(0xFFF2ECE3),
    darkModuleBg: Color(0xFF16100B),
    lightModuleBg: Color(0xFFE5DFD4),
    darkBorder: Color(0xFF4A3525),
    lightBorder: Color(0xFFB89E88),
    needleColor: Color(0xFFF3C68F), // Champagne Gold
    filamentColor: Color(0xFFFF9233), // Warm Hearthfire Glow
    accentColor: Color(0xFF5E4028),
    plateGradientDark: [Color(0xFF2E2218), Color(0xFF221811), Color(0xFF18100A)],
    plateGradientLight: [Color(0xFFEDE8DF), Color(0xFFE3DCD1), Color(0xFFD6CEC1)],
    rivetDark: Color(0xFFC99A40), // Satin Brass Rivet
    rivetLight: Color(0xFFB58A38),
  );

  static const HardwareEdition forgedCarbon = HardwareEdition(
    type: HardwareEditionType.forgedCarbon,
    textureType: HardwareTextureType.forgedCarbon,
    title: 'FORGED CARBON',
    subtitle: 'COMPOSITE MARBLE & AMBER',
    yearLabel: 'MOD. 07 · 2024',
    isPremium: true,
    darkCanvas: Color(0xFF0F1012),
    lightCanvas: Color(0xFFEAECEF),
    darkModuleBg: Color(0xFF15161A),
    lightModuleBg: Color(0xFFD8DCE3),
    darkBorder: Color(0xFF2D3039),
    lightBorder: Color(0xFF9AA0AC),
    needleColor: Color(0xFFFF3B00), // Electric Racing Amber
    filamentColor: Color(0xFFFFAA00), // Phosphor Neon Amber
    accentColor: Color(0xFF00B4D8),
    plateGradientDark: [Color(0xFF1E2025), Color(0xFF141518), Color(0xFF0B0C0E)],
    plateGradientLight: [Color(0xFFEFF2F6), Color(0xFFDFE3E8), Color(0xFFD0D5DC)],
    rivetDark: Color(0xFF3D424F), // Gunmetal Rivet
    rivetLight: Color(0xFF7A808C),
  );

  static const List<HardwareEdition> all = [
    braunClassic,
    braunAtelierCream,
    titaniumStealth,
    bauhausHeritage,
    rawBrassPatina,
    midCenturyWalnut,
    forgedCarbon,
  ];

  static HardwareEdition fromType(HardwareEditionType type) {
    switch (type) {
      case HardwareEditionType.braunClassic:
        return braunClassic;
      case HardwareEditionType.braunAtelierCream:
        return braunAtelierCream;
      case HardwareEditionType.titaniumStealth:
        return titaniumStealth;
      case HardwareEditionType.bauhausHeritage:
        return bauhausHeritage;
      case HardwareEditionType.rawBrassPatina:
        return rawBrassPatina;
      case HardwareEditionType.midCenturyWalnut:
        return midCenturyWalnut;
      case HardwareEditionType.forgedCarbon:
        return forgedCarbon;
    }
  }

  static HardwareEdition fromString(String? key) {
    for (final e in all) {
      if (e.type.name == key) return e;
    }
    return braunClassic;
  }
}
