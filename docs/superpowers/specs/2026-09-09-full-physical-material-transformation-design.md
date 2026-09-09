# Takt Desk: Full Physical Material Transformation & Gallery Navigation Specification

**Date:** 2026-09-09  
**Platform Target:** Mobile Android (maxWidth 440px handheld console)  
**Status:** Approved for Implementation  
**Design Philosophy:** Dieter Rams & Braun Modernist Industrial Aesthetic (*Weniger, aber besser*)

---

## 1. Overview & Problem Statement

In the initial implementation of the Hardware Material Editions feature, the domain models, Drift schema persistence, and accent colors (analog needle, filament glow, spec plate, canvas background) were established. However, real-world user inspection identified two UX and aesthetic gaps:

1. **Gallery Discoverability Gap**: In the Service Hatch (`TaktSettingsSheet`), the 4 edition cards were arranged in a horizontal row without scroll indicators or pagination controls. Because two 180px cards span the full viewport of a typical mobile screen (~390-400px), editions 3 and 4 (*Bauhaus Heritage* and *Raw Brass & Patina*) were pushed off-screen, creating the impression that only 2 editions existed.
2. **Physical Instrument Sasis Theming Gap**: While the dial needle and vacuum tube filament changed color, the physical hardware chassis of the 3 instruments (the Chrono Dial outer bezel & crown, the Ticket Dispenser casing, and the Vinyl Player deck & tonearm) remained hardcoded to default dark charcoal (`basaltSlate` and `slateBorder`), diluting the visual impact of equipping premium finishes like *Raw Brass & Patina* or *Bauhaus Heritage*.

This specification defines the full physical material transformation of all three instruments and introduces tactile mechanical gallery navigation in the Service Hatch.

---

## 2. Service Hatch Gallery Navigation Design

### 2.1 Mechanical Header Controls & Counter
- Beside the section title `HARDWARE EDITIONS // CHASSIS MATERIALITY`, add:
  - Counter badge: `[ 01 / 04 ]` (monospace 9.5pt, bold, high contrast).
  - Tactile micro navigation buttons: `◀` (`Key('edition_prev_button')`) and `▶` (`Key('edition_next_button')`).
  - Buttons trigger `HapticService.selectionClick()` and smoothly animate the carousel to the previous/next card.
  - Left arrow is disabled when on page 1; right arrow is disabled when on page 4.

### 2.2 Carousel with Snapping & Edge Peek
- Replace unconstrained `SingleChildScrollView(Row(...))` with a controlled `PageView.builder` or `ScrollController` with explicit card width and viewport fraction (~0.82) to allow adjacent card edges to peek into view (~30-40px peek margin).
- Page snapping ensures cards lock firmly into focus when swiped.

### 2.3 Page Indicator Dots
- Below the carousel, render a 4-dot status bar:
  - 4 circular LED dots (`ValueKey('edition_dot_$index')`), 5px diameter.
  - Active dot is illuminated in `themeState.filamentColor` with a subtle glow shadow; inactive dots are muted slate.

---

## 3. Full Physical Material Transformation Architecture

### 3.1 Chrono Dial & Crown (`ChronoDialWidget`, `ChronoDialPainter`, `CrownPushButton`, `SplitFlapBoardWidget`)
1. **Outer Bezel Ring**:
   - In `ChronoDialPainter`, replace hardcoded charcoal radial gradient with `isDark ? edition.plateGradientDark : edition.plateGradientLight`.
   - Update inner bezel stepped stroke to use `themeState.borderColor`.
   - Outer chamfer rim reflects metallic tones:
     - *Braun Classic*: Deep atelier charcoal / obsidian rim.
     - *Titanium Stealth*: Gunmetal aerospace PVD titanium rim.
     - *Bauhaus Heritage*: Polished tubular chrome steel rim (`0xFFB0B5BF` to `0xFF7D828E`).
     - *Raw Brass & Patina*: Burnished marine brass rim (`0xFFD4AF37` to `0xFF8A6D2B`).
2. **Crown Stopwatch Push-Button (`CrownPushButton`)**:
   - Top knurled cap gradient dynamically uses `edition.plateGradientDark`/`plateGradientLight`.
   - Cap border uses `themeState.borderColor`.
   - Stem collar uses `themeState.moduleChassisColor`.
3. **Split-Flap Board Frame (`SplitFlapBoardWidget`)**:
   - Container background adopts `themeState.moduleChassisColor`.
   - Container border adopts `themeState.borderColor`.
4. **Pill Timer Box (`ChronoDialWidget`)**:
   - Container background adopts `themeState.moduleChassisColor`.
   - Border adopts `themeState.borderColor`.

### 3.2 Receipt Task Dispenser (`ReceiptRunnerWidget`, `DispenserSlotHeader`, `ArchiveDrawerWidget`)
1. **Dispenser Chassis Casing**:
   - Replace hardcoded `TaktColors.basaltSlate` and `slateBorder` with `themeState.moduleChassisColor` and `themeState.borderColor`.
2. **Corner Rivet Accents**:
   - Add 4 corner mechanical rivet dots to `ReceiptRunnerWidget` matching `isDark ? edition.rivetDark : edition.rivetLight`.
3. **Aperture Slit & Slot Header**:
   - Slit rim and capacity indicator frame adapt to `themeState.borderColor`.
4. **Archive Drawer Plate (`ArchiveDrawerWidget`)**:
   - Metal pull handle and faceplate adapt to `edition.plateGradientDark`/`Light` and `themeState.borderColor`.
   - Drawer rivet accents match edition rivets.

### 3.3 Vinyl Player Deck (`VinylPlayerWidget`, `VinylDeckPainter`)
1. **Deck Chassis Body**:
   - Replace hardcoded `TaktColors.basaltSlate` with `themeState.moduleChassisColor` and `themeState.borderColor`.
   - Add 4 corner mechanical rivet accents matching `isDark ? edition.rivetDark : edition.rivetLight`.
2. **Tonearm & Headshell Assembly**:
   - In `VinylDeckPainter`, tonearm shaft and gimbal pivot adapt to edition metallurgy:
     - *Braun Classic*: Neutral matte steel / silver tonearm.
     - *Titanium Stealth*: Electric cobalt cyan / dark titanium tonearm.
     - *Bauhaus Heritage*: Polished tubular chrome steel tonearm.
     - *Raw Brass & Patina*: Burnished gold brass tonearm.
3. **Center Record Label**:
   - Center circular label background adapts to `edition.accentColor` (instead of static orange `0xFFD97736`).

---

## 4. Testing & Verification

1. **Widget Tests**:
   - `test/features/settings/takt_settings_sheet_test.dart`:
     - Test arrow buttons `edition_prev_button` and `edition_next_button` update carousel page and counter `[ 01 / 04 ]`.
     - Test indicator dots update when carousel page changes.
     - Test all 4 cards are navigable and selectable.
   - `test/features/timer/chrono_dial_widget_test.dart`:
     - Test outer bezel paint gradient and crown metallurgy adapt to active edition.
     - Test split-flap board and pill timer border adapt to active edition.
   - `test/features/tasks/receipt_runner_widget_test.dart`:
     - Test dispenser chassis background, border, and corner rivets adapt to active edition.
   - `test/features/vinyl/vinyl_player_widget_test.dart`:
     - Test deck chassis background, border, corner rivets, and center label color adapt to active edition.
2. **Quality Gates**:
   - `flutter analyze`: 0 issues.
   - `flutter test`: 100% pass across repository.
