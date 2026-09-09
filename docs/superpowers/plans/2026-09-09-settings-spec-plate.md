# Industrial Spec Plate, Daily Tally & Service Hatch Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the Dieter Rams inspired Industrial Spec Plate with reactive daily focus tally at the bottom of the mobile desk canvas, and the Service Hatch modal sheet for audio/haptic calibration, telemetry, and legal/philosophical disclosures.

**Architecture:** Extend Drift SQLite database with preferences (`foleyEnabled`, `hapticsEnabled`) and today/lifetime timer queries. Connect Riverpod state controllers to Drift, `AudioService`, and `HapticService`. Create `DeskSpecPlateWidget` anchoring the lower desk canvas, `SettingsRivetButton` in the header, and `TaktSettingsSheet` modal service hatch.

**Tech Stack:** Flutter 3.x, Dart 3.x, flutter_riverpod 2.x, Drift 2.x SQLite, native Android MethodChannels for audio & focus lock.

## Global Constraints
- Android Target SDK 34+, Min SDK 24.
- Strictly adhere to Dieter Rams / Braun aesthetic (`TaktPalette`: Obsidian `#141517`, Basalt `#24272C`, Warm Bone `#EFECE6`, Thermal Carbon `#1F2226`, Muted Ochre `#C85A32`, Filament Amber `#D99B59`, Patina Olive `#4D5D4B`).
- Zero AI Slop: No generic cards, no neon gradients, no arbitrary rounded-3xl designs.
- Pure Mobile Handheld Console: Single-column responsive layout (maxWidth 440px), no desktop multi-column rack.
- 0 analyzer warnings, 100% test pass rate across the entire repository.

---

### Task 1: Drift Database Extensions & Focus Telemetry Queries

**Files:**
- Modify: `lib/core/database/tables/desk_preferences_table.dart`
- Modify: `lib/core/database/app_database.dart`
- Test: `test/core/database_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `TimerSessions`, `DeskPreferences`
- Produces:
  - `AppDatabase.watchTodayTimerSessions()`: `Stream<List<TimerSession>>`
  - `AppDatabase.watchAllTimerSessions()`: `Stream<List<TimerSession>>`
  - `AppDatabase.clearTimerSessions()`: `Future<void>`
  - `AppDatabase.updatePreferences({double? soundVolume, bool? parallaxEnabled, int? activeAmbientTrackIndex, bool? foleyEnabled, bool? hapticsEnabled})`: `Future<void>`

- [x] **Step 1: Write failing database unit tests**

Add tests to `test/core/database_test.dart` verifying `watchTodayTimerSessions`, `watchAllTimerSessions`, `clearTimerSessions`, and updated preferences:

```dart
test('watchTodayTimerSessions filters sessions for the current day only', () async {
  final now = DateTime.now();
  final yesterday = now.subtract(const Duration(days: 1));

  // Past session
  await db.recordTimerSession(
    targetMinutes: 25,
    elapsedSeconds: 1500,
    isFinished: true,
    startedAt: yesterday,
  );

  // Today session 1
  await db.recordTimerSession(
    targetMinutes: 25,
    elapsedSeconds: 1500,
    isFinished: true,
    startedAt: now.subtract(const Duration(hours: 1)),
  );

  // Today session 2 (unfinished)
  await db.recordTimerSession(
    targetMinutes: 5,
    elapsedSeconds: 60,
    isFinished: false,
    startedAt: now,
  );

  final todaySessions = await db.watchTodayTimerSessions().first;
  expect(todaySessions.length, equals(2));
  expect(todaySessions.first.isFinished, isTrue);
});

test('clearTimerSessions removes all session records', () async {
  await db.recordTimerSession(
    targetMinutes: 25,
    elapsedSeconds: 1500,
    isFinished: true,
    startedAt: DateTime.now(),
  );

  await db.clearTimerSessions();
  final allSessions = await db.watchAllTimerSessions().first;
  expect(allSessions, isEmpty);
});
```

- [x] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/database_test.dart`
Expected: FAIL with compilation error: method `watchTodayTimerSessions` not defined.

- [x] **Step 3: Implement database extensions and regenerate Drift code**

In `lib/core/database/tables/desk_preferences_table.dart`:
```dart
import 'package:drift/drift.dart';

class DeskPreferences extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get soundVolume => real().withDefault(const Constant(0.8))();
  BoolColumn get parallaxEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get activeAmbientTrackIndex => integer().withDefault(const Constant(0))();
  BoolColumn get foleyEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get hapticsEnabled => boolean().withDefault(const Constant(true))();
}
```

