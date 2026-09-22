# ZYKL 20 Soundscapes & 12 Hardware Editions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand ZYKL soundscapes to 20 authentic physical recordings (10 per drawer: 4 Free + 6 PRO) and expand Hardware Editions to 12 industrial themes (4 Free + 8 PRO) with complete test coverage and distribution builds.

**Architecture:** 
- Vinyl Audio: Process 100% real acoustic recordings into 40.0s 22050Hz 16-bit mono linear PCM WAVs with equal-power sinusoidal crossfade. Expand `VinylTrack.presets` from 12 to 20 tracks, partitioned into `drawer1Presets` (0..9) and `drawer2Presets` (10..19).
- Hardware Editions: Expand `HardwareEditionType` enum and `HardwareEdition` instances from 7 to 12 editions (4 Free, 8 PRO). Update `ChronoDialWidget` dial face palette mapping and verify dynamic carousel paging in `_HardwareEditionsSection`.

**Tech Stack:** Flutter / Dart, Riverpod, Kotlin / Android Platform Channel, FFmpeg, Python.

## Global Constraints
- Target directory: `/home/tuneeca/RSQUARE/Android/Takt Desk/`
- Audio Quality: 100% real physical recordings. Zero algorithmic/AI oscillators. 40.0s seamless loop, 22,050 Hz 16-bit mono linear PCM uncompressed WAV.
- Clean Code: Zero analyzer warnings or errors (`flutter analyze` clean).
- Test Coverage: All existing 410 unit/widget tests and new audio/theme tests must pass.
- Distribution: Rebuild all 3 targets in `build_outputs/`: `zykl-developer-pro.apk`, `zykl-user-testing.apk`, and `zykl-playstore-release.aab`.

---

### Task 1: Sourcing & Processing 4 Additional Drawer 1 Nature Tracks (TK-07 .. TK-10)

**Files:**
- Modify: `scripts/process_all_real_recordings.py`
- Create / Output:
  - `assets/audio/vinyl_alpine_brook.wav` (TK-07)
  - `assets/audio/vinyl_ocean_waves.wav` (TK-08)
  - `assets/audio/vinyl_morning_meadow.wav` (TK-09)
  - `assets/audio/vinyl_timber_chamber.wav` (TK-10)

**Interfaces:**
- Consumes: Cached raw master recordings in `~/.cache/zykl_audio_sources/`:
  - `vinyl_alpine_brook.raw`
  - `vinyl_ocean_waves.raw`
  - `vinyl_morning_meadow.raw`
  - `vinyl_timber_chamber.raw`
- Produces: 4 seamless 40s linear PCM WAV files in `assets/audio/`.

- [ ] **Step 1: Write processing script update**
  Update `scripts/process_all_real_recordings.py` to use `crossfade_loop` without zeroing breathing envelope so loop seam is continuous.

- [ ] **Step 2: Execute script to process Drawer 1 PRO tracks**
  Run: `python3 scripts/process_all_real_recordings.py`
  Verify output files are 1,764,044 bytes (40.0s @ 22050Hz 16-bit mono).

- [ ] **Step 3: Verify audio playback & loop continuity**
  Run python verification script to check peak, RMS, and boundary continuity.

- [ ] **Step 4: Commit Drawer 1 audio assets**
  ```bash
  git add assets/audio/vinyl_alpine_brook.wav assets/audio/vinyl_ocean_waves.wav assets/audio/vinyl_morning_meadow.wav assets/audio/vinyl_timber_chamber.wav scripts/process_all_real_recordings.py
  git commit -m "feat(audio): process and deploy 4 authentic nature tracks for Drawer 1 PRO (Alpine Brook, Ocean Waves, Morning Meadow, Timber Chamber)"
  ```

---

### Task 2: Sourcing & Processing 4 Additional Drawer 2 Instrumental Tracks (TK-17 .. TK-20)

**Files:**
- Modify: `scripts/process_real_instrumental_recordings.py`
- Create / Output:
  - `assets/audio/vinyl_goldberg_aria.wav` (TK-17: J.S. Bach - Goldberg Variations Aria by Kimiko Ishizaka)
  - `assets/audio/vinyl_chopin_nocturne.wav` (TK-18: Frédéric Chopin - Nocturne Op. 9 No. 2 by Frank Levy)
  - `assets/audio/vinyl_celtic_harp.wav` (TK-19: Classical Celtic Harp Solo)
  - `assets/audio/vinyl_chamber_quartet.wav` (TK-20: Classical Chamber String Quartet Adagio)

**Interfaces:**
- Consumes: Real master acoustic recordings cached in `~/.cache/zykl_audio_sources/`.
- Produces: 4 seamless 40s linear PCM WAV files in `assets/audio/`.

- [ ] **Step 1: Download / Cache missing source recordings**
  Download high-fidelity public domain recordings for Chopin Nocturne Op. 9, Classical Harp, and Chamber String Quartet using `support@zykl.app` User-Agent into `~/.cache/zykl_audio_sources/`.

- [ ] **Step 2: Update `scripts/process_real_instrumental_recordings.py`**
  Add processing logic for TK-17, TK-18, TK-19, and TK-20 with calibrated target peaks (0.72 - 0.78).

- [ ] **Step 3: Run processing script**
  Run: `python3 scripts/process_real_instrumental_recordings.py`
  Verify all 4 files are generated at 1,764,044 bytes.

