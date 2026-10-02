# ZYKL Promo Video Versi 3: The Apple-Grade Product Film
**Design Specification**
*Date: 2026-09-25*
*Author: Antigravity AI & Ricky Prayasa*
*Status: Approved*

---

## 1. Executive Summary

ZYKL Promo Video Versi 3 elevates the promotional campaign into an **Apple-grade cinematic product film** combining **Remotion** with **Three.js WebGL**. Inspired by the confident, slow, eased motion design of Apple launch films (e.g. *Belanje* and *Retinly*), Versi 3 merges true 3D physical device rendering with the timeless modernist industrial aesthetic of Dieter Rams and Braun.

Running at **30 FPS** for **~52 seconds (1,560 frames)**, Versi 3 achieves cinematic fluidity while reducing total frame computation by over 64% compared to Versi 2 (1,560 frames vs. 4,420 frames), enabling full export in just **~4–5 minutes** on standard desktop hardware.

---

## 2. Design Philosophy & Inspiration

### 2.1 The Apple Product Film Motion Language
- **Slow, Eased, Confident Motion**: Zero frenetic cuts or jittery shakes. Camera transitions use ultra-smooth cubic-bezier kinematics (`cubic-bezier(0.16, 1, 0.3, 1)` / overdamped springs).
- **Hero Single-Phrase Headlines**: Bold, declarative headlines set in *Inter Display* / *SF Pro* with high contrast, paired with quiet, muted sublines.
- **Dynamic 3D Camera Angles**: True Three.js `PerspectiveCamera` orchestrating close-up specular sweeps, isometric angles, rack-focus transitions, and sweeping pullbacks.

### 2.2 Preserving 100% ZYKL Modernist DNA
- **Palette**: Obsidian (`#121316`), Basalt (`#1E222A`), Warm Bone (`#F4F2EC`), Filament Amber (`#FF9E00`), Raw Brass (`#C89B3C`), and Dieter Rams Orange (`#E85D04`).
- **Telemetry & Monospace Accents**: JetBrains Mono teletype coordinates, unit catalog pips (`[ UNIT 01 // CHRONO ]`), and physical hardware specs.
- **Acoustic Integrity**: Strictly Option A—Velvet Rhodes piano score harmonized with tactile mechanical foleys (escapement ticking, paper tearing, lock toggling, vinyl needle drop).

---

## 3. Technical Specifications

| Parameter | Specification |
| :--- | :--- |
| **Resolution** | 1080 × 1920 px (9:16 Vertical Story / Reels / Shorts) |
| **Frame Rate** | **30 FPS** (True cinematic product film standard) |
| **Duration** | **52.0 Seconds (1,560 Frames)** |
| **Core Engine** | Remotion v4 + Three.js (`@remotion/three`, `three`, `@react-three/fiber`) |
| **Rendering Backend** | Headless Chromium with ANGLE / SwiftShader WebGL rasterization |
| **Audio Pipeline** | 44.1 kHz 16-Bit Stereo Master Audio Layer with synchronized sub-frame foleys |
| **Export Target** | `/home/tuneeca/RSQUARE/Android/zykl.app/promo/Video Versi 3/ZYKL_Promo_V3_Apple_Grade_Master.mp4` |

---

## 4. 3D WebGL Device & Studio Architecture

### 4.1 3D Smartphone Mesh (`PhoneModel3D.tsx`)
A procedural or optimized Three.js geometry representing a modern titanium flagship device:
- **Chassis Body**: Extruded rounded rectangle with smooth bevels and chamfers.
- **Titanium PBR Material**: `MeshStandardMaterial` (`roughness: 0.28`, `metalness: 0.88`, deep graphite/black titanium tint).
- **Polished Chamfer Rim**: High specular reflection tracking keylight positions.
- **Camera Plateau & Lenses**: Rear island with triple sapphire lens rings and recessed sensor wells.
- **Dynamic Island / Bezel**: Top pill camera aperture and microscopic acoustic slit.
- **Screen Surface Plane**: A dedicated front mesh receiving high-resolution canvas/video textures with anisotropic filtering.

