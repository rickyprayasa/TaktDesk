# Retro Turntable 3-Channel Soundscape Mixer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Vinyl Deck into an authentic 3-channel analog soundscape mixing console with independent vertical faders for REC (primary vinyl ambient), DUST (needle & surface crackle), and FLOW (10 Hz alpha binaural drone at 432 Hz).

**Architecture:** Flutter Riverpod state management (`soundscapeMixerProvider`) persists fader and mute settings to SQLite via Drift (`DeskPreferences`), and dispatches real-time gain adjustments via MethodChannel (`com.takt.desk/audio`) to a native Android triple-`MediaPlayer` engine in `MainActivity.kt`. A Dieter Rams / Braun-styled tactile widget (`TurntableMixerStrip`) with machined fader tracks, aluminum thumbs, dB markings, and micro-LED mute toggles renders beneath the turntable platter.

**Tech Stack:** Flutter / Dart, Riverpod, Drift (SQLite), Kotlin / Android Native MediaPlayer, Flutter MethodChannel, Flutter Haptics.

## Global Constraints

- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetics (honest materials, uncluttered typography, amber accent #FF9E00, aluminum thumbs, matte dark chassis).
- Battery-first: 0 CPU wakeups per second during background playback; native MediaPlayer background audio.
- Clean namespace: Absolutely 0 occurrences of `tuneeca` across Kotlin, Dart, XML, and Gradle files (`com.takt.desk`).
- 0 analyzer issues (`/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`).
- 100% test pass rate across the entire repository (`/home/tuneeca/RSQUARE/flutter/bin/flutter test`).
- Clean Kotlin compilation via `./gradlew compileDebugKotlin`.

---

### Task 1: Mixer Companion Audio Assets & Unit Verification

**Files:**
- Test: `test/core/audio/mixer_audio_assets_test.dart`
- Verify: `assets/audio/vinyl_surface_crackle.wav`
- Verify: `assets/audio/binaural_alpha_432.wav`
- Verify: `pubspec.yaml`

**Interfaces:**
- Consumes: Flutter asset bundle system (`rootBundle.load`).
- Produces: Verified companion audio assets (`vinyl_surface_crackle.wav`, `binaural_alpha_432.wav`) registered in `pubspec.yaml`.

- [x] **Step 1: Write the failing test**

Create `test/core/audio/mixer_audio_assets_test.dart`:
```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mixer Companion Audio Assets', () {
    test('vinyl_surface_crackle.wav exists and loads from asset bundle', () async {
      final data = await rootBundle.load('assets/audio/vinyl_surface_crackle.wav');
      expect(data.lengthInBytes, greaterThan(100000));
    });

    test('binaural_alpha_432.wav exists and loads from asset bundle', () async {
      final data = await rootBundle.load('assets/audio/binaural_alpha_432.wav');
      expect(data.lengthInBytes, greaterThan(100000));
    });

    test('all 8 vinyl track WAV files exist and load from asset bundle', () async {
      final tracks = [
        'vinyl_lofi_rain.wav',
        'vinyl_brown_noise.wav',
        'vinyl_library.wav',
        'vinyl_cafe.wav',
        'vinyl_campfire.wav',
        'vinyl_forest.wav',
        'vinyl_cosmic.wav',
        'vinyl_train.wav',
      ];
      for (final track in tracks) {
        final data = await rootBundle.load('assets/audio/$track');
        expect(data.lengthInBytes, greaterThan(50000), reason: 'Track $track should be valid WAV');
      }
    });
  });
}
```

- [x] **Step 2: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/audio/mixer_audio_assets_test.dart`
Expected: PASS (All assets are present in `assets/audio/` and registered in `pubspec.yaml`).

- [x] **Step 3: Run static analyzer**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`
Expected: No issues found!

- [x] **Step 4: Commit**

```bash
git add test/core/audio/mixer_audio_assets_test.dart
git commit -m "test(audio): verify mixer companion assets and vinyl soundscapes in asset bundle"
```

---

### Task 2: Native Android Triple-MediaPlayer Engine & MethodChannel Wiring

**Files:**
- Modify: `android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt`
- Test: `test/core/audio/audio_service_test.dart`

**Interfaces:**
- Consumes: MethodChannel `com.takt.desk/audio`.
- Produces: Triple-player hardware audio engine supporting `startAmbient(trackIndex, masterVolume, primaryVolume, crackleVolume, binauralVolume)`, `setMixerLevels(primaryVolume, crackleVolume, binauralVolume)`, `setVolume(volume)`, and `stopAmbient`.

- [x] **Step 1: Write test for updated AudioService MethodChannel client**

Update `test/core/audio/audio_service_test.dart`:
```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/audio/sound_effect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AudioService audioService;
  late List<MethodCall> methodCalls;

  setUp(() {
    methodCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AudioService.channel, (call) async {
      methodCalls.add(call);
      return true;
    });

    audioService = AudioService();
    audioService.init();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AudioService.channel, null);
    audioService.dispose();
  });

  test('AudioService startAmbient sends 3-channel mixer parameters', () {
    audioService.startAmbient(
      trackIndex: 2,
      primaryVolume: 0.75,
      crackleVolume: 0.40,
      binauralVolume: 0.20,
    );

    expect(methodCalls, hasLength(1));
    expect(methodCalls.first.method, 'startAmbient');
    expect(methodCalls.first.arguments['trackIndex'], 2);
    expect(methodCalls.first.arguments['volume'], 0.8);
    expect(methodCalls.first.arguments['primaryVolume'], 0.75);
    expect(methodCalls.first.arguments['crackleVolume'], 0.40);
    expect(methodCalls.first.arguments['binauralVolume'], 0.20);
  });

  test('AudioService setMixerLevels invokes setMixerLevels with clamped values', () {
    audioService.setMixerLevels(
      primaryVolume: 0.90,
      crackleVolume: 0.30,
      binauralVolume: 0.15,
    );

    expect(methodCalls, hasLength(1));
    expect(methodCalls.first.method, 'setMixerLevels');
    expect(methodCalls.first.arguments['primaryVolume'], 0.90);
    expect(methodCalls.first.arguments['crackleVolume'], 0.30);
    expect(methodCalls.first.arguments['binauralVolume'], 0.15);
  });

  test('AudioService playFoley forwards sound effects', () {
    audioService.playFoley(SoundEffect.stylusDrop);
    expect(methodCalls.last.method, 'playFoley');
    expect(methodCalls.last.arguments['effect'], 'stylusDrop');
  });

  test('AudioService stopAmbient stops all channels', () {
    audioService.stopAmbient();
    expect(methodCalls.last.method, 'stopAmbient');
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/audio/audio_service_test.dart`
Expected: FAIL (Named parameters `primaryVolume`, `crackleVolume`, `binauralVolume`, and `setMixerLevels` not yet defined).

- [x] **Step 3: Update `AudioService` in `lib/core/audio/audio_service.dart`**

Modify `lib/core/audio/audio_service.dart`:
```dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sound_effect.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  service.init();
  ref.onDispose(service.dispose);
  return service;
});

class AudioService {
  static const MethodChannel channel = MethodChannel('com.takt.desk/audio');

  final bool isMock;
  bool _initialized = false;
  double _volume = 0.8;
  int _activeTrackIndex = 0;
  bool _isAmbientPlaying = false;
  bool _foleyEnabled = true;

  AudioService({this.isMock = false});

  bool get isInitialized => _initialized;
  double get volume => _volume;
  bool get isAmbientPlaying => _isAmbientPlaying;
  int get activeTrackIndex => _activeTrackIndex;
  bool get foleyEnabled => _foleyEnabled;

  Future<void> init() async {
    _initialized = true;
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    if (!isMock && _initialized) {
      channel.invokeMethod('setVolume', {'volume': _volume}).catchError((_) {});
    }
  }

  void setFoleyEnabled(bool val) {
    _foleyEnabled = val;
  }

  void playFoley(SoundEffect effect) {
    if (!_initialized || !_foleyEnabled) return;
    if (!isMock) {
      channel.invokeMethod('playFoley', {'effect': effect.name}).catchError((_) {});
    }
  }

  void play(SoundEffect effect) => playFoley(effect);

  void startAmbient({
    required int trackIndex,
    double primaryVolume = 0.80,
    double crackleVolume = 0.35,
    double binauralVolume = 0.25,
  }) {
    if (!_initialized) return;
    _activeTrackIndex = trackIndex;
    _isAmbientPlaying = true;
    if (!isMock) {
      channel.invokeMethod('startAmbient', {
        'trackIndex': trackIndex,
        'volume': _volume,
        'primaryVolume': primaryVolume.clamp(0.0, 1.0),
        'crackleVolume': crackleVolume.clamp(0.0, 1.0),
        'binauralVolume': binauralVolume.clamp(0.0, 1.0),
      }).catchError((_) {});
    }
  }

  void setMixerLevels({
    required double primaryVolume,
    required double crackleVolume,
    required double binauralVolume,
  }) {
    if (!_initialized) return;
    if (!isMock) {
      channel.invokeMethod('setMixerLevels', {
        'primaryVolume': primaryVolume.clamp(0.0, 1.0),
        'crackleVolume': crackleVolume.clamp(0.0, 1.0),
        'binauralVolume': binauralVolume.clamp(0.0, 1.0),
      }).catchError((_) {});
    }
  }

  void stopAmbient() {
    _isAmbientPlaying = false;
    if (!isMock) {
      channel.invokeMethod('stopAmbient').catchError((_) {});
    }
  }

  void dispose() {
    stopAmbient();
    _initialized = false;
  }
}
```

- [x] **Step 4: Update `MainActivity.kt` with Triple-MediaPlayer Engine**

Modify `android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt` lines 20-154:
```kotlin
    private var soundscapePlayer: MediaPlayer? = null
    private var cracklePlayer: MediaPlayer? = null
    private var binauralPlayer: MediaPlayer? = null
    private var masterVolume: Float = 0.8f
    private var primaryGain: Float = 0.80f
    private var crackleGain: Float = 0.35f
    private var binauralGain: Float = 0.25f

    private fun updateAllVolumes() {
        val pVol = (masterVolume * primaryGain).coerceIn(0f, 1f)
        val cVol = (masterVolume * crackleGain).coerceIn(0f, 1f)
        val bVol = (masterVolume * binauralGain).coerceIn(0f, 1f)
        try {
            soundscapePlayer?.setVolume(pVol, pVol)
        } catch (_: Exception) {}
        try {
            cracklePlayer?.setVolume(cVol, cVol)
        } catch (_: Exception) {}
        try {
            binauralPlayer?.setVolume(bVol, bVol)
        } catch (_: Exception) {}
    }
```
And update `AUDIO_CHANNEL` handler in `MainActivity.kt`:
```kotlin
                "startAmbient" -> {
                    try {
                        val trackIndex = call.argument<Int>("trackIndex") ?: 0
                        masterVolume = (call.argument<Double>("volume") ?: 0.8).toFloat()
                        primaryGain = (call.argument<Double>("primaryVolume") ?: 0.8).toFloat()
                        crackleGain = (call.argument<Double>("crackleVolume") ?: 0.35).toFloat()
                        binauralGain = (call.argument<Double>("binauralVolume") ?: 0.25).toFloat()

                        val assetPath = when (trackIndex) {
                            0 -> "flutter_assets/assets/audio/vinyl_lofi_rain.wav"
                            1 -> "flutter_assets/assets/audio/vinyl_brown_noise.wav"
                            2 -> "flutter_assets/assets/audio/vinyl_library.wav"
                            3 -> "flutter_assets/assets/audio/vinyl_cafe.wav"
                            4 -> "flutter_assets/assets/audio/vinyl_campfire.wav"
                            5 -> "flutter_assets/assets/audio/vinyl_forest.wav"
                            6 -> "flutter_assets/assets/audio/vinyl_cosmic.wav"
                            7 -> "flutter_assets/assets/audio/vinyl_train.wav"
                            else -> "flutter_assets/assets/audio/vinyl_lofi_rain.wav"
                        }

                        // 1. Primary Soundscape Player
                        soundscapePlayer?.apply {
                            if (isPlaying) stop()
                            reset()
                        }
                        soundscapePlayer = soundscapePlayer ?: MediaPlayer()
                        val fdPrimary = context.assets.openFd(assetPath)
                        soundscapePlayer?.apply {
                            reset()
                            setDataSource(fdPrimary.fileDescriptor, fdPrimary.startOffset, fdPrimary.length)
                            isLooping = true
                            prepare()
                            start()
                        }
                        fdPrimary.close()

                        // 2. Vinyl Surface Crackle Player
                        cracklePlayer?.apply {
                            if (isPlaying) stop()
                            reset()
                        }
                        cracklePlayer = cracklePlayer ?: MediaPlayer()
                        val fdCrackle = context.assets.openFd("flutter_assets/assets/audio/vinyl_surface_crackle.wav")
                        cracklePlayer?.apply {
                            reset()
                            setDataSource(fdCrackle.fileDescriptor, fdCrackle.startOffset, fdCrackle.length)
                            isLooping = true
                            prepare()
                            start()
                        }
                        fdCrackle.close()

                        // 3. Binaural Alpha 432 Hz Drone Player
                        binauralPlayer?.apply {
                            if (isPlaying) stop()
                            reset()
                        }
                        binauralPlayer = binauralPlayer ?: MediaPlayer()
                        val fdBinaural = context.assets.openFd("flutter_assets/assets/audio/binaural_alpha_432.wav")
                        binauralPlayer?.apply {
                            reset()
                            setDataSource(fdBinaural.fileDescriptor, fdBinaural.startOffset, fdBinaural.length)
                            isLooping = true
                            prepare()
                            start()
                        }
                        fdBinaural.close()

                        updateAllVolumes()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "stopAmbient" -> {
                    try {
                        soundscapePlayer?.apply { if (isPlaying) stop(); reset() }
                        cracklePlayer?.apply { if (isPlaying) stop(); reset() }
                        binauralPlayer?.apply { if (isPlaying) stop(); reset() }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "setMixerLevels" -> {
                    try {
                        primaryGain = (call.argument<Double>("primaryVolume") ?: primaryGain.toDouble()).toFloat()
                        crackleGain = (call.argument<Double>("crackleVolume") ?: crackleGain.toDouble()).toFloat()
                        binauralGain = (call.argument<Double>("binauralVolume") ?: binauralGain.toDouble()).toFloat()
                        updateAllVolumes()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "setVolume" -> {
                    try {
                        masterVolume = (call.argument<Double>("volume") ?: 0.8).toFloat()
                        updateAllVolumes()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
```

- [x] **Step 5: Verify Kotlin compilation**

Run: `cd android && ./gradlew compileDebugKotlin && cd ..`
Expected: BUILD SUCCESSFUL.

- [x] **Step 6: Run Flutter unit tests & static analysis**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/audio/audio_service_test.dart`
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`
Expected: All tests pass, 0 analyzer issues.

- [x] **Step 7: Commit**

```bash
git add android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt lib/core/audio/audio_service.dart test/core/audio/audio_service_test.dart
git commit -m "feat(audio): implement native triple-MediaPlayer soundscape mixer engine in MainActivity"
```

---

### Task 3: Domain Model, Drift Database Persistence & Riverpod Controller

**Files:**
- Create: `lib/features/vinyl/domain/soundscape_mixer_state.dart`
- Modify: `lib/core/database/tables/desk_preferences_table.dart`
- Modify: `lib/core/database/app_database.dart`
- Create: `lib/features/vinyl/presentation/soundscape_mixer_controller.dart`
- Test: `test/features/vinyl/soundscape_mixer_controller_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `AudioService`.
- Produces: `soundscapeMixerProvider` state notifier providing `SoundscapeMixerState` with `setPrimaryVolume(double)`, `setCrackleVolume(double)`, `setBinauralVolume(double)`, `togglePrimaryMute()`, `toggleCrackleMute()`, and `toggleBinauralMute()`.

- [x] **Step 1: Write the failing unit test**

Create `test/features/vinyl/soundscape_mixer_controller_test.dart`:
```dart
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/vinyl/domain/soundscape_mixer_state.dart';
import 'package:takt_desk/features/vinyl/presentation/soundscape_mixer_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AudioService mockAudio;
  late ProviderContainer container;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockAudio = AudioService(isMock: true);

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioServiceProvider.overrideWithValue(mockAudio),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('SoundscapeMixerState defaults to 0.80 primary, 0.35 crackle, 0.25 binaural and unmuted', () {
    const state = SoundscapeMixerState();
    expect(state.primaryVolume, 0.80);
    expect(state.crackleVolume, 0.35);
    expect(state.binauralVolume, 0.25);
    expect(state.isPrimaryMuted, isFalse);
    expect(state.isCrackleMuted, isFalse);
    expect(state.isBinauralMuted, isFalse);
    expect(state.effectivePrimary, 0.80);
    expect(state.effectiveCrackle, 0.35);
    expect(state.effectiveBinaural, 0.25);
  });

  test('effective gain collapses to 0.0 when channel is muted', () {
    const state = SoundscapeMixerState(
      primaryVolume: 0.90,
      isPrimaryMuted: true,
      crackleVolume: 0.50,
      isCrackleMuted: true,
    );
    expect(state.effectivePrimary, 0.0);
    expect(state.effectiveCrackle, 0.0);
    expect(state.effectiveBinaural, 0.25);
  });

  test('SoundscapeMixerController updates volumes and toggles mutes', () async {
    final controller = container.read(soundscapeMixerProvider.notifier);

    controller.setPrimaryVolume(0.65);
    expect(container.read(soundscapeMixerProvider).primaryVolume, 0.65);

    controller.setCrackleVolume(0.50);
    expect(container.read(soundscapeMixerProvider).crackleVolume, 0.50);

    controller.setBinauralVolume(0.10);
    expect(container.read(soundscapeMixerProvider).binauralVolume, 0.10);

    controller.toggleCrackleMute();
    expect(container.read(soundscapeMixerProvider).isCrackleMuted, isTrue);
    expect(container.read(soundscapeMixerProvider).effectiveCrackle, 0.0);

    controller.toggleCrackleMute();
    expect(container.read(soundscapeMixerProvider).isCrackleMuted, isFalse);
    expect(container.read(soundscapeMixerProvider).effectiveCrackle, 0.50);
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/soundscape_mixer_controller_test.dart`
Expected: FAIL (Classes `SoundscapeMixerState` and `soundscapeMixerProvider` not found).

- [x] **Step 3: Implement `SoundscapeMixerState`**

Create `lib/features/vinyl/domain/soundscape_mixer_state.dart`:
```dart
class SoundscapeMixerState {
  final double primaryVolume;
  final double crackleVolume;
  final double binauralVolume;
  final bool isPrimaryMuted;
  final bool isCrackleMuted;
  final bool isBinauralMuted;

  const SoundscapeMixerState({
    this.primaryVolume = 0.80,
    this.crackleVolume = 0.35,
    this.binauralVolume = 0.25,
    this.isPrimaryMuted = false,
    this.isCrackleMuted = false,
    this.isBinauralMuted = false,
  });

  double get effectivePrimary => isPrimaryMuted ? 0.0 : primaryVolume;
  double get effectiveCrackle => isCrackleMuted ? 0.0 : crackleVolume;
  double get effectiveBinaural => isBinauralMuted ? 0.0 : binauralVolume;

  SoundscapeMixerState copyWith({
    double? primaryVolume,
    double? crackleVolume,
    double? binauralVolume,
    bool? isPrimaryMuted,
    bool? isCrackleMuted,
    bool? isBinauralMuted,
  }) {
    return SoundscapeMixerState(
      primaryVolume: primaryVolume ?? this.primaryVolume,
      crackleVolume: crackleVolume ?? this.crackleVolume,
      binauralVolume: binauralVolume ?? this.binauralVolume,
      isPrimaryMuted: isPrimaryMuted ?? this.isPrimaryMuted,
      isCrackleMuted: isCrackleMuted ?? this.isCrackleMuted,
      isBinauralMuted: isBinauralMuted ?? this.isBinauralMuted,
    );
  }
}
```

- [x] **Step 4: Update `DeskPreferences` table & schema version in `AppDatabase`**

In `lib/core/database/tables/desk_preferences_table.dart`:
Add columns:
```dart
  RealColumn get primaryVolume => real().withDefault(const Constant(0.80))();
  RealColumn get crackleVolume => real().withDefault(const Constant(0.35))();
  RealColumn get binauralVolume => real().withDefault(const Constant(0.25))();
  BoolColumn get primaryMuted => boolean().withDefault(const Constant(false))();
  BoolColumn get crackleMuted => boolean().withDefault(const Constant(false))();
  BoolColumn get binauralMuted => boolean().withDefault(const Constant(false))();
```

In `lib/core/database/app_database.dart`:
Increment `schemaVersion` to 3 and add migration step in `onUpgrade`:
```dart
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(deskPreferences, deskPreferences.selectedEdition);
            await m.addColumn(deskPreferences, deskPreferences.isProSimulated);
          }
          if (from < 3) {
            await m.addColumn(deskPreferences, deskPreferences.primaryVolume);
            await m.addColumn(deskPreferences, deskPreferences.crackleVolume);
            await m.addColumn(deskPreferences, deskPreferences.binauralVolume);
            await m.addColumn(deskPreferences, deskPreferences.primaryMuted);
            await m.addColumn(deskPreferences, deskPreferences.crackleMuted);
            await m.addColumn(deskPreferences, deskPreferences.binauralMuted);
          }
        },
      );
