# Status Bar & Lock Screen Media Notification Controller Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native Android Status Bar & Lock Screen Media Notification Controller (powered by `MediaSessionCompat` and `NotificationCompat.MediaStyle`) with real-time Pomodoro telemetry, expand the audio soundscape to 12 curated focus tracks, and introduce modular dual-drawer and multi-drawer industrial interfaces for the Vinyl Player and Task Dispenser.

**Architecture:** A native Android `MediaNotificationService` (`foregroundServiceType="mediaPlayback|specialUse"`) manages the `MediaSessionCompat` and audio focus, communicating bi-directionally with Flutter via `MethodChannel('com.zykl.app/media_notification')`. Flutter UI presents 12 curated calm focus tracks organized into two stacked 6-disc drawers in `VinylDiscDrawerWidget`, and dynamically divides archived tasks into 10-task brass filing drawers in `ArchiveDrawerWidget`.

**Tech Stack:** Kotlin, AndroidX Media, `MediaSessionCompat`, `NotificationCompat.MediaStyle`, Flutter, Dart, Riverpod, Python (WAV audio generation).

## Global Constraints
- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetics (matte chassis, amber accent `#FF9E00`, monospace typography).
- Clean namespace: Absolutely 0 occurrences of `tuneeca` across all Kotlin, Dart, XML, and Gradle files (`com.zykl.app` / `com.takt.desk`).
- 0 analyzer diagnostics (`/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`).
- 100% test pass rate across the repository (`/home/tuneeca/RSQUARE/flutter/bin/flutter test`).
- Production APK build destination strictly at `/home/tuneeca/RSQUARE/ZYKL_Release.apk` (never `Takt_Desk_Release.apk`).

---

### Task 1: 12 Curated Focus Audio Soundscapes Generation & Domain Presets

**Files:**
- Create: `scripts/generate_all_vinyl_soundscapes.py`
- Modify: `lib/features/vinyl/domain/vinyl_track.dart`
- Test: `test/core/audio/vinyl_audio_assets_test.dart`

**Interfaces:**
- Produces: 12 preset instances of `VinylTrack` in `VinylTrack.presets` (index 0 to 11, catalog ID `TK-01` to `TK-12`).
- Asset paths: `assets/audio/vinyl_*.wav` (12 files, 22050 Hz 16-bit mono PCM).

- [ ] **Step 1: Write failing test verifying 12 presets and audio assets**

```dart
// test/core/audio/vinyl_audio_assets_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/vinyl/domain/vinyl_track.dart';

void main() {
  group('VinylTrack 12 Presets & Soundscape Assets', () {
    test('contains exactly 12 calibrated presets divided into 2 drawers', () {
      expect(VinylTrack.presets.length, 12);
      expect(VinylTrack.drawer1Presets.length, 6);
      expect(VinylTrack.drawer2Presets.length, 6);

      // Verify no noisy tracks remain
      final titles = VinylTrack.presets.map((t) => t.name.toLowerCase()).toList();
      expect(titles.contains('cafe echo'), isFalse);
      expect(titles.contains('forest canopy'), isFalse);
      expect(titles.contains('cosmic drift'), isFalse);
      expect(titles.contains('midnight train'), isFalse);

      // Verify new quiet tracks
      expect(titles.contains('kyoto bamboo stream'), isTrue);
      expect(titles.contains('nordic pine whispers'), isTrue);
      expect(titles.contains('alpine mountain brook'), isTrue);
      expect(titles.contains('warm tape & felt piano'), isTrue);
      expect(titles.contains('zen temple bowl'), isTrue);
      expect(titles.contains('misty morning meadow'), isTrue);
      expect(titles.contains('pure focus white noise'), isTrue);
      expect(titles.contains('timber acoustic chamber'), isTrue);
    });

    test('all 12 asset files exist on disk with valid headers', () {
      for (final track in VinylTrack.presets) {
        final file = File(track.assetPath);
        expect(file.existsSync(), isTrue, reason: 'Missing asset: ${track.assetPath}');
        expect(file.lengthSync(), greaterThan(10000));
      }
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/audio/vinyl_audio_assets_test.dart`  
Expected: FAIL (only 8 presets currently exist, missing helper getters).

