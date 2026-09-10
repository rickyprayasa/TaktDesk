# Vinyl Record Crate & Ambient Sound Gallery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Analog Vinyl Deck from a plain dropdown track selector into a tactile, skeuomorphic "Vinyl Record Crate" (`VinylRecordCrateSheet`) with 8 curated ambient records (4 Free + 4 Studio Pro exclusive), complete with procedural offline audio synthesis, flipping 12-inch record jackets, and integrated Freemium entitlements.

**Architecture:** 
1. Synthesize 4 new seamless looping WAV audio tracks using Python mathematical procedural filters (`vinyl_campfire.wav`, `vinyl_forest.wav`, `vinyl_cosmic.wav`, `vinyl_train.wav`).
2. Extend `VinylTrack` with `catalogId`, `subtitle`, `description`, and `isPremium`, updating `MainActivity.kt` and `VinylController` with entitlement guards.
3. Build `VinylRecordCrateSheet` with a snapping horizontal carousel of 8 album sleeves, peeking miniature vinyl discs, and tactile load/locked actions.
4. Replace the generic dropdown in `VinylPlayerWidget` with an industrial stamped metal trigger badge `[ CRATE // 08 DISCS ▾ ]`, and wire `DeskPreferencesController` to revert premium tracks when Pro clearance is revoked.

**Tech Stack:** Flutter 3.x, Dart 3.x, Riverpod, Kotlin / Android MediaPlayer, CustomPainter.

---

## Global Constraints

- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetic (*Weniger, aber besser*).
- Target platform: Mobile Android handheld console (maxWidth 440px).
- 0 analyzer issues (`/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`).
- 100% test pass rate across repository.
- Avoid external internet audio streaming; all audio tracks must be offline, seamless looping WAV assets synthesized mathematically.

---

### Task 1: Procedural Audio Generation, 8-Track Domain Model & Native Audio Mapping

**Files:**
- Create/Run: `scripts/generate_vinyl_audio.py`
- Modify: `lib/features/vinyl/domain/vinyl_track.dart`
- Modify: `lib/features/vinyl/presentation/vinyl_controller.dart`
- Modify: `android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt`
- Modify: `test/features/vinyl/vinyl_controller_test.dart`

**Interfaces:**
- Consumes: `AudioService`, `VinylTrack.presets`.
- Produces:
  - 8 audio assets in `assets/audio/`: `vinyl_lofi_rain.wav`, `vinyl_brown_noise.wav`, `vinyl_library.wav`, `vinyl_cafe.wav`, `vinyl_campfire.wav`, `vinyl_forest.wav`, `vinyl_cosmic.wav`, `vinyl_train.wav`.
  - `VinylTrack` fields: `index`, `catalogId`, `name`, `subtitle`, `description`, `labelColorHex`, `assetPath`, `isPremium`.
  - `VinylController.selectTrack(int index, {bool isPro = false})`: guards premium selection.
  - `MainActivity.kt`: handles `startAmbient` indices 0..7.

- [ ] **Step 1: Write the failing test**