- [ ] **Step 4: Commit Drawer 2 audio assets**
  ```bash
  git add assets/audio/vinyl_goldberg_aria.wav assets/audio/vinyl_chopin_nocturne.wav assets/audio/vinyl_celtic_harp.wav assets/audio/vinyl_chamber_quartet.wav scripts/process_real_instrumental_recordings.py
  git commit -m "feat(audio): process and deploy 4 authentic acoustic instrumental tracks for Drawer 2 PRO (Goldberg Aria, Chopin Nocturne, Celtic Harp, Chamber Quartet)"
  ```

---

### Task 3: Expand VinylTrack Domain Model to 20 Tracks & Update Tests

**Files:**
- Modify: `lib/features/vinyl/domain/vinyl_track.dart`
- Modify: `android/app/src/main/kotlin/com/zykl/app/MainActivity.kt`
- Modify: `test/core/audio/vinyl_audio_assets_test.dart`

**Interfaces:**
- Consumes: 20 WAV audio files in `assets/audio/`.
- Produces: `VinylTrack.presets` with 20 tracks, `drawer1Presets` (10 tracks), `drawer2Presets` (10 tracks).

- [ ] **Step 1: Update `vinyl_audio_assets_test.dart` to expect 20 presets (10 per drawer)**
  Write test expectations for:
  - 20 presets total.
  - 10 tracks in Drawer 1 (4 Free, 6 PRO).
  - 10 tracks in Drawer 2 (4 Free, 6 PRO).
  - All 20 assets exist on disk with length > 10,000 bytes.

- [ ] **Step 2: Update `lib/features/vinyl/domain/vinyl_track.dart`**
  Add tracks 6..9 to Drawer 1 and tracks 16..19 to Drawer 2 with full metadata, catalog IDs (`TK-01` to `TK-20`), label colors, and descriptions.

- [ ] **Step 3: Update `MainActivity.kt` asset mapping**
  Ensure fallback `when (trackIndex)` in `startAmbient` supports indices 0..19.

- [ ] **Step 4: Run vinyl tests and verify**
  Run: `flutter test test/core/audio/vinyl_audio_assets_test.dart`
  Expected: PASS

- [ ] **Step 5: Commit vinyl track expansion**
  ```bash
  git add lib/features/vinyl/domain/vinyl_track.dart android/app/src/main/kotlin/com/zykl/app/MainActivity.kt test/core/audio/vinyl_audio_assets_test.dart
  git commit -m "feat(vinyl): expand soundscapes to 20 tracks (10 per drawer with 4 Free and 6 PRO each)"
  ```

---

### Task 4: Expand Hardware Editions to 12 Themes (4 Free + 8 PRO)

**Files:**
- Modify: `lib/app/theme/hardware_edition.dart`
- Modify: `lib/features/timer/presentation/chrono_dial_widget.dart`
- Modify: `test/app/theme_controller_test.dart`

**Interfaces:**
- Consumes: `HardwareEditionType` enum.
- Produces: 12 editions in `HardwareEdition.all`, 4 with `isPremium: false` and 8 with `isPremium: true`.

- [ ] **Step 1: Update `hardware_edition.dart`**
  - Add enum values: `industrialMonoSteel`, `obsidianCeramic`, `copperHearthAsh`, `britishRacingGreen`, `indigoAstronomical`.
  - Update `bauhausHeritage`: set `isPremium: false` (Free #3).
  - Implement `industrialMonoSteel` with `isPremium: false` (Free #4).
  - Implement 4 new PRO editions (`obsidianCeramic`, `copperHearthAsh`, `britishRacingGreen`, `indigoAstronomical`) with industrial color tokens, plate gradients, needles, and rivets.
  - Update `HardwareEdition.all` and `fromType`.

- [ ] **Step 2: Update `chrono_dial_widget.dart`**
  Add switch cases for the 5 new edition types to return calibrated `lightDialColor`.

- [ ] **Step 3: Update and expand theme tests**
  Add test asserting `HardwareEdition.all.length == 12`, exactly 4 Free editions, and exactly 8 PRO editions.

- [ ] **Step 4: Run theme tests**
  Run: `flutter test test/app/theme_controller_test.dart`
  Expected: PASS

- [ ] **Step 5: Commit hardware editions expansion**
  ```bash
  git add lib/app/theme/hardware_edition.dart lib/features/timer/presentation/chrono_dial_widget.dart test/app/theme_controller_test.dart
  git commit -m "feat(theme): expand hardware editions gallery to 12 themes (4 Free and 8 PRO)"
  ```

---

### Task 5: End-to-End Verification & Distribution Builds

**Files:**
- Test: Full Flutter test suite (`flutter test`)
- Verify: `flutter analyze`
- Output:
  - `build_outputs/zykl-developer-pro.apk`
  - `build_outputs/zykl-user-testing.apk`
  - `build_outputs/zykl-playstore-release.aab`

- [ ] **Step 1: Run static analysis**
  Run: `flutter analyze`
  Expected: No issues found!

- [ ] **Step 2: Run full test suite**
  Run: `flutter test`
  Expected: All 410+ tests pass.

- [ ] **Step 3: Build Developer Pro APK**
  Run: `flutter build apk --release --dart-define=ENABLE_PRO_SIMULATION=true --split-per-abi`
  Copy arm64 output to `build_outputs/zykl-developer-pro.apk`.

- [ ] **Step 4: Build User Testing APK**
  Run: `flutter build apk --release --split-per-abi`
  Copy arm64 output to `build_outputs/zykl-user-testing.apk`.

- [ ] **Step 5: Build Google Play Release App Bundle**
  Run: `flutter build appbundle --release`
  Copy output to `build_outputs/zykl-playstore-release.aab`.

- [ ] **Step 6: Final status check and report**
  Check file sizes and verify all outputs.
