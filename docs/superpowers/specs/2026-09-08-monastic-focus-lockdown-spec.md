# Takt Desk: Monastic Focus Lockdown (Anti-Brainrot Mode) Specification

**Date:** 2026-09-08  
**Platform Target:** Mobile Android (with testable mock channels on host runners)  
**Status:** Approved for Implementation Planning  

---

## 1. Overview & Purpose
The **Monastic Focus Lockdown** is a physical-analog inspired discipline system designed to eliminate digital distractions ("anti-brainrot") while working or studying. When engaged, Takt Desk transforms into a sealed pocket instrument:
1. The app cannot be minimized, closed, or switched away from via native Android **App Pinning (`startLockTask()`)** and Flutter **`PopScope(canPop: false)`**.
2. Notifications, alerts, and calls are silenced via Android **Do Not Disturb (DND)**.
3. The screen remains persistently awake with a warm analog amber filament glow (**Wakelock**), keeping the desk clock and pomodoro visibly ticking.
4. An **Emergency Release Latch (`[ ⏻ HOLD 5s TO UNLATCH ]`)** ensures safety: the user must physically hold the release latch for 5 continuous seconds with auditory/haptic feedback to abort early.
5. In accordance with user requirements, the workbench is streamlined exclusively as a **Pure Mobile Handheld Console**, eliminating desktop multi-column layouts.

---

## 2. Architectural Components

```
+-------------------------------------------------------------+
|                     DeskCanvasScreen                        |
|  - PopScope(canPop: !isFocusLocked)                         |
|  - AmbientLightingLayer                                     |
+-------------------------------------------------------------+
|  Top Bar: [ Monastic Toggle Switch ] [ ChassisThemeSwitch ] |
|  - Normal vs Monastic Focus Switch                          |
|  - Filament Amber Glow Lamp                                 |
+-------------------------------------------------------------+
|  Instrument Switcher: [ DIAL ] [ TASKS ] [ VINYL ]          |
|  - Pure Mobile Viewport Fitting (Zero Vertical Scroll)      |
+-------------------------------------------------------------+
|  Active Instrument: ChronoDial / Tasks / Vinyl              |
+-------------------------------------------------------------+
|  Bottom: [ ⏻ HOLD 5s TO UNLATCH ] (When Locked)             |
|  - 5-second continuous press progress gauge                 |
|  - Incremental ratchet clicks + haptic pulses               |
|  - Instant reset if finger lifts before 5.0s               |
+-------------------------------------------------------------+
           |                                  |
           v                                  v
+------------------------+      +---------------------------+
|  FocusLockController   |      |  Android MethodChannel    |
|  - State management    | ---> |  com.tuneeca.takt_desk/   |
|  - 5s hold timer       |      |  focus_lock               |
|  - Drift DB session    |      |  - startLockTask()        |
+------------------------+      |  - stopLockTask()         |
                                |  - FLAG_KEEP_SCREEN_ON    |
                                |  - DND Interruption Filter|
                                +---------------------------+
```

---

## 3. Detailed Specifications

### 3.1 Android Native Integration (`MainActivity.kt`)
- **MethodChannel Identifier:** `com.tuneeca.takt_desk/focus_lock`
- **Methods Supported:**
  1. `enableFocusLock()`:
     - Invokes `activity.startLockTask()` to pin the window.
     - Adds `WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON`.
     - Hides system status bar and navigation bar via `WindowInsetsControllerCompat` (immersive sticky).
     - Checks `NotificationManager.isNotificationPolicyAccessGranted`; if granted, sets `INTERRUPTION_FILTER_PRIORITY` or `INTERRUPTION_FILTER_NONE`.
  2. `disableFocusLock()`:
     - Invokes `activity.stopLockTask()`.
     - Clears `FLAG_KEEP_SCREEN_ON`.
     - Restores system bars and original notification policy.
  3. `isLockTaskPermitted()`:
     - Returns boolean indicating device capability.
- **Graceful Host Fallback:**
  - If running on desktop Linux / Flutter test runner where Android channel is unavailable or throws `MissingPluginException`, the Dart service catches safely without crashing and simulates the state in-memory.

### 3.2 Mobile-First Console Layout Refinement
- Remove the desktop wide multi-column rack (from `desk_canvas_screen.dart`).
- Enforce the single-screen mobile layout across all screen sizes:
  - Header: Branding, Monastic Focus Switch, and Chassis Theme Switch.
  - Tactical Instrument Selector: Segmented pill (`DIAL` | `TASKS` | `VINYL`).
  - Active View: Fills remaining viewport space precisely without vertical scrollbars (`SingleChildScrollView` removed from main canvas body).

### 3.3 The Monastic Switch (`MonasticSwitchWidget`)
- Industrial sliding toggle with textured knurled thumb.
- States:
  - **OFF (Basalt Gray / Muted)**: Normal Takt Desk mode.
  - **ON (Obsidian & Filament Amber `#D99B59`)**: Focus Mode Engaged.
- Audio foley: plays `SoundEffect.switchClick` and triggers `HapticService.heavyClick()`.
- Subtle pulsing amber glow border indicating deep focus state.

### 3.4 The Emergency Unlatch Mechanism (`EmergencyUnlatchWidget`)
- Visible only when `isFocusLocked == true`.
- Position: Anchored at the bottom of the console in a reinforced recessed bezel.
- Label: `[ ⏻ HOLD 5s TO UNLATCH ]`.
- Interaction:
  - Handled via `Listener(onPointerDown, onPointerUp, onPointerCancel)`.
  - Driven by a dedicated `AnimationController` with a fixed duration of `5000 milliseconds` (5.0s).
  - While held down:
    - Custom painter draws a high-precision progress bar / circular gauge from 0.0 to 1.0.
    - Emits a periodic mechanical ticking sound (`SoundEffect.dialClick`) and light haptic tick every 500ms.
  - Premature Release (< 5.0s):
    - Instantly resets progress to 0.0 with a soft spring mechanical sound.
    - Prevents accidental unlocks and reinforces discipline.
  - Completion (== 5.0s):
    - Triggers `FocusLockController.completeUnlock()`.
    - Plays `SoundEffect.drawerLatch` and `HapticService.heavyClick()`.
    - Disables native lock task and restores normal state.

### 3.5 Drift Persistence
- Store focus sessions in `timer_sessions` or dedicated records:
  - `startedAt`, `durationSeconds`, `completedNormally (bool)`.

---

## 4. Testing & Quality Acceptance Criteria
1. **0 Analyzer Warnings**: `flutter analyze` returns zero issues.
2. **100% Test Pass Rate**: All existing 88 tests + new focus lock tests pass.
3. **Unit Tests**:
   - `FocusLockController` initial state is unlocked.
   - Locking initiates native channel call and sets `isLocked = true`.
   - Holding starts progress; releasing before 5s cancels and resets to 0.0.
   - Holding to 100% completes unlock and calls `disableFocusLock()`.
4. **Widget Tests**:
   - `MonasticSwitchWidget` toggles lock state and displays amber glow.
   - `EmergencyUnlatchWidget` renders only when locked, fills progress on pointer hold, and resets on pointer release.
   - `DeskCanvasScreen` respects `PopScope` when locked.
