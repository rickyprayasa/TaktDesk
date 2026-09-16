# Status Bar & Lock Screen Media Notification Controller, 12 Focus Soundscapes & Multi-Drawer Systems

**Date:** 2026-09-16  
**Status:** Validated & Approved  
**Author:** Pair Programming (Antigravity & User)  
**Target:** ZYKL Studio Console (Android & Flutter)

---

## 1. Overview & Objectives

This specification defines the complete architectural and visual design for the **Status Bar & Lock Screen Media Notification Controller**, alongside an audio soundscape overhaul (12 focus-calibrated tracks) and industrial multi-drawer physical interfaces for both the **Vinyl Player** and the **Task Dispenser Archive**.

### Key Objectives
1. **OS Media Integration**: Native Android `MediaSessionCompat` and `NotificationCompat.MediaStyle` providing an OS-level Media Controller on the Status Bar shade, Quick Settings carousel, and Lock Screen with Braun TP-1 vinyl disc artwork, track metadata, and real-time Pomodoro countdown telemetry.
2. **Instant Dual-Way Control**: Direct, low-latency control (`[PREV]`, `[PLAY / PAUSE]`, `[NEXT]`) from lockscreen and Bluetooth headsets, immediately synchronizing with Flutter Riverpod state.
3. **Audio Soundscape Overhaul (12 Calibrated Focus Tracks)**: Replace distracting/noisy soundscapes (*Cafe Echo, Forest Canopy, Cosmic Drift, Midnight Train*) with calm, frequency-sculpted ambient soundscapes, expanding the catalog from 8 to 12 tracks.
4. **Dual Record Drawer System**: Organize the 12 vinyl discs into two physical stacked modular drawers (6 discs each) under the TP-1 player, preventing excessive horizontal scrolling.
5. **Dynamic Modular Task Dispenser Archive**: Split archived tasks into industrial brass filing drawers (10 tasks per drawer capacity), dynamically generating Drawer 01, Drawer 02, Drawer 03, etc., as completed tasks accumulate.
6. **Codebase Hygiene**: Maintain 0 occurrences of `tuneeca`, 100% test pass rate, 0 analyzer diagnostics, and release artifact generation exclusively at `/home/tuneeca/RSQUARE/ZYKL_Release.apk`.

---

## 2. Architecture & Subsystems