In `lib/core/database/app_database.dart`:
Add `watchTodayTimerSessions`, `watchAllTimerSessions`, `clearTimerSessions`, and update `updatePreferences`:
```dart
Stream<List<TimerSession>> watchTodayTimerSessions() {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  return (select(timerSessions)
        ..where((t) =>
            t.startedAt.isBiggerOrEqualValue(startOfDay) &
            t.startedAt.isSmallerThanValue(endOfDay))
        ..orderBy([(t) => OrderingTerm(expression: t.startedAt, mode: OrderingMode.asc)]))
      .watch();
}

Stream<List<TimerSession>> watchAllTimerSessions() {
  return (select(timerSessions)
        ..orderBy([(t) => OrderingTerm(expression: t.startedAt, mode: OrderingMode.desc)]))
      .watch();
}

Future<void> clearTimerSessions() {
  return delete(timerSessions).go();
}

Future<void> updatePreferences({
  double? soundVolume,
  bool? parallaxEnabled,
  int? activeAmbientTrackIndex,
  bool? foleyEnabled,
  bool? hapticsEnabled,
}) async {
  final existing = await (select(deskPreferences)..limit(1)).getSingleOrNull();
  if (existing == null) {
    await into(deskPreferences).insert(DeskPreferencesCompanion.insert(
      soundVolume: soundVolume != null ? Value(soundVolume) : const Value.absent(),
      parallaxEnabled: parallaxEnabled != null ? Value(parallaxEnabled) : const Value.absent(),
      activeAmbientTrackIndex:
          activeAmbientTrackIndex != null ? Value(activeAmbientTrackIndex) : const Value.absent(),
      foleyEnabled: foleyEnabled != null ? Value(foleyEnabled) : const Value.absent(),
      hapticsEnabled: hapticsEnabled != null ? Value(hapticsEnabled) : const Value.absent(),
    ));
  } else {
    await (update(deskPreferences)..where((p) => p.id.equals(existing.id))).write(
      DeskPreferencesCompanion(
        soundVolume: soundVolume != null ? Value(soundVolume) : const Value.absent(),
        parallaxEnabled: parallaxEnabled != null ? Value(parallaxEnabled) : const Value.absent(),
        activeAmbientTrackIndex:
            activeAmbientTrackIndex != null ? Value(activeAmbientTrackIndex) : const Value.absent(),
        foleyEnabled: foleyEnabled != null ? Value(foleyEnabled) : const Value.absent(),
        hapticsEnabled: hapticsEnabled != null ? Value(hapticsEnabled) : const Value.absent(),
      ),
    );
  }
}
```

Run build_runner:
`dart run build_runner build --delete-conflicting-outputs`

- [x] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/database_test.dart`
Expected: PASS

- [x] **Step 5: Commit changes**

```bash
git add lib/core/database/ test/core/database_test.dart
git commit -m "feat(database): add today/all timer queries and foley/haptic preferences"
```

---

### Task 2: Preferences & Telemetry State Providers and Services Wiring

**Files:**
- Modify: `lib/core/audio/audio_service.dart`
- Modify: `lib/core/haptics/haptic_service.dart`
- Create: `lib/features/settings/presentation/settings_controller.dart`
- Test: `test/features/settings/settings_controller_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `AudioService`, `HapticService`
- Produces:
  - `AudioService.foleyEnabled`: `bool`
  - `HapticService.enabled`: `bool`
  - `deskPreferencesControllerProvider`: `StateNotifierProvider<DeskPreferencesController, DeskPreferencesState>`
  - `todayFocusStatsProvider`: `Provider<AsyncValue<TodayFocusStats>>`
  - `lifetimeFocusStatsProvider`: `Provider<AsyncValue<LifetimeFocusStats>>`

- [x] **Step 1: Write failing tests for settings controller and telemetry**

Create `test/features/settings/settings_controller_test.dart`:
```dart
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/core/haptics/haptic_service.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';

void main() {
  late AppDatabase db;
  late AudioService audioService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    audioService = AudioService(isMock: true);
    HapticService.enabled = true;
  });

  tearDown(() async {
    await db.close();
  });

  test('SettingsController loads defaults and toggles foley and haptics', () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioServiceProvider.overrideWithValue(audioService),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(deskPreferencesControllerProvider.notifier);
    await controller.init();

    expect(container.read(deskPreferencesControllerProvider).foleyEnabled, isTrue);
    expect(container.read(deskPreferencesControllerProvider).hapticsEnabled, isTrue);

    await controller.setFoleyEnabled(false);
    expect(container.read(deskPreferencesControllerProvider).foleyEnabled, isFalse);
    expect(audioService.foleyEnabled, isFalse);

    await controller.setHapticsEnabled(false);
    expect(container.read(deskPreferencesControllerProvider).hapticsEnabled, isFalse);
    expect(HapticService.enabled, isFalse);
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/settings/settings_controller_test.dart`
Expected: FAIL with compilation error: file not found.

