# Full Physical Material Transformation & Gallery Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the physical hardware chassis, bezels, crowns, drawer faceplates, and tonearms of all three instruments (Chrono Dial, Task Dispenser, Vinyl Player) to match the active Hardware Edition finish, and introduce mechanical arrow buttons, counter badge, and page dots to the Service Hatch material gallery.

**Architecture:** Extend `ChassisThemeState` with semantic getters (`plateGradient`, `rivetColor`, `accentColor`), replace static hardcoded colors on instrument outer frames with theme tokens, add corner mechanical rivets to the chassis containers, and replace the unconstrained horizontal scroll in `TaktSettingsSheet` with a controlled snapping `PageView` featuring `[ 01 / 04 ]` counter and `◀`/`▶` tactile arrow controls.

**Tech Stack:** Flutter 3.x, Dart 3.x, Riverpod (StateNotifierProvider), CustomPainter.

## Global Constraints

- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetic (*Weniger, aber besser*).
- Target platform: Mobile Android handheld console (maxWidth 440px).
- 0 analyzer issues (`/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`).
- 100% test pass rate across repository.
- Avoid external billing SDKs (maintain simulated pro developer preview).

---

### Task 1: Service Hatch Gallery Navigation Controls, Snapping Carousel & Page Indicators

**Files:**
- Modify: `lib/app/theme/theme_controller.dart`
- Modify: `lib/features/settings/presentation/takt_settings_sheet.dart`
- Modify: `test/features/settings/takt_settings_sheet_test.dart`

**Interfaces:**
- Consumes: `HardwareEdition`, `ChassisThemeState`, `ThemeController`, `HapticService`.
- Produces:
  - `ChassisThemeState.plateGradient`, `ChassisThemeState.rivetColor`, `ChassisThemeState.accentColor`.
  - `TaktSettingsSheet`:
    - Arrow buttons: `ValueKey('edition_prev_button')`, `ValueKey('edition_next_button')`.
    - Counter text: `[ 01 / 04 ]` (or corresponding 1-indexed page).
    - Page dots: `ValueKey('edition_dot_$index')` for index 0..3.
    - Controlled `PageView.builder` with `PageController(viewportFraction: 0.82)`.

- [ ] **Step 1: Write the failing test**

In `test/features/settings/takt_settings_sheet_test.dart`, add widget tests for the navigation controls:
```dart
testWidgets('TaktSettingsSheet displays gallery counter, arrows, and page dots', (tester) async {
  final container = ProviderContainer(
    overrides: [
      todayFocusStatsProvider.overrideWith(
        (ref) => Stream.value(const TodayFocusStats(completedCount: 1, totalMinutes: 25)),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: TaktSettingsSheet(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // Verify counter badge and arrow buttons exist
  expect(find.textContaining('01 / 04'), findsOneWidget);
  expect(find.byKey(const ValueKey('edition_prev_button')), findsOneWidget);
  expect(find.byKey(const ValueKey('edition_next_button')), findsOneWidget);

  // Verify 4 indicator dots exist
  for (int i = 0; i < 4; i++) {
    expect(find.byKey(ValueKey('edition_dot_$i')), findsOneWidget);
  }

  // Tap next button to advance to page 2
  await tester.tap(find.byKey(const ValueKey('edition_next_button')));
  await tester.pumpAndSettle();

  expect(find.textContaining('02 / 04'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/settings/takt_settings_sheet_test.dart`  
Expected: FAIL with "01 / 04" not found.

- [ ] **Step 3: Write minimal implementation**

1. In `lib/app/theme/theme_controller.dart`, add getters to `ChassisThemeState`:
```dart
  List<Color> get plateGradient =>
      isDarkMode ? edition.plateGradientDark : edition.plateGradientLight;

  Color get rivetColor =>
      isDarkMode ? edition.rivetDark : edition.rivetLight;

  Color get accentColor => edition.accentColor;
```

