# Dial & Archive Light-Mode Industrial Refinement Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Overhaul the Pomodoro Chrono Dial and Task Dispenser Archive Drawer in Light Mode to eliminate the unnatural black-hole clock defect, remove the disjointed 2-color drawer mismatch, and deliver authentic, high-contrast Dieter Rams / Braun industrial aesthetics across all 4 hardware editions.

**Architecture:** 
1. Upgrade `ChronoDialPainter` with dual-mode light/dark horological rendering: authentic off-white/porcelain matte dial faces, crisp dark charcoal tick marks and numerals, shadow-etched knurling grooves on metallic bezels, and theme-synchronized `MonasticSwitchWidget`.
2. Refactor `ArchiveDrawerWidget` to seamlessly harmonize with `MaterialChassisBox` (eliminating the clashing 2-color split), and upgrade all drawer typography/actions (handle plate, archived task cards, reprint button, purge link) to high-contrast theme tokens.

**Tech Stack:** Flutter 3.x, Dart 3.x, Riverpod, CustomPainter.

---

## Global Constraints

- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetic (*Weniger, aber besser*).
- Target platform: Mobile Android handheld console (maxWidth 440px).
- 0 analyzer issues (`/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`).
- 100% test pass rate across repository.
- Avoid external raster image assets; use mathematical procedural Flutter shaders/painters.

---

### Task 1: Pomodoro Chrono Dial & Monastic Switch Light-Mode Industrial Overhaul

**Files:**
- Modify: `lib/features/timer/presentation/chrono_dial_painter.dart`
- Modify: `lib/features/timer/presentation/chrono_dial_widget.dart`
- Modify: `lib/features/desk/presentation/widgets/monastic_switch_widget.dart`
- Modify: `test/features/timer/chrono_dial_widget_test.dart`
- Modify: `test/features/desk/monastic_switch_test.dart`

**Interfaces:**
- Consumes: `themeState.isDarkMode`, `themeState.edition`, `themeState.chassisTextColor`, `themeState.chassisMutedTextColor`, `themeState.moduleChassisColor`, `themeState.borderColor`.
- Produces:
  - `ChronoDialPainter(isDark: ..., dialFaceColor: ...)`: Light mode renders authentic matte porcelain/bone dial face, crisp `#1B1E23` ticks and numbers, and dark shadow knurling grooves.
  - `MonasticSwitchWidget`: Light mode renders seamless `moduleChassisColor` and `chassisTextColor`.

- [ ] **Step 1: Write the failing test**
In `test/features/timer/chrono_dial_widget_test.dart` and `test/features/desk/monastic_switch_test.dart`:
- Assert that in Light Mode:
  - `ChronoDialPainter` receives `isDark == false` and a distinct light `dialFaceColor`.
  - `ChronoDialPainter` paints with dark tick marks and dark numerals.
  - `MonasticSwitchWidget` uses `themeState.moduleChassisColor` and `themeState.chassisTextColor`.

- [ ] **Step 2: Run test to verify it fails**
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_dial_widget_test.dart test/features/desk/monastic_switch_test.dart`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**
1. In `lib/features/timer/presentation/chrono_dial_painter.dart`:
   - Add `final bool isDark;` and `final Color? dialFaceColor;`.
   - In `paint()`:
     - Dial face: `isDark ? const Color(0xFF16181B) : (dialFaceColor ?? const Color(0xFFEBE8DF))`.
     - Knurling strokes: `isDark ? Colors.white.withValues(alpha: knurlAlpha) : Colors.black.withValues(alpha: knurlAlpha * 0.75)`.
     - Ticks: `isDark ? TaktColors.warmBone.withValues(alpha: 0.90) : const Color(0xFF1B1E23).withValues(alpha: 0.88)` (major) and `0.32` / `0.38` (minor).
     - Numerals: `isDark ? TaktColors.warmBone.withValues(alpha: 0.65) : const Color(0xFF1B1E23).withValues(alpha: 0.78)`.
     - Dish shadow: `isDark ? Colors.black.withValues(alpha: 0.45) : Colors.black.withValues(alpha: 0.12)`.
     - Hub cap: `isDark ? const Color(0xFF22252A) : const Color(0xFF2B2E34)`.
     - Glass highlight: `isDark ? [0.15, 0.03] : [0.28, 0.06]`.
   - Update `shouldRepaint`.
2. In `lib/features/timer/presentation/chrono_dial_widget.dart`:
   - Pass `isDark: themeState.isDarkMode` and edition-specific light dial tone:
     - `braunClassic`: `Color(0xFFEAE6DC)`
     - `titaniumStealth`: `Color(0xFFD3D8E0)`
     - `bauhausHeritage`: `Color(0xFFF0EDE4)`
     - `rawBrassPatina`: `Color(0xFFE2DCB8)`
3. In `lib/features/desk/presentation/widgets/monastic_switch_widget.dart`:
   - Use `themeState.moduleChassisColor`, `themeState.borderColor`, and `themeState.chassisTextColor`.

- [ ] **Step 4: Run test to verify it passes**
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_dial_widget_test.dart test/features/desk/monastic_switch_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/features/timer/presentation/chrono_dial_painter.dart lib/features/timer/presentation/chrono_dial_widget.dart lib/features/desk/presentation/widgets/monastic_switch_widget.dart test/features/timer/chrono_dial_widget_test.dart test/features/desk/monastic_switch_test.dart
git commit -m "feat(timer): implement authentic light-mode horological dial face, knurling shadows, and monastic theming"
```

