# Takt Desk: Industrial Spec Plate, Daily Tally & Service Hatch Settings Specification

**Date:** 2026-09-09  
**Platform Target:** Mobile Android  
**Status:** Approved for Implementation Planning  
**Design Philosophy:** Dieter Rams & Braun Industrial Aesthetic (*Weniger, aber besser*)

---

## 1. Overview & Goals

Takt Desk currently delivers three focused analog instruments (Chrono Dial, Thermal Task Runner, and Vinyl Deck) paired with Monastic Focus Lockdown. However, on tall mobile screens (18:9 to 20:9), the lower section of the desk canvas presents excessive blank space that disconnects the instruments from the physical desk metaphor. Furthermore, essential mobile settings, audio/haptic calibration, focus telemetry, and legal/philosophical disclosures (such as Dieter Rams' creed and open-source licenses) currently lack a dedicated interface.

This specification addresses both requirements through two complementary systems:
1. **The Industrial Spec Plate & Daily Focus Tally (`DeskSpecPlateWidget`):** A debossed brushed aluminum manufacturer plate anchoring the base of the desk canvas. It incorporates 4 micro-LED quadrant indicators and an analog session tally counter reactively linked to local Drift SQLite records.
2. **The Industrial Service Hatch (`TaktSettingsSheet`):** An unobtrusive screw-head / cogwheel trigger in the header that summons a slide-up industrial service panel. It provides master audio volume calibration, foley and haptic toggles, Android DND status verification, focus session telemetry, and the Dieter Rams design philosophy along with legal open-source license attribution.

---

## 2. Architectural Structure

```
+-------------------------------------------------------------------------+
|                           DeskCanvasScreen                              |
+-------------------------------------------------------------------------+
| Header Row:                                                             |
| [• TAKT DESK]                                  [⚙ SETTINGS] [LIGHT/DARK]|
+-------------------------------------------------------------------------+
| Navigation Row:                                                         |
|                  [  DIAL  ]   [  TASKS  ]   [  VINYL  ]                 |
+-------------------------------------------------------------------------+
| Active Instrument Console:                                              |
| - ChronoDialWidget / ReceiptRunnerWidget / VinylPlayerWidget            |
| - Monastic Lockdown Pill Switch (when on Dial)                          |
| - Emergency Unlatch Latch (when lockdown active)                        |
+-------------------------------------------------------------------------+
| Base Anchor:                                                            |
| +---------------------------------------------------------------------+ |
| |  [•] TAKT DESK · MOD. 01                (•) (•) (○) (○)  3/4 SESS   | |
| |  APPARATUS · 44.1kHz                    TODAY: 75 MIN FOCUSED       | |
| +---------------------------------------------------------------------+ |
+-------------------------------------------------------------------------+
                                     |
                                     v (Tapping ⚙ Settings Trigger)
+-------------------------------------------------------------------------+
|                  TaktSettingsSheet (Service Hatch Modal)                |
|  [ ====== TEXTURED GRIP HANDLE ====== ]                                 |
|                                                                         |
|  1. HARDWARE ACOUSTICS & TACTILITY                                      |
|     - Master Sound Volume Slider [━━━━━●━━━━] 80%                       |
|     - Mechanical Foley Clicks Toggle          [ ON / OFF ]              |
|     - Tactile Haptics Feedback Toggle         [ ON / OFF ]              |
|                                                                         |
|  2. SYSTEM CLEARANCE & LOCKDOWN                                         |
|     - Android Do Not Disturb (DND) Policy     [ ACTIVE / VERIFIED ]     |
|     - Emergency Abort Protocol                "Hold latch 5s to unlatch"|
|                                                                         |
|  3. TELEMETRY & DATA MANAGEMENT                                         |
|     - Lifetime Completed Sessions             42 SESSIONS               |
|     - Total Focused Hours                     17.5 HOURS                |
|     - [ PURGE SESSION LOGS ] (tactile red alert)                        |
|                                                                         |
|  4. THE BRAUN CREED & LEGAL DISCLOSURES                                 |
|     - Homage: "Weniger, aber besser" (10 Principles of Good Design)     |
|     - Version: Takt Desk v1.0.0 · Build 2026                            |
|     - Privacy: 100% Offline · Zero Telemetry · Local SQLite Storage     |
|     - [ OPEN SOURCE LICENSES ] (Native Flutter LicensePage)             |
+-------------------------------------------------------------------------+
```

---

## 3. Detailed Component Specifications

### 3.1 Base Spec Plate & Daily Focus Tally (`DeskSpecPlateWidget`)
- **Location:** Placed directly at the bottom of the scrollable column in `DeskCanvasScreen`.
- **Dimensions & Styling:**
  - Full width up to max container width (440px), height ~68px.
  - Border: 1.0px solid `TaktColors.slateBorder` (Dark mode) or `#C4C8D0` (Light mode).
  - Background: `TaktColors.basaltSlate` with subtle linear gradient simulating brushed metal anodization.
  - Corner accents: 4 simulated mechanical rivet / screw indentations at corners.
- **Left Column: Manufacturer Stamp:**
  - Line 1: `TAKT DESK · MOD. 01 · 2026` (Space Mono, 9.5sp, bold, tracking 1.2).
  - Line 2: `GERMANIC MINIMALISM · STEREO 44.1kHz` (Space Mono, 8sp, muted bone / charcoal).
- **Right Column: Daily Focus Tally & Quadrant LEDs:**
  - Micro-LED Row: 4 circular dot indicators (diameter 6px, spacing 5px):
    - Amber filament glow (`#D99B59`) with subtle radial shadow when completed in the current 4-cycle loop (`sessionIndex % 4`).
    - Dark slate outline (`#141517`) when incomplete.
  - Tally Text:
    - Line 1: `TODAY: X / 4 CYCLES` (bold monospaced).
    - Line 2: `Y MIN FOCUSED` (Space Mono, 8sp).
- **Interactivity:**
  - Tapping the plate triggers `HapticService.lightClick()`, playing `SoundEffect.dialClick` and briefly showing an inline summary snackbar or status indicator.

### 3.2 Header Settings Trigger Button (`SettingsRivetButton`)
- **Location:** In the top header row of `DeskCanvasScreen`, adjacent to `ChassisThemeSwitch`.
- **Appearance:** A compact tactile circular button (32x32px) styled as a slotted machine screw head or knurled adjustment nut.
- **Iconography:** Subtle minimalist cogwheel/slider symbol (`Icons.tune` or `Icons.settings_outlined`), colored `TaktColors.warmBone` (Dark) or `#2C3038` (Light).
- **Behavior:** On tap, triggers `HapticService.mechanicalPress()` and opens `TaktSettingsSheet` via `showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, ...)`.

### 3.3 The Industrial Service Hatch Sheet (`TaktSettingsSheet`)
- **Visual Design:**
  - Background: `TaktColors.chassisObsidian` (#141517) in dark mode, or `#E3E0D8` in light mode.
  - Top: Knurled horizontal grip bar (width 40px, height 4px, rounded 2px).
  - Header: `SERVICE HATCH // CALIBRATION & TELEMETRY` (Space Mono, 11sp, bold uppercase).
- **Section 1: Hardware Acoustics & Tactility:**
  - Master Volume Slider: Custom minimalist slider styled with `TaktColors.filamentAmber` active track, continuous 0.0 to 1.0 range, invoking `audioService.setVolume(val)` and updating `DeskPreferences`.
  - Foley Clicks Toggle: Switch controlling whether mechanical click/tear audio sounds play. Updates `AudioService.foleyEnabled` and `DeskPreferences.foleyEnabled`.
  - Mechanical Haptics Toggle: Switch controlling whether device vibrations fire. Updates `HapticService.enabled` and `DeskPreferences.hapticsEnabled`.
- **Section 2: System Clearance & Lockdown:**
  - Displays current Android DND and keep-awake status (`CLEARANCE: VERIFIED`).
  - Text summary of Emergency Unlatch mechanism: *"In monastic lockdown, press and hold the bottom unlatch lever for 5 continuous seconds to release the system."*
- **Section 3: Telemetry & Data Management:**
  - Lifetime Stats: Displays total focus sessions completed and total hours accumulated across all time from `TimerSessions` table.
  - Data Purge Button: Tactile button styled with `TaktColors.mutedOchre` (#C85A32) outline: `[ PURGE SESSION LOGS ]`.
    - Shows confirmation dialog before executing `appDatabase.clearTimerSessions()`.
- **Section 4: The Braun Creed & Legal:**
  - Quote: *"Weniger, aber besser — Less, but better."* — Dieter Rams
  - App Metadata: `Takt Desk v1.0.0 (Build 2026.09) · Pure Handheld Mobile Edition`.
  - Privacy Declaration: *"100% Offline. Zero analytics. Zero network requests. All task receipts and focus sessions remain exclusively on this device."*
  - License Button: `[ OPEN SOURCE LICENSES ]` calling Flutter's built-in `showLicensePage(...)` with themed dark/light styling.

---

## 4. Data Layer & Persistence Architecture

### 4.1 Drift Database Extensions (`AppDatabase`)
- **Table: `DeskPreferences`:**
  - Add columns:
    - `foleyEnabled`: `BoolColumn get foleyEnabled => boolean().withDefault(const Constant(true))();`
    - `hapticsEnabled`: `BoolColumn get hapticsEnabled => boolean().withDefault(const Constant(true))();`
- **Queries:**
  - `Stream<List<TimerSession>> watchTodayTimerSessions()`:
    Filter sessions where `startedAt` is between `DateTime(now.year, now.month, now.day)` and `startOfDay.add(const Duration(days: 1))`, ordered by `startedAt asc`.
  - `Stream<List<TimerSession>> watchAllTimerSessions()`:
    Watch all recorded sessions for lifetime telemetry calculations.
  - `Future<void> clearTimerSessions()`:
    Purge all records in `timerSessions`.
  - `Future<void> updatePreferences(...)`:
    Persist `soundVolume`, `foleyEnabled`, `hapticsEnabled`, `parallaxEnabled`.

### 4.2 State Providers (Riverpod)
- `deskPreferencesControllerProvider`:
  - Exposes state: `DeskPreferencesState(volume, foleyEnabled, hapticsEnabled, parallaxEnabled)`.
  - On change: updates Drift database, synchronizes `AudioService` and `HapticService`.
- `todayFocusStatsProvider`:
  - Watches `watchTodayTimerSessions()`.
  - Calculates:
    - `completedCount`: count where `isFinished == true`.
    - `totalMinutes`: sum of `elapsedSeconds / 60` or `targetMinutes`.
    - `quadrantProgress`: `completedCount % 4` (0 to 4).
- `lifetimeFocusStatsProvider`:
  - Watches `watchAllTimerSessions()`.
  - Calculates total completed sessions and total accumulated hours.

---

## 5. Testing & Quality Gates

1. **Unit Tests:**
   - Test database queries: `watchTodayTimerSessions` correctly isolates today's date from previous dates; `clearTimerSessions` purges data; `updatePreferences` updates `foleyEnabled` and `hapticsEnabled`.
   - Test `deskPreferencesController`: verifies state transitions and service coordination.
2. **Widget Tests:**
   - Test `DeskSpecPlateWidget`: verifies debossed plate renders today's tally and 4 LED indicators accurately given mock/drift state.
   - Test `TaktSettingsSheet`: verifies volume slider, foley switch, haptic switch, and license button interactions.
   - Test `DeskCanvasScreen`: verifies settings rivet button tap displays `TaktSettingsSheet`.
3. **Analyzer & Formatter:**
   - Must achieve 0 issues with `flutter analyze`.
   - Must maintain 100% test pass rate across the full test suite.