```
┌────────────────────────────────────────────────────────────────────────┐
│                        FLUTTER PRESENTATION LAYER                      │
│                                                                        │
│  ┌───────────────────────┐  ┌───────────────────────┐  ┌─────────────┐ │
│  │ VinylDiscDrawerWidget │  │  ChronoDialController │  │   Archive   │ │
│  │ (Drawer 01 & 02: 6+6) │  │  (Focus/Break Phase)  │  │ Drawer (10+)│ │
│  └───────────┬───────────┘  └───────────┬───────────┘  └──────┬──────┘ │
│              │                          │                     │        │
│              ▼                          ▼                     ▼        │
│   ┌───────────────────────────────────────────────────────────────┐    │
│   │             Flutter MediaNotificationService / Provider       │    │
│   └─────────────────────────────┬─────────────────────────────────┘    │
└─────────────────────────────────┼──────────────────────────────────────┘
                                  │ MethodChannel('com.zykl.app/media_notification')
┌─────────────────────────────────▼──────────────────────────────────────┐
│                         ANDROID NATIVE LAYER                           │
│                                                                        │
│   ┌───────────────────────────────────────────────────────────────┐    │
│   │               MediaNotificationService (Foreground)           │    │
│   │  - foregroundServiceType="mediaPlayback|specialUse"           │    │
│   │  - MediaSessionCompat & PlaybackStateCompat                   │    │
│   │  - NotificationCompat.MediaStyle (Action buttons 0, 1, 2)     │    │
│   │  - Audio Focus & Bluetooth MediaReceiver Handling             │    │
│   │  - Looping Ambient MediaPlayer Engine                         │    │
│   └─────────────────────────────┬─────────────────────────────────┘    │
│                                 │                                      │
│                                 ▼                                      │
│   ┌───────────────────────────────────────────────────────────────┐    │
│   │           Android OS System Shade & Lock Screen Player        │    │
│   │  - Braun TP-1 Vinyl Disc LargeIcon / Album Art                │    │
│   │  - Title: Track Name (e.g. "LO-FI RAIN · 33⅓ RPM")            │    │
│   │  - Subtitle: "ZYKL BRAUN TP-1 // FOCUS 24:18 · CYCLE 1/4"     │    │
│   │  - Actions: [⏮ PREV]  [▶ / ⏸ PLAY/PAUSE]  [⏭ NEXT]             │    │
│   └───────────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Detailed Specifications

### 3.1 Native Android Media Controller (`MediaNotificationService.kt`)

#### Service Lifecycle & Registration
- **Class**: `com.zykl.app.MediaNotificationService : Service()`
- **Manifest Declaration**:
  ```xml
  <service
      android:name=".MediaNotificationService"
      android:exported="false"
      android:foregroundServiceType="mediaPlayback|specialUse" />
  ```
- **Notification Channel**:
  - `ID`: `zykl_media_playback_channel`
  - `Name`: `ZYKL Media & Focus Controller`
  - `Importance`: `NotificationManager.IMPORTANCE_LOW` (no intrusion chime)
  - `LockscreenVisibility`: `NotificationCompat.VISIBILITY_PUBLIC`

#### MediaSessionCompat Configuration
- `tag`: `"ZYKL_TP1_SESSION"`
- `flags`: `FLAG_HANDLES_MEDIA_BUTTONS or FLAG_HANDLES_TRANSPORT_CONTROLS`
- `PlaybackStateCompat.Builder`:
  - Actions supported:
    - `ACTION_PLAY`
    - `ACTION_PAUSE`
    - `ACTION_PLAY_PAUSE`
    - `ACTION_SKIP_TO_NEXT`
    - `ACTION_SKIP_TO_PREVIOUS`
    - `ACTION_STOP`
  - State: `STATE_PLAYING` (when vinyl audio is active) or `STATE_PAUSED` (when vinyl is paused while timer runs).

#### Notification MediaStyle Presentation
- Style: `androidx.media.app.NotificationCompat.MediaStyle`
  - `setMediaSession(mediaSession.sessionToken)`
  - `setShowActionsInCompactView(0, 1, 2)` (All 3 actions visible on collapsed status bar and lockscreen)
- Actions added:
  1. `R.drawable.ic_media_prev` -> Action Title: `"Previous"`, PendingIntent for `ACTION_PREV`
  2. `R.drawable.ic_media_play` / `R.drawable.ic_media_pause` -> Action Title: `"Play"` / `"Pause"`, PendingIntent for `ACTION_PLAY_PAUSE`
  3. `R.drawable.ic_media_next` -> Action Title: `"Next"`, PendingIntent for `ACTION_NEXT`
- Notification Metadata:
  - `setContentTitle`: Track Name formatted e.g. `LO-FI RAIN · 33⅓ RPM`
  - `setContentText`: Pomodoro telemetry e.g. `ZYKL BRAUN TP-1 // FOCUS 24:18 · CYCLE 1/4`
  - `setSubText`: `ZYKL MONASTIC VINYL`
  - `setLargeIcon`: Procedural or pre-rendered circular vinyl disc bitmap (`TP-1 disc`)
  - `setColor`: `0xFFFF9E00` (Braun signature filament amber)
  - `setOngoing`: `true` when playing or while timer session is active.
  - `setContentIntent`: Launch `MainActivity` with `FLAG_ACTIVITY_SINGLE_TOP`.

