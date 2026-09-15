# Mechanical Pull Crown Calibration & Telemetry Guidance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement mechanical 3D Pull Crown elevation animation, vertical drag gestures, and contextual `PULL CROWN // SET` telemetry status guidance on the ZYKL analog Pomodoro watch.

**Architecture:** 
- `CrownPushButton` is upgraded with physical 2-state mechanics (Position 0 flush vs. Position 1 elevated -6px with exposed polished stem) and vertical drag gesture detection.
- `ChronoProfileSelectorWidget` dynamically renders `PULL CROWN // SET` in horological amber when the `custom` profile is idle.
- `ChronoDialWidget` wires crown pull-out and push-in callbacks directly to `ChronoDialController`'s `enterCustomCalibration()` and `cancelCalibration()` with tactile foley audio and haptics.

**Tech Stack:** Flutter / Dart, Flutter Riverpod, Custom Canvas / AnimatedBuilder, Drift SQLite, Flutter Test.

## Global Constraints

- Adhere strictly to Dieter Rams / Braun modernist industrial aesthetics (honest materials, uncluttered monospace typography, amber accent #FF9E00).
- Clean namespace: Absolutely 0 occurrences of private directory names across Kotlin, Dart, XML, and Gradle files.
- 0 analyzer issues (`flutter analyze`).
- 100% test pass rate across repository (`flutter test`).
- Production Release APK verified and deployed to `/home/tuneeca/RSQUARE/ZYKL_Release.apk` and `/home/tuneeca/RSQUARE/Takt_Desk_Release.apk`.

---

### Task 1: `CrownPushButton` Mechanical Pull Animation, Exposed Stem Shaft & Drag Up/Down Gestures

**Files:**
- Create: `test/features/timer/crown_push_button_test.dart`
- Modify: `lib/features/timer/presentation/widgets/crown_push_button.dart`

**Interfaces:**
- Consumes: `TaktColors.slateBorder`, Flutter animation primitives.
- Produces:
  ```dart
  class CrownPushButton extends StatefulWidget {
    final bool isPressed;
    final bool isPulledOut;
    final VoidCallback onTap;
    final VoidCallback? onPullOut;
    final VoidCallback? onPushIn;
    final List<Color>? gradientColors;
    final Color? borderColor;
    final Color? stemColor;
  ...
  ```

- [ ] **Step 1: Write the failing widget tests in `crown_push_button_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/timer/presentation/widgets/crown_push_button.dart';

void main() {
  testWidgets('CrownPushButton renders in normal flush position when isPulledOut is false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CrownPushButton(
              isPressed: false,
              isPulledOut: false,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CrownPushButton), findsOneWidget);
  });

  testWidgets('CrownPushButton triggers onPullOut on upward vertical drag', (tester) async {
    bool pullTriggered = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CrownPushButton(
              isPressed: false,
              isPulledOut: false,
              onTap: () {},
              onPullOut: () => pullTriggered = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final crownCenter = tester.getCenter(find.byType(CrownPushButton));
    final gesture = await tester.startGesture(crownCenter);
    await tester.pump();
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(pullTriggered, isTrue);
  });

  testWidgets('CrownPushButton triggers onPushIn on downward vertical drag when pulled out', (tester) async {
    bool pushTriggered = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CrownPushButton(
              isPressed: false,
              isPulledOut: true,
              onTap: () {},
              onPushIn: () => pushTriggered = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final crownCenter = tester.getCenter(find.byType(CrownPushButton));
    final gesture = await tester.startGesture(crownCenter);
    await tester.pump();
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(pushTriggered, isTrue);
  });

  testWidgets('CrownPushButton invokes onTap when tapped', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CrownPushButton(
              isPressed: false,
              isPulledOut: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(CrownPushButton));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails (RED)**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/crown_push_button_test.dart
```
Expected: Compilation failure because `isPulledOut`, `onPullOut`, and `onPushIn` parameters are not yet defined.

- [ ] **Step 3: Implement `CrownPushButton` with mechanical elevation and drag gestures (GREEN)**

Update `lib/features/timer/presentation/widgets/crown_push_button.dart`:
- Add `isPulledOut`, `onPullOut`, `onPushIn` properties.
- Add `_pullController` and `_pullAnimation` with `Tween<double>(begin: 0.0, end: -6.0)` and `Curves.easeOutBack` (160ms).
- Add vertical drag listener tracking vertical displacement $\Delta y$.
- Render metallic stem extension cylinder when elevated.

- [ ] **Step 4: Run test to verify it passes (GREEN)**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/crown_push_button_test.dart
```
Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/timer/presentation/widgets/crown_push_button.dart test/features/timer/crown_push_button_test.dart
git commit -m "feat(crown): implement mechanical 3D pull-out animation and vertical drag gestures in CrownPushButton"
```

---

### Task 2: Telemetry Status Plaque Dynamic Guidance (`PULL CROWN // SET`)

**Files:**
- Modify: `lib/features/timer/presentation/widgets/chrono_profile_selector_widget.dart`
- Modify: `test/features/timer/chrono_profile_selector_widget_test.dart`

**Interfaces:**
- Consumes: `timerState.setupStage.isActive`, `timerState.isRunning`, `timerState.profile.type == PomodoroProfileType.custom`.
- Produces: Status plaque displaying `'PULL CROWN // SET'` in `TaktColors.filamentAmber`.

- [ ] **Step 1: Write failing test in `chrono_profile_selector_widget_test.dart`**

Add test in `test/features/timer/chrono_profile_selector_widget_test.dart`:
```dart
testWidgets('telemetry status plaque displays PULL CROWN // SET when custom profile is idle in standby', (tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ChronoProfileSelectorWidget(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  // Initially CLASSIC 25: plaque should display STANDBY // READY
  expect(find.text('STANDBY // READY'), findsOneWidget);

  // Switch to CUSTOM profile
  await tester.tap(find.text('CUSTOM'));
  await tester.pump();

  // Plaque should now guide user with PULL CROWN // SET in filamentAmber
  expect(find.text('PULL CROWN // SET'), findsOneWidget);
  final plaqueText = tester.widget<Text>(find.text('PULL CROWN // SET'));
  expect(plaqueText.style?.color, equals(TaktColors.filamentAmber));
});
```

- [ ] **Step 2: Run test to verify failure (RED)**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_profile_selector_widget_test.dart
```
Expected: FAIL with `Expected: exactly one matching candidate, Actual: 0 (text 'PULL CROWN // SET' not found)`.

- [ ] **Step 3: Implement telemetry status guidance in `chrono_profile_selector_widget.dart`**

In `lib/features/timer/presentation/widgets/chrono_profile_selector_widget.dart`:
```dart
final isCustomStandby = !timerState.isRunning &&
    !timerState.setupStage.isActive &&
    timerState.profile.type == PomodoroProfileType.custom;

final plaqueText = timerState.setupStage.isActive
    ? timerState.setupStage.telemetryLabel
    : (timerState.isRunning
        ? 'RUNNING // SEC-ROLL'
        : (isCustomStandby ? 'PULL CROWN // SET' : 'STANDBY // READY'));

final isCalibrating = timerState.setupStage.isActive;
final plaqueColor = isCalibrating || timerState.isRunning || isCustomStandby
    ? TaktColors.filamentAmber
    : textColor;
```

- [ ] **Step 4: Run tests to verify pass (GREEN)**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_profile_selector_widget_test.dart
```
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/timer/presentation/widgets/chrono_profile_selector_widget.dart test/features/timer/chrono_profile_selector_widget_test.dart
git commit -m "feat(telemetry): display PULL CROWN // SET guidance plaque when custom profile is idle"
```

---

### Task 3: Dial & Crown Integration in `ChronoDialWidget` & Foley Audio Wiring

**Files:**
- Modify: `lib/features/timer/presentation/chrono_dial_widget.dart`
- Modify: `test/features/timer/chrono_dial_widget_test.dart`

**Interfaces:**
- Consumes: `CrownPushButton(isPulledOut, onPullOut, onPushIn)`.
- Produces: Integrated mechanical pull/push actuation triggering `enterCustomCalibration()` and `cancelCalibration()`.

- [ ] **Step 1: Write failing tests in `chrono_dial_widget_test.dart`**

Add tests in `test/features/timer/chrono_dial_widget_test.dart`:
```dart
testWidgets('Swiping up on CrownPushButton pulls crown and enters custom calibration', (tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ChronoDialWidget(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.none));

  // Find CrownPushButton and drag upward
  final crownFinder = find.byType(CrownPushButton);
  expect(crownFinder, findsOneWidget);

  final crownCenter = tester.getCenter(crownFinder);
  final gesture = await tester.startGesture(crownCenter);
  await tester.pump();
  await gesture.moveBy(const Offset(0, -20));
  await tester.pump();
  await gesture.up();
  await tester.pump();

  expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.focus));
  expect(container.read(chronoDialProvider).profile.type, equals(PomodoroProfileType.custom));

  // Swiping down on CrownPushButton pushes crown back in and cancels calibration
  final gestureDown = await tester.startGesture(crownCenter);
  await tester.pump();
  await gestureDown.moveBy(const Offset(0, 20));
  await tester.pump();
  await gestureDown.up();
  await tester.pump();

  expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.none));
});
```

- [ ] **Step 2: Run test to verify failure (RED)**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_dial_widget_test.dart
```

