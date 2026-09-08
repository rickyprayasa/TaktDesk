# Design Specification: Takt Desk (The Spatial Pocket Desk)

- **Date**: 2026-09-08
- **Project**: Takt Desk
- **Platform**: Flutter (Android Target SDK 34+, Min SDK 24, Engine Impeller)
- **Status**: Validated & Approved

---

## 1. Overview & Vision

**Takt Desk** is a spatial focus and productivity Android application built with Flutter. It replaces conventional flat digital todo lists and digital timers with a tactile, analog-inspired desk workspace.

### Design Philosophy: *Industrial Minimalist Tactility* (Dieter Rams / Braun Heritage)
- **Zero AI Slop**: Strict avoidance of generic AI aesthetics—no purple-violet neon glows, no excessive gradients, no oversized arbitrary card rounding (`rounded-3xl` everywhere), and no visual clutter.
- **Physical Realism & Functionality**: High-contrast, matte textures, chamfered mechanical edges, precision tick marks, realistic paper perforation, and micro-fiber tear physics.
- **Synchronized Foley Sensory Feedback**: Every physical UI manipulation (turning a dial, pressing a mechanical spring button, tearing receipt paper, dropping a record player stylus) triggers synchronized low-latency sound (<25ms via `flutter_soloud`) and hardware haptics (`HapticFeedback`).

---

## 2. Color Palette & Typography Tokens

### 2.1 Color Tokens
| Token Name | Hex Code | Semantic Purpose |
|------------|----------|------------------|
| `chassisObsidian` | `#141517` | Canvas desk background (OLED battery efficiency) |
| `basaltSlate` | `#24272C` | Instrument hardware housing, bezel frames, dial bodies |
| `warmBone` | `#EFECE6` | Physical receipt thermal paper substrate |
| `thermalCarbon` | `#1F2226` | High-contrast thermal imprint ink on receipt paper |
| `mutedOchre` | `#C85A32` | Primary active accent (indicator needles, active switches) |
| `filamentAmber` | `#D99B59` | Warm illumination ring, night ambient lamp |
| `patinaOlive` | `#4D5D4B` | Stamped status verification (`[DONE]`), completion marker |

### 2.2 Typography Hierarchy
- **Primary UI & Controls**: *Space Grotesk* (or system geometric fallback), weights 500 & 600. Clean, architectural, legible.
- **Data, Counters & Receipts**: *JetBrains Mono*, weights 400 & 700. Monospaced clarity for timestamps, countdown timers, and receipt printing.

---

## 3. Architecture & Rendering Engine

### 3.1 Dual-Engine Rendering Model
To enable immediate testability, tactile authenticity, and zero external blocking, visual presentation follows a **Dual-Engine Adapter Pattern**:
1. **Procedural Analog Canvas Engine (Default / Active)**:
   - High-performance `CustomPainter` implementations drawing directly on the Flutter Canvas.
   - 60/120 FPS fluid motions powered by Flutter `Ticker` (continuous sweep second/minute hand, serrated tear polygon morphing, turntable vinyl reflection arcs).
2. **Rive State Machine Adapter (Ready for `.riv` drop-in)**:
   - Identical interface mapping to Rive State Machines:
     - `SM_ChronoDial`: `targetMinutes` (Number), `progressPercent` (Number), `isRunning` (Boolean), `pressTrigger` (Trigger), event `onMinuteTick`.
     - `SM_ReceiptRunner`: `feedPaper` (Trigger), `tearProgress` (Number), `stampTrigger` (Trigger), `ejectPaper` (Trigger).
     - `SM_VinylDeck`: `needleOnRecord` (Boolean), `turntableSpeed` (Number), `vinylStyleIndex` (Number).

```
   ┌────────────────────────────────────────────────────────┐
   │                  Riverpod Controller                   │
   │   (ChronoDialController / ReceiptController / etc.)    │
   └───────────────────────────┬────────────────────────────┘
                               │ Controller State / Events
                               ▼
               ┌───────────────────────────────┐
               │    Unified Instrument Widget   │
               └───────┬───────────────┬───────┘
                       │               │
        Has .riv file? │               │ Fallback / Procedural
                       ▼               ▼
           ┌──────────────────────┐  ┌──────────────────────┐
           │  Rive State Machine  │  │   Procedural Canvas  │
           │       Adapter        │  │     CustomPainter    │
           └──────────────────────┘  └──────────────────────┘
```

---

## 4. Feature Modules Specification

### 4.1 Modul A: The Chrono Dial (Pomodoro Timer)
- **Interaction**:
  - Dragging or rotating the outer knurled knob sets target duration (1 to 90 minutes).
  - Continuous sweep motion with sub-second accuracy using `Ticker`.
  - Mechanical side push-button to start/pause session.
  - Amber halo indicator (`#D99B59`) emits soft glow around dial during active sessions.
  - Haptic feedback (`selectionClick`) triggered upon passing each 1-minute increment.

