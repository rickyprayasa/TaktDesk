# Chrono Dial Custom Cycle Calibration Wizard & Precision Settings Layout Design

## Overview
This specification defines the interactive on-instrument Pomodoro calibration wizard for custom cycles and the layout precision fix for the settings interval engine.
Users can configure all 4 Pomodoro cycle stages (Focus duration, Short break, Long break, and Cycle count) directly from the physical Chrono Dial interface using the rotary bezel and crown push-button, while the Service Hatch settings sheet provides pixel-perfect aligned steppers that never wrap or drop below labels.

---

## 1. Problem Statement & User Experience Goals

### 1.1 Chrono Dial Calibration Wizard
- **Current Limitation:** To customize Pomodoro durations, users had to open the Service Hatch Settings sheet and press tiny `+` and `-` buttons.
- **Desired Interaction (Dieter Rams / Braun physical instrument design):**
  - When activating or tuning `CUSTOM`, users can program the timer directly from the main hardware dial.
  - The telemetry plaque (`STANDBY // READY`) transforms into an interactive step-by-step calibration guide (`SET 1/4 // FOCUS`, `SET 2/4 // SHORT BRK`, `SET 3/4 // LONG BRK`, `SET 4/4 // CYCLES`).
  - Rotating the analog dial dynamically sets the duration for that stage.
  - Pressing the 12 o'clock Crown push-button commits the value for that stage and advances to the next.
  - Once all 4 stages are programmed, the telemetry plaque returns to `STANDBY // READY`. Pressing the crown then immediately launches the focus session.
  - **Quick-Use Support (Approach 2):** Single-tapping `[ CUSTOM ]` when in standard mode switches to the saved custom profile without forcing a recalibration. Long-pressing `[ CUSTOM ]` or tapping `[ CUSTOM ]` while already selected initiates the Calibration Wizard.

### 1.2 Settings Sheet Interval Layout Precision Fix
- **Current Defect (from user screenshot):**
  - `_buildStepperRow` in `_PomodoroIntervalEngineSection` uses a `Wrap` container.
  - For rows with longer subtitles (`LONG BREAK` and `CYCLE COUNT`), the stepper controls (`[-] 15 MIN [+]` and `[-] 4 CYCLES [+]`) wrap down to a second line.
  - The section headers (`POMODORO INTERVAL ENGI...` and `SYSTEM CLEARANCE & LOC...`) truncate with ellipses due to overly restrictive `Flexible` constraints.
- **Fix:**
  - Convert `_buildStepperRow` to an unyielding horizontal `Row`: `Expanded` column on the left (title and 1-line ellipsis subtitle) and fixed-width stepper controls on the right.
  - Ensure the value label container has adequate fixed width (68dp) so values like `4 CYCLES` and `25 MIN` fit without line breaks.
  - Fix section header constraints so headers render cleanly without truncation.

---

## 2. Architecture & Domain Model

### 2.1 Setup State Machine (`ChronoSetupStage`)
In `lib/features/timer/domain/timer_state.dart`:
```dart
enum ChronoSetupStage {
  none,
  focus,
  shortBreak,
  longBreak,
  cycleCount;

  bool get isActive => this != ChronoSetupStage.none;

  String get telemetryLabel {
    switch (this) {
      case ChronoSetupStage.none:
        return 'STANDBY // READY';
      case ChronoSetupStage.focus:
        return 'SET 1/4 // FOCUS';
      case ChronoSetupStage.shortBreak:
        return 'SET 2/4 // SHORT BRK';
      case ChronoSetupStage.longBreak:
        return 'SET 3/4 // LONG BRK';
      case ChronoSetupStage.cycleCount:
        return 'SET 4/4 // CYCLES';
    }
  }
}
```

### 2.2 `TimerState` Enhancements
Add `setupStage: ChronoSetupStage` (default `ChronoSetupStage.none`):
```dart
class TimerState {
  ...
  final ChronoSetupStage setupStage;
  ...
}
```