- [ ] **Step 3: Create Python soundscape synthesis script and generate all 12 WAV files**

Write `scripts/generate_all_vinyl_soundscapes.py` to generate:
- `vinyl_lofi_rain.wav` (TK-01)
- `vinyl_brown_noise.wav` (TK-02)
- `vinyl_library.wav` (TK-03)
- `vinyl_kyoto_bamboo.wav` (TK-04: bamboo trickle, gentle water stream, moss stone resonance)
- `vinyl_campfire.wav` (TK-05)
- `vinyl_nordic_pines.wav` (TK-06: high-altitude soft filtered pine wind)
- `vinyl_alpine_brook.wav` (TK-07: crystalline steady brook murmur)
- `vinyl_warm_tape.wav` (TK-08: warm analog tape saturation & muted felt piano chords)
- `vinyl_zen_bowl.wav` (TK-09: singing bowl fundamental & gentle decaying harmonics)
- `vinyl_morning_meadow.wav` (TK-10: morning air dew blanket)
- `vinyl_pure_white_noise.wav` (TK-11: flat linear reading/coding white noise)
- `vinyl_timber_chamber.wav` (TK-12: dry timber room reflection)

Run: `python3 scripts/generate_all_vinyl_soundscapes.py`

- [ ] **Step 4: Update `VinylTrack` domain model**

In `lib/features/vinyl/domain/vinyl_track.dart`:
- Define `drawer1Presets => presets.sublist(0, 6);`
- Define `drawer2Presets => presets.sublist(6, 12);`
- Update `presets` list with all 12 items.
- Ensure `pubspec.yaml` includes all new assets under `assets/audio/`.

- [ ] **Step 5: Run tests and static analysis**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/audio/vinyl_audio_assets_test.dart`  
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`  
Expected: PASS and 0 issues.

- [ ] **Step 6: Commit Task 1**

```bash
git add assets/audio/ scripts/generate_all_vinyl_soundscapes.py lib/features/vinyl/domain/vinyl_track.dart pubspec.yaml test/core/audio/vinyl_audio_assets_test.dart
git commit -m "feat(audio): calibrate 12 focus soundscapes and partition VinylTrack into dual drawers"
```

---

### Task 2: Dual Record Drawer Interface (`VinylDiscDrawerWidget`)

**Files:**
- Modify: `lib/features/vinyl/presentation/widgets/vinyl_disc_drawer_widget.dart`
- Test: `test/features/vinyl/vinyl_disc_drawer_widget_test.dart`

**Interfaces:**
- Consumes: `VinylTrack.drawer1Presets` (6 items) & `VinylTrack.drawer2Presets` (6 items).
- Produces: Dual stacked modular drawers with independent handle bars and slide bays.

- [ ] **Step 1: Write failing widget test for dual record drawers**

```dart
// test/features/vinyl/vinyl_disc_drawer_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takt_desk/features/vinyl/presentation/widgets/vinyl_disc_drawer_widget.dart';

void main() {
  testWidgets('renders dual record drawers (Drawer 01 & Drawer 02)', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VinylDiscDrawerWidget(),
            ),
          ),
        ),
      ),
    );

    // Verify both drawer handle plates are rendered
    expect(find.byKey(const ValueKey('vinyl_drawer_1_handle')), findsOneWidget);
    expect(find.byKey(const ValueKey('vinyl_drawer_2_handle')), findsOneWidget);

    expect(find.textContaining('DRAWER 01 // 06 DISCS'), findsOneWidget);
    expect(find.textContaining('DRAWER 02 // 06 DISCS'), findsOneWidget);

    // Tap Drawer 1 to expand
    await tester.tap(find.byKey(const ValueKey('vinyl_drawer_1_handle')));
    await tester.pumpAndSettle();

    // Verify Drawer 1 interior bay is visible with 6 items
    expect(find.byKey(const ValueKey('record_sleeve_0')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/vinyl_disc_drawer_widget_test.dart`  
