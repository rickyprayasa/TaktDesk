# Floating Glass 3D Metamaterial Depth & Vinyl Deck Simplification Design

**Date:** 2026-09-14  
**Status:** Approved  
**Author:** Pair Programming (Google DeepMind Antigravity & User)  
**Target Platform:** Android (Flutter 3.x, Sensors Plus, Riverpod, Drift SQLite)

---

## 1. Overview & Objectives

This specification defines two coordinated architectural changes for Takt Desk:
1. **Vinyl Deck Simplification:** Complete removal of the multi-fader Soundscape Mixer console (`TurntableMixerStrip` and related UI/state bindings) from the Vinyl player screen, restoring Dieter Rams' pure, uncluttered Braun TP-1 industrial design. All organic studio audio recordings, the tactile "Load to Platter" foley sound effect, silent opening screen, and soft drawer latch click foleys are strictly preserved.
2. **Floating Glass 3D Metamaterial Depth Engine:** Implementation of an authentic optical Liquid Glass depth simulation across the physical instrument chassis (Pomodoro Dial, Tasks Batch, and Vinyl Deck). Inspired by modern next-generation mobile interfaces (such as Apple Liquid Glass / iOS metamaterial concepts), the chassis panels will physically float in 3D perspective space with real-time gyroscopic rim specular caustic glares, frosted refraction, and multi-depth parallax shadow casting.

---

## 2. Part 1: Vinyl Deck Simplification

### 2.1 Scope of Removals
- Remove `TurntableMixerStrip` component from `lib/features/vinyl/presentation/widgets/turntable_mixer_strip.dart` and unmount it from `lib/features/vinyl/presentation/vinyl_player_widget.dart`.
- Clean up unused mixer controller bindings in `VinylPlayerWidget` and `VinylController`.
- In `MainActivity.kt`, streamline ambient playback to the primary high-fidelity vinyl loop player, retaining the safe asset file descriptor handling (`openFd().use { ... }`) and defensive lifecycle teardown.
- In `DeskPreferences`, keep database migration v3 columns backwards-compatible to prevent migration rollbacks.

