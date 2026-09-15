# Specification: Mechanical Pull Crown Calibration & Telemetry Guidance

**Status:** APPROVED  
**Date:** 2026-09-15  
**Domain:** Timer / Hardware Presentation / UI Ergonomics  
**Style & Philosophy:** Braun / Dieter Rams Industrial Design, Analog Horological Tactility  

---

## 1. Overview & Objectives

In mechanical chronographs and analog luxury instruments, setting the time is performed by pulling the crown outward away from the case (Position 1 / "Hacking" state), exposing the cylindrical winding stem, which disengages the balance wheel and enables rotary calibration.

This specification defines the implementation of a physical **Mechanical Pull Crown** interaction and contextual **Telemetry Status Guidance** on the ZYKL analog Pomodoro watch:
1. **Physical Pull Gesture:** Swiping/dragging upward on the 12 o'clock crown button pulls the crown outward, physically elevating the knurled cap by 6px with a spring-snap animation, exposing a polished metallic stem collar with authentic mechanical foley audio (`SoundEffect.drawerLatch`) and tactile detent (`HapticService.selectionClick`).
2. **Contextual Telemetry Status:** When the `CUSTOM` cassette profile is selected and the timer is idle, the upper status plaque immediately displays **`PULL CROWN // SET`** in horological amber (`TaktColors.filamentAmber`), guiding the user clearly without cluttering the interface.
3. **Seamless Stage Advance & Lock:** Tapping the pulled-out crown sequentially advances through the 4 calibration stages (`SET 1/4 // FOCUS` $\rightarrow$ `SET 2/4 // SHORT BRK` $\rightarrow$ `SET 3/4 // LONG BRK` $\rightarrow$ `SET 4/4 // CYCLES`). Upon completing stage 4, the crown mechanically snaps back flush with the bezel (`SoundEffect.springButton`), and the timer enters ready mode.
4. **Push to Cancel:** Swiping downward on the pulled-out crown (or tapping the status plaque) pushes the crown back into the case, cancelling calibration and returning to `PULL CROWN // SET`.

---

## 2. Component Architecture & Visual Specifications