- [x] **Step 3: Implement AudioService foleyEnabled, HapticService.enabled, and settings controller**

In `lib/core/audio/audio_service.dart`:
Add `bool _foleyEnabled = true;` getter `foleyEnabled`, setter `setFoleyEnabled(bool v)`, and in `playFoley`:
```dart
bool _foleyEnabled = true;
bool get foleyEnabled => _foleyEnabled;

void setFoleyEnabled(bool val) {
  _foleyEnabled = val;
}

void playFoley(SoundEffect effect) {
  if (!_initialized || !_foleyEnabled) return;
  if (!isMock) {
    _channel.invokeMethod('playFoley', {'effect': effect.name}).catchError((_) {});
  }
}
```

In `lib/core/haptics/haptic_service.dart`:
Add `static bool enabled = true;` and guard all methods:
```dart
static bool enabled = true;

static Future<void> dialTick() async {
  if (!enabled) return;
  await HapticFeedback.selectionClick();
}
// Apply if (!enabled) return; to mechanicalPress, paperTorn, stampDone.
```

In `lib/features/settings/presentation/settings_controller.dart`:
Define `DeskPreferencesState`, `DeskPreferencesController`, `todayFocusStatsProvider`, and `lifetimeFocusStatsProvider`.

- [x] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/settings/settings_controller_test.dart`
Expected: PASS

- [x] **Step 5: Commit changes**

```bash
git add lib/core/audio/ lib/core/haptics/ lib/features/settings/ test/features/settings/
git commit -m "feat(settings): wire preferences controller and telemetry providers with audio/haptic flags"
```

---

### Task 3: Base Anchor: The Industrial Spec Plate & Daily Focus Tally Widget

**Files:**
- Create: `lib/features/desk/presentation/widgets/desk_spec_plate_widget.dart`
- Test: `test/features/desk/desk_spec_plate_widget_test.dart`

**Interfaces:**
- Consumes: `todayFocusStatsProvider`, `chassisThemeProvider`, `audioServiceProvider`, `HapticService`
- Produces:
  - `DeskSpecPlateWidget`: `ConsumerWidget`

- [x] **Step 1: Write failing widget test for DeskSpecPlateWidget**

Create `test/features/desk/desk_spec_plate_widget_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/desk/presentation/widgets/desk_spec_plate_widget.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';

void main() {
  testWidgets('DeskSpecPlateWidget renders manufacturer stamp and 4 LED dots', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayFocusStatsProvider.overrideWithValue(
            const AsyncValue.data(TodayFocusStats(
              completedCount: 2,
              totalMinutes: 50,
            )),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DeskSpecPlateWidget(),
          ),
        ),
      ),
    );

    expect(find.textContaining('TAKT DESK'), findsOneWidget);
    expect(find.textContaining('MOD. 01'), findsOneWidget);
    expect(find.textContaining('2 / 4 CYCLES'), findsOneWidget);
    expect(find.textContaining('50 MIN FOCUSED'), findsOneWidget);
    expect(find.byKey(const ValueKey('spec_plate_led_row')), findsOneWidget);
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/desk/desk_spec_plate_widget_test.dart`
Expected: FAIL with compilation error: `DeskSpecPlateWidget` not found.

- [x] **Step 3: Implement DeskSpecPlateWidget**

In `lib/features/desk/presentation/widgets/desk_spec_plate_widget.dart`:
- Implement debossed apparatus plate container with corner screw indicators.
- Left column: `TAKT DESK · MOD. 01 · 2026` + `GERMANIC MINIMALISM · STEREO 44.1kHz`.
- Right column: 4 micro-LED dots (`filamentAmber` when active, `basaltSlate` with dark outline when inactive) + `TODAY: X / 4 CYCLES` and `Y MIN FOCUSED`.
- Wrap in `InkWell` / `GestureDetector` that plays `dialClick` and `HapticService.lightClick()`.

- [x] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/desk/desk_spec_plate_widget_test.dart`
Expected: PASS

- [x] **Step 5: Commit changes**

```bash
git add lib/features/desk/presentation/widgets/desk_spec_plate_widget.dart test/features/desk/desk_spec_plate_widget_test.dart
git commit -m "feat(desk): implement DeskSpecPlateWidget with daily focus tally and 4 quadrant LEDs"
```

---

### Task 4: The Industrial Service Hatch Modal Sheet (Settings, About & Legal)

