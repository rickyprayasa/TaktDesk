# Design Spec: Pomodoro Custom Durations, Break Timer & Mechanical Bell Chime

**Date:** 2026-09-10  
**Feature:** Pomodoro Custom Durations & Break Mode  
**Platform:** Android Mobile Console (Takt Desk, Braun / Dieter Rams Industrial Aesthetic)

---

## 1. Overview & Goals

Takt Desk currently operates on a fixed 25-minute Pomodoro timer with basic `[-]` and `[+]` 5-minute adjustments. While `PomodoroPhase` (`focus`, `shortBreak`, `longBreak`) and `advancePhase()` exist in the domain model, break intervals are not seamlessly integrated into the physical loop, do not alter the visual language of the Chrono Dial, and lack an authentic mechanical chime to announce session transitions.

This specification defines the complete end-to-end implementation of:
1. **Interval Profile Engine (`PomodoroProfile`):** Presets for Classic (25/5), Monastic Deep Work (50/10), Sprint (15/3), and Custom durations (persisted in Drift DB).
2. **Semi-Automated Phase Machine & Bell Chime:** When a session countdown reaches 00:00, a mathematically synthesized analog brass bell chime (`SoundEffect.bellChime`) rings, focus sessions are committed to the Drift database audit log, and the controller transitions to the appropriate break phase in **Standby Mode** awaiting a tactile crown push.
3. **Calming Patina Olive Dial Aesthetics:** During break phases, the needle, progress arc, and split-flap LED transition from high-intensity amber to a calming sage patina olive (`TaktColors.patinaOlive`), signaling mental decompression.
4. **Machined Cassette Preset Selector:** A horizontal metallic preset selector bar mounted below the Chrono Dial replacing the simple pill button, accompanied by custom interval configuration in `TaktSettingsSheet`.

---

## 2. Architecture & Domain Model

### 2.1 Domain Model: `PomodoroProfile`
Location: `lib/features/timer/domain/pomodoro_profile.dart`

```dart
enum PomodoroProfileType {
  classic,
  monastic,
  sprint,
  custom;

  String get label {
    switch (this) {
      case PomodoroProfileType.classic:
        return 'CLASSIC 25/5';
      case PomodoroProfileType.monastic:
        return 'MONASTIC 50/10';
      case PomodoroProfileType.sprint:
        return 'SPRINT 15/3';
      case PomodoroProfileType.custom:
        return 'CUSTOM';
    }
  }
}

class PomodoroProfile {
  final PomodoroProfileType type;
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  const PomodoroProfile({
    required this.type,
    required this.focusMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
  });

  static const classic = PomodoroProfile(
    type: PomodoroProfileType.classic,
    focusMinutes: 25,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
  );

  static const monastic = PomodoroProfile(
    type: PomodoroProfileType.monastic,
    focusMinutes: 50,
    shortBreakMinutes: 10,
    longBreakMinutes: 30,
  );

  static const sprint = PomodoroProfile(
    type: PomodoroProfileType.sprint,
    focusMinutes: 15,
    shortBreakMinutes: 3,
    longBreakMinutes: 10,
  );
}
```

### 2.2 Extended `TimerState`
Location: `lib/features/timer/domain/timer_state.dart`

Add active profile reference:
- `final PomodoroProfile profile;` (defaults to `PomodoroProfile.classic`)
- `final bool isBreak;` (`phase == PomodoroPhase.shortBreak || phase == PomodoroPhase.longBreak`)

### 2.3 Phase Transition State Machine (`ChronoDialController`)
Location: `lib/features/timer/presentation/chrono_dial_controller.dart`

1. **Cycle Rules:**
   - S1: `Focus` (Cycle 1/4) $\rightarrow$ Completion rings bell chime $\rightarrow$ Auto-advance to `Short Break` (Cycle 1/4) in Standby.
   - S2: `Short Break` (Cycle 1/4) $\rightarrow$ Completion rings bell chime $\rightarrow$ Auto-advance to `Focus` (Cycle 2/4) in Standby.
   - S3: `Focus` (Cycle 2/4) $\rightarrow$ `Short Break` (Cycle 2/4) in Standby.
   - S4: `Short Break` (Cycle 2/4) $\rightarrow$ `Focus` (Cycle 3/4) in Standby.
   - S5: `Focus` (Cycle 3/4) $\rightarrow$ `Short Break` (Cycle 3/4) in Standby.
   - S6: `Short Break` (Cycle 3/4) $\rightarrow$ `Focus` (Cycle 4/4) in Standby.
   - S7: `Focus` (Cycle 4/4) $\rightarrow$ Completion rings bell chime $\rightarrow$ Auto-advance to `Long Break` (Cycle 4/4) in Standby.
   - S8: `Long Break` (Cycle 4/4) $\rightarrow$ Completion rings bell chime $\rightarrow$ Auto-advance to `Focus` (Cycle 1/4) in Standby.