In `test/features/vinyl/vinyl_controller_test.dart`:
- Assert `VinylTrack.presets.length == 8`.
- Assert tracks 0..3 have `isPremium == false` and tracks 4..7 have `isPremium == true`.
- Assert each track has non-empty `catalogId`, `subtitle`, `description`, `labelColorHex`, and `assetPath`.
- Assert `VinylController.selectTrack(4, isPro: false)` returns `false` and leaves `selectedTrackIndex` at `0`.
- Assert `VinylController.selectTrack(4, isPro: true)` returns `true` and updates `selectedTrackIndex` to `4`.
- Assert `VinylController.revertIfProRevoked()` reverts index to `0` if currently on a premium track (index >= 4).

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/vinyl_controller_test.dart`
Expected: FAIL.

- [ ] **Step 3: Generate audio files and implement domain & controller**

1. Create and execute `scripts/generate_vinyl_audio.py`:
   Generate:
   - `assets/audio/vinyl_campfire.wav` (16s looping crackling hearth)
   - `assets/audio/vinyl_forest.wav` (16s looping pine breeze and leaves)
   - `assets/audio/vinyl_cosmic.wav` (16s looping analog synth drone)
   - `assets/audio/vinyl_train.wav` (16s looping rhythmic steel rail)
2. Update `lib/features/vinyl/domain/vinyl_track.dart`:
   Add `catalogId`, `subtitle`, `description`, `assetPath`, `isPremium`.
   Populate all 8 tracks as defined in spec.
3. Update `lib/features/vinyl/presentation/vinyl_controller.dart`:
   Add `selectTrack(int index, {bool isPro = false})` returning `bool`.
   Add `revertIfProRevoked()`.
4. Update `android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt`:
   Add branches for indices 4..7 in `startAmbient`.

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/vinyl_controller_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/generate_vinyl_audio.py assets/audio/ lib/features/vinyl/domain/vinyl_track.dart lib/features/vinyl/presentation/vinyl_controller.dart android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt test/features/vinyl/vinyl_controller_test.dart
git commit -m "feat(vinyl): expand curated ambient catalog to 8 tracks with Freemium entitlements and procedural audio"
```

---

### Task 2: Tactile Vinyl Record Crate Modal (`VinylRecordCrateSheet`)

**Files:**
- Create: `lib/features/vinyl/presentation/widgets/vinyl_record_crate_sheet.dart`
- Create: `test/features/vinyl/vinyl_record_crate_sheet_test.dart`

**Interfaces:**
- Consumes: `VinylTrack.presets`, `vinylProvider`, `deskPreferencesControllerProvider`, `chassisThemeProvider`.
- Produces:
  - `VinylRecordCrateSheet`: Industrial modal bottom sheet containing 8-card horizontal carousel with miniature peeking vinyl discs, sleeve jackets, catalog IDs, and tactile status buttons (`[ ON PLATTER ]`, `[ LOAD ON PLATTER ]`, `[ LOCKED // STUDIO PRO 🔒 ]`).
  - Helper `VinylRecordCrateSheet.show(BuildContext context)`.

- [ ] **Step 1: Write the failing test**