### 4.2 Modul B: The Thermal Task Runner (Receipt Printer)
- **Interaction**:
  - Capacity: Strict limit of maximum 5 active tasks per batch to maintain deep focus.
  - Paper Feed: Creating a task triggers paper feed animation accompanied by micro-vibration and stepper-motor audio.
  - Double Tap: Imprints a wet-ink stamp `[DONE]` with Patina Olive ink (`#4D5D4B`).
  - Swipe-to-Tear: Horizontal swipe gesture drags paper tear angle. Crossing 75% threshold rips the paper off, emitting paper fiber micro-particles and tearing sound, flying the completed receipt out of view.

### 4.3 Modul C: The Analog Vinyl Deck (Ambient Sound Generator)
- **Interaction**:
  - 4 Offline Audio Presets: *Lo-fi Rain*, *Deep Brown Noise*, *Library Atmosphere*, *Cafe Echo*.
  - Interactive Tonearm: Dragging the tonearm onto the spinning vinyl record triggers rotational momentum (`turntableSpeed` ramp to 1.0) and fades in audio loop.
  - Lifting the tonearm triggers needle scratch stop audio and decelerates vinyl rotation.

### 4.4 Modul D: Spatial Lighting & Parallax Canvas
- **Sensor Parallax**:
  - Gyroscope (`sensors_plus`) stream passed through a low-pass smoothing filter ($y_t = \alpha \cdot x_t + (1 - \alpha) \cdot y_{t-1}$).
  - Drives a 3D isometric tilt (1° to 3°) using Flutter `Matrix4.identity()`, creating subtle depth without disorientation.
- **Ambient Lighting Engine**:
  - Dynamically evaluates local device time:
    - **Morning (06:00 - 11:00)**: Cool diffused daylight from top-left.
    - **Afternoon (11:00 - 17:30)**: Warm directional sunlight with elongated shadows.
    - **Night (17:30 - 06:00)**: Soft warm incandescent desk lamp cone focused on the active workspace.

---

## 5. Data Architecture (Drift SQLite)

### 5.1 Tables
- **`Tasks`**:
  - `id`: Int (auto-increment primary key)
  - `title`: Text (task description)
  - `isCompleted`: Bool (default false)
  - `createdAt`: DateTime
  - `completedAt`: DateTime (nullable)
  - `sortOrder`: Int (display position 1..5)
  - `isArchived`: Bool (default false, set when torn off)
- **`TimerSessions`**:
  - `id`: Int (auto-increment primary key)
  - `targetMinutes`: Int
  - `elapsedSeconds`: Int
  - `isFinished`: Bool
  - `startedAt`: DateTime
  - `finishedAt`: DateTime (nullable)
- **`DeskPreferences`**:
  - `id`: Int (single row)
  - `soundVolume`: Real (0.0 - 1.0)
  - `parallaxEnabled`: Bool (default true)
  - `activeAmbientTrackIndex`: Int (0 - 3)

---

## 6. Directory Structure

```
lib/
├── app/
│   ├── app.dart
│   └── theme/
│       ├── takt_colors.dart
│       ├── takt_typography.dart
│       └── takt_decorations.dart
├── core/
│   ├── audio/
│   │   ├── audio_service.dart
│   │   └── audio_constants.dart
│   ├── haptics/
│   │   └── haptic_service.dart
│   ├── database/
│   │   ├── app_database.dart
│   │   └── tables/
│   │       ├── tasks_table.dart
│   │       ├── timer_sessions_table.dart
│   │       └── desk_preferences_table.dart
│   └── sensors/
│       └── parallax_controller.dart
└── features/
    ├── desk/
    │   ├── presentation/
    │   │   ├── desk_canvas_screen.dart
    │   │   ├── isometric_desk_layout.dart
    │   │   └── ambient_lighting_layer.dart
    │   └── domain/
    ├── timer/
    │   ├── presentation/
    │   │   ├── chrono_dial_widget.dart
    │   │   ├── chrono_dial_painter.dart
    │   │   ├── chrono_dial_rive.dart
    │   │   └── chrono_dial_controller.dart
    │   ├── domain/models/
    │   └── data/
    ├── tasks/
    │   ├── presentation/
    │   │   ├── receipt_runner_widget.dart
    │   │   ├── receipt_runner_painter.dart
    │   │   ├── receipt_runner_rive.dart
    │   │   ├── receipt_runner_controller.dart
    │   │   └── task_input_sheet.dart
    │   ├── domain/models/
    │   └── data/
    └── vinyl/
        ├── presentation/
        │   ├── vinyl_player_widget.dart
        │   ├── vinyl_deck_painter.dart
        │   ├── vinyl_deck_rive.dart
        │   └── vinyl_controller.dart
        ├── domain/models/
        └── data/
```

---

## 7. Quality Gates & Non-Functional Verification

- **Frame Rate**: Minimum 60 FPS on Snapdragon 6 series / Helio G99; 120 FPS on high-refresh displays.
- **Audio Latency**: Sub-25ms trigger response via `flutter_soloud`.
- **Power Efficiency**: Ambient Ticker pauses when inactive or backgrounded; AMOLED dark background (`#141517`) ensures <4% battery drain per hour.
- **Zero AI Slop**: Verified against design tokens in Section 2.
