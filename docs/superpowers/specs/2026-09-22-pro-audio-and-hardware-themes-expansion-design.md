# Design Specification: ZYKL 20 Soundscapes & 12 Hardware Editions Expansion

**Date:** 2026-09-22  
**Status:** Approved  
**Author:** AI Agent (Pair Programming with Ricky Prayasa)  
**Target:** ZYKL Android Focus Instrument (`com.zykl.app`)  

---

## 1. Overview & Objectives

To deliver immense value for both Free and Studio PRO users, ZYKL expands its sensory hardware experience across two central pillars:
1. **Vinyl Soundscape Expansion (20 Tracks Total)**:
   - Increasing from 12 tracks (6 per drawer) to **20 tracks (10 per drawer)**.
   - Drawer 1 (`01 · ATMOSPHERES`): 4 Free + 6 PRO authentic acoustic environmental field recordings.
   - Drawer 2 (`02 · HARMONICS`): 4 Free + 6 PRO authentic acoustic studio instrumental master recordings.
   - PRO users receive **12 exclusive tracks** (6 in Drawer 1, 6 in Drawer 2) instead of only 4 previously.
   - Every single track is 100% real physical recording (zero synthetic oscillators, zero AI generation).
2. **Hardware Edition Gallery Expansion (12 Editions Total)**:
   - Expanding from 7 editions to **12 editions**.
   - Free tier receives **4 Free Hardware Editions** (promoting `Bauhaus Heritage` and adding new `Industrial Mono Steel`).
   - PRO tier receives **8 Exclusive Hardware Editions** (adding `Obsidian Ceramic`, `Copper Hearth & Ash`, `British Racing Green`, and `Indigo Astronomical`).

---

## 2. Vinyl Soundscape Architecture (20 Tracks)

### 2.1 Audio Engineering Standards
- **Format**: Linear PCM 16-bit Mono @ 22,050 Hz uncompressed `.wav`.
- **Duration**: Exactly 40.0 seconds per track.
- **Looping Dynamics**: Constant-power equal-energy sinusoidal crossfade (`sin²(t) + cos²(t) = 1`) over a 4.0-second fade window.
- **Loop Seam Continuity**: Sample `num_samples - 1` connects continuously to sample `0` with zero amplitude steps and zero zeroing envelopes, guaranteeing that playback never cuts, clicks, or dips in volume.
- **Total Storage Impact**: 20 files × ~1.7 MB = ~34.4 MB total audio footprint in `assets/audio/`, maintaining APK size below 58 MB.

### 2.2 Track Manifest

#### **Drawer 01: `01 · ATMOSPHERES` (Quiet Nature & Acoustic Environments)**
| Index | Catalog ID | Name | Subtitle | Access | Source & Master Material |
| :---: | :---: | :--- | :--- | :---: | :--- |
| 0 | `TK-01` | **Lo-fi Rain** | *Electric Piano & Rain* | **FREE** | Real precipitation & vinyl dust crackle |
| 1 | `TK-02` | **Deep Brown Noise** | *1/f² Sleep & Focus* | **FREE** | Acoustic 1/f² low-frequency warmth |
| 2 | `TK-03` | **Library Atmosphere** | *Room Tone & Solitude* | **FREE** | TU Delft study hall wooden room tone |
| 3 | `TK-04` | **Kyoto Bamboo Stream** | *Water & Moss Stone* | **FREE** | Shishi-odoshi bamboo fountain stream |
| 4 | `TK-05` | **Campfire Embers** | *Pine Wood & Hearth* | **PRO** | Real crackling pine hearth embers |
| 5 | `TK-06` | **Nordic Pine Whispers** | *High Altitude Breeze* | **PRO** | High-altitude Swedish pine forest wind |
| 6 | `TK-07` | **Alpine Mountain Brook** | *Crystalline Snowmelt* | **PRO** | Okanagan mountain snowmelt stream |
| 7 | `TK-08` | **Pacific Ocean Waves** | *Coastal Tide & Foam* | **PRO** | Real Pacific shoreline ocean wave surge |
| 8 | `TK-09` | **Misty Morning Meadow** | *Dawn Breeze & Birdsong* | **PRO** | Early dawn woodland birdsong & breeze |
| 9 | `TK-10` | **Timber Chamber Hall** | *Acoustic Wood Ambience* | **PRO** | Reverberant wooden acoustic concert chamber |