### 2.1. `CrownPushButton` Mechanical Enhancement
[`lib/features/timer/presentation/widgets/crown_push_button.dart`](file:///home/tuneeca/RSQUARE/Android/Takt%20Desk/lib/features/timer/presentation/widgets/crown_push_button.dart)

#### Properties & Parameters:
- `isPressed` (`bool`): Indicates timer is running (slight downward compression, 2px).
- `isPulledOut` (`bool`): Indicates calibration mode is active (upward extension, -6px).
- `onTap` (`VoidCallback`): Triggered when tapped.
- `onPullOut` (`VoidCallback?`): Triggered when dragged upward ($\Delta y < -8\text{px}$).
- `onPushIn` (`VoidCallback?`): Triggered when dragged downward ($\Delta y > 8\text{px}$).

#### Layout & Visual Layers:
The widget bounding box expands from `height: 16` to `height: 24` to accommodate the 6px upward travel without clipping:
1. **Stem Collar & Exposed Polished Shaft:**
   - Base collar seated at `bottom: 0`, `width: 14`, `height: 4`.
   - When `isPulledOut` is true, an animated shaft container expands upward (`height: 10px`, `width: 8px`) rendered with a metallic gradient (specular highlight: `#D8DCE2` center with darker brushed borders `#4A4E56`).
2. **Knurled Crown Cap:**
   - Width: `32px`, Height: `12px`, with 5 vertical knurling grooves.
   - Positioned animatedly via `_pullAnimation` (interpolating from `top: 6px` when normal to `top: 0px` when pulled out) and `_pressAnimation` (offset downward when pressed).
   - Easing curve: `Curves.easeOutBack` (160ms) providing a subtle physical mechanical rebound.

#### Gesture Mechanics:
- `GestureDetector`:
  - `onVerticalDragUpdate` / `onPanUpdate`: Accumulates vertical delta $\Delta y$.
    - If `!isPulledOut && dy < -8`: triggers `onPullOut()`.
    - If `isPulledOut && dy > 8`: triggers `onPushIn()`.
  - `onTap`: Calls `onTap()`.

---

### 2.2. Telemetry Status Plaque Logic
[`lib/features/timer/presentation/widgets/chrono_profile_selector_widget.dart`](file:///home/tuneeca/RSQUARE/Android/Takt%20Desk/lib/features/timer/presentation/widgets/chrono_profile_selector_widget.dart)

The plaque text string and color are determined as follows:
```dart
final String plaqueText;
final Color plaqueColor;

if (timerState.setupStage.isActive) {
  plaqueText = timerState.setupStage.telemetryLabel; // 'SET 1/4 // FOCUS', etc.
  plaqueColor = TaktColors.filamentAmber;
} else if (timerState.isRunning) {
  plaqueText = 'RUNNING // SEC-ROLL';
  plaqueColor = TaktColors.filamentAmber;
} else if (timerState.profile.type == PomodoroProfileType.custom) {
  plaqueText = 'PULL CROWN // SET';
  plaqueColor = TaktColors.filamentAmber;
} else {
  plaqueText = 'STANDBY // READY';
  plaqueColor = textColor;
}
```

---

### 2.3. Controller & Presentation Integration
[`lib/features/timer/presentation/chrono_dial_widget.dart`](file:///home/tuneeca/RSQUARE/Android/Takt%20Desk/lib/features/timer/presentation/chrono_dial_widget.dart)

1. **Crown Wiring in `ChronoDialWidget`:**
   ```dart
   CrownPushButton(
     isPressed: state.isRunning,
     isPulledOut: state.setupStage.isActive,
     onTap: _handleToggle,
     onPullOut: () {
       if (state.isRunning) return;
       ref.read(chronoDialProvider.notifier).enterCustomCalibration();
     },
     onPushIn: () {
       if (state.setupStage.isActive) {
         ref.read(chronoDialProvider.notifier).cancelCalibration();
       }
     },
     gradientColors: themeState.plateGradient,
     borderColor: themeState.borderColor,
     stemColor: themeState.moduleChassisColor,
   )
   ```
2. **Audio & Foley Mapping:**
   - Entering calibration (`enterCustomCalibration`): plays `SoundEffect.drawerLatch` and triggers `HapticService.selectionClick`.
   - Advancing stage: plays `SoundEffect.dialClick` and triggers `HapticService.dialTick`.
   - Exiting/Locking calibration (`cancelCalibration` or final stage completion): plays `SoundEffect.springButton` and triggers `HapticService.mechanicalPress`.

---

## 3. Edge Cases & Defensive Invariants

1. **Timer Running Protection:**
   - If `state.isRunning == true`, `onPullOut` is strictly a no-op to prevent calibration while time is elapsing.
2. **Profile Auto-Switching:**
   - If the user pulls the crown while another profile (e.g. `CLASSIC 25`) is selected, `enterCustomCalibration()` automatically sets the profile to `custom` and starts stage 1 calibration.
3. **Boundary Tap Protection:**
   - Tapping the dial face while crown is pulled out continues to advance calibration stage, while tapping the crown button also advances stage or pushes it in when complete.
4. **Touch Target Sizing:**
   - The touch area for `CrownPushButton` is padded with `HitTestBehavior.opaque` ensuring swiping or tapping the top crown is effortless even on compact screens.

---

## 4. Test Strategy

1. **Widget Tests in `crown_push_button_test.dart`:**
   - Verify `CrownPushButton` renders in default state with stem collar hidden/flush.
   - Verify setting `isPulledOut: true` elevates crown cap and reveals extended metallic stem shaft.
   - Verify upward drag gesture ($\Delta y < -8$) invokes `onPullOut`.
   - Verify downward drag gesture ($\Delta y > 8$) invokes `onPushIn`.
   - Verify tap gesture invokes `onTap`.
2. **Widget Tests in `chrono_dial_widget_test.dart`:**
   - Verify dragging crown upward enters `ChronoSetupStage.focus`.
   - Verify dragging crown downward during calibration calls `cancelCalibration()`.
   - Verify tapping crown advances through all 4 stages and snaps back.
3. **Widget Tests in `chrono_profile_selector_widget_test.dart`:**
   - Verify status plaque displays `PULL CROWN // SET` in amber when `custom` profile is idle.
   - Verify status plaque displays `STANDBY // READY` in default text color when `classic` profile is idle.
   - Verify status plaque displays `SET 1/4 // FOCUS` when calibration is active.
