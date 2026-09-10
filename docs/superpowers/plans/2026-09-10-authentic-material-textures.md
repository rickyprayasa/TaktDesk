# Authentic Physical Material Textures & High-Contrast Finish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the visual finish of all three instruments (Chrono Dial, Task Dispenser, Vinyl Player) from flat solid colors to authentic procedural material textures (hairline brushed titanium, burnished marine brass with patina, tubular chrome reflections, and matte ABS grain) and resolve the bleached/transparent text defect in Light Mode by introducing high-contrast typography tokens.

**Architecture:** Extend `HardwareEdition` with `HardwareTextureType` and `ChassisThemeState` with `chassisTextColor` and `chassisMutedTextColor`. Build a reusable, 60fps-performant `MaterialChassisBox` with procedural `CustomPainter` textures, and refactor all instrument labels and controls to consume dynamic contrast tokens so text is crystal clear in both light and dark modes.

**Tech Stack:** Flutter 3.x, Dart 3.x, Riverpod, CustomPainter.

## Global Constraints

- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetic (*Weniger, aber besser*).
- Target platform: Mobile Android handheld console (maxWidth 440px).
- 0 analyzer issues (`/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`).
- 100% test pass rate across repository.
- Avoid external raster image assets; use mathematical procedural Flutter shaders/painters to guarantee crispness at all DPIs and 60fps performance.

---

### Task 1: HardwareTextureType Domain Model & High-Contrast Chassis Text Tokens

**Files:**
- Modify: `lib/app/theme/hardware_edition.dart`
- Modify: `lib/app/theme/theme_controller.dart`
- Modify: `test/app/theme/hardware_edition_test.dart`

**Interfaces:**
- Consumes: `HardwareEdition`, `ChassisThemeState`.
- Produces:
  - `enum HardwareTextureType { matteAbsGrain, brushedTitanium, tubularChrome, burnishedBrass }`
  - `HardwareEdition.textureType`
  - `ChassisThemeState.chassisTextColor`, `ChassisThemeState.chassisMutedTextColor`
  - Refined `lightModuleBg` values ensuring distinct separation from `lightCanvas`.

- [ ] **Step 1: Write the failing test**

In `test/app/theme/hardware_edition_test.dart`, add tests verifying:
- Each of the 4 editions has its specified `textureType`.
- `ChassisThemeState.chassisTextColor` and `chassisMutedTextColor` return dark colors in light mode and light colors in dark mode.
- Module background has distinct contrast from canvas in both dark and light modes.

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/app/theme/hardware_edition_test.dart`  
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

1. In `lib/app/theme/hardware_edition.dart`:
Add `enum HardwareTextureType { matteAbsGrain, brushedTitanium, tubularChrome, burnishedBrass }`.
Add `final HardwareTextureType textureType;` to `HardwareEdition`.
Assign:
- `braunClassic`: `HardwareTextureType.matteAbsGrain`, `lightModuleBg: Color(0xFFCFCBC0)`
- `titaniumStealth`: `HardwareTextureType.brushedTitanium`, `lightModuleBg: Color(0xFFBFC4CD)`
- `bauhausHeritage`: `HardwareTextureType.tubularChrome`, `lightModuleBg: Color(0xFFD3CFC7)`
- `rawBrassPatina`: `HardwareTextureType.burnishedBrass`, `lightModuleBg: Color(0xFFCCC7B3)`

2. In `lib/app/theme/theme_controller.dart`:
Add getters on `ChassisThemeState`:
```dart
Color get chassisTextColor =>
    isDarkMode ? const Color(0xFFE8E5DE) : const Color(0xFF1B1E23);

Color get chassisMutedTextColor =>
    isDarkMode ? const Color(0x99E8E5DE) : const Color(0x991B1E23);