---

### Task 2: Dispenser Archive Drawer Seamless Chassis & High-Contrast Typography

**Files:**
- Modify: `lib/features/tasks/presentation/widgets/archive_drawer_widget.dart`
- Modify: `test/features/tasks/receipt_runner_widget_test.dart`

**Interfaces:**
- Consumes: `themeState.moduleChassisColor`, `themeState.borderColor`, `themeState.canvasColor`, `themeState.chassisTextColor`, `themeState.chassisMutedTextColor`, `themeState.filamentColor`.
- Produces:
  - Unified seamless archive drawer matching dispenser chassis in Light Mode (eliminating the clashing 2-color split).
  - High-contrast handle plate (`ARCHIVE // $count`) and internal task cards/buttons in Light Mode.

- [ ] **Step 1: Write the failing test**
In `test/features/tasks/receipt_runner_widget_test.dart`, add widget test asserting that in Light Mode:
- Archive drawer container has `color: themeState.moduleChassisColor` (not `#1B1E22`).
- Handle center plate text `ARCHIVE // $count` has `color: themeState.chassisTextColor`.
- Archived task cards inside use `themeState.canvasColor` and title text uses `themeState.chassisTextColor`.
- Reprint button and Purge button have distinct high-contrast colors.

- [ ] **Step 2: Run test to verify it fails**
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/tasks/receipt_runner_widget_test.dart`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**
In `lib/features/tasks/presentation/widgets/archive_drawer_widget.dart`:
1. Container background:
   `color: themeState.isDarkMode ? const Color(0xFF1B1E22) : themeState.moduleChassisColor`
2. Handle plate:
   - Background: `themeState.isDarkMode ? themeState.filamentColor.withValues(alpha: 0.15) : themeState.canvasColor`
   - Border: `themeState.isDarkMode ? themeState.filamentColor.withValues(alpha: 0.7) : themeState.borderColor`
   - Text & arrow: `themeState.isDarkMode ? themeState.filamentColor : themeState.chassisTextColor`
3. Inside drawer:
   - Archived task card: `color: themeState.isDarkMode ? const Color(0xFF25282E) : themeState.canvasColor`, border `themeState.borderColor`
   - Archived task title: `color: themeState.chassisTextColor.withValues(alpha: 0.75)`
   - Reprint button: background `themeState.isDarkMode ? const Color(0xFF333842) : themeState.moduleChassisColor`, text `themeState.isDarkMode ? const Color(0xFFD99B59) : const Color(0xFF8B4513)`
   - Delete icon: `themeState.chassisMutedTextColor`
   - PURGE ARCHIVE: `themeState.isDarkMode ? TaktColors.mutedOchre.withValues(alpha: 0.8) : const Color(0xFFB33A18)`
   - DRAWER EMPTY: `themeState.chassisMutedTextColor`

- [ ] **Step 4: Run test to verify it passes**
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/tasks/receipt_runner_widget_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/features/tasks/presentation/widgets/archive_drawer_widget.dart test/features/tasks/receipt_runner_widget_test.dart
git commit -m "feat(tasks): harmonize archive drawer chassis and high-contrast typography in light mode"
```

---

### Task 3: End-to-End Verification & Whole-Branch Quality Gate

**Files:**
- Full test suites and static analyzer.

- [ ] **Step 1: Run full test suite**
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test`
Expected: 100% tests passing.

- [ ] **Step 2: Run static code analysis**
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`
Expected: 0 issues found.

- [ ] **Step 3: Whole-branch review & Push to GitHub**
Review diff package and push to `origin/main`.
