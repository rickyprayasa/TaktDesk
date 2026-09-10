# Pomodoro Custom Durations, Break Mode & Bell Chime Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement customizable Pomodoro duration profiles (Classic 25/5, Monastic 50/10, Sprint 15/3, Custom), semi-automated break transitions with mathematical brass bell chime foley, calming Patina Olive break dial aesthetics, and an industrial 280px cassette selector.

**Architecture:** A domain model `PomodoroProfile` encapsulates focus/break intervals. `ChronoDialController` manages a 4-cycle state machine (`Focus` $\rightarrow$ `Short Break` $\dots \rightarrow$ `Long Break`), triggers procedural audio and haptics on completion, isolates database session logging to focus periods, and rests in Standby mode awaiting crown push. A modular 280px `ChronoProfileSelectorWidget` mounts beneath the dial while `TaktSettingsSheet` handles custom minute tuning.

**Tech Stack:** Flutter, Riverpod, Drift (SQLite), Procedural Python Audio synthesis (WAV PCM 22050Hz 16-bit), Android Native MediaPlayer foley.

## Global Constraints

- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetic (honest materials, high contrast, tactile feedback, "Weniger, aber besser").
- Target platform: Mobile Android (maxWidth 440px handheld console, 280px modular console grid).
- 0 analyzer issues (`flutter analyze`).
- 100% test pass rate across repository (`flutter test`).
- Offline-first: zero external network or streaming dependencies; all audio synthesized offline.

---

### Task 1: Procedural Bell Chime Audio & Domain Model (`PomodoroProfile`)

**Files:**
- Create: `scripts/generate_bell_chime.py`
- Create: `lib/features/timer/domain/pomodoro_profile.dart`
- Modify: `lib/core/audio/sound_effect.dart:1-13`
- Modify: `android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt`
- Modify: `lib/features/timer/domain/timer_state.dart:1-42`
- Test: `test/features/timer/pomodoro_profile_test.dart`

**Interfaces:**
- Consumes: `SoundEffect` enum, `TimerState`
- Produces: `PomodoroProfileType`, `PomodoroProfile`, `TimerState.profile`, `TimerState.isBreak`, `SoundEffect.bellChime`

- [ ] **Step 1: Write the failing domain test**

```dart
// test/features/timer/pomodoro_profile_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_phase.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_profile.dart';
import 'package:takt_desk/features/timer/domain/timer_state.dart';

void main() {
  group('PomodoroProfile', () {
    test('standard presets have accurate focus and break intervals', () {
      expect(PomodoroProfile.classic.focusMinutes, equals(25));
      expect(PomodoroProfile.classic.shortBreakMinutes, equals(5));
      expect(PomodoroProfile.classic.longBreakMinutes, equals(15));

      expect(PomodoroProfile.monastic.focusMinutes, equals(50));
      expect(PomodoroProfile.monastic.shortBreakMinutes, equals(10));
      expect(PomodoroProfile.monastic.longBreakMinutes, equals(30));

      expect(PomodoroProfile.sprint.focusMinutes, equals(15));
      expect(PomodoroProfile.sprint.shortBreakMinutes, equals(3));
      expect(PomodoroProfile.sprint.longBreakMinutes, equals(10));
    });

    test('custom profile clamps values within bounds', () {
      final custom = PomodoroProfile.custom(
        focusMinutes: 120, // should clamp to 90
        shortBreakMinutes: 0, // should clamp to 1
        longBreakMinutes: 60, // should clamp to 45
      );
      expect(custom.focusMinutes, equals(90));
      expect(custom.shortBreakMinutes, equals(1));
      expect(custom.longBreakMinutes, equals(45));
    });

    test('TimerState reports isBreak properly', () {
      const focusState = TimerState(
        targetMinutes: 25,
        remainingSeconds: 1500,
        isRunning: false,
        phase: PomodoroPhase.focus,
      );
      expect(focusState.isBreak, isFalse);

      const breakState = TimerState(
        targetMinutes: 5,
        remainingSeconds: 300,
        isRunning: false,
        phase: PomodoroPhase.shortBreak,
      );
      expect(breakState.isBreak, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/pomodoro_profile_test.dart`
Expected: Compilation failure due to missing `pomodoro_profile.dart` and `isBreak`.

- [ ] **Step 3: Synthesize `assets/audio/foley_bell_chime.wav` and implement domain model**