HardwareTextureType get textureType => edition.textureType;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/app/theme/hardware_edition_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/app/theme/hardware_edition.dart lib/app/theme/theme_controller.dart test/app/theme/hardware_edition_test.dart
git commit -m "feat(theme): add HardwareTextureType and chassis contrast text tokens"
```

---

### Task 2: Procedural Texture Painters & Reusable MaterialChassisBox Component

**Files:**
- Create: `lib/app/theme/widgets/material_texture_painter.dart`
- Create: `lib/app/theme/widgets/material_chassis_box.dart`
- Create: `test/app/theme/material_chassis_box_test.dart`

**Interfaces:**
- Consumes: `HardwareTextureType`, `ChassisThemeState`.
- Produces:
  - `MaterialTexturePainter`: CustomPainter rendering procedural micro-hairlines (brushed titanium), subtle patina vignette & warm striations (burnished brass), mirror chrome highlights (tubular chrome), and fine stippled ABS grain (Braun classic).
  - `MaterialChassisBox`: Container widget that applies the appropriate texture painter, outer bezel border, 4 corner rivets, and elevation shadow around any child widget.

- [ ] **Step 1: Write the failing test**

In `test/app/theme/material_chassis_box_test.dart`, test that `MaterialChassisBox`:
- Renders its child inside a textured container.
- Embeds 4 corner rivets with `rivetKeyPrefix`.
- Reacts dynamically when theme changes from `braunClassic` to `titaniumStealth`.

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/app/theme/material_chassis_box_test.dart`  
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

1. Implement `MaterialTexturePainter` in `lib/app/theme/widgets/material_texture_painter.dart`:
   - `paint()` checks `textureType`:
     - `brushedTitanium`: Draws horizontal micro-hairline strokes (`Colors.white` and `Colors.black` at low alpha `0.04-0.08`) across the rect.
     - `burnishedBrass`: Draws horizontal hairline brush with warm gold tint plus a perimeter darker patina gradient.
     - `tubularChrome`: Draws dual specular linear gradient bands at 45 degrees simulating chrome reflection.
     - `matteAbsGrain`: Draws subtle stippling dot grid simulating matte thermoplastic texture.
   - `shouldRepaint` checks `textureType`, `isDark`, and `chassisColor`.

2. Implement `MaterialChassisBox` in `lib/app/theme/widgets/material_chassis_box.dart`:
   - Wraps child in `Stack` with:
     1. Base `BoxDecoration` with `themeState.moduleChassisColor`, `themeState.borderColor`, and multi-layer elevation shadows.
     2. `CustomPaint(painter: MaterialTexturePainter(...))` clipped to rounded rect.
     3. 4 corner rivets with `themeState.rivetColor` wrapped in `IgnorePointer`.
     4. The `child` widget.

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/app/theme/material_chassis_box_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/app/theme/widgets/material_texture_painter.dart lib/app/theme/widgets/material_chassis_box.dart test/app/theme/material_chassis_box_test.dart
git commit -m "feat(theme): implement procedural MaterialTexturePainter and reusable MaterialChassisBox"
```

---

### Task 3: Instrument High-Contrast Legibility & Texture Integration (Vinyl Player & Task Dispenser)

**Files:**
- Modify: `lib/features/vinyl/presentation/vinyl_player_widget.dart`
- Modify: `lib/features/tasks/presentation/receipt_runner_widget.dart`
- Modify: `lib/features/tasks/presentation/widgets/dispenser_slot_header.dart`
- Modify: `test/features/vinyl/vinyl_player_widget_test.dart`
- Modify: `test/features/tasks/receipt_runner_widget_test.dart`

**Interfaces:**
- Consumes: `MaterialChassisBox`, `themeState.chassisTextColor`, `themeState.chassisMutedTextColor`.
- Produces:
  - Vinyl Player deck wrapped in `MaterialChassisBox` with high-contrast text (`BRAUN TP-1`, `33 RPM`, `LO-FI RAIN` using `chassisTextColor`).
  - Task Dispenser wrapped in `MaterialChassisBox` with high-contrast text (`DISPENSER: 5 MAX` and `+` button using `chassisTextColor`).

- [ ] **Step 1: Write the failing test**

Update `test/features/vinyl/vinyl_player_widget_test.dart` and `test/features/tasks/receipt_runner_widget_test.dart` to assert that in Light Mode:
- Text `BRAUN TP-1` has color `themeState.chassisTextColor` (not `warmBone`).
- Text `DISPENSER: 5 MAX` has color `themeState.chassisTextColor` (not `warmBone`).
- `MaterialChassisBox` is present in the widget tree.

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/vinyl_player_widget_test.dart test/features/tasks/receipt_runner_widget_test.dart`  
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

