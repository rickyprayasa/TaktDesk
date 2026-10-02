# ZYKL Promo Video Versi 3: The Apple-Grade Product Film Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and render an Apple-grade 9:16 vertical promo video (1080×1920 @ 30 FPS, 52s / 1,560 frames) for ZYKL using Remotion + Three.js WebGL, featuring true 3D physical smartphone motion, Apple-style declarative headlines, Dieter Rams modernist aesthetics, and synchronized mechanical foley audio.

**Architecture:** A modular Remotion composition driven by `@remotion/three` and `three`. A central 3D WebGL stage (`StudioStage3D.tsx`) renders a procedural titanium flagship smartphone (`PhoneMesh.tsx`) with dynamic PBR materials and a camera rig (`CameraRig.tsx`) interpolated per frame. Front display renders high-contrast ZYKL instrument animations. Audio layer harmonizes velvet Rhodes chords with tactile foley.

**Tech Stack:** Remotion v4, Three.js (`three`, `@types/three`), `@remotion/three`, `@react-three/fiber`, React 18, TypeScript, Tailwind CSS / inline styling.

## Global Constraints
- Target directory: `/home/tuneeca/RSQUARE/Android/zykl.app/promo/remotion-1x1`
- Format: 1080 × 1920 (9:16 Vertical Story / Reels / Shorts)
- Framerate: Strictly **30 FPS**
- Total Duration: **1,560 Frames (52.0 Seconds)**
- Composition ID: `ZYKLPromoV3-9x16`
- Output target: `/home/tuneeca/RSQUARE/Android/zykl.app/promo/Video Versi 3/ZYKL_Promo_V3_Apple_Grade_Master.mp4`
- Aesthetic: Pure Dieter Rams / Braun Modernist Industrial Modernism (Obsidian `#121316`, Warm Bone `#F4F2EC`, Filament Amber `#FF9E00`, Raw Brass `#C89B3C`, Dieter Rams Orange `#E85D04`). Zero generic AI slop.
- Audio: Strictly Option A—Velvet Rhodes master score + tactile physical foley (ticking escapement, switch clicks, paper tear, vinyl needle drop). Zero spoken voiceover.

---

### Task 1: Environment & 3D WebGL Dependencies Setup

**Files:**
- Modify: `package.json`
- Verify: `tsconfig.json`

**Interfaces:**
- Produces: `three`, `@types/three`, `@remotion/three`, `@react-three/fiber` ready for import.

- [ ] **Step 1: Install Three.js and Remotion Three packages**
  Run `npm install three@0.160.0 @types/three@0.160.0 @remotion/three@4.0.528 @react-three/fiber@8.17.10 --save --legacy-peer-deps` inside `promo/remotion-1x1`.
- [ ] **Step 2: Verify TypeScript Compilation**
  Run `npx tsc --noEmit` and confirm 0 diagnostic errors.
- [ ] **Step 3: Commit**
  `git commit -m "chore(promo): install three and remotion-three for 3D product film"`

---

### Task 2: Constants, Timings & Master Audio Pipeline

**Files:**
- Create: `src/constantsV3.ts`
- Create: `src/componentsV3/AudioLayerV3.tsx`

**Interfaces:**
- Produces: `TIMING_V3` with frame offsets for all 8 scenes (1,560 frames total).
- Produces: `<AudioLayerV3 />` with synchronized Rhodes music and tactile mechanical foleys.

- [ ] **Step 1: Define `constantsV3.ts`**
  Set `duration: 1560`, `fps: 30`, `width: 1080`, `height: 1920`.
  Breakdown:
  - `scene01_trap`: frames 0 – 180 (6.0s)
  - `scene02_chronometer`: frames 180 – 390 (7.0s)
  - `scene03_lockdown`: frames 390 – 570 (6.0s)
  - `scene04_dispenser`: frames 570 – 780 (7.0s)
  - `scene05_turntable`: frames 780 – 990 (7.0s)
  - `scene06_analytics`: frames 990 – 1170 (6.0s)
  - `scene07_editions`: frames 1170 – 1380 (7.0s)
  - `scene08_outro`: frames 1380 – 1560 (6.0s)
- [ ] **Step 2: Build `AudioLayerV3.tsx`**
  - Frames 0 – 150: Distraction push notification chimes.
  - Frame 150: `tv_power_off.wav` + `vacuum_implosion_drop.wav` at CRT cut.
  - Frame 180 – 1560: Continuous velvet Rhodes piano score (`vinyl_rhodes_velvet.wav`) with graceful outro fade.
  - Synchronized foleys at exact scene transitions:
    - Frame 200: Escapement tick loop
    - Frame 430: Mechanical unlatch switch
    - Frame 620: Paper tear foley
    - Frame 810: Vinyl surface crackle & needle drop
    - Frame 1210: Rotary dial click
- [ ] **Step 3: Verify TypeScript Compilation**
  Run `npx tsc --noEmit`.