### 2.2 Preserved Audio & Foley Behaviors
- `SoundEffect.discLoad`: Plays `foley_disc_load.wav` when user selects or loads a record to the platter.
- `SoundEffect.dialClick` and `SoundEffect.switchClick`: Play the warm, damped `foley_drawer_latch.wav` (soft drawer closure).
- Silent opening screen: [TaktOpeningScreen](file:///home/tuneeca/RSQUARE/Android/Takt%20Desk/lib/features/opening/presentation/takt_opening_screen.dart) remains completely free of ticking noises, retaining only the smooth RSQUARE brand animation and subtle tactile haptics.
- Vinyl soundscape audio: The 8 curated 44.1kHz focus tracks (Lo-fi Rain, Brown Noise, Deep Library, Cafe, Campfire, Forest Wind, Cosmic Drone, Night Train) remain playable with needle drop/lift mechanics.

---

## 3. Part 2: Floating Glass 3D Metamaterial Depth Engine

### 3.1 Architectural Principles: Three-Layer Metamaterial
The Floating Glass visual model operates across three distinct compositing layers:

```
┌────────────────────────────────────────────────────────────────────────┐
│ 1. HIGHLIGHT LAYER (Specular Rim Caustic Sweep)                        │
│    - Renders dynamic edge caustics on the convex glass perimeter       │
│    - Glare position dynamically tracks the computed virtual light      │
│      vector based on device gyroscope pitch and roll                   │
├────────────────────────────────────────────────────────────────────────┤
│ 2. GLASS LAYER (Refractive Bevel & Frosted Backdrop)                  │
│    - Dual-tone machined glass bevel: illuminated upper edge and        │
│      internally refracted shadowed lower edge                          │
│    - Translucent backdrop blur (sigma 12.0) interacting with active    │
│      hardware edition finishes (Obsidian, Cream, Titanium, Walnut)     │
├────────────────────────────────────────────────────────────────────────┤
│ 3. DEPTH PERSPECTIVE LAYER (Matrix4 3D Parallax & Floating Shadow)     │
│    - Perspective projection matrix (setEntry(3, 2, 0.0012))            │
│    - Counter-projected dynamic drop shadow (Z = -18px)                 │
│    - Forward floating instrument controls and typography (Z = +6px)    │
└────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Sensor Pipeline & Virtual Light Vector
- **Controller:** Extend `ParallaxController` (`lib/core/motion/parallax_controller.dart`).
- **Input:** Continuous accelerometer/gyroscope streams from `sensors_plus`.
- **Smoothing:** Double-buffered low-pass filter with spring-damper interpolation:
  $$\text{pitch}_{t} = \text{pitch}_{t-1} + (\text{targetPitch} - \text{pitch}_{t-1}) \times \alpha$$
  $$\text{roll}_{t} = \text{roll}_{t-1} + (\text{targetRoll} - \text{roll}_{t-1}) \times \alpha$$
  where $\alpha = 0.15$ ensures buttery-smooth response without jitter or micro-tremors.
- **Normalized Light Vector:**
  $$\vec{L} = \left( -\sin(\text{roll}), -\sin(\text{pitch}), \cos(\text{roll})\cos(\text{pitch}) \right)$$
  The 2D projection $(L_x, L_y)$ defines the angle and intensity of the specular rim caustic sweep.

### 3.3 Specular Rim Painter (`GlassRimPainter`)
- Rendered on top of the chassis boundary using a custom `CustomPainter`.
- Computes the tangential contact point of $\vec{L}$ against the `RRect` rounded rectangle corner radius ($R = 12.0\text{ px}$).
- Draws a dual-stop highlight gradient:
  - **Leading edge (facing $\vec{L}$):** `Colors.white.withOpacity(0.55)` to `Colors.white.withOpacity(0.0)`.
  - **Trailing edge (opposite $\vec{L}$):** `TaktColors.filamentAmber.withOpacity(0.12)` subtle warm chromatic refraction line.
- Edge thickness: $1.2\text{ px}$ hairline stroke with `MaskFilter.blur(BlurStyle.solid, 0.5)` for authentic sub-millimeter glass refraction.

### 3.4 3D Perspective Matrix & Multi-Depth Parallax
- The chassis container is wrapped in a `Transform` widget using perspective projection:
  ```dart
  final transform = Matrix4.identity()
    ..setEntry(3, 2, 0.0012) // Realistic focal length
    ..rotateX(-smoothedPitch)
    ..rotateY(smoothedRoll);
  ```
- **Z-Axis Separation:**
  1. **Floating Drop Shadow ($Z = -18\text{ px}$):** Casts opposite to tilt:
     `Offset(-roll * 20.0, -pitch * 20.0)` with Gaussian blur radius `28.0` and spread `-2.0`.
  2. **Chassis Body ($Z = 0\text{ px}$):** Frosted glass container with hardware edition texture and perimeter bevel.
  3. **Floating Dial / Controls ($Z = +6\text{ px}$):** Translated by `Offset(roll * 6.0, pitch * 6.0)`, giving the optical illusion that the chronometer dial, rolling counter, and vinyl record sit in a raised plane above the chassis baseplate.

### 3.5 Battery & Performance Efficiency
- **Power Optimization:** When `parallaxEnabled == false` (configured in Settings Sheet or if sensor unavailable), matrix rotation is clamped to zero, sensor event subscriptions are paused, and rendering falls back to high-performance static glass styling (0 CPU/GPU overhead).
- **Repaint Boundaries:** The glass chassis and dynamic specular painters are isolated within `RepaintBoundary` widgets to prevent cascading layout passes down the Flutter render tree.

---

## 4. Quality & Verification Gates

1. **Unit & Widget Tests:**
   - Verify `ParallaxController` sensor stream handling and light vector calculation.
   - Verify `VinylPlayerWidget` renders clean deck with no mixer components and exactly 41/41 passing vinyl feature tests.
   - Verify `GlassRimPainter` draws proper specular caustics based on light vector input.
   - Verify full test suite (300+ tests passing 100%).
2. **Static Analysis:**
   - Zero issues in `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`.
3. **Clean Namespace:**
   - Zero occurrences of `tuneeca` across the repository.
4. **Production Build:**
   - Successful release APK compilation: `/home/tuneeca/RSQUARE/Takt_Desk_Release.apk`.
