# Takt Desk: Archive Drawer, Split-Flap Pomodoro, Interactive Dial & Compact Console Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the Stereo VU meter, eliminate vertical scrolling with a compact 3-instrument console layout, fix the Chrono Dial needle mapping and enable direct rotary dragging, fix receipt paper asymmetry and tear bugs, add the Slide-Out Brass Archive Drawer, and add the 3D Split-Flap Pomodoro Display.

**Architecture:** 
- Modular Flutter architecture with Riverpod controllers and Drift SQLite persistence.
- Decoupled 3D matrix transforms and custom painters for realistic tactile mechanical instruments.
- Responsive layout prioritizing zero vertical scrolling on desktop Linux and tablets with a 3-column modular audio rack.

**Tech Stack:** Flutter 3.27+, Dart 3.6+, Flutter Riverpod 2.6+, Drift SQLite, Sensors Plus.

## Global Constraints

- Android Target SDK 34+, Min SDK 24 / Linux Desktop.
- Zero AI Slop: Strictly adhere to TaktPalette (Dieter Rams / Braun aesthetic: Obsidian, Basalt Slate, Warm Bone, Thermal Carbon, Muted Ochre, Filament Amber).
- No vertical scrolling on standard desktop resolutions (>= 600px height).
- 0 analyzer warnings, 100% test suite passing.

---

### Task 1: Chrono Dial Needle Mapping & Interactive Rotary Drag

**Files:**
- Modify: `lib/features/timer/presentation/chrono_dial_painter.dart`
- Modify: `lib/features/timer/presentation/chrono_dial_widget.dart`
- Test: `test/features/timer/timer_controller_test.dart`
- Test: `test/features/timer/chrono_dial_widget_test.dart`

**Interfaces:**
- Needle angle calculated directly from remaining time: $\theta = \left(\frac{\text{remainingSeconds}}{3600.0}\right) \times 2\pi - \frac{\pi}{2}$.
- Rotary drag on dial surface updates `targetMinutes` in real time with haptic ticks and click sounds.

- [ ] **Step 1: Update needle angle calculation in `ChronoDialPainter`**
  - Pass `remainingSeconds` to `ChronoDialPainter`.
  - Draw needle pointing directly to the corresponding minute mark (e.g. 25 min -> mark 25, 9 min -> mark 09).
- [ ] **Step 2: Expand interactive drag area in `ChronoDialWidget`**
  - Allow user to drag anywhere across the dial face (`dist < dialRadius + 20`).
  - Update `ref.read(chronoDialProvider.notifier).setTargetMinutes(...)` as user rotates finger/cursor.
- [ ] **Step 3: Run unit and widget tests for Chrono Dial**
  - Run `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/`
- [ ] **Step 4: Commit Task 1**
  - `git commit -am "fix(timer): synchronize dial needle angle with minutes and enable full-surface rotary drag"`

---

### Task 2: Receipt Paper Symmetry, Straight Edges & Tear Bug Fix

**Files:**
- Modify: `lib/features/tasks/presentation/receipt_runner_painter.dart`
- Modify: `lib/features/tasks/presentation/widgets/animated_receipt_strip.dart`
- Modify: `lib/features/tasks/presentation/receipt_runner_controller.dart`
- Test: `test/features/tasks/receipt_runner_widget_test.dart`

**Interfaces:**
- Thermal paper is perfectly horizontal, straight, and symmetric at rest.
- Tearing uses clean local progress that resets to 0.0 on drag release or dismissal.

- [ ] **Step 1: Fix `ReceiptRunnerPainter` for symmetric straight serration**
  - Ensure tooth height is uniform across the entire width without residual skew or shearing when `tearProgress == 0`.
- [ ] **Step 2: Fix `AnimatedReceiptStrip` state handling**
  - Reset `_localTearProgress = 0.0` on drag cancel / completion.
  - Constrain perspective rotation so paper stays within chassis bounds.
- [ ] **Step 3: Run tests in `test/features/tasks/`**
  - Run `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/tasks/`