1. Run python script to synthesize brass bell chime:
```python
# scripts/generate_bell_chime.py
import math, struct, wave, os

SAMPLE_RATE = 22050
DURATION = 1.8
NUM_SAMPLES = int(SAMPLE_RATE * DURATION)
out_path = "assets/audio/foley_bell_chime.wav"

samples = []
for i in range(NUM_SAMPLES):
    t = i / SAMPLE_RATE
    decay = math.exp(-3.5 * t)
    # Fundamental 880Hz + harmonic overtone 1764Hz + transient strike 2640Hz
    s1 = math.sin(2 * math.pi * 880.0 * t) * decay
    s2 = 0.45 * math.sin(2 * math.pi * 1764.0 * t) * math.exp(-5.0 * t)
    s3 = 0.20 * math.sin(2 * math.pi * 2640.0 * t) * math.exp(-12.0 * t)
    # Initial hammer transient
    strike = (0.25 * (1.0 - t / 0.04) if t < 0.04 else 0.0)
    sample = (s1 + s2 + s3 + strike) * 0.75
    sample = max(-1.0, min(1.0, sample))
    samples.append(int(sample * 32767.0))

os.makedirs("assets/audio", exist_ok=True)
with wave.open(out_path, "w") as f:
    f.setnchannels(1)
    f.setsampwidth(2)
    f.setframerate(SAMPLE_RATE)
    f.writeframes(struct.pack(f"<{len(samples)}h", *samples))
print(f"Generated {out_path}")
```
Execute: `python3 scripts/generate_bell_chime.py`

2. In `lib/core/audio/sound_effect.dart`: Add `bellChime` to enum.
3. In `android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt`: Map `"bellChime"` to `"flutter_assets/assets/audio/foley_bell_chime.wav"`.
4. Create `lib/features/timer/domain/pomodoro_profile.dart`.
5. Update `lib/features/timer/domain/timer_state.dart` with `profile` and `isBreak`.

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/pomodoro_profile_test.dart`
Expected: PASS

- [ ] **Step 5: Commit Task 1**

```bash
git add scripts/generate_bell_chime.py assets/audio/foley_bell_chime.wav lib/core/audio/sound_effect.dart android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt lib/features/timer/domain/pomodoro_profile.dart lib/features/timer/domain/timer_state.dart test/features/timer/pomodoro_profile_test.dart
git commit -m "feat(timer): create PomodoroProfile domain model and synthesize analog bell chime foley"
```

---

### Task 2: Semi-Automated Phase Machine & State Controller (`ChronoDialController`)

**Files:**
- Modify: `lib/features/timer/presentation/chrono_dial_controller.dart:1-148`
- Test: `test/features/timer/chrono_dial_controller_test.dart`

**Interfaces:**
- Consumes: `PomodoroProfile`, `SoundEffect.bellChime`, `AppDatabase.recordTimerSession`
- Produces: `ChronoDialController.setProfile`, auto-advance phase on completion, Standby transition

- [ ] **Step 1: Write failing controller test for phase progression & chime trigger**

```dart
// test/features/timer/chrono_dial_controller_test.dart
test('ChronoDialController auto-advances to Short Break, rings chime, logs focus, and enters standby', () async {
  final mockAudio = MockAudioService();
  final testDb = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(testDb.close);

  final controller = ChronoDialController(mockAudio, testDb);
  controller.setProfile(PomodoroProfile.classic);
  expect(controller.state.targetMinutes, equals(25));
  expect(controller.state.phase, equals(PomodoroPhase.focus));

  controller.start();
  expect(controller.state.isRunning, isTrue);

  // Complete the 25 minute focus session
  controller.tick(25 * 60.0);

  // Verifications:
  // 1. Chime played
  expect(mockAudio.playedEffects, contains(SoundEffect.bellChime));
  // 2. Switched to Short Break (Cycle 1/4)
  expect(controller.state.phase, equals(PomodoroPhase.shortBreak));
  expect(controller.state.targetMinutes, equals(5));
  expect(controller.state.remainingSeconds, equals(300.0));
  // 3. Standby mode awaiting user crown press
  expect(controller.state.isRunning, isFalse);

  // 4. Focus session was recorded in database
  final sessions = await testDb.getTodayTimerSessions();
  expect(sessions.length, equals(1));
  expect(sessions.first.targetMinutes, equals(25));

  // Now start and complete short break
  mockAudio.playedEffects.clear();
  controller.start();
  controller.tick(5 * 60.0);

  // Verifications for Break completion:
  // 1. Chime played
  expect(mockAudio.playedEffects, contains(SoundEffect.bellChime));
  // 2. Switched to Focus (Cycle 2/4)
  expect(controller.state.phase, equals(PomodoroPhase.focus));
  expect(controller.state.cycleCount, equals(2));
  expect(controller.state.targetMinutes, equals(25));
  expect(controller.state.isRunning, isFalse);

  // 3. Break was NOT recorded in database (still only 1 session)
  final sessionsAfterBreak = await testDb.getTodayTimerSessions();
  expect(sessionsAfterBreak.length, equals(1));
});
```

- [ ] **Step 2: Run test to verify failure**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_dial_controller_test.dart`
Expected: FAIL (missing `setProfile`, no chime play, no auto-advance in `tick`).