### 2.3 `ChronoDialController` Interaction Flow
1. `enterCustomCalibration()`:
   - Sets `setupStage: ChronoSetupStage.focus`.
   - Sets `profile` to `customProfile`.
   - Sets `targetMinutes` to `customProfile.focusMinutes`, `remainingSeconds` to `customProfile.focusMinutes * 60.0`.
   - Foley sound: `SoundEffect.drawerLatchOpen` or `dialClick`.
   - Haptic: `HapticService.selectionClick()`.
2. Rotary dial adjustment while `setupStage.isActive`:
   - Rotary pan updates the current stage's parameter:
     - `focus`: 1 to 90 min.
     - `shortBreak`: 1 to 30 min.
     - `longBreak`: 1 to 45 min.
     - `cycleCount`: 2 to 8 cycles.
   - Needle angle and digital counter reflect the live value.
3. Crown push-button / Dial tap while `setupStage.isActive`:
   - `advanceCalibrationStage()`:
     - `focus` -> saves `focusMinutes`, transitions to `shortBreak`, updates dial to `customProfile.shortBreakMinutes`.
     - `shortBreak` -> saves `shortBreakMinutes`, transitions to `longBreak`, updates dial to `customProfile.longBreakMinutes`.
     - `longBreak` -> saves `longBreakMinutes`, transitions to `cycleCount`, updates dial to `customProfile.longBreakInterval`.
     - `cycleCount` -> saves `longBreakInterval`, transitions to `none`.
     - On exit to `none`: sets `phase: PomodoroPhase.focus`, `targetMinutes: customProfile.focusMinutes`, `remainingSeconds: customProfile.focusMinutes * 60.0`. Status plaque displays `STANDBY // READY`.
     - Haptics: mechanical haptic tick on each advance, solid mechanical press on completion.
4. `cancelCalibration()`:
   - If user taps status plaque or another preset cassette, cancels setup and restores standard standby.

---

## 3. Visual & UI Implementation

### 3.1 ChronoProfileSelectorWidget Integration
- Status plaque text:
  If `timerState.setupStage.isActive`: displays `timerState.setupStage.telemetryLabel` with amber accent.
  Tapping the plaque while calibrating exits calibration back to `STANDBY // READY`.
- Preset Cassette `[ CUSTOM ]` button:
  - Tapping when not on Custom: switches to Custom in `STANDBY // READY`.
  - Long-pressing, or tapping while already active on Custom: triggers `enterCustomCalibration()`.

### 3.2 ChronoDialWidget Integration
- When `setupStage.isActive`:
  - Rotary pan adjusts the specific stage's duration rather than a running timer.
  - Tapping the Crown button or center dial invokes `advanceCalibrationStage()`.
  - When not calibrating, Crown button retains standard Start/Pause functionality.

### 3.3 TaktSettingsSheet Precision Layout
- Replace `Wrap` in `_buildStepperRow` with `Row(crossAxisAlignment: CrossAxisAlignment.center)`.
- Wrap label column in `Expanded`.
- Add fixed-width `Container(width: 68)` for stepper value text.
- Ensure all subtitles fit within single line with `maxLines: 1, overflow: TextOverflow.ellipsis`.
- Section headers: maintain natural title width without premature ellipsis truncation.

---

## 4. Testing & Verification Plan
1. Unit tests for `ChronoSetupStage` transitions and clamping across all 4 stages.
2. Unit tests for `ChronoDialController`:
   - `enterCustomCalibration()` initializes stage to `focus`.
   - Dial panning during setup updates stage durations.
   - Crown press commits each stage and cycles through `focus` -> `shortBreak` -> `longBreak` -> `cycleCount` -> `none`.
   - Crown press after completion starts timer normally.
3. Widget tests for `ChronoDialWidget` and `ChronoProfileSelectorWidget`:
   - Plaque displays `SET 1/4 // FOCUS`, `SET 2/4 // SHORT BRK`, etc.
   - Long press on `CUSTOM` enters wizard.
4. Widget tests for `TaktSettingsSheet`:
   - Verifies 4 stepper rows remain strictly single-row without wrapping.
5. Purity verification: 0 `tuneeca` occurrences.
6. Full test suite run (`flutter test` 100% pass) and static analysis (`flutter analyze` 0 issues).
7. Rebuild production release APK.
