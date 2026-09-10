# Takt Desk: Vinyl Record Crate & Ambient Sound Gallery Specification

- **Date:** 2026-09-10
- **Platform:** Mobile Android (maxWidth 440px handheld console)
- **Status:** Approved for Implementation
- **Design Philosophy:** Dieter Rams / Braun Modernist Industrial Aesthetic (*Weniger, aber besser*) — Tangible Skeuomorphism, Tactile Record Flipping, and Integrated Freemium Entitlements

---

## 1. Overview & Problem Statement

Currently, the Analog Vinyl Deck (`VinylPlayerWidget`) selects ambient audio via a basic dropdown menu (`DropdownButton<int>`). While functional, it lacks the tactile analog joy of flipping through an authentic collection of physical vinyl records in a record crate. Furthermore, the catalog is restricted to 4 default tracks with no differentiation between standard focus presets and premium Studio Pro atmospheres.

This feature introduces:
1. **The Vinyl Record Crate (`VinylRecordCrateSheet`)**: An industrial slide-up bottom sheet styled with `MaterialChassisBox`, featuring a horizontal carousel of 8 authentic 12-inch style album sleeves (*record jackets*).
2. **Expanded 8-Track Curated Ambient Catalog**: 4 fundamental Free tracks + 4 exclusive Studio Pro atmospheric records, complete with offline looping WAV audio synthesized mathematically with zero external dependencies.
3. **Seamless Freemium Entitlement**: Integration with `ThemeController` / `DeskPreferencesController` (`isProSimulated`) where premium records display a `STUDIO PRO` badge and launch the tactile Studio Pro unlock dialog when tapped.
4. **Physical Tactile Trigger**: Replaces the generic dropdown on the turntable deck with an industrial stamped metal badge: `[ CRATE // 08 DISCS ▾ ]`.

---

## 2. Audio Catalog & Domain Model

### 2.1 Domain Model (`VinylTrack`)
Extend `lib/features/vinyl/domain/vinyl_track.dart`:
```dart
class VinylTrack {
  final int index;
  final String catalogId;       // e.g. 'TK-01'
  final String name;            // e.g. 'Lo-fi Rain'
  final String subtitle;        // e.g. 'Electric Piano & Rain'
  final String description;     // e.g. 'Warm electric piano chord progression with gentle rain shower and vinyl dust crackle.'
  final String labelColorHex;   // e.g. '#C85A32'
  final String assetPath;       // e.g. 'assets/audio/vinyl_lofi_rain.wav'
  final bool isPremium;         // true for Studio Pro exclusive records

  const VinylTrack({
    required this.index,
    required this.catalogId,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.labelColorHex,
    required this.assetPath,
    this.isPremium = false,
  });
}
```

### 2.2 Curated 8-Record Catalog
| Index | Catalog | Name | Subtitle | Label Color | Tier | Description |
|---|---|---|---|---|---|---|
| 0 | `TK-01` | Lo-fi Rain | Electric Piano & Rain | `#C85A32` (Ochre) | FREE | Warm electric piano chords over soft rain showers and subtle vinyl dust. |
| 1 | `TK-02` | Deep Brown Noise | 1/f² Sleep & Focus | `#4D5D4B` (Olive) | FREE | Low-frequency brown noise blanket blocking external room distractions. |
| 2 | `TK-03` | Library Atmosphere | Room Tone & Solitude | `#D99B59` (Amber) | FREE | Reverberant wooden hall tone with gentle page turns and quiet solace. |
| 3 | `TK-04` | Cafe Echo | Porcelain & Murmur | `#2E3238` (Basalt) | FREE | Distant coffeehouse clinks and cozy muffled murmur of morning routines. |
| 4 | `TK-05` | Campfire Embers | Pine Wood & Spark | `#E05A2B` (Hearth) | STUDIO PRO | Warm pine log crackle and embers popping under a calm starlit night sky. |
| 5 | `TK-06` | Forest Canopy | Mountain Pines & Wind | `#3B7A57` (Pine) | STUDIO PRO | Binaural pine breeze with rustling dry leaves and distant timber resonance. |
| 6 | `TK-07` | Cosmic Drift | Analog Synth Drone | `#3A86FF` (Blue) | STUDIO PRO | Deep meditative modular synth harmonics and warm low-frequency planetary hum. |
| 7 | `TK-08` | Midnight Train | Rhythmic Steel Rail | `#6C757D` (Steel) | STUDIO PRO | Steady rhythmic steel-wheel rail cadence and distant nocturne locomotive rumble. |

---

## 3. Procedural Audio Synthesis (`generate_audio.py`)

