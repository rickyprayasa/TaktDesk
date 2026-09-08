# Takt Desk Workbench Layout, Dual VU Meter & Chassis Finish Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the 4th modular instrument (Analog Dual VU Meter with twin galvanometer needles and warm amber phosphor illumination), an adaptive 2x2 / single-column responsive workbench layout, and a physical chassis finish theme switch (Braun Atelier Dark vs. Braun Audio Light) persisted in Drift SQLite.

**Architecture:** A dedicated `vumeter` feature module driven by a ballistics `StateNotifier` reacting to Vinyl and Chrono Dial streams; a theme controller persisting chassis finish preferences; and an adaptive responsive `DeskCanvasScreen` using `LayoutBuilder` with interconnecting modular bracket styling.

**Tech Stack:** Flutter 3.27+, Dart 3.6+, Flutter Riverpod 2.6+, Drift SQLite, CustomPainter with Vector Math.

## Global Constraints
- Android Target SDK 34+, Min SDK 24. Linux desktop supported.
- Zero AI Slop: Strictly adhere to Dieter Rams / Braun industrial design palette.
- 60/120 FPS fluid ballistics using `Ticker` / `ValueNotifier` decoupled from Riverpod state rebuilds.
- 100% test pass rate with zero analyzer issues.

---

### Task 1: The Analog Dual VU Meter Engine & Presentation

**Files:**
- Create: `lib/features/vumeter/domain/vu_meter_state.dart`
- Create: `lib/features/vumeter/presentation/vu_meter_controller.dart`
- Create: `lib/features/vumeter/presentation/vu_meter_painter.dart`
- Create: `lib/features/vumeter/presentation/analog_vu_meter_widget.dart`
- Test: `test/features/vumeter/vu_meter_controller_test.dart`
- Test: `test/features/vumeter/analog_vu_meter_widget_test.dart`

**Interfaces:**
- Consumes: `vinylProvider` for audio playback status, `chronoDialProvider` for timer tick impulses.
- Produces: `analogVuMeterProvider` providing `VuMeterState(leftLevel: double, rightLevel: double, isFastBallistics: bool, peakLeft: bool, peakRight: bool)` and `AnalogVuMeterWidget`.

- [ ] **Step 1: Write failing controller and painter test**

```dart
// test/features/vumeter/vu_meter_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/vumeter/presentation/vu_meter_controller.dart';

void main() {
  test('VuMeterController initial state has zero levels and slow ballistics', () {
    final controller = VuMeterController();
    expect(controller.state.leftLevel, 0.0);
    expect(controller.state.rightLevel, 0.0);
    expect(controller.state.isFastBallistics, isFalse);
    expect(controller.state.peakLeft, isFalse);
  });

  test('toggleBallistics switches between slow and fast mode', () {
    final controller = VuMeterController();
    controller.toggleBallistics();
    expect(controller.state.isFastBallistics, isTrue);
    controller.toggleBallistics();
    expect(controller.state.isFastBallistics, isFalse);
  });

  test('pulseTick impulses the needles', () {
    final controller = VuMeterController();
    controller.pulseTick(0.6);
    expect(controller.state.leftLevel, greaterThan(0.0));
    expect(controller.state.rightLevel, greaterThan(0.0));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vumeter/vu_meter_controller_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement domain, controller, painter, and widget**

Implement:
1. `lib/features/vumeter/domain/vu_meter_state.dart`
2. `lib/features/vumeter/presentation/vu_meter_controller.dart` with critically damped spring ballistics decay.
3. `lib/features/vumeter/presentation/vu_meter_painter.dart` rendering twin oval meter apertures, `-20dB` to `+3dB` arc scales, warm amber backlight radial glow, and dual pivoted galvanometer needles.
4. `lib/features/vumeter/presentation/analog_vu_meter_widget.dart` with 280px chassis and front-panel ballistics toggle.

- [ ] **Step 4: Run controller and widget tests to verify they pass**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vumeter/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/vumeter/ test/features/vumeter/
git commit -m "feat(vumeter): add Analog Dual VU Meter with twin galvanometer needles and ballistics engine"
```

---

### Task 2: Chassis Finish Theme Switcher & Persistence

**Files:**
- Modify: `lib/app/theme/takt_colors.dart`
- Create: `lib/app/theme/theme_controller.dart`
- Create: `lib/features/desk/presentation/widgets/chassis_theme_switch.dart`
- Test: `test/app/theme_controller_test.dart`

**Interfaces:**
- Consumes: `AppDatabase` (`watchDeskPreferences`, `updateDeskPreferences`).
- Produces: `chassisThemeProvider` providing `ChassisThemeState(isDarkMode: bool)` and `ChassisThemeSwitch` widget.

- [ ] **Step 1: Write failing theme controller test**

```dart
// test/app/theme_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';

void main() {
  test('ThemeController defaults to dark obsidian chassis', () {
    final controller = ThemeController();
    expect(controller.state.isDarkMode, isTrue);
  });

  test('toggleTheme alternates between dark and light finish', () {
    final controller = ThemeController();
    controller.toggleTheme();
    expect(controller.state.isDarkMode, isFalse);
    controller.toggleTheme();
    expect(controller.state.isDarkMode, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/app/theme_controller_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement theme controller, color tokens, and switch widget**

Implement:
1. Palette tokens for Light Chassis in `lib/app/theme/takt_colors.dart` (`lightChassisCanvas`, `lightChassisBasalt`, `lightChassisFaceplate`).
2. `lib/app/theme/theme_controller.dart` synchronizing with Drift SQLite `AppDatabase`.
3. `lib/features/desk/presentation/widgets/chassis_theme_switch.dart` rendering a tactile Dieter Rams slide switch.

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/app/theme_controller_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/app/theme/ lib/features/desk/presentation/widgets/chassis_theme_switch.dart test/app/theme_controller_test.dart
git commit -m "feat(theme): add chassis finish theme switcher (Braun Dark vs Light) with sqlite persistence"
```

---

### Task 3: Responsive Workbench Layout & Desk Canvas Integration

**Files:**
- Create: `lib/features/desk/presentation/widgets/modular_rack_bracket.dart`
- Modify: `lib/features/desk/presentation/desk_canvas_screen.dart`
- Modify: `test/features/desk/desk_screen_test.dart`

**Interfaces:**
- Consumes: `ChronoDialWidget`, `AnalogVuMeterWidget`, `ReceiptRunnerWidget`, `VinylPlayerWidget`, `ChassisThemeSwitch`.
- Produces: Responsive 2x2 workbench layout on width >= 680px, single column on width < 680px.

- [ ] **Step 1: Write failing widget test for responsive layout and VU meter presence**

Add tests in `test/features/desk/desk_screen_test.dart` checking:
1. `AnalogVuMeterWidget` and `ChassisThemeSwitch` rendered on `DeskCanvasScreen`.
2. Layout adapts to 2x2 grid when screen width >= 680px.

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/desk/desk_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement modular rack bracket and update DeskCanvasScreen**

1. Create `modular_rack_bracket.dart` rendering brushed aluminum rack connectors between adjacent instruments.
2. Update `desk_canvas_screen.dart` to use `LayoutBuilder` to arrange modules in 2x2 workbench on wide viewports (desktop Linux), or single-column on mobile, with theme colors.

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/desk/desk_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Run full test suite and flutter analyze**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test`
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`
Expected: All 73+ tests PASS, 0 analyzer issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/desk/ test/features/desk/
git commit -m "feat(desk): integrate Analog VU Meter, responsive 2x2 workbench layout, and rack clips"
```