- [ ] **Step 3: Implement `setProfile` and semi-automated transition in `ChronoDialController`**

In `lib/features/timer/presentation/chrono_dial_controller.dart`:
- Add `void setProfile(PomodoroProfile profile)`:
  - If `state.isRunning` return.
  - Updates `state.profile`, sets `phase: PomodoroPhase.focus`, `cycleCount: 1`, `targetMinutes: profile.focusMinutes`, `remainingSeconds: profile.focusMinutes * 60.0`.
- In `tick(double deltaSeconds)`:
  - When `nextRemaining <= 0`:
    - Record session in database ONLY IF `state.phase == PomodoroPhase.focus`.
    - Play `_audioService?.playFoley(SoundEffect.bellChime);`
    - Call `HapticService.mechanicalPress();`
    - Advance phase:
      - If `focus` and `cycleCount < 4`: next is `shortBreak`, same cycle.
      - If `focus` and `cycleCount == 4`: next is `longBreak`, same cycle.
      - If `shortBreak`: next is `focus`, cycle count increases by 1.
      - If `longBreak`: next is `focus`, cycle count resets to 1.
    - Resolve target duration from `state.profile` based on new phase:
      - `focus`: `profile.focusMinutes`
      - `shortBreak`: `profile.shortBreakMinutes`
      - `longBreak`: `profile.longBreakMinutes`
    - Update state with `phase: nextPhase`, `cycleCount: nextCycle`, `targetMinutes: nextMins`, `remainingSeconds: nextMins * 60.0`, `lastTickMinute: nextMins`, `isRunning: false` (Standby mode).

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_dial_controller_test.dart`
Expected: PASS

- [ ] **Step 5: Commit Task 2**

```bash
git add lib/features/timer/presentation/chrono_dial_controller.dart test/features/timer/chrono_dial_controller_test.dart
git commit -m "feat(timer): implement 4-cycle Pomodoro state machine with bell chime foley and standby break transitions"
```

---

### Task 3: Calming Patina Olive Dial & Split-Flap Break Aesthetics

**Files:**
- Modify: `lib/features/timer/presentation/chrono_dial_painter.dart:1-120`
- Modify: `lib/features/timer/presentation/chrono_dial_widget.dart:170-220`
- Modify: `lib/features/timer/presentation/widgets/split_flap_board_widget.dart:20-40`
- Test: `test/features/timer/chrono_dial_painter_test.dart`
- Test: `test/features/timer/chrono_dial_widget_test.dart`

**Interfaces:**
- Consumes: `TimerState.isBreak`, `TimerState.phase`
- Produces: Visual break styling (patina olive needle, progress arc, green split-flap LED)

- [ ] **Step 1: Write failing widget test for Break mode aesthetics**

```dart
// test/features/timer/chrono_dial_widget_test.dart
testWidgets('ChronoDialWidget renders Patina Olive colors and split flap labels during break', (tester) async {
  final container = ProviderContainer(
    overrides: [
      chronoDialProvider.overrideWith((ref) {
        final ctrl = ChronoDialController();
        ctrl.setPhase(PomodoroPhase.shortBreak);
        return ctrl;
      }),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: ChronoDialWidget())),
    ),
  );
  await tester.pump();

  // Split-flap displays SHORT BRK
  expect(find.text('SHORT BRK'), findsOneWidget);

  // ChronoDialPainter receives patinaOlive needle and filament
  final customPaintFinder = find.byType(CustomPaint);
  final dialPainter = tester.widget<CustomPaint>(customPaintFinder.first).painter as ChronoDialPainter;
  expect(dialPainter.needleColor, equals(TaktColors.patinaOlive));
  expect(dialPainter.filamentColor, equals(TaktColors.patinaOlive));
});
```

- [ ] **Step 2: Run test to verify failure**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_dial_widget_test.dart`
Expected: FAIL (dialPainter still receives standard needle/filament colors).

- [ ] **Step 3: Implement Break Palette in ChronoDialWidget and ChronoDialPainter**

1. In `lib/features/timer/presentation/chrono_dial_widget.dart`:
   - When `state.isBreak` is true:
     - `effectiveNeedleColor = TaktColors.patinaOlive;`
     - `effectiveFilamentColor = TaktColors.patinaOlive;`
   - Pass `needleColor: effectiveNeedleColor` and `filamentColor: effectiveFilamentColor` to `ChronoDialPainter`.