- [ ] **Step 4: Commit Task 2**
  - `git commit -am "fix(tasks): fix receipt paper asymmetry and eliminate residual shear on tear"`

---

### Task 3: Slide-Out Brass Archive Drawer

**Files:**
- Modify: `lib/core/audio/sound_effect.dart` (add `drawerSlide`, `drawerLatch`)
- Create: `lib/features/tasks/presentation/widgets/archive_drawer_widget.dart`
- Modify: `lib/features/tasks/presentation/receipt_runner_widget.dart`
- Modify: `lib/features/tasks/presentation/receipt_runner_controller.dart`
- Test: `test/features/tasks/archive_drawer_test.dart`

**Interfaces:**
- `ArchiveDrawerWidget`: Attached at the bottom of `ReceiptRunnerWidget`.
- Pull/click handle with brass finish (`#C89B59` / `#9E7B3B`) and engraved "ARCHIVE" label.
- Slides open with `Curves.easeOutCubic`, listing completed tasks with reprint/purge buttons.

- [ ] **Step 1: Add sound effects to `SoundEffect` enum**
- [ ] **Step 2: Write unit/widget test for `ArchiveDrawerWidget` and reprint controller method**
- [ ] **Step 3: Implement `ArchiveDrawerWidget` and wire into `ReceiptRunnerWidget`**
- [ ] **Step 4: Run tests in `test/features/tasks/`**
- [ ] **Step 5: Commit Task 3**
  - `git commit -am "feat(tasks): add Slide-Out Brass Archive Drawer with reprint and purge"`

---

### Task 4: 3D Split-Flap Mechanical Pomodoro Display

**Files:**
- Create: `lib/features/timer/domain/pomodoro_phase.dart`
- Modify: `lib/features/timer/domain/timer_state.dart`
- Modify: `lib/features/timer/presentation/chrono_dial_controller.dart`
- Create: `lib/features/timer/presentation/widgets/split_flap_board_widget.dart`
- Modify: `lib/features/timer/presentation/chrono_dial_widget.dart`
- Test: `test/features/timer/split_flap_pomodoro_test.dart`

**Interfaces:**
- `PomodoroPhase`: `focus` (25m), `shortBreak` (5m), `longBreak` (15m).
- `SplitFlapBoardWidget`: 3D perspective folding cards (`Matrix4.identity()..setEntry(3, 2, 0.002)..rotateX(angle)`).
- Automatic phase transitions upon timer countdown completion.

- [ ] **Step 1: Define `PomodoroPhase` and update `TimerState`**
- [ ] **Step 2: Update `ChronoDialController` with pomodoro progression logic**
- [ ] **Step 3: Create `SplitFlapBoardWidget` with 3D mechanical card fold animation**
- [ ] **Step 4: Mount split-flap board above Chrono Dial in `ChronoDialWidget`**
- [ ] **Step 5: Run tests in `test/features/timer/`**
- [ ] **Step 6: Commit Task 4**
  - `git commit -am "feat(timer): add 3D Split-Flap Mechanical Pomodoro Display with phase progression"`

---

### Task 5: Removal of VU Meter & Non-Scrolling Responsive Console Layout

**Files:**
- Modify: `lib/features/desk/presentation/desk_canvas_screen.dart`
- Modify: `test/features/desk/desk_screen_test.dart`

**Interfaces:**
- 3 core instruments: Chrono Dial (with Split-Flap), Task Runner (with Archive Drawer), Vinyl Deck.
- Wide layout (width >= 720px): Clean horizontal 3-instrument rack side-by-side with zero vertical scrolling.
- Compact layout: Clean responsive fitting without long vertical overflow.

- [ ] **Step 1: Remove `AnalogVuMeterWidget` from `desk_canvas_screen.dart`**
- [ ] **Step 2: Implement 3-instrument horizontal rack console**
- [ ] **Step 3: Update `desk_screen_test.dart`**
- [ ] **Step 4: Verify 0 issues with `flutter analyze` and 100% tests passing with `flutter test`**
- [ ] **Step 5: Commit Task 5**
  - `git commit -am "feat(desk): remove VU meter and implement compact non-scrolling 3-instrument console"`