#### **Drawer 02: `02 · HARMONICS` (Pure Studio Acoustic Instrumental Recordings)**
| Index | Catalog ID | Name | Subtitle | Access | Source & Master Material |
| :---: | :---: | :--- | :--- | :---: | :--- |
| 10 | `TK-11` | **Warm Tape & Felt Piano** | *Analog Tape Saturation* | **FREE** | Felt upright piano on reel-to-reel tape |
| 11 | `TK-12` | **Monastic Cello Solo** | *J.S. Bach · Suite in G* | **FREE** | Cello Suite No. 1 Prelude (John Michel) |
| 12 | `TK-13` | **Tape Acoustic Guitar** | *Tárrega · Recuerdos* | **FREE** | Nylon classical guitar (Carlo Alberto Boni) |
| 13 | `TK-14` | **Debussy Clair de Lune** | *Impressionist Concert Grand* | **FREE** | Claude Debussy · Clair de Lune grand piano |
| 14 | `TK-15` | **Midnight Solitude Piano** | *Erik Satie · Gnossienne 1* | **PRO** | Erik Satie · Gnossienne No. 1 felt piano |
| 15 | `TK-16` | **Zen Bronze Singing Bowl** | *Tibetan Bowls & Bell* | **PRO** | Tibetan singing bowl & bronze temple bell |
| 16 | `TK-17` | **Goldberg Variations Aria** | *J.S. Bach · Bösendorfer* | **PRO** | Kimiko Ishizaka on Bösendorfer Imperial grand |
| 17 | `TK-18` | **Chopin Nocturne Op. 9** | *Frédéric Chopin · Eb Major* | **PRO** | Frank Levy on Steinway concert grand piano |
| 18 | `TK-19` | **Classical Celtic Harp** | *Acoustic Harp Arpeggios* | **PRO** | Authentic acoustic wooden harp performance |
| 19 | `TK-20` | **Chamber String Quartet** | *Adagio String Ensemble* | **PRO** | Acoustic chamber strings (violins, viola, cello) |

### 2.3 Data Structures & Controller Updates
- In `VinylTrack`:
  ```dart
  static final List<VinylTrack> drawer1Presets = presets.sublist(0, 10);
  static final List<VinylTrack> drawer2Presets = presets.sublist(10, 20);
  ```
- In `MainActivity.kt`:
  Update `startAmbient` to map indexes 0..19 to their respective assets, while retaining dynamic `rawAssetPath` fallback.

---

## 3. Hardware Edition Themes Gallery (12 Editions)

### 3.1 Tier Classification
- **FREE Tier (4 Editions)**:
  1. `braunClassic` (MOD. 01 · 1960)
  2. `braunAtelierCream` (MOD. 05 · 1965)
  3. `bauhausHeritage` (MOD. 03 · 1925) - *Promoted to Free*
  4. `industrialMonoSteel` (MOD. 08 · 1980) - *New Free Edition*
- **PRO Tier (8 Editions)**:
  5. `titaniumStealth` (MOD. 02 · 2026)
  6. `rawBrassPatina` (MOD. 04 · 1954)
  7. `midCenturyWalnut` (MOD. 06 · 1958)
  8. `forgedCarbon` (MOD. 07 · 2024)
  9. `obsidianCeramic` (MOD. 09 · 2025) - *New PRO Edition*
  10. `copperHearthAsh` (MOD. 10 · 1968) - *New PRO Edition*
  11. `britishRacingGreen` (MOD. 11 · 1962) - *New PRO Edition*
  12. `indigoAstronomical` (MOD. 12 · 1974) - *New PRO Edition*

### 3.2 Visual Token Specification for New Editions