2. In `lib/features/settings/presentation/takt_settings_sheet.dart`:
Convert `_HardwareEditionsSection` to a `ConsumerStatefulWidget` or manage `PageController`:
- Initialize `_pageController = PageController(initialPage: initialIndex, viewportFraction: 0.82)`.
- Keep track of `_currentPage` (0..3).
- In the section header row:
  - Title: `HARDWARE EDITIONS // CHASSIS MATERIALITY`
  - Counter badge: `[ 0${_currentPage + 1} / 04 ]` in monospace.
  - Micro icon buttons `◀` (`ValueKey('edition_prev_button')`) and `▶` (`ValueKey('edition_next_button')`).
  - Arrow buttons trigger `_pageController.previousPage(...)` / `_pageController.nextPage(...)` with `HapticService.selectionClick()`.
- Carousel:
  - Height 152.
  - `PageView.builder(controller: _pageController, itemCount: 4, onPageChanged: (idx) => setState(() => _currentPage = idx), ...)`
  - Card wrapped with small horizontal margin (e.g. 5px on each side) so cards don't collide when peeking.
- Bottom indicator dots row:
  - 4 dots (`ValueKey('edition_dot_$i')`).
  - Dot diameter 5px.
  - Illuminated with `themeState.filamentColor` if `_currentPage == i`, else muted border color.

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/settings/takt_settings_sheet_test.dart`  
Expected: PASS (all tests passing).

- [ ] **Step 5: Commit**

```bash
git add lib/app/theme/theme_controller.dart lib/features/settings/presentation/takt_settings_sheet.dart test/features/settings/takt_settings_sheet_test.dart
git commit -m "feat(settings): add carousel navigation controls, counter badge, and page dots to Hardware Editions gallery"
```

---

### Task 2: Chrono Dial Outer Bezel, Knurled Crown, Split-Flap Frame & Pill Timer Theming

**Files:**
- Modify: `lib/features/timer/presentation/chrono_dial_painter.dart`
- Modify: `lib/features/timer/presentation/chrono_dial_widget.dart`
- Modify: `lib/features/timer/presentation/widgets/crown_push_button.dart`
- Modify: `lib/features/timer/presentation/widgets/split_flap_board_widget.dart`
- Modify: `test/features/timer/chrono_dial_widget_test.dart`

**Interfaces:**
- Consumes: `themeState.plateGradient`, `themeState.borderColor`, `themeState.moduleChassisColor`.
- Produces:
  - `ChronoDialPainter` accepts `outerBezelGradient` and `innerBezelColor`.
  - `CrownPushButton` accepts optional `gradientColors`, `borderColor`, `stemColor`.
  - `SplitFlapBoardWidget` and Pill Timer container background and border dynamically adapt to active edition.

- [ ] **Step 1: Write the failing test**

In `test/features/timer/chrono_dial_widget_test.dart`, add tests verifying:
- Changing edition to `rawBrassPatina` configures `ChronoDialPainter` with brass plate gradient and border color.
- Pill timer container border color matches active edition border.
- Split-flap board border color matches active edition border.

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_dial_widget_test.dart`  
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

1. In `lib/features/timer/presentation/chrono_dial_painter.dart`:
Add parameters:
```dart
final List<Color> outerBezelGradient;
final Color innerBezelColor;
```
Defaulting to Braun Classic dark colors (`[Color(0xFF353940), Color(0xFF22252A), Color(0xFF181A1D)]` and `Color(0xFF141517)`).
Use `outerBezelGradient` in `RadialGradient(colors: outerBezelGradient, stops: [0.85, 0.95, 1.0])`.
Use `innerBezelColor` in `innerBezelStroke.color = innerBezelColor`.
Update `shouldRepaint` to check `outerBezelGradient` and `innerBezelColor`.

2. In `lib/features/timer/presentation/widgets/crown_push_button.dart`:
Add optional parameters:
```dart
final List<Color>? gradientColors;
final Color? borderColor;
final Color? stemColor;
```
Use them in the decoration of the crown cap and stem collar.