- [ ] **Step 4: Commit**
  `git commit -m "feat(promo): define V3 timings (30 FPS) and synchronized audio pipeline"`

---

### Task 3: 3D Titanium Smartphone Model & Studio Lighting Rig

**Files:**
- Create: `src/components3D/PhoneMesh.tsx`
- Create: `src/components3D/StudioStage3D.tsx`
- Create: `src/components3D/CameraRig.tsx`
- Create: `src/componentsV3/EditorialHeadlineV3.tsx`

**Interfaces:**
- Produces: `<PhoneMesh />` with titanium PBR material, chamfers, buttons, and dynamic screen content mapping.
- Produces: `<StudioStage3D />` providing warm amber keylight, cool fill, contact shadows, and drafting grid.
- Produces: `<CameraRig />` interpolating 3D perspective camera angles smoothly across frames.
- Produces: `<EditorialHeadlineV3 />` Apple-style bold headline + quiet subline with kinetic spring reveal.

- [ ] **Step 1: Implement `PhoneMesh.tsx`**
  Procedural 3D rounded-box titanium body, camera plateau with sapphire lens rings, dynamic island pill, and display screen plane with PBR metallic sheen.
- [ ] **Step 2: Implement `StudioStage3D.tsx`**
  Studio ambient lighting, warm keylight bloom, contact shadow ground plane, and Dieter Rams millimeter drafting grid.
- [ ] **Step 3: Implement `CameraRig.tsx`**
  Three.js camera controller driven by Remotion frame interpolation with smooth cubic easing.
- [ ] **Step 4: Implement `EditorialHeadlineV3.tsx`**
  Single-phrase bold headline (`Inter Display`, 52px bold) + muted telemetry subline (`JetBrains Mono`, 16px).
- [ ] **Step 5: Verify TypeScript Compilation**
  Run `npx tsc --noEmit`.
- [ ] **Step 6: Commit**
  `git commit -m "feat(promo): implement 3D smartphone mesh and studio lighting rig"`

---

### Task 4: Scenes 1 & 2 — The Distraction Trap & Unit 01 Chronometer

**Files:**
- Create: `src/scenesV3_9x16/Scene01TrapV3.tsx`
- Create: `src/scenesV3_9x16/Scene02ChronometerV3.tsx`

**Interfaces:**
- Consumes: `<StudioStage3D />`, `<PhoneMesh />`, `<EditorialHeadlineV3 />`, `TIMING_V3`
- Produces: Scene 1 (Frames 0 - 180) & Scene 2 (Frames 180 - 390).

- [ ] **Step 1: Build `Scene01TrapV3.tsx`**
  - Phone tilts dramatically in darkness with specular edge glint.
  - Headline: *"WHERE DID YOUR TIME GO?"*
  - Screen overwhelmed by urgent lock screen notifications.
  - Frame 150: CRT phosphor collapse into dead black slab.
- [ ] **Step 2: Build `Scene02ChronometerV3.tsx`**
  - Warm studio environment illuminates the desk.
  - Camera glides into a close-up macro hero angle.
  - Headline: *"TIME IS NOT A FEED."* Subline: *"Analog intent. Calibrated 25/5 monastic cycles."*
  - Screen displays the physical Pomodoro dial ticking with authentic escapement needle physics.
- [ ] **Step 3: Verify TypeScript Compilation**
  Run `npx tsc --noEmit`.
- [ ] **Step 4: Commit**
  `git commit -m "feat(promo): implement Scene 1 The Trap and Scene 2 Unit 01 Chronometer"`

---

### Task 5: Scenes 3 & 4 — Monastic Lockdown & Unit 02 Dispenser

**Files:**
- Create: `src/scenesV3_9x16/Scene03LockdownV3.tsx`
- Create: `src/scenesV3_9x16/Scene04DispenserV3.tsx`

**Interfaces:**
- Consumes: `<StudioStage3D />`, `<PhoneMesh />`, `<EditorialHeadlineV3 />`
- Produces: Scene 3 (Frames 390 - 570) & Scene 4 (Frames 570 - 780).

- [ ] **Step 1: Build `Scene03LockdownV3.tsx`**
  - Smooth camera transition to isometric view.
  - Headline: *"STRICTLY UNCOMPROMISED."* Subline: *"Hold 3 seconds to unlatch. No quick escapes."*
  - Screen showcases the monastic lockdown hold gesture with brass progress ring filling smoothly.
- [ ] **Step 2: Build `Scene04DispenserV3.tsx`**
  - Phone turns smoothly to front hero angle.
  - Headline: *"5 TASKS. PHYSICAL PAPER CAP."* Subline: *"Tear off finished work. Zero infinite backlog."*
  - Screen animates thermal receipt dispenser, serrated paper tear, and wet ink stamp `[DONE]`.
- [ ] **Step 3: Verify TypeScript Compilation**
  Run `npx tsc --noEmit`.
