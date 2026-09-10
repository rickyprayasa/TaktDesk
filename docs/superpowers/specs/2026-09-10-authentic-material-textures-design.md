# Takt Desk: Authentic Physical Material Textures & High-Contrast Finish Specification

**Date:** 2026-09-10  
**Platform Target:** Mobile Android (maxWidth 440px handheld console)  
**Status:** Approved for Implementation  
**Design Philosophy:** Dieter Rams & Braun Modernist Industrial Aesthetic (*Weniger, aber besser*) — Honest Materials, Tactile Fidelity, and Uncompromising Legibility

---

## 1. Problem Statement & User Inspection

In the initial material transformation pass, instrument containers swapped flat background color fills (`themeState.moduleChassisColor`). In user field testing, two critical defects were revealed:

1. **Illegibility & "Transparent" Appearance in Light Mode**:
   - The module chassis container adopted `lightModuleBg` (`0xFFD6D3C8`), which closely matches the canvas background (`0xFFDCDAD4`).
   - The text labels (`BRAUN TP-1`, `33 RPM`, `LO-FI RAIN`, `DISPENSER: 5 MAX`, `25 MIN`, and `+`/`-` buttons) relied on hardcoded `warmBone` (off-white) or `Colors.white` styling.
   - White text on a light beige chassis resulted in near-zero contrast, making the text and controls invisible and giving the user the impression that the module was completely "transparent".
2. **Lack of Physical Material Textures**:
   - The hardware editions felt like flat color swaps rather than distinct physical materials.
   - Users expect tangible, tactile surface finishes:
     - *Titanium Stealth*: Aerospace horizontal hairline brushed metal grain with satin PVD specular sheen.
     - *Raw Brass & Patina*: Burnished marine brass with warm golden grain and perimeter oxidized patina.
     - *Bauhaus Heritage*: Polished tubular chrome reflective bevels and crisp enamel plates.
     - *Braun Classic*: Granular matte ABS thermoplastic with precision aluminum chamfers.

---

## 2. Architectural Design

### 2.1 Domain Model & Tokens (`HardwareEdition`, `ChassisThemeState`)
- Introduce `HardwareTextureType`:
  ```dart
  enum HardwareTextureType {
    matteAbsGrain,     // Braun Classic: granular matte thermoplastic with chamfer
    brushedTitanium,   // Titanium Stealth: horizontal hairline brushed PVD Grade 5
    tubularChrome,     // Bauhaus Heritage: polished tubular chrome & crisp enamel
    burnishedBrass,    // Raw Brass & Patina: burnished brushed golden brass with patina
  }
  ```
- Add `HardwareTextureType textureType` to `HardwareEdition`.
- Add `Color get chassisTextColor => isDarkMode ? const Color(0xFFE8E5DE) : const Color(0xFF1B1E23);`
- Add `Color get chassisMutedTextColor => isDarkMode ? const Color(0x99E8E5DE) : const Color(0x991B1E23);`
- Ensure every edition defines high-contrast module backgrounds with distinct separation from `canvasColor` in both dark and light modes.

### 2.2 Procedural Material Texture Rendering (`MaterialChassisBox`)
Create a performant, reusable 60fps Flutter component: `MaterialChassisBox` that wraps each instrument's chassis container:
- **Hairline Brushed Metal Painter**:
  - Renders horizontal micro-hairline striations with alternating subtle specular alpha bands (`0.03` to `0.07` opacity).
  - Anisotropic metallic sheen highlights that catch light at a 15-degree angle.
- **Burnished Brass Painter**:
  - Warm brushed golden striations overlaid with a soft radial/linear edge vignette simulating oxidized patina along the outer bevel.
- **Tubular Chrome Frame**:
  - Double-beveled metallic border with sharp specular chrome gradient highlight (`[0xFFF8F9FA, 0xFFC2C7D0, 0xFF7D8390, 0xFFF8F9FA]`).
- **Matte ABS Granular Texture**:
  - Fine micro-pebble stippling texture with crisp chamfered edge bevels.
- **Physical Elevation & Inset Borders**:
  - Multi-tier box shadows: an ambient blur shadow (blur: 14, y: 6) plus an edge highlight line, providing authentic skeuomorphic depth.

### 2.3 Comprehensive Legibility & Contrast Refactor
1. **Turntable Deck (`VinylPlayerWidget`)**:
   - `BRAUN TP-1`: Text style uses `themeState.chassisTextColor`.
   - `33 RPM` and `LO-FI RAIN`: Text style uses `themeState.chassisMutedTextColor`.
   - Track selector pill: background uses `themeState.canvasColor`, border uses `themeState.borderColor`, and text uses `themeState.chassisTextColor`.
2. **Task Dispenser (`ReceiptRunnerWidget`, `DispenserSlotHeader`, `ArchiveDrawerWidget`)**:
   - `DISPENSER: 5 MAX`: Text style uses `themeState.chassisTextColor`.
   - Pip LEDs inactive color uses `themeState.borderColor`.
   - Add button (`+` icon): Color uses `themeState.chassisTextColor`.
   - Empty queue text: Uses `themeState.chassisMutedTextColor`.
3. **Chrono Dial & Timer (`ChronoDialWidget`, `SplitFlapBoardWidget`, `CrownPushButton`)**:
   - Pill Timer (`25 MIN`, `+`, `-` buttons):
     - Background uses `themeState.moduleChassisColor`.
     - Border uses `themeState.borderColor`.
     - Text `${targetMinutes} MIN` uses `isRunning ? themeState.filamentColor : themeState.chassisTextColor`.
     - `+` and `-` button icons use `isRunning ? themeState.borderColor : themeState.chassisTextColor`.
   - Monastic focus lockdown container: Uses high-contrast styling in both dark and light modes.

---

## 3. Testing & Verification

1. **Contrast & Light Mode Verification**:
   - Unit tests verifying `chassisTextColor` and `chassisMutedTextColor` have >= 4.5:1 WCAG contrast ratio against `moduleChassisColor` in both light and dark modes.
   - Widget tests asserting all 3 instruments render with `chassisTextColor` in light mode (no `warmBone` bleached text on light backgrounds).
2. **Texture Painter Unit & Widget Tests**:
   - Test `MaterialChassisBox` renders appropriate painter based on `HardwareTextureType`.
   - Verify `shouldRepaint` handles texture type, theme changes, and list equality.
3. **Quality Gates**:
   - 0 analyzer warnings (`flutter analyze`).
   - 100% test pass rate across all suites.