```
Run: `/home/tuneeca/RSQUARE/flutter/bin/dart run build_runner build --delete-conflicting-outputs`

- [x] **Step 5: Implement `SoundscapeMixerController`**

Create `lib/features/vinyl/presentation/soundscape_mixer_controller.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_service.dart';
import '../../core/database/app_database.dart';
import '../domain/soundscape_mixer_state.dart';

final soundscapeMixerProvider =
    StateNotifierProvider<SoundscapeMixerController, SoundscapeMixerState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final audioService = ref.watch(audioServiceProvider);
  return SoundscapeMixerController(db, audioService);
});

class SoundscapeMixerController extends StateNotifier<SoundscapeMixerState> {
  final AppDatabase _db;
  final AudioService _audioService;

  SoundscapeMixerController(this._db, this._audioService)
      : super(const SoundscapeMixerState()) {
    _loadFromDatabase();
  }

  Future<void> _loadFromDatabase() async {
    try {
      final prefs = await _db.getDeskPreferences();
      if (prefs != null) {
        state = SoundscapeMixerState(
          primaryVolume: prefs.primaryVolume,
          crackleVolume: prefs.crackleVolume,
          binauralVolume: prefs.binauralVolume,
          isPrimaryMuted: prefs.primaryMuted,
          isCrackleMuted: prefs.crackleMuted,
          isBinauralMuted: prefs.binauralMuted,
        );
        _syncToAudioService();
      }
    } catch (_) {}
  }