- [ ] **Step 4: Commit**
  `git commit -m "feat(promo): implement Scene 3 Monastic Lockdown and Scene 4 Unit 02 Dispenser"`

---

### Task 6: Scenes 5 & 6 — Unit 03 Turntable & Focus Telemetry

**Files:**
- Create: `src/scenesV3_9x16/Scene05TurntableV3.tsx`
- Create: `src/scenesV3_9x16/Scene06AnalyticsV3.tsx`

**Interfaces:**
- Consumes: `<StudioStage3D />`, `<PhoneMesh />`, `<EditorialHeadlineV3 />`
- Produces: Scene 5 (Frames 780 - 990) & Scene 6 (Frames 990 - 1170).

- [ ] **Step 1: Build `Scene05TurntableV3.tsx`**
  - Cinematic isometric angle spotlighting the turntable platter.
  - Headline: *"ANALOG SOUNDSCAPES."* Subline: *"12 procedural audio atmospheres. Zero ads."*
  - Screen animates Braun TP-1 vinyl record spinning at 33⅓ RPM with brushed steel tonearm landing.
- [ ] **Step 2: Build `Scene06AnalyticsV3.tsx`**
  - Lateral tracking camera motion across phone surface.
  - Headline: *"TELEMETRY OF FOCUS."* Subline: *"Physical receipts. 100% offline SQLite."*
  - Screen displays weekly focus receipts and session history archive.
- [ ] **Step 3: Verify TypeScript Compilation**
  Run `npx tsc --noEmit`.
- [ ] **Step 4: Commit**
  `git commit -m "feat(promo): implement Scene 5 Monastic Turntable and Scene 6 Focus Telemetry"`

---

### Task 7: Scenes 7 & 8 — 4 Hardware Editions & Monastic Trinity Outro

**Files:**
- Create: `src/scenesV3_9x16/Scene07EditionsV3.tsx`
- Create: `src/scenesV3_9x16/Scene08OutroV3.tsx`

**Interfaces:**
- Consumes: `<StudioStage3D />`, `<PhoneMesh />`, `<EditorialHeadlineV3 />`
- Produces: Scene 7 (Frames 1170 - 1380) & Scene 8 (Frames 1380 - 1560).

- [ ] **Step 1: Build `Scene07EditionsV3.tsx`**
  - 360-degree orbit around the 3D phone.
  - Headline: *"FOUR TIMELESS EDITIONS."* Subline: *"Crafted from modernism's finest palettes."*
  - Materials seamlessly cycle: Braun Classic White $\to$ Bauhaus Heritage $\to$ Mid-Century Walnut $\to$ Raw Brass Patina.
- [ ] **Step 2: Build `Scene08OutroV3.tsx`**
  - Sweeping pullback showing **The Monastic Trinity** fanning out in 3D:
    - Left: Unit 02 Dispenser
    - Center: Unit 01 Chronometer
    - Right: Unit 03 Turntable
  - Overlay: ZYKL wordmark, *"Monastic Pomodoro App for Android"*, Dieter Rams tenet quote *"Weniger, aber besser"*, and tactile Google Play Store CTA button with brass rivets.
- [ ] **Step 3: Verify TypeScript Compilation**
  Run `npx tsc --noEmit`.
- [ ] **Step 4: Commit**
  `git commit -m "feat(promo): implement Scene 7 Hardware Editions and Scene 8 Trinity Outro CTA"`

---

### Task 8: Master Integration, Still Frame Verification & Production Render

**Files:**
- Create: `src/MainV3_9x16.tsx`
- Modify: `src/Root.tsx`
- Create: `render-v3-9x16.mjs`

**Interfaces:**
- Produces: Registered Remotion composition `ZYKLPromoV3-9x16` (1080×1920 @ 30 FPS, 1,560 frames).
- Produces: Master MP4 output at `/home/tuneeca/RSQUARE/Android/zykl.app/promo/Video Versi 3/ZYKL_Promo_V3_Apple_Grade_Master.mp4`.

- [ ] **Step 1: Assemble `MainV3_9x16.tsx` & Register in `Root.tsx`**
  Compose `<AudioLayerV3 />` and the 8 scene sequences according to `TIMING_V3`.
- [ ] **Step 2: Create Render Script `render-v3-9x16.mjs`**
  Configure Remotion Webpack bundler, 30 FPS renderer, and copy output to `promo/Video Versi 3/`.
- [ ] **Step 3: Render and Inspect Key Still Frames**
  Render still frames at Frame 120, 300, 500, 700, 900, 1100, 1300, 1500 using `npx remotion still`.
- [ ] **Step 4: Execute Master Video Render**
  Run `node render-v3-9x16.mjs` and monitor progress.
- [ ] **Step 5: Verify Video Integrity**
  Inspect the output with `ffprobe` (confirm 1080×1920, 30 FPS, 52.0s, H.264/AAC).
- [ ] **Step 6: Commit**
  `git commit -m "release(promo): complete ZYKL Promo Video Versi 3 Apple-grade master"`