In `test/features/vinyl/vinyl_record_crate_sheet_test.dart`:
- Test that opening `VinylRecordCrateSheet` displays header `TAKT DESK // ANALOG RECORD CRATE` and counter `[ 01 / 08 ]`.
- Test that 8 record sleeve cards exist with keys `record_sleeve_0` through `record_sleeve_7`.
- Test that Track 0 shows `[ ON PLATTER ]`.
- Test that tapping `record_sleeve_1` calls `controller.selectTrack(1)` and pops the sheet.
- Test that Track 4 (Campfire) displays `STUDIO PRO` badge when `isProSimulated == false`.
- Test that tapping locked track opens the Studio Pro dialog.
- Test that when `isProSimulated == true`, Track 4 displays `[ LOAD ON PLATTER ]` and tapping it equips the track.

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/vinyl_record_crate_sheet_test.dart`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

Implement `lib/features/vinyl/presentation/widgets/vinyl_record_crate_sheet.dart`:
- Modal bottom sheet with dark/light theme awareness (`themeState.canvasColor`, `themeState.moduleChassisColor`, `themeState.borderColor`).
- Industrial drag handle and header bar with close button `✕`.
- Horizontal snapping `PageView.builder` with `viewportFraction: 0.82`.
- `_RecordSleeveCard`:
  - Key: `ValueKey('record_sleeve_${track.index}')`
  - Sleeve jacket container styled with mood gradient and micro-beveled border.
  - Peeking miniature vinyl disc with circular grooves and central label in `track.labelColor`.
  - Catalog badge `track.catalogId` (e.g. `TK-01`).
  - Title, subtitle, description in high-contrast monospace typography.
  - Action button:
    - If `isActive`: `[ ON PLATTER ]` (active accent glow).
    - If `isUnlocked`: `[ LOAD ON PLATTER ]` (`ValueKey('load_track_button_${track.index}')`). Tapping calls `selectTrack`, plays stylus foley, and pops dialog.
    - If `isLocked`: `[ LOCKED // STUDIO PRO 🔒 ]` (`ValueKey('locked_track_button_${track.index}')`). Tapping calls existing Studio Pro dialog.

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/vinyl_record_crate_sheet_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/vinyl/presentation/widgets/vinyl_record_crate_sheet.dart test/features/vinyl/vinyl_record_crate_sheet_test.dart
git commit -m "feat(vinyl): create tactile VinylRecordCrateSheet with flipping album sleeves and Studio Pro gating"
```

---

### Task 3: Turntable Deck Integration & Pro Revocation Synchronization

**Files:**
- Modify: `lib/features/vinyl/presentation/vinyl_player_widget.dart`
- Modify: `lib/features/settings/presentation/settings_controller.dart`
- Modify: `test/features/vinyl/vinyl_player_widget_test.dart`
- Modify: `test/features/settings/settings_controller_test.dart`

**Interfaces:**
- Consumes: `VinylRecordCrateSheet`, `DeskPreferencesController.setProSimulated`.
- Produces:
  - Replaces `DropdownButton<int>` on the turntable deck with `_CrateTriggerBadge` (`ValueKey('vinyl_crate_trigger_button')`).
  - Automatically reverts premium vinyl tracks to Track 0 (*Lo-fi Rain*) when Studio Pro clearance is revoked in settings.

- [ ] **Step 1: Write the failing test**

In `test/features/vinyl/vinyl_player_widget_test.dart`:
- Assert `DropdownButton` is no longer in the widget tree.
- Assert `_CrateTriggerBadge` with key `ValueKey('vinyl_crate_trigger_button')` is present.
- Assert tapping `vinyl_crate_trigger_button` opens `VinylRecordCrateSheet`.
In `test/features/settings/settings_controller_test.dart`:
- Assert that when `selectedTrackIndex == 4` (Campfire Embers) and `setProSimulated(false)` is called, `VinylController.revertIfProRevoked()` reverts track index to `0`.

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/vinyl_player_widget_test.dart test/features/settings/settings_controller_test.dart`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

1. In `lib/features/vinyl/presentation/vinyl_player_widget.dart`:
   - Remove `DropdownButton<int>`.
   - Add `_CrateTriggerBadge`:
     - Container styled with `themeState.moduleChassisColor`, `Border.all(color: themeState.borderColor, width: 1.0)`, and padding.
     - Text `[ CRATE // 08 DISCS ▾ ]` with `TaktTypography.controlLabel.copyWith(color: themeState.chassisTextColor, fontSize: 9)`.
     - Tapping calls `HapticService.selectionClick()` and `VinylRecordCrateSheet.show(context)`.
2. In `lib/features/settings/presentation/settings_controller.dart`:
   - Inject `VinylController` or call `ref.read(vinylProvider.notifier).revertIfProRevoked()` when `setProSimulated(false)` is executed.

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/vinyl_player_widget_test.dart test/features/settings/settings_controller_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/vinyl/presentation/vinyl_player_widget.dart lib/features/settings/presentation/settings_controller.dart test/features/vinyl/vinyl_player_widget_test.dart test/features/settings/settings_controller_test.dart
git commit -m "feat(vinyl): wire tactile crate trigger on turntable deck and sync Pro revocation revert"
```

---

### Task 4: End-to-End Verification & Whole-Branch Quality Gate

**Files:**
- Full test suites and static analyzer.

- [ ] **Step 1: Run full test suite**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test`
Expected: 100% tests passing across all suites.

- [ ] **Step 2: Run static code analysis**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`
Expected: 0 issues found.

- [ ] **Step 3: Whole-branch review & Push to GitHub**

Review diff package and push to `origin/main`.