Expected: FAIL.

- [ ] **Step 3: Implement Dual Record Drawer in `VinylDiscDrawerWidget`**

In `lib/features/vinyl/presentation/widgets/vinyl_disc_drawer_widget.dart`:
- Support independent expansion for Drawer 1 (`_isDrawer1Open`) and Drawer 2 (`_isDrawer2Open`).
- Provide dedicated `PageController` instances for Drawer 1 (tracks 0..5) and Drawer 2 (tracks 6..11).
- Render two vertically stacked industrial drawer chassis units, each with Dieter Rams rivets, handle plate, micro navigation strip (`[ XX / 06 ]`), and compact 6-disc carousel.
- Play foley sound (`SoundEffect.drawerSlide` and `SoundEffect.drawerLatch`) on toggle.

- [ ] **Step 4: Run tests and static analysis**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/vinyl_disc_drawer_widget_test.dart`  
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`  
Expected: PASS and 0 issues.

- [ ] **Step 5: Commit Task 2**

```bash
git add lib/features/vinyl/presentation/widgets/vinyl_disc_drawer_widget.dart test/features/vinyl/vinyl_disc_drawer_widget_test.dart
git commit -m "feat(vinyl): implement dual stacked modular record drawers with 6-disc carousels"
```

---

### Task 3: Dynamic Multi-Drawer Task Dispenser Archive (`ArchiveDrawerWidget`)

**Files:**
- Modify: `lib/features/tasks/presentation/widgets/archive_drawer_widget.dart`
- Test: `test/features/tasks/archive_drawer_multi_test.dart`

**Interfaces:**
- Consumes: `ref.watch(receiptRunnerProvider).archivedTasks`.
- Produces: Dynamic brass archive filing drawers, partitioned every 10 tasks.

- [ ] **Step 1: Write failing widget test for dynamic multi-drawer archiving**

```dart
// test/features/tasks/archive_drawer_multi_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takt_desk/features/tasks/domain/receipt_task.dart';
import 'package:takt_desk/features/tasks/presentation/receipt_runner_controller.dart';
import 'package:takt_desk/features/tasks/presentation/widgets/archive_drawer_widget.dart';

void main() {
  testWidgets('partitions archived tasks into 10-task modular drawers', (tester) async {
    final container = ProviderContainer();
    // Simulate 23 completed tasks
    final fakeTasks = List.generate(
      23,
      (i) => ReceiptTask(
        id: 'task_$i',
        title: 'Task #$i',
        isCompleted: true,
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ArchiveDrawerWidget(),
            ),
          ),
        ),
      ),
    );

    // Initially 0 tasks -> 1 empty drawer
    expect(find.textContaining('ARCHIVE // DRAWER 01'), findsOneWidget);

    // Update state with 23 tasks
    container.read(receiptRunnerProvider.notifier).state =
        container.read(receiptRunnerProvider).copyWith(archivedTasks: fakeTasks);
    await tester.pumpAndSettle();

    // Now must display 3 drawers (Drawer 01: 10, Drawer 02: 10, Drawer 03: 3)
    expect(find.textContaining('ARCHIVE // DRAWER 01'), findsOneWidget);
    expect(find.textContaining('ARCHIVE // DRAWER 02'), findsOneWidget);
    expect(find.textContaining('ARCHIVE // DRAWER 03'), findsOneWidget);
    expect(find.textContaining('10 TASKS'), findsNWidgets(2));
    expect(find.textContaining('03 TASKS'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/tasks/archive_drawer_multi_test.dart`  
Expected: FAIL.

- [ ] **Step 3: Implement dynamic multi-drawer partitioning in `ArchiveDrawerWidget`**

