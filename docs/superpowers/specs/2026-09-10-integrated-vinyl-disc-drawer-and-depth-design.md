# Design Spec: Integrated Vinyl Disc Drawer & 2.5D Physical Depth Enhancement

**Date:** 2026-09-10  
**Feature:** Integrated Vinyl Disc Drawer & 2.5D Physical Depth Enhancement  
**Status:** DRAFT (Ready for Review)  

---

## 1. Problem Statement & Motivation

### Current Issues:
1. **Oversized Modal Disconnect:** The current `VinylRecordCrateSheet` opens as a full modal bottom sheet covering ~70% of the screen. It occludes the turntable deck, feels like a disconnected mobile OS popup rather than a physical part of the audio instrument, and disrupts workflow.
2. **Flat Chassis Perception:** While material colors and textures were introduced, the instrument chassis borders could exhibit greater physical depth (machined slab thickness, chamfered edge bevels, and sunken platter wells) to deliver the authentic, hyper-tactile 2.5D feel of high-end industrial design (such as *Teenage Engineering* and *Braun*).

### Desired Outcome:
1. **Integrated Disc Drawer:** Replace the modal bottom sheet with an in-place, slide-out **Disc Drawer** (`VinylDiscDrawerWidget`) built directly into the bottom of the `BRAUN TP-1` chassis, in perfect aesthetic and functional symmetry with the Task Dispenser's `ArchiveDrawerWidget`.
2. **2.5D Physical Depth & Relief:** Elevate the physical realism of the instruments with top-down 2.5D mechanical relief (chamfered slab borders, recessed turntable well inner shadows, and tactile sliding drawer rails) while retaining 100% lightweight, GPU-accelerated 60/120fps vector rendering with zero engine overhead or battery drain.

---

## 2. Architectural Design

```
+-------------------------------------------------------+
|  BRAUN TP-1 Turntable Chassis (MaterialChassisBox)   |
|  - Machined Top Chamfer Highlight (Specular Rim)      |
|  - Machined Bottom Drop Shadow (5mm Slab Depth)       |
|                                                       |
|  [ Header: BRAUN TP-1                 • 33 RPM ]     |
|                                                       |
|  +-------------------------------------------------+  |
|  |  Recessed Platter Well (Inner Drop Shadow)      |  |
|  |  ( ) 12-Inch Vinyl Record (33 RPM Spindle)      |  |
|  |  \   Tonearm & Needle                           |  |
|  +-------------------------------------------------+  |
|                                                       |
|  Track Display: "LO-FI RAIN"                          |
|                                                       |
|  +-------------------------------------------------+  |
|  |  [ RECORD DRAWER // 08 DISCS ▾ ]  (Handle Bar)  |  |
|  |  - Brushed Metal Finish, Dual Rivets            |  |
|  |-------------------------------------------------|  |
|  |  [EXPANDED DRAWER BAY (AnimatedSize)]           |  |
|  |  • Drawer side rails (machined guide grooves)   |  |
|  |  • Snapping Horizontal Album Sleeves (8 Discs)  |  |
|  |  • Micro Counter: [ 01 / 08 ]  [◀]  [▶]         |  |
|  |  • Mini Peeking Vinyl (Grooves + Active Halo)   |  |
|  |  • [ ON PLATTER ] / [ LOAD ] / [ PRO 🔒 ]       |  |
|  +-------------------------------------------------+  |
+-------------------------------------------------------+
```

---

## 3. Detailed Component Specifications

### 3.1. 2.5D Physical Depth Enhancements
1. **Machined Chamfered Bezel in `MaterialChassisBox`:**
   - Inner top and left highlight: subtle 1.0px white stroke with low opacity (`0.12` in dark mode, `0.25` in light mode) simulating a top-lit machined edge chamfer.
   - Outer bottom and right shadow: enhanced multi-layer ambient occlusion drop shadow simulating a solid 5mm physical aluminum/chassis slab.
