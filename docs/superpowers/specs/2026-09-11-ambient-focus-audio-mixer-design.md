# Design Spec: Ambient Focus Audio (Retro Turntable 3-Channel Soundscape Mixer)

**Date:** 2026-09-11  
**Feature:** Ambient Focus Audio — Retro Turntable 3-Channel Soundscape Mixer  
**Platform:** Android Mobile Console (Takt Desk, Braun / Dieter Rams Industrial Aesthetic)

---

## 1. Overview & Philosophy

In authentic 1960s–1970s analog hi-fi acoustics (such as Dieter Rams' Braun audio systems and Studer console strips), sound is not a flat monolithic file; it is an acoustic composition of mechanical friction, intentional ambiance, and acoustic presence.

Takt Desk currently supports 8 static ambient vinyl tracks with a single master volume control. 

This feature transforms the **Vinyl Deck Drawer** into a physical **Retro Turntable Soundscape Mixing Console**. Users can tailor their focus environment in real time through three independent analog faders:
1. **`REC` (Primary Record):** The melodic soundscape (Lo-fi Rain, Campfire, Forest Canopy, Cafe Echo, Cosmic Drift, etc.).
2. **`DUST` (Vinyl Surface & Needle Crackle):** Continuous analog needle friction, dust pops, and warm vinyl floor texture.
3. **`FLOW` (Binaural Focus Drone):** Calibrated 10 Hz alpha wave binaural beat with a 432 Hz carrier drone for deep cognitive flow.

---

## 2. Audio Pipeline Architecture

```
+-----------------------------------------------------------------------------------+
| Flutter UI / Riverpod Layer                                                       |
|                                                                                   |
|  [ TurntableMixerStrip ]  ---> [ soundscapeMixerProvider ]                        |
|   - REC  fader (0.0..1.0)       State: primaryVol, crackleVol, flowVol, muteFlags |
|   - DUST fader (0.0..1.0)       Persisted to SQLite via Drift (deskPreferences)   |
|   - FLOW fader (0.0..1.0)                                                         |
+------------------------------------------+----------------------------------------+
                                           | MethodChannel 'com.takt.desk/audio'
                                           v
+-----------------------------------------------------------------------------------+
| Native Android OS Hardware Audio Engine (MainActivity.kt)                         |
|                                                                                   |
|  1. soundscapePlayer (MediaPlayer) : Loops vinyl_<selected_track>.wav             |
|  2. cracklePlayer    (MediaPlayer) : Loops vinyl_surface_crackle.wav              |
|  3. binauralPlayer   (MediaPlayer) : Loops binaural_alpha_432.wav                 |
|                                                                                   |
|  - Real-time gain scaling via MediaPlayer.setVolume(left, right)                 |
|  - Battery-First: 0 CPU wakeups per second during background playback             |
|  - Seamless background & AOD playback persistence                                 |
+-----------------------------------------------------------------------------------+
```

### 2.1 Native Android Engine (`MainActivity.kt`)
- Maintain three parallel `MediaPlayer` instances:
  - `soundscapePlayer`: Loops active track from `VinylTrack.presets`.
  - `cracklePlayer`: Loops `flutter_assets/assets/audio/vinyl_surface_crackle.wav`.
  - `binauralPlayer`: Loops `flutter_assets/assets/audio/binaural_alpha_432.wav`.
- **MethodChannel Methods (`com.takt.desk/audio`):**
  - `startAmbient(trackIndex, masterVolume, primaryVolume, crackleVolume, binauralVolume)`: Initializes and synchronizes playback across all 3 players.
  - `stopAmbient`: Immediately pauses and releases or resets all 3 players.
  - `setMixerLevels(primary, crackle, binaural)`: Adjusts volume dynamically in real time without playback interruption or audio stutter.
  - `setMasterVolume(volume)`: Scales global master gain across all active channels.

### 2.2 Audio Assets (`assets/audio/`)
- `vinyl_surface_crackle.wav`: 16-second seamless looping 22050 Hz 16-bit mono PCM WAV, generated procedurally with Poisson micro-snaps, needle friction hiss, and warm 60 Hz hum attenuation.
- `binaural_alpha_432.wav`: 16-second seamless looping 22050 Hz 16-bit mono/stereo PCM WAV, generating a 432 Hz focus carrier tone with smooth 10 Hz alpha wave modulation.

---

## 3. Data Model & Persistence

### 3.1 Domain Model: `SoundscapeMixerState`
Location: `lib/features/vinyl/domain/soundscape_mixer_state.dart`

```dart
class SoundscapeMixerState {
  final double primaryVolume;     // 0.0 to 1.0 (default 0.80)
  final double crackleVolume;     // 0.0 to 1.0 (default 0.35)
  final double binauralVolume;    // 0.0 to 1.0 (default 0.25)
  final bool isPrimaryMuted;      // default false
  final bool isCrackleMuted;      // default false
  final bool isBinauralMuted;     // default false

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

  SoundscapeMixerState copyWith({...});
}
```

### 3.2 Drift Database Migration
In `lib/core/database/tables/desk_preferences.dart`:
- Add column `RealColumn get crackleVolume => real().withDefault(const Constant(0.35))();`
- Add column `RealColumn get binauralVolume => real().withDefault(const Constant(0.25))();`
- Add column `BoolColumn get crackleMuted => boolean().withDefault(const Constant(false))();`
- Add column `BoolColumn get binauralMuted => boolean().withDefault(const Constant(false))();`

---

## 4. UI Architecture & Dieter Rams Industrial Design

### 4.1 Component: `TurntableMixerStrip`
Location: `lib/features/vinyl/presentation/widgets/turntable_mixer_strip.dart`

Mounted inside `VinylDiscDrawerWidget` alongside the turntable platter.

```
+-------------------------------------------------------------+
|  REC             DUST            FLOW                       |
|                                                             |
|  [ +3 ]          [ +3 ]          [ +3 ]   <- dB markings    |
|    |               |               |                        |
|  [===]           [ | ]           [ | ]    <- Beveled        |
|    |             [===]             |         Aluminum Thumbs|
|  [ 0dB]  <----   [ 0dB]          [===]    <- Unity Gain     |
|    |               |             [ 0dB]      Haptic Detent  |
|  [ -12]          [ -12]          [ -12]                     |
|    |               |               |                        |
|  [ -∞ ]          [ -∞ ]          [ -∞ ]                     |
|                                                             |
|   (●)             (●)             (●)     <- Micro-LED      |
|  [MUTE]          [MUTE]          [MUTE]      Toggles        |
+-------------------------------------------------------------+
```

1. **Slider Physical Anatomy:**
   - Machined vertical track slot with deep shadow groove (`#0D0E10`).
   - Center hairline indicator guide.
   - Anodized aluminum slider thumb (`#DDD9CE` in dark mode, `#FFFFFF` in light mode) with 3 horizontal micro-ribs.
   - Distinctive Amber index line on the active thumb (`#FF9E00`).
2. **Tactile Haptics:**
   - Triggers `HapticService.selectionClick()` when slider thumb crosses `0 dB` (`value ≈ 0.75`).
3. **Mute Control:**
   - Circular micro-LED button beneath each track.
   - Lit amber when channel is active; dimmed slate when muted.

---

## 5. Implementation Task Breakdown

- **Task 1: Procedural Companion WAV Audio Generators & Assets**
  - Create `scripts/generate_mixer_companion_audio.py` producing `vinyl_surface_crackle.wav` and `binaural_alpha_432.wav`.
  - Register assets in `pubspec.yaml` and verify file integrity.
- **Task 2: Native Android Triple-MediaPlayer Engine & MethodChannel Wiring**
  - Update `MainActivity.kt` with `cracklePlayer` and `binauralPlayer`.
  - Handle `setMixerLevels` and updated `startAmbient` with master and channel gains.
  - Compile with `./gradlew compileDebugKotlin` to verify native correctness.
- **Task 3: Domain Model, Drift Database Persistence & Riverpod Controller**
  - Implement `SoundscapeMixerState` and `soundscapeMixerControllerProvider`.
  - Update `DeskPreferences` table and DAO in `AppDatabase`.
  - Wire reactive syncing to `AudioService`.
- **Task 4: Tactile UI Component `TurntableMixerStrip` & Drawer Integration**
  - Implement `TurntableMixerStrip` with Braun vertical faders, dB scale, micro-LED mute buttons, and haptic detents.
  - Mount inside `VinylDiscDrawerWidget`.
  - Write comprehensive widget tests and verify 100% test pass rate across the repository.

---

## 6. Verification & Quality Gates

- Battery-first: 0 CPU wakeups per second during background playback.
- Clean namespace: Absolutely 0 occurrences of `tuneeca` (`com.takt.desk`).
- Static analysis: `flutter analyze` 0 issues.
- Test coverage: 100% test pass rate across unit, widget, and integration test suites.
- Audio reliability: Zero pops, stutters, or leaks during rapid fader movements.