### 4.2 Studio Lighting Rig (`StudioStage3D.tsx`)
- **Key Light**: Warm amber directional light (`color: #FFB350`, `intensity: 1.8`) creating golden rim specular highlights on titanium bevels.
- **Fill Light**: Soft cool-blue diffused ambient light (`color: #88A5D0`, `intensity: 0.7`) preventing pitch-black shadows.
- **Rim / Kicker Light**: High-intensity grazing light on chassis edges.
- **Shadow Floor Plane**: Soft diffuse shadow catcher receiving realistic ground contact shadows.

---

## 5. Storyboard & Scene Breakdown (1,560 Frames @ 30 FPS)

```
00:00        00:06        00:13        00:19        00:26        00:33        00:39        00:46        00:52
|-- Scene 1 --|-- Scene 2 --|-- Scene 3 --|-- Scene 4 --|-- Scene 5 --|-- Scene 6 --|-- Scene 7 --|-- Scene 8 --|
  The Trap     Chronometer    Lockdown      Dispenser    Turntable    Analytics     4 Editions      Outro CTA
  (0 - 180f)   (180 - 390f)  (390 - 570f)  (570 - 780f) (780 - 990f) (990 - 1170) (1170 - 1380) (1380 - 1560)
```

### Scene 1: The Trap — The Distraction Slab (Frames 0 – 180 / 00:00 – 00:06)
- **3D Camera**: Extreme close-up isometric tilt on the dark titanium chassis. Specular highlight glides across the volume rocker and antenna band.
- **Screen Action**: Screen lights up displaying the Lock Screen (`09:41 · Wednesday, Sep 25`). 5 urgent push notifications cascade rapidly (WhatsApp executive call, Instagram reel loop, Cloud paywall warning, Screen time limit breached).
- **The Turn**: At Frame 150 (00:05.00), a visceral CRT television power shutdown collapses the display beam into darkness.
- **Typography**:
  ```
  WHERE DID YOUR TIME GO?
  Your phone was built to steal your attention.
  ```
- **Audio**: Urgent notification chimes $\to$ `tv_power_off.wav` + sub-bass implosion drop $\to$ 1.0s of pure contemplative silence.

### Scene 2: The Antidote — Unit 01: Analog Chronometer (Frames 180 – 390 / 00:06 – 00:13)
- **3D Camera**: Smooth glide into a macro hero perspective. Studio drafting grid and warm ambient light illuminate the desk.
- **Screen Action**: The screen awakens into the ZYKL Analog Chronometer. The 25-minute Pomodoro dial ticks with realistic escapement needle physics.
- **Typography**:
  ```
  TIME IS NOT A FEED.
  Analog intent. Calibrated 25/5 monastic cycles.
  ```
- **Audio**: Velvet Rhodes piano enters smoothly + mechanical ticking escapement clicks.

### Scene 3: Anti-Distraction — Monastic Lockdown & Unlatch (Frames 390 – 570 / 00:13 – 00:19)
- **3D Camera**: Controlled 3D rotation revealing the side chassis and screen depth.
- **Screen Action**: Focus mode initiates monastic lockdown. The user interaction demo shows the tactile 3-second hold gesture (`Hold to Unlatch`), with the circular brass progress bar filling smoothly.
- **Typography**:
  ```
  STRICTLY UNCOMPROMISED.
  Hold 3 seconds to unlatch. No quick escapes.
  ```
- **Audio**: Low mechanical locking switch foley + tactile pressure release.

### Scene 4: Unit 02 — 5-Task Thermal Dispenser (Frames 570 – 780 / 00:19 – 00:26)
- **3D Camera**: Elegant dolly back to reveal the full device profile.
- **Screen Action**: The 5-Task Physical Dispenser prints a thermal receipt. Serrated zig-zag teeth animate as a completed task is torn off and stamped with wet ink `[DONE]`.
- **Typography**:
  ```
  5 TASKS. PHYSICAL PAPER CAP.
  Tear off finished work. Zero infinite backlog.
  ```