#### Audio Focus & Interruption Handling
- Requests `AUDIOFOCUS_GAIN` on `AudioManager`.
- In `OnAudioFocusChangeListener`:
  - `AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK`: Lower volume to 30%.
  - `AUDIOFOCUS_LOSS_TRANSIENT`: Pause ambient playback; resume when focus regained.
  - `AUDIOFOCUS_LOSS`: Pause ambient playback and update notification to paused.

---

### 3.2 Flutter Platform Channel (`com.zykl.app/media_notification`)

#### MethodChannel Calls (Flutter -> Native)
1. `startMediaNotification`:
   - Arguments:
     ```dart
     {
       'trackIndex': int,
       'trackName': String,
       'isPlaying': bool,
       'volume': double,
       'phase': String, // 'focus', 'shortBreak', 'longBreak'
       'remainingSeconds': int,
       'cycleCount': int,
     }
     ```
2. `updatePlaybackState`:
   - Arguments: `{'isPlaying': bool, 'trackIndex': int, 'trackName': String}`
3. `updateTimerTelemetry`:
   - Arguments: `{'phase': String, 'remainingSeconds': int, 'cycleCount': int}`
4. `stopMediaNotification`:
   - Arguments: none (Dismisses service and notification when timer & audio both stop).

#### MethodChannel Callbacks (Native -> Flutter)
- Native calls `channel.invokeMethod('onMediaControlAction', {'action': action})` where `action` is `'play'`, `'pause'`, `'next'`, or `'previous'`.
- Flutter `MediaNotificationService` dispatches:
  - `'play'` / `'pause'`: Toggles `vinylProvider.notifier.togglePlayback()`.
  - `'next'`: Cycles to `(currentIndex + 1) % 12` via `selectTrack()`.
  - `'previous'`: Cycles to `(currentIndex - 1 + 12) % 12` via `selectTrack()`.

---

### 3.3 Curated 12 Focus Audio Soundscapes

The 4 noisy/distracting tracks (*Cafe Echo, Forest Canopy, Cosmic Drift, Midnight Train*) are replaced and 4 additional tracks are added. All tracks are generated as seamless looping 22050 Hz 16-bit mono PCM WAV files with smooth crossfade loops and calibrated frequency spectra (avoiding harsh mids and sudden transient spikes):

#### Drawer 01: Nature & Solitude (TK-01 to TK-06)
1. **TK-01: Lo-fi Rain** (`assets/audio/vinyl_lofi_rain.wav`): Gentle rainfall, warm acoustic Rhodes piano chords, vinyl surface dust crackle.
2. **TK-02: Deep Brown Noise** (`assets/audio/vinyl_brown_noise.wav`): 1/f² low-frequency acoustic warmth, blocks background chatter.
3. **TK-03: Library Solitude** (`assets/audio/vinyl_library.wav`): Hallroom acoustic tone, soft page turns, peaceful isolation.
4. **TK-04: Kyoto Bamboo Stream** (`assets/audio/vinyl_kyoto_bamboo.wav`): Gentle trickling stream, soft hollow bamboo resonance, moss stone ripples.
5. **TK-05: Campfire Embers** (`assets/audio/vinyl_campfire.wav`): Low hearth glow, gentle pine embers without loud pops.
6. **TK-06: Nordic Pine Whispers** (`assets/audio/vinyl_nordic_pines.wav`): Ultra-soft mountain pine breeze filtered through high-altitude timber.