**Files:**
- Create: `lib/features/settings/presentation/takt_settings_sheet.dart`
- Test: `test/features/settings/takt_settings_sheet_test.dart`

**Interfaces:**
- Consumes: `deskPreferencesControllerProvider`, `lifetimeFocusStatsProvider`, `appDatabaseProvider`
- Produces:
  - `TaktSettingsSheet`: `ConsumerWidget`

- [x] **Step 1: Write failing widget test for TaktSettingsSheet**

Create `test/features/settings/takt_settings_sheet_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';
import 'package:takt_desk/features/settings/presentation/takt_settings_sheet.dart';

void main() {
  testWidgets('TaktSettingsSheet renders acoustics, clearance, telemetry, and creed sections', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TaktSettingsSheet(),
          ),
        ),
      ),
    );

    expect(find.textContaining('SERVICE HATCH'), findsOneWidget);
    expect(find.textContaining('HARDWARE ACOUSTICS'), findsOneWidget);
    expect(find.textContaining('SYSTEM CLEARANCE'), findsOneWidget);
    expect(find.textContaining('TELEMETRY & LOGS'), findsOneWidget);
    expect(find.textContaining('Weniger, aber besser'), findsOneWidget);
    expect(find.text('OPEN SOURCE LICENSES'), findsOneWidget);
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/settings/takt_settings_sheet_test.dart`
Expected: FAIL with compilation error: `TaktSettingsSheet` not found.

- [x] **Step 3: Implement TaktSettingsSheet**

In `lib/features/settings/presentation/takt_settings_sheet.dart`:
- Top knurled textured grip bar.
- Section 1: Master volume slider (`0.0` - `1.0`), Foley sound toggle, Haptic feedback toggle.
- Section 2: Android DND clearance indicator and emergency unlatch instructions.
- Section 3: Lifetime sessions count and hours focused, plus "PURGE SESSION LOGS" button with dialog.
- Section 4: Dieter Rams quote *"Weniger, aber besser"*, version metadata `v1.0.0 (Build 2026)`, 100% offline privacy pledge, and "OPEN SOURCE LICENSES" calling `showLicensePage(context: context)`.

- [x] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/settings/takt_settings_sheet_test.dart`
Expected: PASS

- [x] **Step 5: Commit changes**

```bash
git add lib/features/settings/presentation/takt_settings_sheet.dart test/features/settings/takt_settings_sheet_test.dart
git commit -m "feat(settings): implement TaktSettingsSheet service hatch modal sheet"
```

---

### Task 5: Header Trigger Button & Desk Integration Canvas Wiring

**Files:**
- Create: `lib/features/desk/presentation/widgets/settings_rivet_button.dart`
- Modify: `lib/features/desk/presentation/desk_canvas_screen.dart`
- Modify: `test/features/desk/desk_screen_test.dart`

**Interfaces:**
- Consumes: `SettingsRivetButton`, `DeskSpecPlateWidget`, `TaktSettingsSheet`
- Produces: Integrated desk console layout with bottom anchor and header settings trigger

- [x] **Step 1: Write failing widget test in desk_screen_test.dart**

Add test to `test/features/desk/desk_screen_test.dart`:
```dart
testWidgets('DeskCanvasScreen renders Settings rivet button and DeskSpecPlateWidget', (tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        home: DeskCanvasScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.byType(SettingsRivetButton), findsOneWidget);
  expect(find.byType(DeskSpecPlateWidget), findsOneWidget);

  // Tapping settings button displays TaktSettingsSheet
  await tester.tap(find.byType(SettingsRivetButton));
  await tester.pumpAndSettle();

  expect(find.byType(TaktSettingsSheet), findsOneWidget);
});
```

- [x] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/desk/desk_screen_test.dart`
Expected: FAIL with compilation error: `SettingsRivetButton` not found.

- [x] **Step 3: Implement SettingsRivetButton and wire into DeskCanvasScreen**

Create `lib/features/desk/presentation/widgets/settings_rivet_button.dart`:
- Circular machine screw / knurled gear button with tactile press feedback.
- Opens `showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => const TaktSettingsSheet())`.

In `lib/features/desk/presentation/desk_canvas_screen.dart`:
- In Row 1 (Header): place `SettingsRivetButton` alongside `ChassisThemeSwitch`.
- At the bottom of the column: place `const DeskSpecPlateWidget()`.

- [x] **Step 4: Run all tests and analyzer**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test`
Expected: ALL PASS (100%)
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`
Expected: 0 issues

- [x] **Step 5: Commit changes**

```bash
git add lib/features/desk/ presentation/ test/features/desk/
git commit -m "feat(desk): integrate SettingsRivetButton and DeskSpecPlateWidget into DeskCanvasScreen"
```