- **Audio**: Crisp paper tear foley (`foley_paper_tear.wav`) + mechanical ink stamp thud.

### Scene 5: Unit 03 — 33⅓ RPM Monastic Turntable (Frames 780 – 990 / 00:26 – 00:33)
- **3D Camera**: Cinematic isometric angle highlighting the circular platter.
- **Screen Action**: The minimalist Braun TP-1 vinyl turntable rotates smoothly at 33⅓ RPM. The brushed steel tonearm glides down onto the dark vinyl groove.
- **Typography**:
  ```
  ANALOG SOUNDSCAPES.
  12 procedural audio atmospheres. Zero ads.
  ```
- **Audio**: Warm vinyl surface noise crackle + gentle Rhodes chords.

### Scene 6: Focus Telemetry & Offline SQLite Archive (Frames 990 – 1170 / 00:33 – 00:39)
- **3D Camera**: Lateral tracking shot across the phone surface.
- **Screen Action**: The focus analytics ledger displays weekly focus telemetry, bar charts, and historical session receipts stored locally.
- **Typography**:
  ```
  TELEMETRY OF FOCUS.
  Physical receipts. 100% offline SQLite.
  ```
- **Audio**: Smooth teletype printing ticks.

### Scene 7: Four Iconic Hardware Editions (Frames 1170 – 1380 / 00:39 – 00:46)
- **3D Camera**: Continuous 3D orbit around the device while light sweeps across the chassis.
- **Screen & Hardware Action**: Seamless material morphing across the 4 editions:
  1. *Braun Classic White* (Matte Bone chassis, amber accents)
  2. *Bauhaus Heritage* (Primary chromatic accents, industrial gray)
  3. *Mid-Century Walnut* (Rich warm woodgrain chassis)
  4. *Raw Brass Patina* (Brushed aged brass bezels)
- **Typography**:
  ```
  FOUR TIMELESS EDITIONS.
  Crafted from modernism's finest palettes.
  ```
- **Audio**: Foley rotary dial clicks (`foley_dial_click.wav`).

### Scene 8: Outro — The Monastic Trinity & Google Play CTA (Frames 1380 – 1560 / 00:46 – 00:52)
- **3D Camera**: Majestic pullback (*dolly out*). Three phones fan out symmetrically in 3D perspective forming **The Monastic Trinity**:
  - Left: *Unit 02 // 5-Task Dispenser*
  - Center: *Unit 01 // Analog Chronometer*
  - Right: *Unit 03 // 33⅓ RPM Turntable*
- **Overlay Elements**: ZYKL wordmark, *"Monastic Pomodoro App for Android"*, Dieter Rams tenet quote *"Weniger, aber besser"*, corner brass rivets, and prominent Google Play Store CTA button.
- **Typography**:
  ```
  Z Y K L
  Monastic Pomodoro App for Android
  GET IT ON GOOGLE PLAY
  One-Time Purchase · Lifetime Access · 0 Subscriptions
  ```
- **Audio**: Rhodes velvet cadence resolution with smooth fade to black.

---

## 6. Implementation Strategy

1. **Install Three.js Packages**:
   Install `three`, `@types/three`, and `@remotion/three` inside `promo/remotion-1x1`.
2. **Build Modular 3D Phone & Studio Components**:
   - `src/components3D/PhoneMesh.tsx`: Procedural 3D titanium smartphone chassis with chamfers, buttons, and screen texture support.
   - `src/components3D/StudioStage.tsx`: Three.js lighting rig, contact shadow receiver, and drafting grid floor.
   - `src/components3D/CameraRig.tsx`: Remotion frame-interpolated 3D camera controller.
3. **Assemble Scene Controllers**:
   Create modular scenes under `src/scenesV3_9x16/` corresponding to the 8 storyboard beats.
4. **Master Composition & Audio Timing**:
   Define `TIMING_V3` in `src/constantsV3.ts` (1,560 frames, 30 FPS).
5. **Fast Preview & Verification**:
   Verify still frames and render full video master to `promo/Video Versi 3/`.
