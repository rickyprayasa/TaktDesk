# Focus Analytics & Reports, Pricing Tiers, and Clean Launcher Icon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Dieter Rams / Braun-styled Focus Analytics & Reports with Day/Week/Month histograms, update Studio Pro pricing tiers to Rp 69.000 / $9.99 (normal Rp 129.000 / $19.99), and restore the clean borderless circular app launcher icon.

**Architecture:**
- **App Launcher Icon:** Restore the full-bleed circular AW10 watch dial assets from commit `54428bc` that naturally fit Android launcher circular masks without triggering launcher-synthesized white disk plates.
- **Pricing:** Update `StudioProDialog` to display Founder Launch Edition at Rp 69.000 / ~$9.99 (47% off) with strikethrough Rp 129.000 / ~$19.99.
- **Analytics Domain & Controller:** Create `FocusAnalyticsController` reading from Drift SQLite `watchAllTimerSessions()`, grouping by Day, Week, and Month with date navigation (`<` and `>`), aggregating focus minutes, completed sessions, completion rate, and average daily focus.
- **Analytics Presentation:** Build `FocusAnalyticsDialog` and `FocusBarChartWidget` with Dieter Rams industrial styling, basalt slate / bone palette, filament amber bars, and integrate access from `TaktSettingsSheet` and `DeskSpecPlateWidget`.

**Tech Stack:** Flutter 3.x, Dart 3.x, Drift SQLite, Riverpod, Material Design 3.

