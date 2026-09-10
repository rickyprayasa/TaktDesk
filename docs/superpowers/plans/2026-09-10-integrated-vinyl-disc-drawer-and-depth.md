# Integrated Vinyl Disc Drawer & 2.5D Physical Depth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the oversized modal bottom sheet with an in-place, tactile 2.5D Disc Drawer attached to the `BRAUN TP-1` vinyl turntable chassis, and introduce realistic 2.5D machined chamfers and recessed platter wells across the instruments.

**Architecture:**
- Extend `VinylState` and `VinylController` to manage `isDrawerOpen` state with haptic feedback.
- Build `VinylDiscDrawerWidget` inside the `BRAUN TP-1` chassis featuring a brushed metal handle bar, `AnimatedSize` mechanical expansion, side guide rails, and a compact horizontal carousel of 8 album sleeves.
- Upgrade `MaterialChassisBox` with top/left specular chamfer rims and deep ambient drop shadows, and `VinylDeckPainter` with an inner radial shadow well for sunken platter realism.

**Tech Stack:** Flutter / Dart, Riverpod, CustomPainter (GPU-accelerated procedural vectors), HapticService.

## Global Constraints

- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetic ("Weniger, aber besser").
- Target platform: Mobile Android (maxWidth 440px handheld console, module width 280px).
- 0 analyzer warnings (`flutter analyze`).
- 100% test pass rate across repository (`flutter test`).
- Avoid external raster image assets; use mathematical procedural Flutter shaders/painters to guarantee crispness at all DPIs and 60fps performance.
- Offline-first: zero external streaming dependencies.

---

### Task 1: 2.5D Physical Depth Relief (Chassis Chamfers & Recessed Platter Well)

**Files:**
- Modify: `lib/app/theme/widgets/material_chassis_box.dart`
- Modify: `lib/features/vinyl/presentation/vinyl_deck_painter.dart`
- Modify: `test/app/theme/material_chassis_box_test.dart`
- Modify: `test/features/vinyl/vinyl_player_widget_test.dart`

**Interfaces:**
- Consumes: `ChassisThemeState.isDarkMode`, `ChassisThemeState.borderColor`, `ChassisThemeState.moduleChassisColor`.
- Produces: Enhanced `MaterialChassisBox` with dual-edge chamfer highlight and `VinylDeckPainter` with recessed inner well shadow.

- [ ] **Step 1: Write the failing test**

In `test/app/theme/material_chassis_box_test.dart`:
- Add test verifying that `MaterialChassisBox` renders multi-layer elevation depth and top-edge chamfer highlight.
In `test/features/vinyl/vinyl_player_widget_test.dart`:
- Add test asserting `VinylDeckPainter.paint` draws the recessed platter well shadow.

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/app/theme/material_chassis_box_test.dart test/features/vinyl/vinyl_player_widget_test.dart`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

1. In `lib/app/theme/widgets/material_chassis_box.dart`:
   - Enhance box decoration:
     - Add inner top-left specular chamfer line using `Border(top: BorderSide(...), left: BorderSide(...))` or custom border painter.
     - Add enhanced multi-layer `BoxShadow` (ambient contact shadow + deep directional cast shadow: `offset: Offset(0, 4), blurRadius: 10`).
2. In `lib/features/vinyl/presentation/vinyl_deck_painter.dart`:
   - In `paint()`, before drawing the platter disc, draw a recessed circular well:
     - Outer ring with radial gradient from `Color(0x55000000)` at `radius + 3.0` fading inward to `Colors.transparent` at `radius - 4.0`.

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/app/theme/material_chassis_box_test.dart test/features/vinyl/vinyl_player_widget_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/app/theme/widgets/material_chassis_box.dart lib/features/vinyl/presentation/vinyl_deck_painter.dart test/app/theme/material_chassis_box_test.dart test/features/vinyl/vinyl_player_widget_test.dart
git commit -m "feat(theme): add 2.5d chamfered chassis edges and recessed platter well shadow"
```

---

### Task 2: Vinyl State Drawer Expansion & `VinylDiscDrawerWidget` Component

**Files:**
- Modify: `lib/features/vinyl/presentation/vinyl_controller.dart`
- Create: `lib/features/vinyl/presentation/widgets/vinyl_disc_drawer_widget.dart`
- Create: `test/features/vinyl/vinyl_disc_drawer_widget_test.dart`
- Modify: `test/features/vinyl/vinyl_controller_test.dart`

**Interfaces:**
- Consumes: `VinylState`, `VinylController`, `VinylTrack.presets`, `showStudioProDialog`, `MaterialTexturePainter`.
- Produces: `VinylState.isDrawerOpen`, `VinylController.toggleDrawer()`, `VinylDiscDrawerWidget`.

- [ ] **Step 1: Write the failing test**

