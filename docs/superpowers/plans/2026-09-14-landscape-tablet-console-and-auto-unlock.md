# ZYKL Dual-Pane Master Console (Tablet/Landscape Mode), Auto-Unlock Monastic Focus & Natural Alarm Suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver an expansive Braun Studio dual-pane master console for tablets/landscape mode, an auto-unlocking monastic focus workflow on timer finish, and an authentic acoustic physical alarm suite with FREE vs STUDIO PRO account gating.

**Architecture:**
- **Domain & Audio:** `AlarmChime` catalog of 5 authentic physical acoustic instruments (Braun dual-hammer, brass desk bell, Tibetan singing bowl, Zen temple gong, tubular horology chime) loaded via `AudioService`.
- **Persistence & State:** Drift schema v5 adding `alarmChimeId` to `DeskPreferences`, synchronized via Riverpod `deskPreferencesControllerProvider`.
- **Focus Flow:** `ChronoDialController` auto-unlatches `focusLockProvider` upon focus completion (`nextRemaining <= 0`), ringing the selected chime and popping monastic lock.
- **Responsive UI:** `DeskCanvasScreen` detects tablet / landscape mode (`Orientation.landscape` or `maxWidth >= 720`) and renders `MasterConsoleLandscapeLayout` (Left: Chrono Dial + Monastic switch; Right: simultaneous Receipt Runner + Vinyl Player).

**Tech Stack:** Flutter 3.29, Dart 3.7, Riverpod 2.6, Drift 2.22, sensors_plus 6.1, Native Android MethodChannel MediaPlayer, Dieter Rams / Braun Modernist Design.

## Global Constraints
- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetics (honest materials, uncluttered typography, amber accent `#FF9E00`).
- Battery-first: 0 CPU wakeups per second during idle; low-pass filtering and deadband thresholds.
- Clean namespace: Absolutely 0 occurrences of `tuneeca` across Kotlin, Dart, XML, and Gradle files (`com.zykl.app`).
- 0 analyzer issues (`/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`).
- 100% test pass rate across the entire repository (`/home/tuneeca/RSQUARE/flutter/bin/flutter test`).
- Clean Kotlin compilation (`cd android && ./gradlew compileDebugKotlin && cd ..`).

---

### Task 1: Natural Acoustic Alarm Chime Suite Assets & Domain Model

**Files:**
- Create: `lib/features/timer/domain/alarm_chime.dart`
- Create: `scripts/generate_natural_alarm_chimes.py`
- Create: `test/features/timer/alarm_chime_test.dart`
- Modify: `lib/core/audio/audio_service.dart:1-60`
- Create: `assets/audio/alarm_braun_bell.wav`
- Create: `assets/audio/alarm_desk_bell.wav`
- Create: `assets/audio/alarm_tibetan_bowl.wav`
- Create: `assets/audio/alarm_zen_gong.wav`
- Create: `assets/audio/alarm_tubular_chime.wav`

**Interfaces:**
- Produces:
  - `AlarmChime` class: `id`, `name`, `category`, `assetPath`, `isPro`.
  - `AlarmChimes.all`: list of 5 chimes (`braunBell`, `deskBell`, `tibetanBowl`, `zenGong`, `tubularChime`).
  - `AlarmChimes.findById(String id)`: fallback to `braunBell`.
  - `AudioService.playAlarmChime(String chimeId)`: forwards to native/local player.

- [ ] **Step 1: Write failing unit test in `test/features/timer/alarm_chime_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/timer/domain/alarm_chime.dart';

void main() {
  group('AlarmChime Domain Model', () {
    test('contains 5 standard acoustic chimes with correct FREE and PRO tiers', () {
      final chimes = AlarmChimes.all;
      expect(chimes.length, equals(5));

      final freeChimes = chimes.where((c) => !c.isPro).toList();
      final proChimes = chimes.where((c) => c.isPro).toList();

      expect(freeChimes.length, equals(2));
      expect(proChimes.length, equals(3));

      expect(freeChimes.map((c) => c.id), containsAll(['braunBell', 'deskBell']));
      expect(proChimes.map((c) => c.id), containsAll(['tibetanBowl', 'zenGong', 'tubularChime']));
    });

    test('findById returns correct chime and falls back to braunBell for unknown id', () {
      expect(AlarmChimes.findById('tibetanBowl').name, equals('TIBETAN SINGING BOWL'));
      expect(AlarmChimes.findById('deskBell').isPro, isFalse);
      expect(AlarmChimes.findById('unknown_chime_xyz').id, equals('braunBell'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails (RED)**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/alarm_chime_test.dart`  