2. **Recessed Turntable Well in `VinylDeckPainter`:**
   - Draw an inner radial shadow / gradient ring immediately outside the platter boundary (`radius + 4px` tapering inward).
   - This creates the visual reality that the platter sits sunken inside a machined circular well in the chassis rather than painted flat on the surface.

---

### 3.2. Integrated Disc Drawer (`VinylDiscDrawerWidget`)
1. **Chassis Integration:**
   - Replaces the legacy `_CrateTriggerBadge` and the detached `VinylRecordCrateSheet.show(context)` modal.
   - Placed directly inside `VinylPlayerWidget` below the track name display.
2. **State & Reactive Control:**
   - State addition in `VinylState`: `final bool isDrawerOpen;` (default `false`).
   - Method in `VinylController`: `void toggleDrawer()` with haptic feedback (`HapticService.selectionClick()`).
3. **Handle Bar (`VinylDrawerHandle`):**
   - Height: 32px.
   - Finish: Brushed metal gradient (`themeState.plateGradient`), 2 metal rivets matching active edition (`themeState.rivetColor`).
   - Center Badge: `[ RECORD DRAWER // 08 DISCS ▾ ]` (displays `▲` when drawer is open).
   - Accessibility: Wrapped with `Semantics(button: true, label: 'Toggle vinyl record drawer')`.
4. **Drawer Interior (Slide-Out Bay):**
   - Animation: `AnimatedSize` with `Curves.easeInOutCubic` (280ms duration).
   - Outer Frame: Dark metal bay with subtle horizontal sliding guide rails on the left and right borders (`drawer_rails`).
   - Height when open: ~185px.
   - Header Row: Mini control strip with counter `[ 01 / 08 ]` and accessible arrow buttons `◀` and `▶`.
   - Card Carousel: Compact `PageView.builder` with `viewportFraction: 0.85` displaying the 8 album sleeves (`TK-01` to `TK-08`).
5. **Compact Album Sleeve Cards:**
   - Dimensions: ~210px wide x ~140px high.
   - Peeking Mini Vinyl Disc: Custom procedural painter with grooves, center label, and amber illuminated halo if active on the platter.
   - Track Metadata: Catalog ID, Name, Subtitle, and Tier (`33 RPM // HI-FI` or `STUDIO PRO 🔒`).
   - Action Buttons:
     - Active track: `[ ON PLATTER ]` (subtle filament amber glow).
     - Unlocked track: `[ LOAD TO PLATTER ]` (equips track onto the deck directly above; deck platter immediately reflects the new label color and starts rotating).
     - Locked track: `[ STUDIO PRO 🔒 ]` (triggers shared `showStudioProDialog`).

---

## 4. Performance & Mobile Constraints
- **Zero Raster Assets:** 100% vector CustomPainters and declarative Flutter widgets.
- **60/120 FPS Rendering:** Isolated with `RepaintBoundary` and cached painters.
- **Max Width Boundary:** Fits comfortably within mobile 280px module width and <=440px viewport.
- **Backwards Compatibility:** Unit tests for track selection and Pro revocation remain intact.

---

## 5. Verification & Testing Plan
1. **Unit Tests:**
   - Verify `VinylController.toggleDrawer()` toggles `isDrawerOpen` and triggers haptic feedback.
   - Verify Pro revocation resets track while drawer remains interactive.
2. **Widget Tests:**
   - Verify `VinylPlayerWidget` renders `VinylDiscDrawerWidget`.
   - Verify tapping handle bar expands drawer via `AnimatedSize`.
   - Verify 8 cards are present in the carousel.
   - Verify tapping `[ LOAD TO PLATTER ]` loads the track onto the deck without navigating away.
   - Verify tapping locked track opens `StudioProDialog`.
3. **Static Analysis & Suite:**
   - 0 issues on `flutter analyze`.
   - 100% passing tests across the entire repository.