2. In `lib/features/timer/presentation/widgets/split_flap_board_widget.dart`:
   - Ensure `PomodoroPhase.shortBreak` and `PomodoroPhase.longBreak` illuminate the LED with `TaktColors.patinaOlive` and `#C85A32` respectively.

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_dial_widget_test.dart`
Expected: PASS

- [ ] **Step 5: Commit Task 3**

```bash
git add lib/features/timer/presentation/chrono_dial_painter.dart lib/features/timer/presentation/chrono_dial_widget.dart lib/features/timer/presentation/widgets/split_flap_board_widget.dart test/features/timer/chrono_dial_widget_test.dart
git commit -m "feat(timer): apply calming Patina Olive break aesthetic to ChronoDial and SplitFlap board"
```

---

### Task 4: Horizontal Cassette Preset Selector & Settings Sheet Custom Tuning

**Files:**
- Create: `lib/features/timer/presentation/widgets/chrono_profile_selector_widget.dart`
- Modify: `lib/features/timer/presentation/chrono_dial_widget.dart:230-285`
- Modify: `lib/features/settings/presentation/takt_settings_sheet.dart`
- Modify: `lib/features/settings/presentation/settings_controller.dart`
- Test: `test/features/timer/chrono_profile_selector_widget_test.dart`
- Test: `test/features/settings/takt_settings_sheet_test.dart`

**Interfaces:**
- Consumes: `PomodoroProfile`, `chronoDialProvider`
- Produces: `ChronoProfileSelectorWidget` mounted on 280px modular console grid, `TaktSettingsSheet` custom interval steppers

- [ ] **Step 1: Write failing widget test for ChronoProfileSelectorWidget**

```dart
// test/features/timer/chrono_profile_selector_widget_test.dart
testWidgets('ChronoProfileSelectorWidget displays 4 cassette segments and selects profile on tap', (tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: ChronoProfileSelectorWidget())),
    ),
  );
  await tester.pump();

  expect(find.text('25/5 CLS'), findsOneWidget);
  expect(find.text('50/10 MON'), findsOneWidget);
  expect(find.text('15/3 SPR'), findsOneWidget);
  expect(find.text('CUSTOM'), findsOneWidget);

  // Tap 50/10 MON
  await tester.tap(find.text('50/10 MON'));
  await tester.pump();

  final state = container.read(chronoDialProvider);
  expect(state.profile.type, equals(PomodoroProfileType.monastic));
  expect(state.targetMinutes, equals(50));
});
```

- [ ] **Step 2: Run test to verify failure**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_profile_selector_widget_test.dart`
Expected: Compilation error due to missing `ChronoProfileSelectorWidget`.

- [ ] **Step 3: Implement `ChronoProfileSelectorWidget` and Settings Sheet tuning**

1. Create `lib/features/timer/presentation/widgets/chrono_profile_selector_widget.dart`:
   - 280px modular width, `themeState.moduleChassisColor`, 1.0px metallic border, 4 segments (`25/5 CLS`, `50/10 MON`, `15/3 SPR`, `CUSTOM`).
   - Micro-LED indicating active profile.
   - On tap: calls `ref.read(chronoDialProvider.notifier).setProfile(...)` and triggers haptic / dial click.
2. In `lib/features/timer/presentation/chrono_dial_widget.dart`:
   - Replace the rudimentary `[-] 25 MIN [+]` button with `const ChronoProfileSelectorWidget()`.
3. In `lib/features/settings/presentation/takt_settings_sheet.dart`:
   - Add `POMODORO INTERVAL ENGINE` section allowing users to tune Custom Focus, Short Break, and Long Break durations with tactile steppers.

- [ ] **Step 4: Run tests to verify they pass**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_profile_selector_widget_test.dart test/features/settings/takt_settings_sheet_test.dart`
Expected: PASS

- [ ] **Step 5: Full verification & Commit**

Run:
```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter analyze
/home/tuneeca/RSQUARE/flutter/bin/flutter test
```
Expected: 0 issues, 100% tests passing.

```bash
git add lib/features/timer/presentation/widgets/chrono_profile_selector_widget.dart lib/features/timer/presentation/chrono_dial_widget.dart lib/features/settings/presentation/takt_settings_sheet.dart lib/features/settings/presentation/settings_controller.dart test/features/timer/chrono_profile_selector_widget_test.dart test/features/settings/takt_settings_sheet_test.dart
git commit -m "feat(timer): mount horizontal cassette profile selector and add custom interval tuning to settings"
```