In `lib/features/tasks/presentation/widgets/archive_drawer_widget.dart`:
- Partition `state.archivedTasks` into chunks of 10 items: `chunkSize = 10`.
- Maintain a set of open drawer indices (`Set<int> _openDrawers`).
- Render stacked brass drawer handle plates (`ARCHIVE // DRAWER 01 · 10 TASKS ▾`, `DRAWER 02 · 10 TASKS ▾`, etc.).
- Inside each drawer:
  - Task list for that partition.
  - Strikethrough title, reprint button.
  - `[ PURGE THIS BATCH ]` button to remove tasks in that partition.

- [ ] **Step 4: Run tests and static analysis**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/tasks/archive_drawer_multi_test.dart`  
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`  
Expected: PASS and 0 issues.

- [ ] **Step 5: Commit Task 3**

```bash
git add lib/features/tasks/presentation/widgets/archive_drawer_widget.dart test/features/tasks/archive_drawer_multi_test.dart
git commit -m "feat(tasks): implement dynamic 10-task modular brass filing drawers in ArchiveDrawerWidget"
```

---

### Task 4: Android Native `MediaNotificationService` & `MediaSessionCompat`

**Files:**
- Create: `android/app/src/main/kotlin/com/zykl/app/MediaNotificationService.kt`
- Create: `android/app/src/main/res/drawable/ic_media_prev.xml`
- Create: `android/app/src/main/res/drawable/ic_media_play.xml`
- Create: `android/app/src/main/res/drawable/ic_media_pause.xml`
- Create: `android/app/src/main/res/drawable/ic_media_next.xml`
- Modify: `android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Service actions: `ACTION_START`, `ACTION_UPDATE_PLAYBACK`, `ACTION_UPDATE_TIMER`, `ACTION_STOP`.
- Notification Channel: `zykl_media_playback_channel`.
- `MediaSessionCompat` with token and `PlaybackStateCompat`.

- [ ] **Step 1: Create media action vector drawables**

Create `ic_media_prev.xml`, `ic_media_play.xml`, `ic_media_pause.xml`, and `ic_media_next.xml` in `android/app/src/main/res/drawable/`.

- [ ] **Step 2: Implement `MediaNotificationService.kt`**

In `android/app/src/main/kotlin/com/zykl/app/MediaNotificationService.kt`:
- Service lifecycle management with `MediaSessionCompat`.
- `PlaybackStateCompat` handling actions (`ACTION_SKIP_TO_PREVIOUS`, `ACTION_PLAY_PAUSE`, `ACTION_SKIP_TO_NEXT`, `ACTION_STOP`).
- `NotificationCompat.MediaStyle` with `setShowActionsInCompactView(0, 1, 2)`.
- LargeIcon bitmap generation: Braun TP-1 vinyl record with amber spindle.
- Audio focus management (`AudioManager.OnAudioFocusChangeListener`).
- Native audio player for looping 12 tracks (`assets/audio/vinyl_*.wav`).
- Broadcast receiver or callback intent forwarder to `MainActivity`.

- [ ] **Step 3: Register Service in `AndroidManifest.xml`**

Declare `.MediaNotificationService` with `foregroundServiceType="mediaPlayback|specialUse"`.

- [ ] **Step 4: Verify Kotlin compilation**

Run: `cd android && ./gradlew compileReleaseKotlin && cd ..`  
Expected: BUILD SUCCESSFUL.

- [ ] **Step 5: Commit Task 4**

```bash
git add android/app/src/main/kotlin/com/zykl/app/MediaNotificationService.kt android/app/src/main/res/drawable/ic_media_*.xml android/app/src/main/AndroidManifest.xml
git commit -m "feat(native): implement MediaNotificationService with MediaSessionCompat and MediaStyle"
```

---

### Task 5: Platform Channel Wiring & Flutter `MediaNotificationService`

**Files:**
- Create: `lib/core/services/media_notification_service.dart`
- Modify: `android/app/src/main/kotlin/com/zykl/app/MainActivity.kt`
- Modify: `lib/features/vinyl/presentation/vinyl_controller.dart`
- Modify: `lib/features/chrono/presentation/controllers/chrono_dial_controller.dart`
- Test: `test/core/services/media_notification_service_test.dart`

**Interfaces:**
- MethodChannel: `com.zykl.app/media_notification`
- Methods: `startMediaNotification`, `updatePlaybackState`, `updateTimerTelemetry`, `stopMediaNotification`.
- Callback: `onMediaControlAction` (`'play'`, `'pause'`, `'next'`, `'previous'`).

- [ ] **Step 1: Write failing unit test for `MediaNotificationService`**

```dart
// test/core/services/media_notification_service_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/services/media_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<MethodCall> log;

  setUp(() {
    log = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.zykl.app/media_notification'),
      (call) async {
        log.add(call);
        return true;
      },
    );
  });

  test('startNotification invokes startMediaNotification with payload', () async {
    final service = MediaNotificationService();
    await service.startNotification(
      trackIndex: 0,
      trackName: 'Lo-fi Rain',
      isPlaying: true,
      volume: 0.8,
      phase: 'focus',
      remainingSeconds: 1500,
      cycleCount: 1,
    );

    expect(log.length, 1);
    expect(log.first.method, 'startMediaNotification');
    expect(log.first.arguments['trackName'], 'Lo-fi Rain');
    expect(log.first.arguments['isPlaying'], isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/services/media_notification_service_test.dart`  
Expected: FAIL.

- [ ] **Step 3: Implement `MediaNotificationService.dart` & wire in `MainActivity.kt`**

- In `lib/core/services/media_notification_service.dart`:
  - Implement class with method channel invocations.
  - Register method call handler for `onMediaControlAction`.
  - Dispatch actions to Riverpod providers (`vinylProvider.notifier.togglePlayback()`, `selectTrack()`).
- In `MainActivity.kt`:
  - Register `MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.zykl.app/media_notification")`.
  - Forward calls to `MediaNotificationService`.
  - Listen for MediaSession callbacks and send `onMediaControlAction` to Flutter.
- In `vinyl_controller.dart` & `chrono_dial_controller.dart`:
  - Sync playback and countdown timer changes with `mediaNotificationService`.

- [ ] **Step 4: Run tests and static analysis**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test`  
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`  
Expected: 100% PASS and 0 issues.

- [ ] **Step 5: Commit Task 5**

```bash
git add lib/core/services/media_notification_service.dart android/app/src/main/kotlin/com/zykl/app/MainActivity.kt lib/features/vinyl/presentation/vinyl_controller.dart lib/features/chrono/presentation/controllers/chrono_dial_controller.dart test/core/services/media_notification_service_test.dart
git commit -m "feat(media): wire platform channel between Flutter and MediaNotificationService"
```

---

### Task 6: Full Verification, Clean Namespace Check & Production Release APK Build

**Files:**
- Output APK: `/home/tuneeca/RSQUARE/ZYKL_Release.apk`

- [ ] **Step 1: Run full automated test suite**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test`  
Expected: 100% PASS across all unit and widget tests.

- [ ] **Step 2: Run static analysis**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`  
Expected: 0 issues found.

- [ ] **Step 3: Check clean namespace**

Run: `git diff 8d28a62..HEAD | grep -i "tuneeca" || true`  
Expected: 0 occurrences.

- [ ] **Step 4: Compile Kotlin and build production release APK**

Run: `cd android && ./gradlew compileReleaseKotlin && cd ..`  
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter build apk --release`  
Expected: BUILD SUCCESSFUL.

- [ ] **Step 5: Deploy release APK**

Run: `cp build/app/outputs/flutter-apk/app-release.apk /home/tuneeca/RSQUARE/ZYKL_Release.apk`  
Run: `ls -lh /home/tuneeca/RSQUARE/ZYKL_Release.apk`  
Confirm output exists and is ~80-85 MB.

- [ ] **Step 6: Commit and tag release**

```bash
git commit --allow-empty -m "chore(release): verify all quality gates and build ZYKL_Release.apk"
```