#### Drawer 02: Harmonics & Meditation (TK-07 to TK-12)
7. **TK-07: Alpine Mountain Brook** (`assets/audio/vinyl_alpine_brook.wav`): Constant crystalline mountain stream, soothing natural white/pink masking.
8. **TK-08: Warm Tape & Felt Piano** (`assets/audio/vinyl_warm_tape.wav`): Analog tape saturation, very slow muted felt piano progression.
9. **TK-09: Zen Temple Bowl** (`assets/audio/vinyl_zen_bowl.wav`): Singing bowl fundamental resonance with long harmonic decay.
10. **TK-10: Misty Morning Meadow** (`assets/audio/vinyl_morning_meadow.wav`): Distant morning atmospheric calm, subtle dew drop air blanket.
11. **TK-11: Pure Focus White Noise** (`assets/audio/vinyl_pure_white_noise.wav`): Flat, calibrated noise blanket for deep reading and code concentration.
12. **TK-12: Timber Acoustic Chamber** (`assets/audio/vinyl_timber_chamber.wav`): Natural dry wood studio resonance with minimal harmonic reflection.

---

### 3.4 Dual Record Drawer Interface (`VinylDiscDrawerWidget`)

- **Stacked Dual Drawer Housing**:
  - Attached directly below the Braun TP-1 Turntable.
  - Composed of two distinct modular drawers:
    - **Drawer 1**:
      - Handle: `[ RECORD DRAWER 01 // 06 DISCS · NATURE ▾ ]`
      - Discs: TK-01 through TK-06
    - **Drawer 2**:
      - Handle: `[ RECORD DRAWER 02 // 06 DISCS · HARMONICS ▾ ]`
      - Discs: TK-07 through TK-12
- **Mechanical Operation**:
  - Each drawer can be opened or closed independently.
  - When opened, an animated sliding interior bay expands showing 6 discs in a compact `PageView` (viewport fraction: 0.86).
  - Horizontal scrolling is strictly bounded to 6 discs per drawer (fast, legible, zero visual fatigue).
  - Loading a disc from either drawer updates the platter and syncs to the lockscreen media player.

---

### 3.5 Dynamic Multi-Drawer Task Dispenser Archive (`ArchiveDrawerWidget`)

- **Partitioning Rule**:
  - Tasks in `ReceiptRunnerState.archivedTasks` are partitioned into batches of 10:
    - Batch 1: Tasks 1–10 -> **Archive Drawer 01**
    - Batch 2: Tasks 11–20 -> **Archive Drawer 02**
    - Batch N: Tasks (10*(N-1) + 1) to (10*N) -> **Archive Drawer N**
- **Visual Presentation**:
  - If `archivedTasks.isEmpty`: Single closed or empty drawer `[ ARCHIVE // DRAWER 01 · 00 TASKS ▾ ]`.
  - For each batch, a dedicated brushed brass handle bar is rendered:
    `[ ARCHIVE // DRAWER 01 · 10 TASKS ▾ ]`
    `[ ARCHIVE // DRAWER 02 · 04 TASKS ▾ ]`
  - Each drawer operates with independent expand/collapse state.
  - Inside each drawer:
    - List of tasks with struck-through title and ochre completion pip.
    - `[ REPRINT ]` action button per task.
    - `[ PURGE DRAWER ]` button to remove tasks belonging only to that specific drawer.

---

## 4. Verification & Quality Gates

1. **Automated Unit & Widget Tests**:
   - `test/core/services/media_notification_service_test.dart`: Test platform channel invocations and callback dispatching.
   - `test/features/vinyl/vinyl_disc_drawer_widget_test.dart`: Test dual drawer expansion, 6 discs per drawer, track loading.
   - `test/features/tasks/archive_drawer_multi_test.dart`: Test automatic drawer spawning at 11, 21, 31 tasks and batch purge.
   - `test/core/audio/vinyl_audio_assets_test.dart`: Test existence and validity of all 12 WAV files.
2. **Analysis & Compilation**:
   - `flutter analyze` must return 0 issues.
   - Kotlin compilation (`./gradlew compileReleaseKotlin`) must succeed with 0 warnings.
3. **Hygiene**:
   - `git diff | grep -i "tuneeca"` returns 0 occurrences.
4. **Build & Release Deployment**:
   - Production APK built via `flutter build apk --release`.
   - Release APK deployed strictly to `/home/tuneeca/RSQUARE/ZYKL_Release.apk`.