  void _syncToAudioService() {
    _audioService.setMixerLevels(
      primaryVolume: state.effectivePrimary,
      crackleVolume: state.effectiveCrackle,
      binauralVolume: state.effectiveBinaural,
    );
  }

  void setPrimaryVolume(double val) {
    state = state.copyWith(primaryVolume: val.clamp(0.0, 1.0));
    _syncToAudioService();
    _persist();
  }

  void setCrackleVolume(double val) {
    state = state.copyWith(crackleVolume: val.clamp(0.0, 1.0));
    _syncToAudioService();
    _persist();
  }

  void setBinauralVolume(double val) {
    state = state.copyWith(binauralVolume: val.clamp(0.0, 1.0));
    _syncToAudioService();
    _persist();
  }

  void togglePrimaryMute() {
    state = state.copyWith(isPrimaryMuted: !state.isPrimaryMuted);
    _syncToAudioService();
    _persist();
  }

  void toggleCrackleMute() {
    state = state.copyWith(isCrackleMuted: !state.isCrackleMuted);
    _syncToAudioService();
    _persist();
  }

  void toggleBinauralMute() {
    state = state.copyWith(isBinauralMuted: !state.isBinauralMuted);
    _syncToAudioService();
    _persist();
  }

  Future<void> _persist() async {
    try {
      await _db.updateDeskPreferences(
        primaryVolume: state.primaryVolume,
        crackleVolume: state.crackleVolume,
        binauralVolume: state.binauralVolume,
        primaryMuted: state.isPrimaryMuted,
        crackleMuted: state.isCrackleMuted,
        binauralMuted: state.isBinauralMuted,
      );
    } catch (_) {}
  }
}
```

- [x] **Step 6: Update `VinylController.start()` to pass mixer gains to `startAmbient`**

In `lib/features/vinyl/presentation/vinyl_controller.dart`:
Read `soundscapeMixerProvider` and pass `primaryVolume: mixer.effectivePrimary, crackleVolume: mixer.effectiveCrackle, binauralVolume: mixer.effectiveBinaural` to `audioService.startAmbient(...)`.

- [x] **Step 7: Run unit tests to verify they pass**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/soundscape_mixer_controller_test.dart`
Expected: PASS (All tests passing).