3. In `lib/features/timer/presentation/widgets/split_flap_board_widget.dart`:
Read `final themeState = ref.watch(chassisThemeProvider);`.
Update container decoration:
```dart
color: themeState.moduleChassisColor,
borderRadius: BorderRadius.circular(6),
border: Border.all(color: themeState.borderColor, width: 1.0),
```

4. In `lib/features/timer/presentation/chrono_dial_widget.dart`:
Pass `outerBezelGradient: themeState.plateGradient`, `innerBezelColor: themeState.borderColor` to `ChronoDialPainter`.
Pass `gradientColors: themeState.plateGradient`, `borderColor: themeState.borderColor`, `stemColor: themeState.moduleChassisColor` to `CrownPushButton`.
Update Pill Timer container decoration:
```dart
color: themeState.moduleChassisColor,
borderRadius: BorderRadius.circular(20),
border: Border.all(color: themeState.borderColor, width: 1.0),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_dial_widget_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/timer/presentation/chrono_dial_painter.dart lib/features/timer/presentation/chrono_dial_widget.dart lib/features/timer/presentation/widgets/crown_push_button.dart lib/features/timer/presentation/widgets/split_flap_board_widget.dart test/features/timer/chrono_dial_widget_test.dart
git commit -m "feat(timer): apply full physical material transformation to dial bezel, crown, split flap, and pill timer"
```

---

### Task 3: Receipt Dispenser Casing, Corner Rivets, Slit & Archive Drawer Metallurgical Theming

**Files:**
- Modify: `lib/features/tasks/presentation/receipt_runner_widget.dart`
- Modify: `lib/features/tasks/presentation/widgets/dispenser_slot_header.dart`
- Modify: `lib/features/tasks/presentation/widgets/archive_drawer_widget.dart`
- Modify: `test/features/tasks/receipt_runner_widget_test.dart`

**Interfaces:**
- Consumes: `themeState.moduleChassisColor`, `themeState.borderColor`, `themeState.rivetColor`, `themeState.plateGradient`, `themeState.accentColor`.
- Produces:
  - `ReceiptRunnerWidget` chassis container with dynamic background, border, and 4 corner rivet dots.
  - `DispenserSlotHeader` aperture slit with dynamic border.
  - `ArchiveDrawerWidget` faceplate, handle bar gradient, and rivets themed to active edition.

- [ ] **Step 1: Write the failing test**

In `test/features/tasks/receipt_runner_widget_test.dart`, add widget tests verifying:
- Changing edition to `titaniumStealth` sets `ReceiptRunnerWidget` chassis color to `HardwareEdition.titaniumStealth.darkModuleBg` and border to `darkBorder`.
- 4 mechanical corner rivets are rendered with `themeState.rivetColor`.
- `ArchiveDrawerWidget` uses `themeState.plateGradient` and `themeState.rivetColor`.

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/tasks/receipt_runner_widget_test.dart`  
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

1. In `lib/features/tasks/presentation/receipt_runner_widget.dart`:
Read `final themeState = ref.watch(chassisThemeProvider);`.
Container decoration:
```dart
color: themeState.moduleChassisColor,
borderRadius: BorderRadius.circular(10),
border: Border.all(color: themeState.borderColor, width: 1.2),
```
Add 4 corner mechanical rivet dots using a Stack or inside the padding with `themeState.rivetColor`.

2. In `lib/features/tasks/presentation/widgets/dispenser_slot_header.dart`:
Accept optional `borderColor: themeState.borderColor` or convert to `ConsumerWidget` and use `themeState.borderColor` on the aperture slit border.

3. In `lib/features/tasks/presentation/widgets/archive_drawer_widget.dart`:
Read `final themeState = ref.watch(chassisThemeProvider);`.
Update container border:
```dart
border: Border.all(
  color: isOpen ? themeState.filamentColor.withValues(alpha: 0.6) : themeState.borderColor,
  width: 1.0,
),
```
Update handle bar gradient:
```dart
gradient: LinearGradient(
  colors: themeState.plateGradient,
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
),
```
Update handle rivets in `_buildBrassRivet()` to use `color: themeState.rivetColor`.
Update center handle plate border and text highlight:
Use `themeState.accentColor` or `themeState.filamentColor`.

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/tasks/receipt_runner_widget_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/tasks/presentation/receipt_runner_widget.dart lib/features/tasks/presentation/widgets/dispenser_slot_header.dart lib/features/tasks/presentation/widgets/archive_drawer_widget.dart test/features/tasks/receipt_runner_widget_test.dart
git commit -m "feat(tasks): apply full metallurgical theming and corner rivets to Receipt Dispenser and Archive Drawer"
```