1. **`industrialMonoSteel` (FREE)**:
   - **Chassis/Canvas**: Dark `#141517` / Light `#D8DADC`
   - **Module**: Dark `#1C1E22` / Light `#C8CBD0`
   - **Borders**: Dark `#3E424A` (Galvanized Steel) / Light `#9AA0AA`
   - **Needle**: `#E2E4E8` (Tungsten Silver)
   - **Filament**: `#B0B4BC` (Cool Halogen)
   - **Rivets**: `#2A2D34` / `#8A8E98`

2. **`obsidianCeramic` (PRO)**:
   - **Chassis/Canvas**: Dark `#0A0A0C` (Mirror Obsidian) / Light `#E8E9EC`
   - **Module**: Dark `#101114` / Light `#D4D6DC`
   - **Borders**: Dark `#22242B` / Light `#9497A2`
   - **Needle**: `#FF9E00` (Intense Filament Amber)
   - **Filament**: `#FFB703` (Golden Glow)
   - **Rivets**: `#181A20` / `#747784`

3. **`copperHearthAsh` (PRO)**:
   - **Chassis/Canvas**: Dark `#181311` / Light `#EFEAE5`
   - **Module**: Dark `#221A17` / Light `#DFD7D0`
   - **Borders**: Dark `#663B2A` (Brushed Rose Copper) / Light `#B88B77`
   - **Needle**: `#D86D47` (Burnished Terracotta)
   - **Filament**: `#E88C60` (Hearth Ember Glow)
   - **Rivets**: `#8A4A32` / `#A8634A`

4. **`britishRacingGreen` (PRO)**:
   - **Chassis/Canvas**: Dark `#0D1612` / Light `#E2EAE5`
   - **Module**: Dark `#13201A` / Light `#D0DDD6`
   - **Borders**: Dark `#2D483A` (Deep Moss Spruce) / Light `#8CA899`
   - **Needle**: `#F4D06F` (Vintage Champagne Gold)
   - **Filament**: `#F3B61F` (Warm Sunlit Gold)
   - **Rivets**: `#C89B3C` (Raw Brass Rivet) / `#A8812E`

5. **`indigoAstronomical` (PRO)**:
   - **Chassis/Canvas**: Dark `#0C101A` / Light `#DCE2EE`
   - **Module**: Dark `#121827` / Light `#CAD3E5`
   - **Borders**: Dark `#2B3856` (Deep Sea Navy Anodized) / Light `#8696BD`
   - **Needle**: `#4CC9F0` (Stellar Cyan Needle)
   - **Filament**: `#7209B7` / `#4361EE` (Deep Horizon Glow)
   - **Rivets**: `#1C253B` / `#7081A8`

---

## 4. UI & Interaction Integration

1. **ChronoDialWidget**:
   - Update switch case for all 12 editions to render their calibrated dial faces in both Dark and Light modes.
2. **Settings Carousel (`_HardwareEditionsSection`)**:
   - Carousel counter will dynamically render `[ 01 / 12 ]` through `[ 12 / 12 ]`.
   - Free editions are selectable without Pro Clearance; Pro editions display the lock pill and route to `showStudioProDialog`.
3. **Vinyl Disc Drawer (`VinylDiscDrawerWidget`)**:
   - The horizontal album sleeve carousel smoothly accommodates all 10 tracks per drawer with snappy paging and lock indicators on tracks 4..9 in Drawer 1 and 14..19 in Drawer 2.

---

## 5. Verification Plan

1. **Unit & Widget Tests**:
   - Verify `VinylTrack.presets.length == 20`.
   - Verify `VinylTrack.drawer1Presets.length == 10` and `VinylTrack.drawer2Presets.length == 10`.
   - Verify all 20 WAV files exist on disk with valid headers and length > 10,000 bytes.
   - Verify `HardwareEdition.all.length == 12` with exactly 4 Free and 8 PRO editions.
   - Run `flutter test` and confirm all tests pass.
   - Run `flutter analyze` with 0 diagnostics.
2. **Build Verification**:
   - Recompile `zykl-developer-pro.apk`.
   - Recompile `zykl-user-testing.apk`.
   - Recompile `zykl-playstore-release.aab`.