1. In `lib/features/vinyl/presentation/vinyl_player_widget.dart`:
   - Replace raw container with `MaterialChassisBox(rivetKeyPrefix: 'vinyl_rivet', width: 280, ...)`.
   - Update `BRAUN TP-1` title style: `TaktTypography.controlLabel.copyWith(color: themeState.chassisTextColor)`.
   - Update `33 RPM` and `LO-FI RAIN` style: `TextStyle(color: themeState.chassisMutedTextColor, ...)`.
   - Update track selector text and border to use `themeState.chassisTextColor` / `themeState.borderColor`.

2. In `lib/features/tasks/presentation/receipt_runner_widget.dart`:
   - Replace raw container with `MaterialChassisBox(rivetKeyPrefix: 'dispenser_rivet', width: 280, ...)`.
   - Update empty state text to `themeState.chassisMutedTextColor`.

3. In `lib/features/tasks/presentation/widgets/dispenser_slot_header.dart`:
   - Update `DISPENSER: 5 MAX` style to use `themeState.chassisTextColor`.
   - Update `+` button icon color to use `themeState.chassisTextColor`.
   - Update inactive pip LED dot color to `themeState.borderColor`.

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/vinyl_player_widget_test.dart test/features/tasks/receipt_runner_widget_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/vinyl/presentation/vinyl_player_widget.dart lib/features/tasks/presentation/receipt_runner_widget.dart lib/features/tasks/presentation/widgets/dispenser_slot_header.dart test/features/vinyl/vinyl_player_widget_test.dart test/features/tasks/receipt_runner_widget_test.dart
git commit -m "feat(instruments): integrate MaterialChassisBox and high-contrast typography into vinyl player and task dispenser"
```

---

### Task 4: Chrono Dial Pill Timer, Crown, Split-Flap Contrast & Texture Integration

**Files:**
- Modify: `lib/features/timer/presentation/chrono_dial_widget.dart`
- Modify: `lib/features/timer/presentation/chrono_dial_painter.dart`
- Modify: `lib/features/timer/presentation/widgets/split_flap_board_widget.dart`
- Modify: `test/features/timer/chrono_dial_widget_test.dart`

**Interfaces:**
- Consumes: `themeState.chassisTextColor`, `themeState.textureType`.
- Produces:
  - Pill Timer text `${state.targetMinutes} MIN` and `+`/`-` buttons use `themeState.chassisTextColor` (eliminating light mode washed-out/transparent bug).
  - Split-flap board frame container uses `themeState.moduleChassisColor` and border `themeState.borderColor`.
  - Chrono dial outer bezel incorporates micro-grain striations or knurl highlight matching `textureType`.

- [ ] **Step 1: Write the failing test**

In `test/features/timer/chrono_dial_widget_test.dart`, assert that in Light Mode:
- Pill Timer text `25 MIN` has color `themeState.chassisTextColor` when stopped.
- `+` and `-` icons have color `themeState.chassisTextColor` when stopped.

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_dial_widget_test.dart`  
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

1. In `lib/features/timer/presentation/chrono_dial_widget.dart`:
   - Update Pill Timer duration text:
     ```dart
     color: state.isRunning ? themeState.filamentColor : themeState.chassisTextColor,
     ```
   - Update `IconButton` icons:
     ```dart
     color: state.isRunning ? themeState.borderColor : themeState.chassisTextColor,
     ```
   - Pass `textureType: themeState.textureType` to `ChronoDialPainter`.

2. In `lib/features/timer/presentation/chrono_dial_painter.dart`:
   - Add parameter `final HardwareTextureType textureType;`.
   - In `paint()` on outer bezel, tailor diamond knurling stroke opacity and radial highlights based on `textureType` (e.g. burnished brass has warmer knurl lines, titanium has crisp specular knurls).

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_dial_widget_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/timer/presentation/chrono_dial_widget.dart lib/features/timer/presentation/chrono_dial_painter.dart lib/features/timer/presentation/widgets/split_flap_board_widget.dart test/features/timer/chrono_dial_widget_test.dart
git commit -m "feat(timer): integrate high-contrast text and textureType into Chrono Dial, Pill Timer, and Split Flap"
```

---

### Task 5: End-to-End Verification & Whole-Branch Quality Gate

**Files:**
- Whole repository test suites and analyzer.

- [ ] **Step 1: Run full test suite**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test`  
Expected: 100% tests passing across all suites.

- [ ] **Step 2: Run static code analysis**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`  
Expected: 0 issues found.

- [ ] **Step 3: Whole-branch review & Push to GitHub**

Review diff package and push to `origin/main`.
