# Chrono Dial Custom Calibration Wizard & Settings Layout Precision Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the physical Chrono Dial step-by-step calibration wizard for custom Pomodoro cycles directly from the analog dial and crown button, while fixing the Service Hatch interval stepper layout to prevent text and button wrapping.

**Architecture:** Extend `TimerState` with a `ChronoSetupStage` state machine (`none`, `focus`, `shortBreak`, `longBreak`, `cycleCount`). Wire `ChronoDialController` to calibrate durations via bezel rotation and crown presses. Update `ChronoProfileSelectorWidget` and `ChronoDialWidget` to handle calibration modes, and refactor `TaktSettingsSheet` stepper rows from `Wrap` to a rigid `Row` + `Expanded` layout.

**Tech Stack:** Flutter, Riverpod, Dart, Drift, Dieter Rams / Braun design aesthetics.

## Global Constraints
- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetics (honest materials, uncluttered typography, amber accent #FF9E00).
- Clean namespace: Absolutely 0 occurrences of tuneeca across Kotlin, Dart, XML, and Gradle files (com.takt.desk / com.zykl.app).
- 0 analyzer issues (/home/tuneeca/RSQUARE/flutter/bin/flutter analyze).
- 100% test pass rate across repository (/home/tuneeca/RSQUARE/flutter/bin/flutter test).
- Deliver release APK to `/home/tuneeca/RSQUARE/ZYKL_Release.apk` and `/home/tuneeca/RSQUARE/Takt_Desk_Release.apk`.

---

### Task 1: Domain State Model & ChronoDialController Calibration State Machine

**Files:**
- Modify: `lib/features/timer/domain/timer_state.dart`
- Modify: `lib/features/timer/presentation/chrono_dial_controller.dart`
- Test: `test/features/timer/chrono_dial_controller_test.dart`

**Interfaces:**
- Consumes: `PomodoroProfile`, `PomodoroPhase`
- Produces: `ChronoSetupStage`, `enterCustomCalibration()`, `advanceCalibrationStage()`, `cancelCalibration()`

- [ ] **Step 1: Write failing tests in `chrono_dial_controller_test.dart`**
Add tests asserting:
1. `enterCustomCalibration()` transitions `setupStage` to `ChronoSetupStage.focus`, sets `profile` to custom, and loads `customProfile.focusMinutes`.
2. Setting minutes or panning dial during setup updates current stage's custom value (`focusMinutes`, `shortBreakMinutes`, `longBreakMinutes`, `cycleCount`).
3. Calling `advanceCalibrationStage()` cycles through `focus` -> `shortBreak` -> `longBreak` -> `cycleCount` -> `none`, saving each parameter into `customProfile`.
4. When `setupStage` exits to `none`, status is standby and `customProfile` holds all calibrated values.
5. `cancelCalibration()` restores `setupStage: ChronoSetupStage.none`.

- [ ] **Step 2: Run test to verify it fails**
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_dial_controller_test.dart`
Expected: Compilation failure or missing methods.

- [ ] **Step 3: Implement `ChronoSetupStage` in `timer_state.dart` and methods in `chrono_dial_controller.dart`**
In `timer_state.dart`:
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
Add `final ChronoSetupStage setupStage;` to `TimerState` (default `ChronoSetupStage.none`).

In `chrono_dial_controller.dart`:
Implement:
- `void enterCustomCalibration()`
- `void advanceCalibrationStage()`
- `void cancelCalibration()`
- Update `setTargetMinutes(int minutes)` when `setupStage.isActive` to update the active stage duration (and cycle count when in `cycleCount`).

- [ ] **Step 4: Run test to verify it passes**
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_dial_controller_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/features/timer/domain/timer_state.dart lib/features/timer/presentation/chrono_dial_controller.dart test/features/timer/chrono_dial_controller_test.dart
git commit -m "feat(timer): implement ChronoSetupStage calibration state machine in ChronoDialController"
```

---

### Task 2: Precision Settings Layout Fix in TaktSettingsSheet

**Files:**
- Modify: `lib/features/settings/presentation/takt_settings_sheet.dart`
- Test: `test/features/settings/takt_settings_sheet_test.dart`

**Interfaces:**
- Consumes: `_PomodoroIntervalEngineSection`, `_buildStepperRow`, `_SectionHeader`
- Produces: Unyielding single-line horizontal stepper layout with fixed value container width (68dp) and un-truncated section headers

- [ ] **Step 1: Write failing test in `takt_settings_sheet_test.dart`**
Add widget test verifying all 4 steppers remain strictly horizontal on narrow viewport (width 320), value labels fit completely without line breaks, and section headers do not truncate prematurely.

- [ ] **Step 2: Run test to verify failure**
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/settings/takt_settings_sheet_test.dart`
Expected: Assertions on layout alignment.

- [ ] **Step 3: Refactor `_buildStepperRow` and `_SectionHeader` in `takt_settings_sheet.dart`**
Replace `Wrap` with `Row(crossAxisAlignment: CrossAxisAlignment.center)`.
Wrap title and subtitle in `Expanded(child: Column(...))`.
Give subtitle `maxLines: 1, overflow: TextOverflow.ellipsis`.
Use concise subtitles:
- `Work interval (1 – 90 min)`
- `Cycle rest interval (1 – 30 min)`
- `Long rest interval (1 – 45 min)`
- `Cycles until long rest (2 – 8)`
Set value text container width to `width: 68`.
In `_SectionHeader`: ensure title has `maxLines: 1` and natural width so it doesn't get squashed by `Expanded(Container)`.

- [ ] **Step 4: Run test to verify it passes**
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/settings/takt_settings_sheet_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/features/settings/presentation/takt_settings_sheet.dart test/features/settings/takt_settings_sheet_test.dart
git commit -m "fix(settings): lock interval stepper rows to single horizontal line and prevent header truncation"
```

---

### Task 3: ChronoDialWidget & ChronoProfileSelectorWidget Interactive Calibration UI Wiring

**Files:**
- Modify: `lib/features/timer/presentation/widgets/chrono_profile_selector_widget.dart`
- Modify: `lib/features/timer/presentation/chrono_dial_widget.dart`
- Test: `test/features/timer/chrono_profile_selector_widget_test.dart`
- Test: `test/features/timer/chrono_dial_widget_test.dart`

**Interfaces:**
- Consumes: `timerState.setupStage`, `enterCustomCalibration()`, `advanceCalibrationStage()`, `cancelCalibration()`
- Produces: Interactive dial calibration flow, responsive plaque text, long-press on CUSTOM cassette button

- [ ] **Step 1: Write failing widget tests**
In `test/features/timer/chrono_profile_selector_widget_test.dart`:
- Long-pressing `CUSTOM` cassette button invokes `enterCustomCalibration()`.
- When `setupStage` is active, telemetry plaque displays `SET 1/4 // FOCUS`, `SET 2/4 // SHORT BRK`, etc.
- Tapping telemetry plaque exits calibration to `STANDBY // READY`.
In `test/features/timer/chrono_dial_widget_test.dart`:
- Tapping Crown push-button while `setupStage.isActive` advances the stage instead of toggling timer run state.
- Rotating dial updates current stage's duration.

- [ ] **Step 2: Run test to verify it fails**
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_profile_selector_widget_test.dart test/features/timer/chrono_dial_widget_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement calibration UI wiring in `chrono_profile_selector_widget.dart` and `chrono_dial_widget.dart`**
1. In `chrono_profile_selector_widget.dart`:
   - Add `onLongPress` to segment button for `CUSTOM`: calls `enterCustomCalibration()`.
   - If user taps `CUSTOM` while it's already active, also call `enterCustomCalibration()`.
   - Update telemetry plaque:
     - Text: `timerState.setupStage.isActive ? timerState.setupStage.telemetryLabel : (timerState.isRunning ? 'RUNNING // SEC-ROLL' : 'STANDBY // READY')`
     - Color: Amber when `timerState.setupStage.isActive`.
     - Tappable: when `timerState.setupStage.isActive`, tapping plaque calls `cancelCalibration()`.
2. In `chrono_dial_widget.dart`:
   - `_handleToggle`:
     - If `state.setupStage.isActive`: call `advanceCalibrationStage()`.
     - Else: start / pause timer.
   - `_handleRotaryPan`:
     - If `state.isRunning`: return.
     - When `state.setupStage.isActive`:
       - If `setupStage == ChronoSetupStage.cycleCount`: map angle/rotation to 2–8 cycles.
       - Else: clamp minutes to stage bounds (focus 1–90, short 1–30, long 1–45) and update via `setTargetMinutes`.
   - Center counter:
     - When `setupStage == ChronoSetupStage.cycleCount`: display `0${state.customProfile.longBreakInterval}:00`.

- [ ] **Step 4: Run test to verify it passes**
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_profile_selector_widget_test.dart test/features/timer/chrono_dial_widget_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/features/timer/presentation/widgets/chrono_profile_selector_widget.dart lib/features/timer/presentation/chrono_dial_widget.dart test/features/timer/chrono_profile_selector_widget_test.dart test/features/timer/chrono_dial_widget_test.dart
git commit -m "feat(dial): wire interactive rotary calibration wizard and crown advance on ChronoDialWidget"
```

---

### Task 4: Full Suite Verification & Production Release APK Build

**Files:**
- Output: `/home/tuneeca/RSQUARE/ZYKL_Release.apk`
- Output: `/home/tuneeca/RSQUARE/Takt_Desk_Release.apk`

- [ ] **Step 1: Run full test suite**
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test`
Expected: 100% tests pass.

- [ ] **Step 2: Run static code analysis**
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`
Expected: 0 issues.

- [ ] **Step 3: Verify namespace purity**
Run: `git diff | grep -i "tuneeca" || true`
Expected: No output.

- [ ] **Step 4: Build release APK**
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter build apk --release`
Copy: `cp build/app/outputs/flutter-apk/app-release.apk /home/tuneeca/RSQUARE/ZYKL_Release.apk && cp build/app/outputs/flutter-apk/app-release.apk /home/tuneeca/RSQUARE/Takt_Desk_Release.apk`

- [ ] **Step 5: Verify APK artifacts**
Run: `ls -lh /home/tuneeca/RSQUARE/ZYKL_Release.apk /home/tuneeca/RSQUARE/Takt_Desk_Release.apk`
Expected: Both files exist with ~80MB size.
