# Takt Desk: Archive Drawer, Split-Flap Pomodoro, Interactive Dial & Compact Console Spec

**Author:** Antigravity Team  
**Date:** 2026-09-08  
**Status:** Approved  
**Target:** Flutter 3.27+, Android SDK 34+ / Linux Desktop  

---

## 1. Executive Summary & Goals

This specification resolves usability and visual defects identified from runtime desktop usage while introducing two tactile industrial modules:
1. **Removal of Stereo VU Meter**: Simplify the workbench to 3 core instruments.
2. **Compact Non-Scrolling Console Layout**: Eliminate annoying vertical scrolling on desktop/tablet by displaying the 3 instruments in a clean, horizontal modular audio rack (`[ Chrono Dial ] == [ Task Runner ] == [ Vinyl Deck ]`).
3. **Directly Draggable Chrono Dial Needle**: Synchronize the needle angle directly with minutes (e.g. 25 min -> mark 25, 9 min -> mark 09) and enable full rotary dragging directly on the dial face so the user can drag the needle to set time.
4. **Symmetric Receipt Paper & Tear Bug Fix**: Keep thermal receipt paper perfectly horizontal, straight, and symmetric at rest. Remove residual shear/rotation that distorted paper when dragging or dismissing tasks.
5. **Slide-Out Brass Archive Drawer**: An industrial sliding tray with a brushed brass handle under the printer that slides open mechanically to view, reprint, or purge archived tasks.
6. **3D Split-Flap Pomodoro Display**: Dual-row Solari-style mechanical split-flap board above the dial that flips with 3D perspective, tactile *clack* sound, and tracks `FOCUS` / `SHORT BRK` / `LONG BRK` cycles.

---

## 2. Architecture & Layout Reorganization

### 2.1 Three-Instrument Console
The workbench consists of exactly 3 modular instruments (Dieter Rams audio rack standard):
1. **Chrono Dial** (Left): 3D Split-Flap Cycle Display + Interactive Rotary Needle Timer.
2. **Thermal Task Runner** (Center): Receipt printer + Slide-Out Brass Archive Drawer.
3. **Braun TP-1 Vinyl Deck** (Right): Ambient soundscape player + tonearm.

### 2.2 Responsive Non-Scrolling Grid
- **Wide Viewport (Width >= 760px - Desktop Linux / Tablet)**:
  - 3 columns side-by-side: `Row([ChronoDial, Bracket, TaskRunner, Bracket, VinylDeck])`.
  - Max height ~380px: fits comfortably within 600px+ vertical resolution without vertical scrolling.
- **Medium Viewport (Width 520px - 759px)**:
  - Row 1: Chrono Dial (Left) + Vinyl Deck (Right).
  - Row 2: Task Runner (Centered, with compact height).
- **Narrow Viewport (Width < 520px - Mobile)**:
  - Compact tabbed or paging console selector (`DIAL` | `TASKS` | `VINYL`) or slim vertical stack fitting on screen without scroll overflow.

---

## 3. Chrono Dial: Directly Draggable Needle & Accurate Angle

### 3.1 Needle Angle Mapping
- Current bug: Needle angle was tied to `progressPercent` (which is 0 when reset/idle), causing the needle to point straight to 12 o'clock even when set to 9 min or 25 min.
- Fix: The needle angle is mapped directly to minutes on the 60-minute dial:
  $$\theta = \left(\frac{\text{remainingSeconds}}{3600.0}\right) \times 2\pi - \frac{\pi}{2}$$
  - 15 min -> exactly at 3 o'clock (mark 15).
  - 25 min -> exactly at 5 o'clock (mark 25).
  - 09 min -> exactly at mark 09.
  - 0 min / Complete -> 12 o'clock (mark 60/00).