Expected: FAIL (compilation error, `alarm_chime.dart` not found).

- [ ] **Step 3: Implement `AlarmChime` in `lib/features/timer/domain/alarm_chime.dart`**

```dart
class AlarmChime {
  final String id;
  final String name;
  final String category;
  final String description;
  final String assetPath;
  final bool isPro;

  const AlarmChime({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.assetPath,
    this.isPro = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmChime && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class AlarmChimes {
  static const AlarmChime braunBell = AlarmChime(
    id: 'braunBell',
    name: 'BRAUN DUAL-HAMMER',
    category: 'MECHANICAL',
    description: 'Authentic twin-bell mechanical clockwork chime',
    assetPath: 'assets/audio/alarm_braun_bell.wav',
    isPro: false,
  );

  static const AlarmChime deskBell = AlarmChime(
    id: 'deskBell',
    name: 'BRASS DESK BELL',
    category: 'HOROLOGICAL',
    description: 'Crisp high-frequency brass counter desk chime',
    assetPath: 'assets/audio/alarm_desk_bell.wav',
    isPro: false,
  );

  static const AlarmChime tibetanBowl = AlarmChime(
    id: 'tibetanBowl',
    name: 'TIBETAN SINGING BOWL',
    category: 'MEDITATIVE',
    description: 'Hand-hammered bronze singing bowl with rich overtones',
    assetPath: 'assets/audio/alarm_tibetan_bowl.wav',
    isPro: true,
  );

  static const AlarmChime zenGong = AlarmChime(
    id: 'zenGong',
    name: 'ZEN TEMPLE GONG',
    category: 'ORGANIC',
    description: 'Deep resonant Buddhist temple bell gong',
    assetPath: 'assets/audio/alarm_zen_gong.wav',
    isPro: true,
  );

  static const AlarmChime tubularChime = AlarmChime(
    id: 'tubularChime',
    name: 'TUBULAR CHIME',
    category: 'HOROLOGICAL',
    description: 'Solid brass tubular grandfather clock chime',
    assetPath: 'assets/audio/alarm_tubular_chime.wav',
    isPro: true,
  );

  static const List<AlarmChime> all = [
    braunBell,
    deskBell,
    tibetanBowl,
    zenGong,
    tubularChime,
  ];

  static AlarmChime findById(String? id) {
    if (id == null) return braunBell;
    for (final chime in all) {
      if (chime.id == id) return chime;
    }
    return braunBell;
  }
}
```

- [ ] **Step 4: Generate physical acoustic audio files with `scripts/generate_natural_alarm_chimes.py`**

Write script using acoustic modal resonance (non-linear modal frequencies, impact noise, dual-resonance beating, and natural exponential damping) to generate:
- `assets/audio/alarm_braun_bell.wav`
- `assets/audio/alarm_desk_bell.wav`
- `assets/audio/alarm_tibetan_bowl.wav`
- `assets/audio/alarm_zen_gong.wav`
- `assets/audio/alarm_tubular_chime.wav`
Run the python script to generate all 5 audio files.

- [ ] **Step 5: Register `playAlarmChime` in `lib/core/audio/audio_service.dart`**

Add `Future<void> playAlarmChime(String chimeId)` to `AudioService` which loads and plays the corresponding asset path through the native channel or audioplayers.