In `test/features/vinyl/vinyl_controller_test.dart`:
- Assert `VinylState.isDrawerOpen` defaults to `false`.
- Assert `VinylController.toggleDrawer()` toggles `isDrawerOpen` to `true` and back to `false`.
In `test/features/vinyl/vinyl_disc_drawer_widget_test.dart`:
- Assert `VinylDrawerHandle` renders `[ RECORD DRAWER // 08 DISCS ▾ ]`.
- Assert tapping handle triggers `toggleDrawer()`.
- Assert when `isDrawerOpen == true`, carousel renders with 8 album sleeve cards.
- Assert tapping `[ LOAD TO PLATTER ]` calls `controller.selectTrack(index)`.
- Assert tapping locked track opens `StudioProDialog`.

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/vinyl_controller_test.dart test/features/vinyl/vinyl_disc_drawer_widget_test.dart`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

1. In `lib/features/vinyl/presentation/vinyl_controller.dart`:
   - Add `final bool isDrawerOpen;` to `VinylState` (default `false`), update `copyWith` and `props`.
   - Add `void toggleDrawer()` to `VinylController`:
     ```dart
     void toggleDrawer() {
       state = state.copyWith(isDrawerOpen: !state.isDrawerOpen);
       HapticService.selectionClick();
     }
     ```
2. In `lib/features/vinyl/presentation/widgets/vinyl_disc_drawer_widget.dart`:
   - Implement `VinylDiscDrawerWidget` (ConsumerWidget):
     - Outer container with `margin: const EdgeInsets.only(top: 8)`.
     - `VinylDrawerHandle`:
       - Height: 32px, `plateGradient` brushed metallic background, 2 side rivets (`rivetColor`), center plate: `[ RECORD DRAWER // 08 DISCS ${isOpen ? '▲' : '▾'} ]`.
       - Semantics: `button: true, label: 'Toggle record crate drawer'`.
     - `AnimatedSize(duration: Duration(milliseconds: 280), curve: Curves.easeInOutCubic, child: ...)`
     - When `isOpen`:
       - Interior bay: side mechanical guide rails (`Border(left: ..., right: ...)`).
       - Navigation header: `[ ${(page + 1).toString().padLeft(2, '0')} / 08 ]`, `◀` (`drawer_prev_disc`), `▶` (`drawer_next_disc`).
       - `PageView.builder(controller: _pageController, itemCount: 8, viewportFraction: 0.86)`:
         - Each card (~200px wide x 135px high):
           - Top: Catalog ID (`TK-01`), track name, subtitle.
           - Center: Mini procedural vinyl disc with grooves, center label, and active illuminated amber halo if on platter.
           - Bottom: Action button:
             - Active: `[ ON PLATTER ]` (amber accent).
             - Unlocked: `[ LOAD TO PLATTER ]` (calls `controller.selectTrack(index)`).
             - Locked: `[ STUDIO PRO 🔒 ]` (calls `showStudioProDialog`).

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/vinyl_controller_test.dart test/features/vinyl/vinyl_disc_drawer_widget_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/vinyl/presentation/vinyl_controller.dart lib/features/vinyl/presentation/widgets/vinyl_disc_drawer_widget.dart test/features/vinyl/vinyl_controller_test.dart test/features/vinyl/vinyl_disc_drawer_widget_test.dart
git commit -m "feat(vinyl): create integrated VinylDiscDrawerWidget with mechanical expand and album carousel"
```

---

### Task 3: Turntable Deck Integration & Deprecate Modal Bottom Sheet

**Files:**
- Modify: `lib/features/vinyl/presentation/vinyl_player_widget.dart`
- Delete: `lib/features/vinyl/presentation/widgets/vinyl_record_crate_sheet.dart`
- Delete: `test/features/vinyl/vinyl_record_crate_sheet_test.dart`
- Modify: `test/features/vinyl/vinyl_player_widget_test.dart`

**Interfaces:**
- Consumes: `VinylDiscDrawerWidget`.
- Produces: Integrated turntable deck with in-place disc drawer; eliminates full-screen modal bottom sheet.

- [ ] **Step 1: Write the failing test**

In `test/features/vinyl/vinyl_player_widget_test.dart`:
- Assert `VinylDiscDrawerWidget` is present in `VinylPlayerWidget`.
- Assert `_CrateTriggerBadge` and `VinylRecordCrateSheet` references are removed.
- Assert tapping drawer handle expands drawer and selecting track updates active track on deck.

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/vinyl_player_widget_test.dart`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

1. In `lib/features/vinyl/presentation/vinyl_player_widget.dart`:
   - Remove `_CrateTriggerBadge`.
   - In the bottom row below platter: display track name on left and `33 RPM` status on right.
   - Below the row, add `const VinylDiscDrawerWidget()`.
2. Delete `lib/features/vinyl/presentation/widgets/vinyl_record_crate_sheet.dart` and `test/features/vinyl/vinyl_record_crate_sheet_test.dart`.

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/vinyl_player_widget_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/vinyl/presentation/vinyl_player_widget.dart test/features/vinyl/vinyl_player_widget_test.dart
git rm lib/features/vinyl/presentation/widgets/vinyl_record_crate_sheet.dart test/features/vinyl/vinyl_record_crate_sheet_test.dart
git commit -m "refactor(vinyl): embed VinylDiscDrawerWidget into turntable deck and remove legacy crate modal"
```

---

### Task 4: End-to-End Verification & Whole-Branch Quality Gate

**Files:**
- Full repository test suite and static analyzer.

- [ ] **Step 1: Run static code analysis**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`
Expected: 0 issues found.

- [ ] **Step 2: Run full test suite**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test`
Expected: 100% tests passing across all suites.

- [ ] **Step 3: Whole-branch review**

Review diff package against base commit and obtain approval before push.