---

### Task 4: Vinyl Player Deck Chassis, Corner Rivets, Tonearm Metallurgy & Center Record Label Theming

**Files:**
- Modify: `lib/features/vinyl/presentation/vinyl_player_widget.dart`
- Modify: `lib/features/vinyl/presentation/vinyl_deck_painter.dart`
- Modify: `test/features/vinyl/vinyl_player_widget_test.dart`

**Interfaces:**
- Consumes: `themeState.moduleChassisColor`, `themeState.borderColor`, `themeState.rivetColor`, `themeState.plateGradient`, `themeState.accentColor`.
- Produces:
  - `VinylPlayerWidget` deck chassis with dynamic background, border, and 4 corner rivet dots.
  - `VinylDeckPainter` with dynamic `labelColor: themeState.accentColor` and tonearm metallurgy gradient matching active edition.

- [ ] **Step 1: Write the failing test**

In `test/features/vinyl/vinyl_player_widget_test.dart`, add widget tests verifying:
- Deck container background and border adapt to `themeState.moduleChassisColor` and `themeState.borderColor`.
- 4 mechanical corner rivets are rendered with `themeState.rivetColor`.
- Center vinyl record label color passed to `VinylDeckPainter` matches `themeState.accentColor`.

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/vinyl_player_widget_test.dart`  
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

1. In `lib/features/vinyl/presentation/vinyl_deck_painter.dart`:
Add parameter:
```dart
final List<Color>? tonearmGradient;
final Color? armPivotBorderColor;
```
In tonearm wand paint:
```dart
    final armPaint = Paint()
      ..shader = LinearGradient(
        colors: tonearmGradient ?? const [
          Color(0xFFF0ECE3),
          Color(0xFFBDC3CC),
          Color(0xFF8E95A0),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromPoints(tonearmBase, armTarget))
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
```
In pivot gimbal:
Use `armPivotBorderColor ?? const Color(0xFF555B66)` for `pivotBorder`.
Update `shouldRepaint` to check `tonearmGradient` and `armPivotBorderColor`.

2. In `lib/features/vinyl/presentation/vinyl_player_widget.dart`:
Read `final themeState = ref.watch(chassisThemeProvider);`.
Update deck container decoration:
```dart
color: themeState.moduleChassisColor,
borderRadius: BorderRadius.circular(10),
border: Border.all(color: themeState.borderColor, width: 1.2),
```
Add 4 corner mechanical rivet dots using `themeState.rivetColor`.
Pass `labelColor: themeState.accentColor`, `tonearmGradient: themeState.plateGradient`, `armPivotBorderColor: themeState.borderColor` to `VinylDeckPainter`.

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/vinyl_player_widget_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/vinyl/presentation/vinyl_player_widget.dart lib/features/vinyl/presentation/vinyl_deck_painter.dart test/features/vinyl/vinyl_player_widget_test.dart
git commit -m "feat(vinyl): apply dynamic metallurgy theming to turntable chassis, corner rivets, tonearm, and center label"
```

---

### Task 5: End-to-End Verification & Whole-Branch Quality Gate

**Files:**
- Verification only across all files and tests.

- [ ] **Step 1: Run full test suite**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test`  
Expected: 100% tests passing (all tests across timer, tasks, vinyl, settings, desk, database, theme).

- [ ] **Step 2: Run static code analysis**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`  
Expected: 0 issues found.

- [ ] **Step 3: Verification subagent review & push**

Run code reviewer subagent over the branch diff and push to `origin/main`.