## Global Constraints
- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetics (honest materials, uncluttered typography, amber accent #FF9E00).
- Clean namespace: Absolutely 0 occurrences of `tuneeca` across Kotlin, Dart, XML, and Gradle files (`com.takt.desk` / `com.zykl.app`).
- 0 analyzer issues (`/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`).
- 100% test pass rate across repository (`/home/tuneeca/RSQUARE/flutter/bin/flutter test`).
- Production release APK successfully compiled and deployed to `/home/tuneeca/RSQUARE/ZYKL_Release.apk` and `Takt_Desk_Release.apk`.

---

### Task 1: Restore Clean Borderless App Launcher Icon

**Files:**
- Modify: `assets/images/zykl_icon.png`
- Modify: `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- Modify: `android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png`
- Modify: `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- Modify: `android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png`
- Modify: `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- Modify: `android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png`
- Modify: `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- Modify: `android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png`
- Modify: `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- Modify: `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png`

**Interfaces:**
- Consumes: Commit `54428bc` clean full-bleed circular icon assets.
- Produces: App launcher icon that renders edge-to-edge on Android home screen without white circular plate container.

- [ ] **Step 1: Check out clean icon assets from commit 54428bc**

```bash
git checkout 54428bc -- assets/images/zykl_icon.png android/app/src/main/res/mipmap-*/ic_launcher*.png
```

- [ ] **Step 2: Verify pixel bounding box of restored icon**

```bash
python3 -c "
from PIL import Image
img = Image.open('assets/images/zykl_icon.png')
print('Bbox:', img.getbbox(), 'Size:', img.size)
assert img.getbbox() == (0, 0, 512, 512), 'Icon should be full-bleed circular dial'
"
```

- [ ] **Step 3: Commit restored icons**

```bash
git add assets/images/zykl_icon.png android/app/src/main/res/mipmap-*/ic_launcher*.png
git commit -m "fix(icon): restore clean full-bleed circular dial launcher icon without white background plate"
```

---

### Task 2: Update Studio Pro Pricing Tiers in StudioProDialog

**Files:**
- Modify: `lib/features/settings/presentation/widgets/studio_pro_dialog.dart:148-185`
- Test: `test/features/settings/studio_pro_dialog_test.dart`

**Interfaces:**
- Consumes: `showStudioProDialog(BuildContext context, WidgetRef ref, ...)`
- Produces: Displays `Rp 69.000` (strikethrough `Rp 129.000`) and `~$9.99` (normal `~$19.99`) with `47% OFF` badge.

- [ ] **Step 1: Write failing test in studio_pro_dialog_test.dart asserting updated pricing**

```dart
testWidgets('showStudioProDialog displays updated Rp 69.000 and Rp 129.000 pricing tiers', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => showStudioProDialog(context, ref),
                child: const Text('OPEN PRO DIALOG'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('OPEN PRO DIALOG'));
  await tester.pumpAndSettle();

  expect(find.text('Rp 69.000'), findsOneWidget);
  expect(find.text('Rp 129.000'), findsOneWidget);
  expect(find.textContaining('47% OFF'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/settings/studio_pro_dialog_test.dart
```
Expected: FAIL with "Expected: exactly 1 matching node... 'Rp 69.000'".

- [ ] **Step 3: Implement updated pricing in studio_pro_dialog.dart**

```dart
const Text(
  'FOUNDER LAUNCH EDITION · 47% OFF',
  style: TextStyle(
    fontFamily: 'monospace',
    fontSize: 8.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: TaktColors.filamentAmber,
  ),
),
const SizedBox(height: 2),
Row(
  crossAxisAlignment: CrossAxisAlignment.baseline,
  textBaseline: TextBaseline.alphabetic,
  children: [
    Text(
      'Rp 69.000',
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 15.0,
        fontWeight: FontWeight.w800,
        color: primary,
      ),
    ),
    const SizedBox(width: 8),
    Text(
      'Rp 129.000',
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 10.0,
        fontWeight: FontWeight.w500,
        decoration: TextDecoration.lineThrough,
        color: secondary,
      ),
    ),
    const SizedBox(width: 6),
    Text(
      '· \$9.99',
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 9.0,
        fontWeight: FontWeight.w600,
        color: secondary,
      ),
    ),
  ],
),
```

- [ ] **Step 4: Run test to verify it passes**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/settings/studio_pro_dialog_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add lib/features/settings/presentation/widgets/studio_pro_dialog.dart test/features/settings/studio_pro_dialog_test.dart
git commit -m "feat(pricing): update Studio Pro Founder Launch to Rp 69.000 (\$9.99) with Rp 129.000 normal lifetime tier"
```

---

### Task 3: Focus Analytics Domain & Controller

**Files:**
- Create: `lib/features/analytics/domain/focus_analytics_models.dart`
- Create: `lib/features/analytics/presentation/focus_analytics_controller.dart`
- Test: `test/features/analytics/focus_analytics_controller_test.dart`

**Interfaces:**
- Consumes: `AppDatabase.watchAllTimerSessions()`
- Produces:
  - `FocusAnalyticsPeriod` enum: `day`, `week`, `month`.
  - `FocusBarData` class: `label`, `valueMinutes`, `isHighlighted`, `isCompleted`.
  - `FocusAnalyticsState` class: `period`, `selectedDate`, `dateRangeLabel`, `totalMinutes`, `completedSessions`, `totalSessions`, `completionRate`, `dailyAverageMinutes`, `bestDayLabel`, `bars`.
  - `focusAnalyticsControllerProvider`: Notifier managing period selection, previous/next date navigation, and computed state.

- [ ] **Step 1: Write unit tests in test/features/analytics/focus_analytics_controller_test.dart**

```dart
// Test Day, Week, and Month aggregation, navigation, and summary metrics.
```

- [ ] **Step 2: Run test to verify it fails**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/analytics/focus_analytics_controller_test.dart
```
Expected: FAIL (file not found / classes undefined).

- [ ] **Step 3: Implement domain models and controller**

Implement `focus_analytics_models.dart` and `focus_analytics_controller.dart` with date navigation and session binning.

- [ ] **Step 4: Run test to verify it passes**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/analytics/focus_analytics_controller_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add lib/features/analytics/ test/features/analytics/
git commit -m "feat(analytics): implement FocusAnalyticsController and domain models with reactive Drift session aggregation"
```

---

### Task 4: Focus Analytics Bar Chart & Dialog UI

**Files:**
- Create: `lib/features/analytics/presentation/widgets/focus_bar_chart_widget.dart`
- Create: `lib/features/analytics/presentation/widgets/focus_analytics_dialog.dart`
- Modify: `lib/features/settings/presentation/takt_settings_sheet.dart`
- Modify: `lib/features/desk/presentation/widgets/desk_telemetry_slip_widget.dart`
- Test: `test/features/analytics/focus_analytics_dialog_test.dart`
- Test: `test/features/settings/takt_settings_sheet_test.dart`

**Interfaces:**
- Consumes: `focusAnalyticsControllerProvider`, `TaktColors`, `ChassisThemeController`.
- Produces:
  - `FocusBarChartWidget`: Renders animated vertical bars with Dieter Rams industrial styling and amber accent.
  - `FocusAnalyticsDialog.show(BuildContext context)`: Opens modal report with Day/Week/Month tabs, date navigation, chart, and metric plaques.
  - `TaktSettingsSheet` button: `[ VIEW FOCUS ANALYTICS & CHARTS ➔ ]`
  - `DeskTelemetrySlipWidget` button: `[ VIEW ANALYTICS ➔ ]`

- [ ] **Step 1: Write widget tests in test/features/analytics/focus_analytics_dialog_test.dart**

```dart
// Test dialog rendering, switching between D, W, M tabs, and date navigation.
```

- [ ] **Step 2: Run test to verify it fails**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/analytics/focus_analytics_dialog_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Implement FocusBarChartWidget and FocusAnalyticsDialog**

Build widgets with Braun industrial design, monospace typography, and haptic feedback. Wire launch buttons in `takt_settings_sheet.dart` and `desk_telemetry_slip_widget.dart`.

- [ ] **Step 4: Run test to verify it passes**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/analytics/focus_analytics_dialog_test.dart test/features/settings/takt_settings_sheet_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add lib/features/analytics/ lib/features/settings/ lib/features/desk/ test/features/analytics/ test/features/settings/
git commit -m "feat(analytics): build Dieter Rams FocusAnalyticsDialog with interactive bar chart and wire settings entry point"
```

---

### Task 5: Verification, Analyzer Cleanliness, and Production Release APK Build

**Files:**
- All modified files
- Output APKs: `/home/tuneeca/RSQUARE/ZYKL_Release.apk` and `/home/tuneeca/RSQUARE/Takt_Desk_Release.apk`

- [ ] **Step 1: Run full test suite**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test
```
Expected: 100% tests pass.

- [ ] **Step 2: Run static analyzer**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter analyze
```
Expected: 0 issues found.

- [ ] **Step 3: Check namespace hygiene**

```bash
git diff 5d52ef0..HEAD | grep -i "tuneeca" || true
```
Expected: 0 occurrences.

- [ ] **Step 4: Build release APK**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter build apk --release
```

- [ ] **Step 5: Deploy release APKs**

```bash
cp build/app/outputs/flutter-apk/app-release.apk /home/tuneeca/RSQUARE/ZYKL_Release.apk
cp build/app/outputs/flutter-apk/app-release.apk /home/tuneeca/RSQUARE/Takt_Desk_Release.apk
```
