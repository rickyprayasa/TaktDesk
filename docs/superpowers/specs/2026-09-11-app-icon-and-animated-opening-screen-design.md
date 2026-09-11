# Design Spec: App Icon, RSQUARE Asset Bundling & Animated Horological Opening Sequence

**Date:** 2026-09-11  
**Feature:** Official App Icon, RSQUARE Brand Logo Bundling, and Animated Horological Boot Opening  
**Platform:** Android Mobile Console (Takt Desk, Braun / Dieter Rams Industrial Aesthetic)

---

## 1. Overview & Philosophy

Takt Desk embodies Dieter Rams' 1960s Braun modernist design principles:
- *"Gutes Design ist ehrlich"* (Good design is honest).
- *"Weniger, aber besser"* (Less, but better).
- *"Gutes Design ist unaufdringlich"* (Good design is unobtrusive).

To give Takt Desk a complete, authentic product identity on Android devices:
1. **Official Android App Launcher Icon:**
   - Replaces default Flutter template icons with the authentic circular Braun analog pomodoro dial instrument featuring a metallic knurled steel outer bezel, top 12 o'clock crown push-button, precision 60 tick marks, warm amber micro-LED, and vibrant amber chrono needle with obsidian hub cap.
2. **RSQUARE Official Brand Asset Bundling:**
   - Bundles `/home/tuneeca/RSQUARE/Android/Takt Desk/RSQUARE.png` into `assets/images/rsquare_logo.png` within Flutter assets.
   - Integrates the crisp RSQUARE geometric emblem into the Service Hatch settings dialog (`TaktSettingsSheet`), `StudioProDialog`, and the animated opening sequence.
3. **Animated Horological Opening Screen (`TaktOpeningScreen`):**
   - Implements a tactile 2.4-second procedural vector boot sequence honoring mechanical chronograph calibration:
     - Deep obsidian ignition and filament micro-LED warming up.
     - Concentric dial grooves and tick marks radial revelation.
     - RSQUARE brandmark reveal with monospace industrial lettering.
     - 360° chrono needle sweep with mechanical audio ticks and haptic feedback.
     - Seamless cross-fade handover to `DeskCanvasScreen`.
   - Built with **100% Native Flutter Canvas & Curves** (zero bloated video/Lottie dependencies, 60–120 FPS native refresh rate, 0 CPU battery drain after boot).
   - Features **Tap-to-Skip** for instantaneous entry during fast work sessions.

---

## 2. Asset Architecture & Launcher Icons

### 2.1 RSQUARE Brand Asset
- Source: `RSQUARE.png` (2000x2000 RGBA high-resolution vector emblem).
- Destination: `assets/images/rsquare_logo.png`.
- Registered in `pubspec.yaml` under `flutter.assets`:
  ```yaml
  flutter:
    uses-material-design: true
    assets:
      - assets/images/rsquare_logo.png
  ```

### 2.2 Android Launcher Mipmap Icons
Generated from the Braun Horological Squircle master graphic across all Android density buckets:
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48)
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72)
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96)
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144)
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192x192)
- High-res store graphic (512x512) and adaptive icon support (`ic_launcher_round.png`).

---

## 3. Animated Horological Opening (`TaktOpeningScreen`)

### 3.1 Choreography Timeline (Total Duration: 2400ms)

```
0ms ─── 400ms ─── 1000ms ─── 1800ms ─── 2400ms ───> Transition to DeskCanvas
 │        │          │          │          │
 ├─ Power ┴─ Bezel & ┴─ Needle  ┴─ Typo    ┴─ Crossfade
 │  LED      Dial       360°       Lockup     Handover
 │  Warmup   Expand     Sweep      Reveal
```

1. **Phase 1: Power Ignition (0 – 400ms)**
   - Background starts at deep obsidian `#121316`.
   - Micro-LED at top center pulses from 0% to 100% intensity (`#FF9E00` filament amber) with radial bloom.
   - Subtle power-relay sound (`SoundEffect.toggle`).