- [ ] **Step 3: Implement crown wiring in `ChronoDialWidget`**

In `lib/features/timer/presentation/chrono_dial_widget.dart`:
- Pass `isPulledOut: state.setupStage.isActive`.
- Connect `onPullOut`:
  ```dart
  onPullOut: () {
    if (state.isRunning) return;
    ref.read(chronoDialProvider.notifier).enterCustomCalibration();
  },
  ```
- Connect `onPushIn`:
  ```dart
  onPushIn: () {
    if (state.setupStage.isActive) {
      ref.read(chronoDialProvider.notifier).cancelCalibration();
    }
  },
  ```
- In `ChronoDialController.enterCustomCalibration()`: play `SoundEffect.drawerLatch` foley for authentic mechanical pull clack.

- [ ] **Step 4: Run test to verify pass (GREEN)**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_dial_widget_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/timer/presentation/chrono_dial_widget.dart lib/features/timer/presentation/chrono_dial_controller.dart test/features/timer/chrono_dial_widget_test.dart
git commit -m "feat(dial): wire CrownPushButton pull-out and push-in gestures to calibration lifecycle"
```

---

### Task 4: Full Suite Verification & Production Release APK Build

**Files:**
- Output: `build/app/outputs/flutter-apk/app-release.apk`
- Deploy: `/home/tuneeca/RSQUARE/ZYKL_Release.apk`, `/home/tuneeca/RSQUARE/Takt_Desk_Release.apk`

- [ ] **Step 1: Run full test suite across repository**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test
```
Expected: 100% PASS (all 350+ tests).

- [ ] **Step 2: Run static analysis**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter analyze
```
Expected: 0 errors, 0 warnings, 0 lints.

- [ ] **Step 3: Verify clean namespace**

```bash
git diff c663405..HEAD | grep -i "tuneeca" || true
```
Expected: 0 occurrences.

- [ ] **Step 4: Build production release APK**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter build apk --release
```

- [ ] **Step 5: Deploy APK artifacts**

```bash
cp build/app/outputs/flutter-apk/app-release.apk /home/tuneeca/RSQUARE/ZYKL_Release.apk
cp build/app/outputs/flutter-apk/app-release.apk /home/tuneeca/RSQUARE/Takt_Desk_Release.apk
ls -lh /home/tuneeca/RSQUARE/*Release.apk
```

- [ ] **Step 6: Whole-branch review & report**