All 4 new audio tracks are generated at 22,050 Hz 16-bit PCM mono with seamless loop cross-fading, matching the existing audio assets:
1. `vinyl_campfire.wav`: Pink/brown noise base with Poisson-distributed micro-snaps, ember pops, and low-pass resonant rumble.
2. `vinyl_forest.wav`: Multi-band modulated pink noise breeze filtered with resonant pine whispering and soft organic leaf rustling.
3. `vinyl_cosmic.wav`: Detuned dual analog saw/sine oscillators (45Hz root, 90Hz octave, 135Hz fifth) with slow LFO pulse and warm tube distortion.
4. `vinyl_train.wav`: Rhythmic steel track click-clack percussion (120 BPM triplet cadence) with low-frequency carriage chassis rumble.

---

## 4. UI & Interaction Architecture

### 4.1 Turntable Deck Integration (`VinylPlayerWidget`)
- Remove `DropdownButton<int>`.
- Add `_CrateTriggerBadge`:
  - Displays currently equipped track name: `state.currentTrack.name.toUpperCase()` in `chassisTextColor` (or `filamentAmber` when needle is playing).
  - Tactile button: `Container` styled with `themeState.moduleChassisColor`, `Border.all(color: themeState.borderColor)`, and `Text('[ CRATE // 08 DISCS ▾ ]', style: TaktTypography.controlLabel)`.
  - Tapping calls `HapticService.selectionClick()` and opens `VinylRecordCrateSheet.show(context)`.

### 4.2 Vinyl Record Crate Modal (`VinylRecordCrateSheet`)
- Rendered via `showModalBottomSheet`:
  - Dark/Light mode theme awareness (`themeState.canvasColor`, `themeState.moduleChassisColor`, `themeState.borderColor`).
  - Top drag handle and header: `TAKT DESK // ANALOG RECORD CRATE`, counter badge `[ 01 / 08 ]`, and close button `✕`.
  - Carousel: `PageView.builder(itemCount: 8, controller: PageController(viewportFraction: 0.82))`.
  - Each `_RecordSleeveCard`:
    - **Dimensions**: ~240 width x ~300 height.
    - **Outer Sleeve Jacket**:
      - Gradient background corresponding to track mood.
      - Matte cardboard finish with subtle bevel edge and border (`themeState.borderColor`).
      - Catalog stamp: `TK-01` in monospace bold.
      - Mini peeking vinyl disc: Rendered with circular concentric micro-grooves and central label matching `track.labelColor`.
    - **Typography**:
      - Title: `track.name.toUpperCase()` (w700, monospace).
      - Subtitle: `track.subtitle.toUpperCase()` (w500, monospace 9pt).
      - Description: `track.description` (10pt, `chassisMutedTextColor`).
    - **Action Button / Badge**:
      - If active track on turntable: `[ ON PLATTER ]` (lit with `filamentColor`).
      - If unlocked & selectable: `[ LOAD ON PLATTER ]` (equips track, pops sheet, plays foley stylus sound).
      - If locked (`track.isPremium && !isProSimulated`): `[ LOCKED // STUDIO PRO 🔒 ]`. Tapping opens the Studio Pro dialog.

---

## 5. State Management & Entitlements Flow

1. `vinylProvider` (`VinylController`):
   - `selectTrack(int index)` accepts indices 0..7.
   - If `track.isPremium` and `!isProSimulated`, selection is rejected or triggers pro dialog.
2. `audioServiceProvider` (`AudioService`):
   - Maps `trackIndex` 0..7 to respective asset files in Android native or fallback player.
3. Synchronization:
   - When Pro clearance is toggled off in settings, if the active vinyl track is a premium track, it automatically reverts to `Track 0` (*Lo-fi Rain*), exactly matching how `ThemeController` reverts premium hardware editions.

---

## 6. Testing & Quality Gates

1. **Audio File Integrity**:
   - Verify all 8 audio files exist in `assets/audio/` and are registered in `pubspec.yaml`.
2. **Domain & Controller Tests**:
   - Verify all 8 presets exist in `VinylTrack.presets`.
   - Verify premium track selection guards when `isProSimulated == false` vs `true`.
   - Verify revert to track 0 when Pro is revoked while playing a premium track.
3. **Widget Tests**:
   - Verify tapping `_CrateTriggerBadge` opens `VinylRecordCrateSheet`.
   - Verify 8 cards render with sleeve jackets, catalog IDs, and badges.
   - Verify equipping track 4 (Campfire) updates turntable deck and closes sheet.
   - Verify tapping locked track opens Studio Pro dialog.
4. **Quality Gates**:
   - 0 analyzer issues (`flutter analyze`).
   - 100% test pass rate across repository.