- [ ] **Step 6: Run tests and verify GREEN**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/alarm_chime_test.dart`  
Expected: PASS (2/2 passed).

- [ ] **Step 7: Commit**

```bash
git add lib/features/timer/domain/alarm_chime.dart scripts/generate_natural_alarm_chimes.py assets/audio/alarm_*.wav lib/core/audio/audio_service.dart test/features/timer/alarm_chime_test.dart
git commit -m "feat(audio): implement natural acoustic alarm chime suite and AlarmChime domain catalog"
```

---

### Task 2: Drift Database Schema Migration (v5) & Alarm Preferences Controller

**Files:**
- Modify: `lib/core/database/tables/desk_preferences_table.dart:1-15`
- Modify: `lib/core/database/app_database.dart:1-120`
- Modify: `lib/features/settings/presentation/settings_controller.dart:50-160`
- Test: `test/core/database_test.dart`
- Test: `test/features/settings/desk_preferences_controller_test.dart`

**Interfaces:**
- Consumes: `AlarmChimes` from Task 1.
- Produces:
  - `DeskPreferences.alarmChimeId`: SQLite text column with default `'braunBell'`.
  - `DeskPreferencesState.alarmChimeId`: string property.
  - `DeskPreferencesController.setAlarmChime(String chimeId)`: persists to Drift and updates state.

- [ ] **Step 1: Write failing test in `test/features/settings/desk_preferences_controller_test.dart`**

Assert that `DeskPreferencesState` has default `alarmChimeId == 'braunBell'` and `setAlarmChime('tibetanBowl')` updates state and calls database update.

- [ ] **Step 2: Run test to verify it fails (RED)**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/settings/desk_preferences_controller_test.dart`  
Expected: FAIL.

- [ ] **Step 3: Update `desk_preferences_table.dart` & `app_database.dart`**

In `lib/core/database/tables/desk_preferences_table.dart`:
```dart
TextColumn get alarmChimeId => text().withDefault(const Constant('braunBell'))();
```
In `lib/core/database/app_database.dart`:
- Bump `schemaVersion => 5`.
- In `onUpgrade`: if `from < 5`, add column `alarmChimeId` via `m.addColumn(deskPreferences, deskPreferences.alarmChimeId)`.
- Run: `/home/tuneeca/RSQUARE/flutter/bin/dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Update `DeskPreferencesState` and `DeskPreferencesController` in `settings_controller.dart`**

Add `alarmChimeId` to constructor, `copyWith`, `operator ==`, `hashCode`, and implement `Future<void> setAlarmChime(String chimeId)`.

- [ ] **Step 5: Run tests and verify GREEN**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/database_test.dart test/features/settings/desk_preferences_controller_test.dart`  
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/database/ lib/features/settings/presentation/settings_controller.dart test/core/database_test.dart test/features/settings/desk_preferences_controller_test.dart
git commit -m "feat(db): migrate Drift schema to v5 with alarmChimeId and integrate into DeskPreferencesController"
```

---

### Task 3: Settings UI — Alarm Acoustics Section with Preview & FREE vs PRO Gating

**Files:**
- Modify: `lib/features/settings/presentation/takt_settings_sheet.dart:180-320`
- Create: `test/features/settings/alarm_acoustics_settings_test.dart`

**Interfaces:**
- Consumes: `AlarmChimes`, `deskPreferencesControllerProvider`, `showStudioProDialog()`.
- Produces:
  - `_AlarmAcousticsSection` widget mounted inside `TaktSettingsSheet`.
  - Audition play button per chime.
  - Radio selection tile.
  - Amber `PRO` badge with upgrade dialog prompt on tap if `isProSimulated == false`.

- [ ] **Step 1: Write failing widget test in `test/features/settings/alarm_acoustics_settings_test.dart`**

```dart
testWidgets('TaktSettingsSheet renders Alarm Acoustics section with 5 chimes and PRO badges', (tester) async { ... });
testWidgets('Tapping a FREE chime updates alarm preference directly', (tester) async { ... });
testWidgets('Tapping a PRO chime when isProSimulated is false opens StudioProDialog', (tester) async { ... });
```

- [ ] **Step 2: Run test to verify it fails (RED)**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/settings/alarm_acoustics_settings_test.dart`  
Expected: FAIL.

