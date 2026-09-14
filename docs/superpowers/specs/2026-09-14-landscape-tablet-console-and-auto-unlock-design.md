# Specification: ZYKL Dual-Pane Master Console (Tablet/Landscape Mode) & Auto-Unlock Monastic Mode

**Date:** 2026-09-14  
**Author:** AI Pair Programmer & Ricky Prayasa  
**Status:** Approved  
**Package:** `com.zykl.app`  

---

## 1. Executive Summary & Intent

This specification establishes two core system enhancements for **ZYKL**:
1. **Dual-Pane Master Console (Landscape / Tablet Mode)**:
   - When opened on an Android tablet, large screen, foldable in unfolded mode, or rotated into landscape orientation, ZYKL transitions from its single-instrument mobile view into an expansive **Braun Studio Console** inspired by Dieter Rams' *Braun Audio 310*.
   - Left Pane (~45% width): Pure horology and focus unit with the 3D Floating Glass Chrono Dial, preset cassette selectors, mechanical flip digits, and Monastic toggle.
   - Right Pane (~55% width): Split productivity and soundscape console housing both the Receipt Runner (task manager) and Vinyl Player (ambient lo-fi turntable) simultaneously without requiring tab switching.
2. **Auto-Unlock Monastic Focus Mode**:
   - When a focus pomodoro cycle naturally concludes at `00:00`, the system automatically plays the mechanical drawer latch foley, vibrates with a tactile haptic click, and disengages the Monastic Focus Lock.
   - Eliminates the friction of holding the 5-second emergency unlatch button after a full, successful focus session.
   - The 5-second hold unlatch button remains exclusively as an *Emergency Unlatch* for early aborts prior to cycle completion.
3. **Landscape Parallax & Sensor Mapping**:
   - Accelerometer gravity projection automatically remaps roll and pitch coordinates when in landscape orientation so that 3D floating glass perspective and dynamic shadows track physical tablet tilt naturally.

---

## 2. Architecture & Layout Specifications

### 2.1 Responsive Layout Breakpoint
In `lib/features/desk/presentation/desk_canvas_screen.dart`:
- Inspect screen constraints using `LayoutBuilder` and `MediaQuery.of(context)`:
  - `isLandscape = MediaQuery.of(context).orientation == Orientation.landscape || constraints.maxWidth >= 720.0`
- **Portrait Mode (`isLandscape == false`)**:
  - Preserves the existing single-column mobile console with the segmented instrument switcher (`DIAL`, `TASKS`, `VINYL`), maxWidth constraint of 440px, and single instrument displayed at a time.
- **Landscape / Tablet Mode (`isLandscape == true`)**:
  - Renders `MasterConsoleLandscapeLayout`:
    - Full-width top bar: Minimalist `ZYKL` header, live status indicator LED, theme switcher (`Obsidian`/`Warm Bone`), and settings rivet button.
    - Two-column master studio console:
      - **Left Column (`Flex: 45` or fixed 380–420px)**:
        - Vertically centered `ChronoDialWidget` (including crown push button, circular dial face, cassette profile selector, flip counter).
        - Embedded Monastic Focus toggle switch at the top-left of the left column.
        - Bottom dock of left column: Emergency Unlatch button (visible only when locked).
      - **Right Column (`Flex: 55` or expanded)**:
        - SingleChildScrollView or vertical dual-chassis rack containing:
          - `ReceiptRunnerWidget` (Top module: 5-task dot-matrix receipt runner with tear-off and telemetry).
          - Padding / divider.
          - `VinylPlayerWidget` (Bottom module: 360° rotating turntable, tonearm, stylus foley, and ambient soundscape selection).
    - Bottom bar: Centered `DeskSpecPlateWidget`.

---

## 3. Auto-Unlock Monastic Focus Mechanism

### 3.1 State Flow
1. User flips the Monastic Switch (`engageLock()`). `PopScope.canPop` is set to `false`.
2. Pomodoro countdown is active in `ChronoDialController`.
3. Countdown reaches `nextRemaining <= 0` during `PomodoroPhase.focus`:
   - `_audioService.playFoley(SoundEffect.bellChime)` plays the physical brass chime.
   - `HapticService.mechanicalPress()` delivers physical feedback.
   - Database records the completed session.
   - **Auto-Unlock Trigger**: If `ref.read(focusLockProvider).isLocked` is true:
     - Calls `ref.read(focusLockProvider.notifier).completeUnlock()`.
     - `completeUnlock()` triggers `SoundEffect.drawerLatch` and `HapticService.heavyClick()`.
     - Monastic state transitions: `isLocked = false`, `isHolding = false`, `unlockProgress = 0.0`.
     - `MonasticSwitchWidget` physically clicks to the OFF position.
     - `PopScope.canPop` immediately returns to `true`.
4. If the timer is stopped or paused early:
   - Monastic lock remains locked. The user must use the 5-second hold `EmergencyUnlatchWidget` to exit early.

---

## 4. Landscape Sensor & Parallax Coordination

### 4.1 Coordinate Remapping
In `lib/core/sensors/parallax_controller.dart` or `lib/features/desk/presentation/desk_canvas_screen.dart`:
- When in `Orientation.landscape`:
  - Tilting the tablet left/right corresponds to the device's physical Y or X axis depending on landscape rotation (`landscapeLeft` vs `landscapeRight`).
  - `updateTiltFromAccelerometer(x, y, z, isLandscape: true)` smoothly translates the gravity vector so tiltX tracks horizontal tablet tilt and tiltY tracks vertical tablet tilt.
- Floating Glass surface specular sheen (`GlassRimPainter`) and dynamic shadow offsets shift seamlessly with the tablet's physical orientation.

---

## 5. Non-Functional Constraints & Integrity

1. **Aesthetic Compliance**:
   - Strictly adhere to Dieter Rams / Braun modernist industrial aesthetics (honest materials, uncluttered typography, amber accent `#FF9E00`).
2. **Battery & Performance**:
   - Zero CPU wakeups when idle.
   - Maintain 60–120fps fluid needle and vinyl animations.
3. **Clean Namespace**:
   - Absolutely zero occurrences of `tuneeca` across all files, code comments, and metadata.
4. **Verification Gates**:
   - 100% test pass rate across all existing and new unit/widget tests (`flutter test`).
   - 0 static analyzer issues (`flutter analyze`).
   - Build production release APK and copy to `/home/tuneeca/RSQUARE/ZYKL_Release.apk` and `/home/tuneeca/RSQUARE/Takt_Desk_Release.apk`.