2. **Phase 2: Bezel & Dial Calibration (400 – 1000ms)**
   - Concentric circular dial ring expands smoothly from scale 0.85 to 1.0 (`Curves.easeOutCubic`).
   - Radial dial tick marks fade in with high contrast.
   - At the bottom of the dial, the `RSQUARE.png` emblem gently reveals with alpha 0.0 → 1.0 and a monospace subtext:
     `ENGINEERED BY RSQUARE`

3. **Phase 3: Chrono Calibration Sweep (1000 – 1800ms)**
   - The signature amber needle accelerates and sweeps a full 360° clockwise rotation (`Curves.easeInOutCubic`).
   - Accompanied by tactile haptic feedback (`HapticService.selectionClick()`) and synchronized audio tick.
   - Settles with high-precision stability at the 12 o'clock apex.

4. **Phase 4: Typographic Lockup (1800 – 2400ms)**
   - Main brandmark `TAKT DESK` reveals above the console in crisp German modernist monospace.
   - Telemetry status stamp: `STATUS: CALIBRATED // READY`.

5. **Phase 5: Seamless Handover (2400ms)**
   - Smooth `PageRouteBuilder` crossfade into `DeskCanvasScreen`.

### 3.2 Frictionless Accessibility
- **Tap-to-Skip**: The user can tap anywhere on the screen at any time to immediately cancel the animation and jump directly to `DeskCanvasScreen`.
- **Zero Memory Leak**: `AnimationController` and all tickers properly disposed on completion or skip.

---

## 4. Settings Dialog Branding Enhancements

### 4.1 `TaktSettingsSheet` (The Braun Creed & Legal Section)
- Above `Takt Desk v1.0.0 (Build 2026.09) · Developed by RSQUARE`, display the `RSQUARE.png` emblem (height: 28px, crisp scaling) with amber glow border accent.

### 4.2 `StudioProDialog`
- In the title header of `StudioProDialog`, display the `RSQUARE.png` emblem (height: 18px) next to the `'RSQUARE'` text badge.

---

## 5. Architectural Components

```
lib/
├── features/
│   ├── opening/
│   │   └── presentation/
│   │       ├── takt_opening_screen.dart       # Main boot sequence & animation coordinator
│   │       └── widgets/
│   │           ├── opening_dial_assembly.dart # Procedural vector dial & sweeping needle
│   │           └── opening_brand_stamp.dart   # RSQUARE emblem & typography reveal
│   ├── desk/presentation/desk_canvas_screen.dart
│   └── settings/presentation/
│       ├── takt_settings_sheet.dart           # Includes RSQUARE logo image
│       └── widgets/studio_pro_dialog.dart     # Includes RSQUARE logo image
assets/
└── images/
    └── rsquare_logo.png                       # Copied from RSQUARE.png
```

---

## 6. Testing & Quality Gates

1. **Unit & Widget Tests:**
   - `test/features/opening/takt_opening_screen_test.dart`:
     - Verifies initial frame renders ignition micro-LED and chassis.
     - Verifies dial and needle sweep animates smoothly across ticks.
     - Verifies `RSQUARE.png` image asset is loaded and rendered.
     - Verifies tapping screen triggers immediate skip to `DeskCanvasScreen`.
     - Verifies animation completion transitions to `DeskCanvasScreen`.
   - `test/features/settings/takt_settings_sheet_test.dart`:
     - Verifies RSQUARE emblem image widget is rendered in Creed section.
   - `test/features/settings/studio_pro_dialog_test.dart`:
     - Verifies RSQUARE emblem is rendered in Pro dialog.
2. **Quality Gates:**
   - 100% test pass rate across repository (`flutter test`).
   - 0 analyzer diagnostics (`flutter analyze`).
   - Clean namespace: 0 occurrences of `tuneeca`.