- [ ] **Step 3: Implement `_AlarmAcousticsSection` in `takt_settings_sheet.dart`**

Mount `_AlarmAcousticsSection` right under `HARDWARE ACOUSTICS & TACTILITY`:
- Section Header: `ALARM ACOUSTICS & CHIMES`.
- Render list of `AlarmChimes.all`:
  - Each chime row has:
    - IconButton with `Icons.volume_up` to audition/preview sound via `ref.read(audioServiceProvider).playAlarmChime(chime.id)`.
    - Chime Name and Category/Description.
    - If `chime.isPro`: small amber `PRO` badge (`Container` with amber border and text).
    - Radio check indicator dot (active amber when selected).
  - Tapping tile:
    - If `!chime.isPro || prefs.isProSimulated`:
      `ref.read(deskPreferencesControllerProvider.notifier).setAlarmChime(chime.id);`
      `ref.read(audioServiceProvider).playAlarmChime(chime.id);`
    - If `chime.isPro && !prefs.isProSimulated`:
      Show `showStudioProDialog(context, ref);`

- [ ] **Step 4: Run tests and verify GREEN**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/settings/`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/presentation/takt_settings_sheet.dart test/features/settings/alarm_acoustics_settings_test.dart
git commit -m "feat(settings): add Alarm Acoustics selection section with audio audition and Studio PRO gating"
```

---

### Task 4: Auto-Unlock Monastic Focus Mode on Timer Completion

**Files:**
- Modify: `lib/features/timer/presentation/chrono_dial_controller.dart:120-170`
- Create: `test/features/timer/chrono_dial_auto_unlock_test.dart`

**Interfaces:**
- Consumes: `focusLockProvider`, `deskPreferencesControllerProvider`, `AudioService`.
- Produces:
  - Automatic `completeUnlock()` call when `tick()` reaches `nextRemaining <= 0` during `PomodoroPhase.focus`.
  - Audio chime played matching user's selected `alarmChimeId`.

- [ ] **Step 1: Write failing test in `test/features/timer/chrono_dial_auto_unlock_test.dart`**

```dart
testWidgets('ChronoDialController automatically unlatches Monastic Focus and plays selected alarm chime on focus completion', (tester) async { ... });
```

- [ ] **Step 2: Run test to verify it fails (RED)**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_dial_auto_unlock_test.dart`  
Expected: FAIL.

- [ ] **Step 3: Wire auto-unlock in `ChronoDialController`**

In `lib/features/timer/presentation/chrono_dial_controller.dart`:
- Inject `FocusLockController` / `FocusLockState` reader into `ChronoDialController`.
- In `tick(double deltaSeconds)`:
  When `nextRemaining <= 0` during `PomodoroPhase.focus`:
  - Fetch active `alarmChimeId` from preferences (fallback to `braunBell`).
  - Play `_audioService.playAlarmChime(alarmChimeId)`.
  - If `focusLockController?.state.isLocked == true`:
    - Call `focusLockController.completeUnlock()`.
    - Triggers drawer latch sound, haptic click, and unlocks `isLocked`.

- [ ] **Step 4: Run tests and verify GREEN**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_dial_auto_unlock_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/timer/presentation/chrono_dial_controller.dart test/features/timer/chrono_dial_auto_unlock_test.dart
git commit -m "feat(timer): auto-unlock Monastic Focus and play user-selected acoustic alarm chime on cycle finish"
```

---

### Task 5: Dual-Pane Master Console (Tablet & Landscape Mode) & Parallax Remapping

**Files:**
- Modify: `lib/features/desk/presentation/desk_canvas_screen.dart:230-350`
- Create: `lib/features/desk/presentation/widgets/master_console_landscape_layout.dart`
- Modify: `lib/core/sensors/parallax_controller.dart:80-115`
- Create: `test/features/desk/master_console_landscape_test.dart`

