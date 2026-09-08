# Design Spec: Takt Desk Workbench Layout, Dual VU Meter & Chassis Finish Theme

- **Date:** 2026-09-08
- **Status:** Approved
- **Target:** Flutter Android (API 24+) & Linux Desktop

---

## 1. Overview & Objectives

Following the visual and physical overhaul of the Chrono Dial, Thermal Task Runner, and Analog Vinyl Deck, this specification establishes:
1. **Modul 4 — The Analog Dual VU Meter (`AnalogVuMeterWidget` & `VuMeterPainter`)**: A 4th modular instrument housing twin backlit galvanometer needles measuring stereo audio/focus ballistics.
2. **Responsive Workbench Layout (`IsometricDeskLayout` & `DeskCanvasScreen`)**: An adaptive spatial desk rack that arranges the 4 instruments in a 2x2 Dieter Rams workbench on wide screens (desktop/tablet) and a responsive vertical stack on mobile.
3. **Chassis Finish Theme Switcher**: A physical mechanical toggle between *Braun Atelier Dark* (Obsidian/Basalt) and *Braun Audio Light* (Matte Bone/Anodized Light Grey), persisted in Drift SQLite.

---

## 2. Modul 4: The Analog Dual VU Meter

### 2.1 Mechanical Specification
- **Modular Dimensions:** Standard 280px width to align with Chrono Dial, Thermal Task Runner, and Vinyl Deck.
- **Twin Meter Gauges (Left / Right):**
  - Two dual curved bezel apertures with inner bevel shadow and warm phosphor glow.
  - Scale markings: `-20, -10, -7, -5, -3, 0 dB` in Warm Bone/Dark Grey, and `+1, +2, +3 dB` in Muted Ochre / Filament Amber overload zone.
- **Galvanometer Needles:**
  - Dual slender black needle pointers with teardrop pivot counterweights.
  - Critically damped ballistic motion with authentic needle bounce and decay.
- **Illumination:**
  - Dual warm amber backlight glow diffusing outward from the top of the gauge windows.
- **Controls & Indicators:**
  - Peak LED indicator: Twin micro LEDs in the corner that glow amber/red upon transient peaks.
  - Physical Ballistics Rocker Switch: `BALLISTICS: SLOW (VU) // FAST (PEAK)`.

### 2.2 Reactivity & Ballistic Engine (`VuMeterController`):
- Reacts to:
  - **Vinyl Deck**: Audio amplitude and stereo divergence while playing, settling to silence when lifted.
  - **Chrono Dial**: Micro-impulse tick kicks every second/minute as the timer counts down.
  - **Task Stamping**: A momentary transient surge on task completion.

---

## 3. Responsive Workbench Layout

### 3.1 Adaptive Grid (`IsometricDeskLayout`)
- **Wide Viewports (>= 680px, e.g. Linux Desktop window):**
  - Instruments arranged in a 2x2 studio workbench:
    - Top Row: Chrono Dial (Timer) & Analog Dual VU Meter.
    - Bottom Row: Thermal Task Runner (Dispenser) & Analog Vinyl Deck (Phono).
  - Anodized aluminum interconnect brackets and subtle modular bus channels connecting the chassis.
- **Narrow Viewports (< 680px, e.g. Mobile Portrait):**
  - Smooth single-column vertical flow with consistent 20px spacing.
- **Interactive Parallax:**
  - Preserves 3D isometric tilt (accelerometer/gyroscope on mobile, mouse-hover spatial tilt on desktop).

---

## 4. Chassis Finish Theme Switcher

### 4.1 Theme Definitions
- **Braun Atelier Dark (Default):**
  - Canvas: Obsidian `#141517`
  - Instrument Sasis: Basalt Slate `#24272C`
  - Faceplates: Thermal Carbon `#1F2226` / Warm Bone `#EFECE6`
- **Braun Audio Light:**
  - Canvas: Industrial Warm Grey `#DDD9D0`
  - Instrument Sasis: Anodized Light Grey `#ECE8E1`
  - Faceplates: Bone Cream `#F7F5F0` / Dark Slate `#1A1C20`

### 4.2 Switch Mechanism & Persistence:
- Hardware slide switch on top desk header: `CHASSIS: DARK // LIGHT`.
- State stored in Drift SQLite `DeskPreferencesTable` (`isDarkMode` boolean).

---

## 5. Verification & Testing Strategy
- Unit tests for `VuMeterController` ballistics (damping, vinyl reaction, timer pulse, slow/fast mode).
- Widget tests for `AnalogVuMeterWidget` rendering, painters, toggle switch, and responsive workbench layout.
- Full suite verification across all existing 73 tests ensuring zero regressions.