### 3.2 Full-Surface Rotary Drag Gesture
- The entire dial face responds to `onPanStart`, `onPanUpdate`, and `onPanEnd`:
  - Calculate angle from dial center: `angle = atan2(dy, dx) + pi/2`.
  - Normalize to `[0, 2*pi)` and map to minutes: `minutes = (angle / (2*pi) * 60).round()`.
  - Clamped between 1 and 60 (or 90) minutes.
  - When dragged, update `targetMinutes` and `remainingSeconds`, triggering haptic tick and audio dial click on each discrete minute tick.
  - When timer is running, the needle continuously sweeps towards 12 o'clock.

---

## 4. Thermal Task Runner: Paper Symmetry & Tear Fix

### 4.1 Symmetry & Zero Residual Shear
- At rest, receipt paper strips are **strictly horizontal** and symmetric within the basalt chassis card:
  - `ReceiptRunnerPainter`: Straight horizontal bottom with uniform serration teeth when not tearing.
  - `AnimatedReceiptStrip`: Reset `_localTearProgress` to `0.0` immediately when drag finishes, cancels, or when task is dismissed.
  - Global `tearDragProgress` does NOT persist onto other receipt strips or remain after tear.
- Eliminate excessive 3D rotation that causes paper to poke out past the module boundaries.

### 4.2 Slide-Out Brass Archive Drawer
- **Component**: `ArchiveDrawerWidget` attached at the bottom of the Task Runner.
- **Visuals**: Brushed brass handle (`#C89B59` / `#9E7B3B`) with countersunk rivets and engraved `ARCHIVE` label + badge count.
- **Motion**: `AnimatedCrossFade` or `SizeTransition` / sliding panel driven by `AnimationController` with `Curves.easeOutCubic`.
- **Audio**: Foley audio for drawer slide (`SoundEffect.drawerSlide`) and metallic latch click (`SoundEffect.drawerLatch`).
- **Functionality**:
  - Displays archived tasks from SQLite `watchArchivedTasks()`.
  - Each item has: Stamped date, "REPRINT" button (pushes task back to active queue if < 5), and "PURGE" button.

---

## 5. 3D Split-Flap Mechanical Pomodoro Display

### 5.1 Presentation & Structure
- Mounted horizontally above the Chrono Dial dial face.
- Two Solari-style split flap rows:
  - Top: Phase display (`[ FOCUS ]`, `[ SHORT BRK ]`, `[ LONG BRK ]`).
  - Bottom: Cycle counter (`[ CYCLE 1/4 ]`, `[ CYCLE 2/4 ]`, etc.).
- Each card has a center horizontal seam, rivet caps, and matte dark slate backing with warm bone lettering.

### 5.2 3D Flip Animation
- Top half card, bottom half card, and flipping flap using 3D perspective matrix transform:
  `Transform(transform: Matrix4.identity()..setEntry(3, 2, 0.002)..rotateX(angle))`
- Dynamic shading darkening during the fold.
- Audio: Tactile *clack* flip sound effect (`SoundEffect.splitFlap`).

### 5.3 Automated Pomodoro Phase Cycling
- States:
  1. `PomodoroPhase.focus` (Default 25m): Dial counts down. Upon completion, auto-advances to `shortBreak`.
  2. `PomodoroPhase.shortBreak` (5m): Dial sets to 5m, flaps flip to `SHORT BRK`. Upon completion, increments cycle.
  3. `PomodoroPhase.longBreak` (15m): After cycle 4 completes, triggers 15m long break, then resets cycle count to 1.

---

## 6. Verification & Quality Plan
- Unit tests for:
  - Chrono dial needle angle calculation and rotary drag setting.
  - Pomodoro cycle transitions (focus -> shortBreak -> longBreak).
  - Archive drawer controller & task reprinting.
- Widget tests for:
  - ChronoDialWidget rotary drag interaction.
  - ReceiptRunnerWidget symmetric rendering at rest and drawer toggle.
  - DeskCanvasScreen 3-column non-scrolling responsive layout.
- 0 analyzer warnings, 100% test suite passing.