**Interfaces:**
- Consumes: `ChronoDialWidget`, `ReceiptRunnerWidget`, `VinylPlayerWidget`, `DeskSpecPlateWidget`, `parallaxProvider`.
- Produces:
  - `MasterConsoleLandscapeLayout`: dual-column studio console on landscape / wide displays.
  - Orientation-aware accelerometer mapping in `ParallaxController`.

- [ ] **Step 1: Write failing widget test in `test/features/desk/master_console_landscape_test.dart`**

```dart
testWidgets('DeskCanvasScreen renders dual-pane master console in landscape mode showing ChronoDial, Tasks, and Vinyl simultaneously', (tester) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  ...
  expect(find.byType(ChronoDialWidget), findsOneWidget);
  expect(find.byType(ReceiptRunnerWidget), findsOneWidget);
  expect(find.byType(VinylPlayerWidget), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails (RED)**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/desk/master_console_landscape_test.dart`  
Expected: FAIL (currently only 1 instrument is visible at a time).

- [ ] **Step 3: Implement `MasterConsoleLandscapeLayout` and wire in `desk_canvas_screen.dart`**

Create `lib/features/desk/presentation/widgets/master_console_landscape_layout.dart`:
- Top bar spanning full width (Status indicator LED, ZYKL header, Theme switch, Settings rivet).
- Two-column rack:
  - Left column (40–45% width): Centered `ChronoDialWidget`, Monastic switch at top, Emergency unlatch at bottom.
  - Right column (55–60% width): Vertical scrollable console displaying `ReceiptRunnerWidget` on top and `VinylPlayerWidget` below it.
  - Bottom bar: Centered `DeskSpecPlateWidget`.
In `desk_canvas_screen.dart`:
- Check: `final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape || constraints.maxWidth >= 720;`
- If `isLandscape`: render `MasterConsoleLandscapeLayout`.
- Else: render existing single-column mobile view with segmented tabs.

- [ ] **Step 4: Remap sensor orientation in `ParallaxController`**

In `lib/core/sensors/parallax_controller.dart`:
Add `bool isLandscape = false` parameter to `updateTiltFromAccelerometer`:
When `isLandscape` is true:
- Tablet horizontal tilt corresponds to accelerometer Y, and tablet vertical tilt corresponds to accelerometer X.
- Swap and sign-adjust appropriately so 3D floating glass perspective tilts naturally with the physical tablet orientation.

- [ ] **Step 5: Run tests and verify GREEN**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/desk/`  
Expected: PASS (all tests pass).

- [ ] **Step 6: Commit**

```bash
git add lib/features/desk/presentation/ lib/core/sensors/parallax_controller.dart test/features/desk/master_console_landscape_test.dart
git commit -m "feat(layout): implement Dual-Pane Master Console for tablet/landscape mode and orientation-aware parallax"
```

---

### Task 6: Full Verification, Clean Namespace & Production Release APK

**Files:**
- Verify: Full repository test suite
- Verify: Static analysis
- Verify: APK build & copy to `/home/tuneeca/RSQUARE/`

- [ ] **Step 1: Run full test suite across entire repository**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test`  
Expected: 100% test pass rate (325+ tests passed).

- [ ] **Step 2: Run static analyzer**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`  
Expected: 0 issues found.

- [ ] **Step 3: Verify zero occurrences of `tuneeca`**

Run: `git diff HEAD~5..HEAD | grep -i "tuneeca" || true`  
Expected: Zero output.

- [ ] **Step 4: Compile Kotlin and build release APK**

Run:
```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk /home/tuneeca/RSQUARE/ZYKL_Release.apk
cp build/app/outputs/flutter-apk/app-release.apk /home/tuneeca/RSQUARE/Takt_Desk_Release.apk
ls -lh /home/tuneeca/RSQUARE/ZYKL_Release.apk
```
Expected: Exit code 0, APK copied.

- [ ] **Step 5: Commit & Final Wrap-up**

```bash
git commit --allow-empty -m "chore(release): verify all tests pass, build production release APK with dual-pane tablet console, auto-unlock, and natural alarm suite"
```