- [x] **Step 8: Run static analysis**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`
Expected: No issues found!

- [x] **Step 9: Commit**

```bash
git add lib/features/vinyl/domain/soundscape_mixer_state.dart lib/core/database/tables/desk_preferences_table.dart lib/core/database/app_database.dart lib/core/database/app_database.g.dart lib/features/vinyl/presentation/soundscape_mixer_controller.dart lib/features/vinyl/presentation/vinyl_controller.dart test/features/vinyl/soundscape_mixer_controller_test.dart
git commit -m "feat(mixer): implement SoundscapeMixerState, Drift persistence, and Riverpod controller"
```

---

### Task 4: Tactile UI Component TurntableMixerStrip & Vinyl Player Integration

**Files:**
- Create: `lib/features/vinyl/presentation/widgets/turntable_mixer_strip.dart`
- Modify: `lib/features/vinyl/presentation/vinyl_player_widget.dart`
- Test: `test/features/vinyl/turntable_mixer_strip_test.dart`

**Interfaces:**
- Consumes: `soundscapeMixerProvider`, `chassisThemeProvider`.
- Produces: `TurntableMixerStrip` component rendered within `VinylPlayerWidget` below the tonearm platter.

- [x] **Step 1: Write widget test for `TurntableMixerStrip`**

Create `test/features/vinyl/turntable_mixer_strip_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/vinyl/presentation/widgets/turntable_mixer_strip.dart';
import 'package:takt_desk/features/vinyl/presentation/soundscape_mixer_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TurntableMixerStrip renders 3 faders (REC, DUST, FLOW) and mute toggles', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: TurntableMixerStrip(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify channel labels
    expect(find.text('REC'), findsOneWidget);
    expect(find.text('DUST'), findsOneWidget);
    expect(find.text('FLOW'), findsOneWidget);

    // Verify dB scale markings
    expect(find.text('0dB'), findsNWidgets(3));
    expect(find.text('-∞'), findsNWidgets(3));

    // Verify 3 mute buttons
    expect(find.byKey(const ValueKey('mute_rec_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('mute_dust_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('mute_flow_button')), findsOneWidget);
  });

  testWidgets('Tapping mute button toggles channel mute in controller', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: TurntableMixerStrip(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Initial state: DUST unmuted
    expect(container.read(soundscapeMixerProvider).isCrackleMuted, isFalse);

    // Tap mute DUST
    await tester.tap(find.byKey(const ValueKey('mute_dust_button')));
    await tester.pump();

    expect(container.read(soundscapeMixerProvider).isCrackleMuted, isTrue);

    // Tap mute DUST again to unmute
    await tester.tap(find.byKey(const ValueKey('mute_dust_button')));
    await tester.pump();

    expect(container.read(soundscapeMixerProvider).isCrackleMuted, isFalse);
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/turntable_mixer_strip_test.dart`
Expected: FAIL (`TurntableMixerStrip` not defined).

- [x] **Step 3: Implement `TurntableMixerStrip`**

Create `lib/features/vinyl/presentation/widgets/turntable_mixer_strip.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/theme_controller.dart';
import '../soundscape_mixer_controller.dart';

/// Dieter Rams / Braun 3-Channel Analog Soundscape Mixing Console Strip.
///
/// Features:
/// - REC (Primary Vinyl Audio)
/// - DUST (Surface & Needle Crackle)
/// - FLOW (10 Hz Alpha Binaural Drone at 432 Hz)
class TurntableMixerStrip extends ConsumerWidget {
  const TurntableMixerStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mixerState = ref.watch(soundscapeMixerProvider);
    final mixerNotifier = ref.read(soundscapeMixerProvider.notifier);
    final themeState = ref.watch(chassisThemeProvider);
    final isDark = themeState.isDarkMode;

    return Container(
      width: 256,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131518) : const Color(0xFFE2DDD1),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: isDark ? const Color(0xFF262930) : const Color(0xFFC7C2B4),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x66000000) : const Color(0x1A000000),
            offset: const Offset(0, 1.5),
            blurRadius: 3.0,
            spreadRadius: -0.5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Plaque
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SOUNDSCAPE MIXER // 3-CH',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isDark ? const Color(0xFF8A909A) : const Color(0xFF656A72),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B1E22) : const Color(0xFFDDD8CD),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: isDark ? const Color(0xFF33373E) : const Color(0xFFB5B0A4),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '432Hz · 10Hz α',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: themeState.filamentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 3-Channel Fader Strips Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFaderChannel(
                label: 'REC',
                subLabel: 'PRIMARY',
                value: mixerState.primaryVolume,
                isMuted: mixerState.isPrimaryMuted,
                muteKey: 'mute_rec_button',
                onChanged: mixerNotifier.setPrimaryVolume,
                onMuteToggle: mixerNotifier.togglePrimaryMute,
                themeState: themeState,
                isDark: isDark,
              ),
              Container(
                width: 1.0,
                height: 82,
                color: themeState.borderColor.withValues(alpha: 0.4),
              ),
              _buildFaderChannel(
                label: 'DUST',
                subLabel: 'CRACKLE',
                value: mixerState.crackleVolume,
                isMuted: mixerState.isCrackleMuted,
                muteKey: 'mute_dust_button',
                onChanged: mixerNotifier.setCrackleVolume,
                onMuteToggle: mixerNotifier.toggleCrackleMute,
                themeState: themeState,
                isDark: isDark,
              ),
              Container(
                width: 1.0,
                height: 82,
                color: themeState.borderColor.withValues(alpha: 0.4),
              ),
              _buildFaderChannel(
                label: 'FLOW',
                subLabel: 'BINAURAL',
                value: mixerState.binauralVolume,
                isMuted: mixerState.isBinauralMuted,
                muteKey: 'mute_flow_button',
                onChanged: mixerNotifier.setBinauralVolume,
                onMuteToggle: mixerNotifier.toggleBinauralMute,
                themeState: themeState,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaderChannel({
    required String label,
    required String subLabel,
    required double value,
    required bool isMuted,
    required String muteKey,
    required ValueChanged<double> onChanged,
    required VoidCallback onMuteToggle,
    required dynamic themeState,
    required bool isDark,
  }) {
    const faderHeight = 52.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Channel Label
        Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isMuted
                ? (isDark ? const Color(0xFF555A64) : const Color(0xFFA09B8E))
                : themeState.chassisTextColor,
          ),
        ),
        Text(
          subLabel,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 6.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: isDark ? const Color(0xFF7A808A) : const Color(0xFF8E897E),
          ),
        ),
        const SizedBox(height: 4),
        // Fader Track + dB Markings
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // dB scale markings on the left
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0dB', style: TextStyle(fontFamily: 'monospace', fontSize: 6.5, color: isDark ? const Color(0xFF6A707A) : const Color(0xFF8E897E))),
                const SizedBox(height: 20),
                Text('-∞', style: TextStyle(fontFamily: 'monospace', fontSize: 6.5, color: isDark ? const Color(0xFF6A707A) : const Color(0xFF8E897E))),
              ],
            ),
            const SizedBox(width: 3),
            // Physical Machined Fader Track
            GestureDetector(
              onVerticalDragUpdate: (details) {
                // Dragging up increases volume, dragging down decreases
                final delta = -details.primaryDelta! / faderHeight;
                final newVal = (value + delta).clamp(0.0, 1.0);
                if ((value < 0.75 && newVal >= 0.75) || (value > 0.75 && newVal <= 0.75)) {
                  HapticFeedback.selectionClick();
                }
                onChanged(newVal);
              },
              child: Container(
                width: 18,
                height: faderHeight,
                alignment: Alignment.bottomCenter,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Recessed Center Track Groove
                    Center(
                      child: Container(
                        width: 4.0,
                        height: faderHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C0E10),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: isDark ? const Color(0xFF262930) : const Color(0xFFC7C2B4),
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                    // Aluminum Machined Slider Thumb
                    Positioned(
                      bottom: (value * (faderHeight - 14)).clamp(0.0, faderHeight - 14),
                      child: Container(
                        width: 18,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFFD4D0C5) : const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(2.5),
                          border: Border.all(
                            color: isDark ? const Color(0xFF4A4E58) : const Color(0xFFB5B0A4),
                            width: 0.8,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              offset: Offset(0, 1),
                              blurRadius: 2.0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 10,
                            height: 2.0,
                            decoration: BoxDecoration(
                              color: isMuted ? const Color(0xFF888888) : TaktColors.filamentAmber,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Mute Micro-LED Toggle
        InkWell(
          key: ValueKey(muteKey),
          onTap: onMuteToggle,
          borderRadius: BorderRadius.circular(3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: isMuted
                  ? (isDark ? const Color(0xFF1E2126) : const Color(0xFFD5D0C3))
                  : (isDark ? const Color(0xFF141619) : const Color(0xFFECE7DB)),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: isMuted
                    ? const Color(0xFFC85A32).withValues(alpha: 0.6)
                    : (isDark ? const Color(0xFF2C3038) : const Color(0xFFBBB5A7)),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 4.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isMuted
                        ? const Color(0xFFC85A32)
                        : (isDark ? const Color(0xFF333842) : const Color(0xFFA09B8E)),
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  isMuted ? 'MUTED' : 'MUTE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 7.0,
                    fontWeight: FontWeight.w700,
                    color: isMuted
                        ? const Color(0xFFC85A32)
                        : (isDark ? const Color(0xFF7A808A) : const Color(0xFF7E796E)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

- [x] **Step 4: Mount `TurntableMixerStrip` inside `VinylPlayerWidget`**

In `lib/features/vinyl/presentation/vinyl_player_widget.dart`:
Add `import 'widgets/turntable_mixer_strip.dart';`
Mount `const TurntableMixerStrip()` directly between the track status row and `VinylDiscDrawerWidget`:
```dart
          // Slide-Out Archival Disc Drawer
          const VinylDiscDrawerWidget(),
          const SizedBox(height: 10),
          // 3-Channel Soundscape Mixer Strip
          const TurntableMixerStrip(),
```

- [x] **Step 5: Run widget tests to verify they pass**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/turntable_mixer_strip_test.dart`
Expected: PASS.

- [x] **Step 6: Run full test suite & static analyzer**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test`
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`
Expected: 100% tests pass, 0 analyzer issues.

- [x] **Step 7: Build release APK and verify zero errors**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter build apk --release`
Run: `cp build/app/outputs/flutter-apk/app-release.apk /home/tuneeca/RSQUARE/Takt_Desk_Release.apk`

- [x] **Step 8: Commit**

```bash
git add lib/features/vinyl/presentation/widgets/turntable_mixer_strip.dart lib/features/vinyl/presentation/vinyl_player_widget.dart test/features/vinyl/turntable_mixer_strip_test.dart
git commit -m "feat(vinyl): integrate TurntableMixerStrip 3-channel console into VinylPlayerWidget"
```