2. **Database Logging Integrity:**
   - Only `PomodoroPhase.focus` sessions are written to `appDatabase.recordTimerSession(...)`.
   - Break sessions do NOT increment focus tallies in `TodayFocusStats` or receipt telemetry rolls, keeping productive audit logs pure.

3. **Audio & Haptic Feedback:**
   - `_audioService?.playFoley(SoundEffect.bellChime);`
   - `HapticService.mechanicalPress();`

---

## 3. Industrial Visual Design & Break Mode Palette

### 3.1 Chrono Dial Break Appearance (`ChronoDialPainter`)
- **Needle Color:** During `phase != PomodoroPhase.focus`, `needleColor` switches to `TaktColors.patinaOlive` (`#4D5D4B`).
- **Filament / Progress Arc Color:** Switches to `TaktColors.patinaOlive` with soft diffuse glow.
- **Dial Face Tone:** Subtle sage-tinted depth reflection inside the machined disc dish.

### 3.2 Split-Flap Board Synchronicity (`SplitFlapBoardWidget`)
- **Phase Text:**
  - Focus: `'  FOCUS  '` with amber LED (`#D99B59`).
  - Short Break: `'SHORT BRK'` with patina olive LED (`#4D5D4B`).
  - Long Break: `'LONG  BRK'` with muted ochre / warm olive LED (`#C85A32`).
- **Cycle Text:** `'CYCLE X/4'` advances smoothly with mechanical flip tile animation.

### 3.3 Horizontal Cassette Preset Selector (`ChronoProfileSelectorWidget`)
Mounted below the dial in place of the rudimentary `[-] 25 MIN [+]` button:
- Width: ~280px (matching modular console grid).
- Chassis finish: `themeState.moduleChassisColor` with 1.0px metallic border.
- Segments:
  - `[ 25/5 CLS ]`
  - `[ 50/10 MON ]`
  - `[ 15/3 SPR ]`
  - `[ CUSTOM ▾ ]`
- Micro-LED dot above active segment illuminated in `themeState.filamentColor`.
- Tapping a segment (when timer is stopped):
  - Plays `SoundEffect.dialClick` and `HapticService.selectionClick()`.
  - Sets profile, updates dial target minutes, resets cycle counter to 1, and sets phase to `PomodoroPhase.focus`.

---

## 4. Audio Synthesis: Mechanical Analog Bell Chime

### 4.1 Specification
- **File:** `assets/audio/foley_bell_chime.wav`
- **Audio Profile:** 22050 Hz, 16-bit mono PCM WAV.
- **Acoustic Characteristics:**
  - Primary resonance: 880.0 Hz (A5 pure tone).
  - Secondary metallic partial: 1760.0 Hz with slight phase detuning (+4 Hz beat frequency).
  - High-order strike transient: 2640.0 Hz and pink noise micro-thud over first 40ms.
  - Exponential decay envelope: 1.8 seconds natural reverberant ringdown.
- **Generation:** Python procedural audio generator script `scripts/generate_bell_chime.py`.
- **Mapping:** Added to `SoundEffect.bellChime` in Flutter and `playFoley("bellChime")` in `MainActivity.kt`.

---

## 5. Persistence & Settings Sheet Custom Tuning

### 5.1 Drift Database Persistence
In `DeskPreferences` table:
- `selectedPomodoroProfile`: text (default `'classic'`)
- `customFocusMinutes`: int (default `25`)
- `customShortBreakMinutes`: int (default `5`)
- `customLongBreakMinutes`: int (default `15`)

### 5.2 Settings Sheet Integration (`TaktSettingsSheet`)
Add section `POMODORO INTERVAL ENGINE`:
- Active profile selector dropdown / segmented buttons.
- If `custom` selected: industrial numeric stepper controls for:
  - Focus Duration (1 – 90 mins, default 25)
  - Short Break Duration (1 – 30 mins, default 5)
  - Long Break Duration (1 – 45 mins, default 15)

---

## 6. Verification & Test Plan

1. **Domain & Controller Unit Tests (`chrono_dial_controller_test.dart`):**
   - Verify profile switching sets correct target and break minutes.
   - Verify 4-cycle state progression: Focus 1 $\rightarrow$ Short Break 1 $\rightarrow$ ... Focus 4 $\rightarrow$ Long Break $\rightarrow$ Focus 1.
   - Verify session completion triggers `bellChime`, transitions phase, and enters Standby (`isRunning: false`).
   - Verify only focus sessions are recorded in `AppDatabase`.
2. **Widget & Painter Tests (`chrono_dial_widget_test.dart`, `chrono_dial_painter_test.dart`):**
   - Verify dial painter draws `patinaOlive` needle and progress arc during break phases.
   - Verify preset selector switches profiles and updates UI.
   - Verify split-flap board displays correct text and LED colors for each phase.
3. **Full Suite & Static Analysis:**
   - 0 static analyzer issues (`flutter analyze`).
   - 100% test pass rate across the repository.
