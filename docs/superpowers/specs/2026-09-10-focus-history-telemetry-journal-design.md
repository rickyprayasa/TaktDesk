# Design Specification: Focus History & Telemetry Journal Slip

- **Author:** Antigravity AI & rickyprayasa
- **Date:** 2026-09-10
- **Status:** Approved / In Planning
- **Platform:** Mobile Android Handheld Console (maxWidth 440px, modular 280px chassis)

---

## 1. Overview & Vision

Takt Desk currently tracks daily completed Pomodoro cycles and cumulative focused minutes inside SQLite (`TimerSessionsTable` in Drift) and displays summarized tallies on the bottom aluminum rating plate (`DeskSpecPlateWidget`). However, users currently have no visible interface to inspect their granular session timeline, examine time-stamps of when focus intervals began and ended, or export their productivity logs.

In alignment with Dieter Rams' core principle *"Weniger, aber besser"* (Less, but better) and the physical skeuomorphism established by the Thermal Task Dispenser and Turntable Disc Drawer, the **Focus History & Telemetry Journal** is implemented as an **in-place physical thermal print roll (Slip Struk Telemetri)**. 

Rather than redirecting the user to an abrupt full-screen modal or sterile analytics dashboard, tapping the bottom spec plate causes a tactile receipt roll to smoothly feed downward from an aperture beneath the plate, displaying an authentic dot-matrix telemetry log of today's focus sessions.

---

## 2. Mechanical & Tactile Interaction

### 2.1 Trigger & Toggle State
- The bottom spec plate (`DeskSpecPlateWidget`) acts as the tactile physical housing for the telemetry printer mechanism.
- Tapping the plate:
  - Toggles the expanded/retracted state of the telemetry roll.
  - Plays the analog mechanical sound effect (`SoundEffect.dialClick`).
  - Triggers a subtle tactile click (`HapticService.selectionClick()`).
  - A subtle mechanical cue on the plate (chevron `▲` when open, `▼` or indicator dot) confirms the active state.

### 2.2 Feed & Retract Physics
- When opened, the paper roll feeds vertically downward from directly under the bottom plate with a smooth physical animation (`SizeTransition` / `CurvedAnimation` with `Curves.easeInOutCubic`, ~420ms).
- When closed (via re-tapping the plate or pressing `[ RETRACT ▲ ]`), the paper roll smoothly retracts into the plate housing.
- Outer width: **280.0 px**, exactly matching the width of `DeskSpecPlateWidget`, `VinylPlayerWidget`, and `ReceiptRunnerWidget`.
- Maximum height: **260.0 px**, with internal smooth vertical scrolling if session entries exceed the viewport.

---

## 3. Visual & Aesthetic Design

### 3.1 Paper Substrate & Perforated Edge
- **Paper Finish:** Warm, low-contrast off-white thermal paper (`#F5F3EB` in light mode, `#22252B` in dark mode) with a 1.0px hairline border (`themeState.borderColor`).
- **Contact Depth:** Contact drop shadow (`BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: Offset(0, 4))`) creating the optical illusion of physical paper resting on the desk surface.
- **Perforated Bottom Edge:** A procedural custom painter (`_PerforatedEdgePainter`) draws an authentic zig-zag / perforated sawtooth tear-line at the bottom edge.

### 3.2 Monospace Dot-Matrix Typography
All contents are rendered using clean monospace typography mimicking vintage German industrial teleprinters:

```text
================================
TAKT DESK // SESSION TELEMETRY
EDITION : BRAUN CLASSIC · 1960
DATE    : 2026-09-10
================================
SUMMARY : 3 CYCLES · 75 MIN
RATE    : 100% FOCUS EFFICIENCY
--------------------------------
LOG ENTRIES:
#01  09:15 - 09:40  [25 MIN]
     STATUS: COMPLETED ●
--------------------------------
#02  10:00 - 10:25  [25 MIN]
     STATUS: COMPLETED ●
--------------------------------
#03  10:35 - 10:50  [15/25 MIN]
     STATUS: INTERRUPTED ○
================================
[ COPY TEXT LOG ]   [ RETRACT ▲ ]
```

- **Status Stamps:**
  - `[ COMPLETED ● ]`: Finished timer session, illuminated with `filamentAmber` dot accent.
  - `[ INTERRUPTED ○ ]`: Prematurely cancelled or unlatched session, rendered with muted basalt dot.
- **Empty State (Zero Sessions):**
  If no sessions exist for today yet:
  ```text
  LOG ENTRIES:
  [ NO SESSIONS RECORDED TODAY ]
  STANDBY // COMMENCE CHRONO DIAL
  ```

### 3.3 Bottom Action Bar
- `[ COPY TEXT LOG ]`:
  - Formats today's complete session telemetry into clean plain text and copies to system clipboard (`Clipboard.setData`).
  - Triggers haptic feedback (`HapticService.lightClick()`) and briefly flashes `[ COPIED TO CLIPBOARD ]`.
- `[ RETRACT ▲ ]`:
  - Retracts the paper roll back into the plate housing.

---

## 4. Architecture & State Management

### 4.1 Data Source
- Reactive Riverpod stream subscribing to `appDatabaseProvider.watchTodayTimerSessions()`.
- Data mapping:
  - `completedSessions`: `sessions.where((s) => s.isFinished).length`
  - `totalMinutes`: `(sessions.fold(0, (sum, s) => sum + s.elapsedSeconds) / 60).round()`
  - `efficiencyRate`: `sessions.isEmpty ? 0 : ((completedSessions / sessions.length) * 100).round()`
- Entries are sorted by timestamp (`startedAt` ascending or descending).

### 4.2 Component Structure
1. `DeskSpecPlateWidget` (`lib/features/desk/presentation/widgets/desk_spec_plate_widget.dart`):
   - Houses an internal state or notifier for `isTelemetryExpanded`.
   - Renders the rating plate and attaches `DeskTelemetrySlipWidget` immediately beneath it.
2. `DeskTelemetrySlipWidget` (`lib/features/desk/presentation/widgets/desk_telemetry_slip_widget.dart`):
   - Standalone widget encapsulating the thermal paper container, animated expansion, session stream listener, formatting logic, dot-matrix layout, and clipboard copy action.
3. `_PerforatedEdgePainter`:
   - Procedural vector painter drawing the authentic serrated/perforated bottom boundary.

---

## 5. Testing & Quality Assurance

- **Unit / Widget Tests (`test/features/desk/desk_telemetry_slip_test.dart`):**
  - Verify slip is initially collapsed.
  - Tapping spec plate expands the slip and plays `dialClick`.
  - Verify correct session count, timestamps, duration, and completed/interrupted status formatting.
  - Verify empty state renders gracefully when no sessions exist.
  - Verify `[ COPY TEXT LOG ]` populates clipboard data.
  - Verify `[ RETRACT ▲ ]` collapses the slip.
  - Verify light and dark mode styling.
- **Zero Static Analyzer Warnings:** `flutter analyze` must pass with 0 issues.
- **100% Repository Pass Rate:** All 217+ existing tests must continue to pass without regressions.
