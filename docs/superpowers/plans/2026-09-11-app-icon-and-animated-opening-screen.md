# Official App Icon, RSQUARE Logo Asset Bundling & Animated Horological Opening Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create official Android launcher icons from the circular Braun Pomodoro dial, bundle and register the official `RSQUARE.png` brand logo in Flutter assets, build an authentic 2.4s procedural vector horological boot sequence (`TaktOpeningScreen`) with tap-to-skip, integrate the RSQUARE logo into the settings and pro dialogs, and wire the opening screen into `main.dart`.

**Architecture:** Convert `/home/tuneeca/RSQUARE/takt_desk_icon_round.jpg` to Android mipmap density buckets. Bundle `RSQUARE.png` to `assets/images/rsquare_logo.png` and expose via `pubspec.yaml`. Create a dedicated `lib/features/opening/presentation/takt_opening_screen.dart` with a multi-phase procedural vector canvas animation (Power Ignition -> Dial Expansion -> Needle 360° Sweep -> RSQUARE & Brand Lockup -> Seamless Handover) equipped with tap-to-skip. Mount `TaktOpeningScreen` as initial home in `lib/main.dart`.

**Tech Stack:** Flutter 3.x, Dart, Riverpod, CustomPainter, AnimationController, Android Resource Mipmaps, Drift.

## Global Constraints
- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetic (honest materials, uncluttered typography, amber `#FF9E00` accent, matte `#121316` deep chassis).
- Clean namespace: Absolutely 0 occurrences of `tuneeca` across Kotlin, Dart, XML, and Gradle files (`com.takt.desk`).
- Zero video/Lottie dependencies: 100% Native Flutter Canvas & Curves for the opening animation to guarantee 60-120 FPS and zero background battery drain.
- 0 analyzer issues (`/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`).
- 100% test pass rate across repository (`/home/tuneeca/RSQUARE/flutter/bin/flutter test`).
- Frictionless UX: `TaktOpeningScreen` MUST support instant tap-to-skip so user work sessions are never hindered.

---

### Task 1: Android Launcher Icon Generation & Packaging

**Files:**
- Source: `/home/tuneeca/RSQUARE/takt_desk_icon_round.jpg`
- Generate:
  - `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48)
  - `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72)
  - `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96)
  - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144)
  - `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192x192)
  - `android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png` (48x48)
  - `android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png` (72x72)
  - `android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png` (96x96)
  - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png` (144x144)
  - `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png` (192x192)

**Interfaces:**
- Produces: Official Android app launcher icon resources for standard and round launchers.

- [ ] **Step 1: Generate all mipmap PNG sizes using Python PIL from `/home/tuneeca/RSQUARE/takt_desk_icon_round.jpg`**

Run a python script to crop and resize the high-resolution circular dial graphic with high-quality Lanczos resampling:
```bash
python3 - << 'EOF'
from PIL import Image
import os

src_path = "/home/tuneeca/RSQUARE/takt_desk_icon_round.jpg"
im = Image.open(src_path).convert("RGBA")

# Ensure 1:1 square crop
w, h = im.size
min_dim = min(w, h)
left = (w - min_dim) // 2
top = (h - min_dim) // 2
im_cropped = im.crop((left, top, left + min_dim, top + min_dim))

sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

base_res = "android/app/src/main/res"
for folder, size in sizes.items():
    dest_dir = os.path.join(base_res, folder)
    os.makedirs(dest_dir, exist_ok=True)
    resized = im_cropped.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(os.path.join(dest_dir, "ic_launcher.png"), "PNG")
    resized.save(os.path.join(dest_dir, "ic_launcher_round.png"), "PNG")
    print(f"Generated {folder}: {size}x{size}")
EOF
```

- [ ] **Step 2: Verify all mipmap files exist and match dimensions**

```bash
file android/app/src/main/res/mipmap-*/ic_launcher.png
file android/app/src/main/res/mipmap-*/ic_launcher_round.png
```

- [ ] **Step 3: Run Flutter analyze to verify no manifest issues**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter analyze
```

- [ ] **Step 4: Commit launcher icon assets**

```bash
git add android/app/src/main/res/mipmap-*/ic_launcher*.png
git commit -m "feat(android): install official circular Braun Pomodoro launcher icons across all mipmap densities"
```

---

### Task 2: RSQUARE Logo Asset Registration & Dialog Branding Integration

**Files:**
- Source: `/home/tuneeca/RSQUARE/Android/Takt Desk/RSQUARE.png`
- Create: `assets/images/rsquare_logo.png`
- Modify: `pubspec.yaml:60-70`
- Modify: `lib/features/settings/presentation/takt_settings_sheet.dart:525-550`
- Modify: `lib/features/settings/presentation/widgets/studio_pro_dialog.dart:50-70`
- Modify: `test/features/settings/takt_settings_sheet_test.dart`
- Modify: `test/features/settings/studio_pro_dialog_test.dart`

**Interfaces:**
- Produces:
  - Bundled asset `assets/images/rsquare_logo.png`
  - High-DPI RSQUARE visual emblem rendered in `TaktSettingsSheet` Creed Section
  - RSQUARE visual emblem rendered in `StudioProDialog` title header

- [ ] **Step 1: Write failing widget test asserting RSQUARE logo image asset in settings and pro dialog**

`test/features/settings/takt_settings_sheet_test.dart`:
```dart
testWidgets('Braun creed section displays RSQUARE logo image asset', (tester) async {
  await tester.pumpWidget(buildSheet());
  await tester.pump();

  final logoFinder = find.byWidgetPredicate(
    (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/rsquare_logo.png',
  );
  expect(logoFinder, findsOneWidget);
});
```

`test/features/settings/studio_pro_dialog_test.dart`:
```dart
testWidgets('showStudioProDialog renders RSQUARE logo image asset in title header', (tester) async {
  // pump dialog ...
  final logoFinder = find.byWidgetPredicate(
    (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/rsquare_logo.png',
  );
  expect(logoFinder, findsOneWidget);
});
```

- [ ] **Step 2: Run tests and verify failure (RED)**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/settings/studio_pro_dialog_test.dart
```

- [ ] **Step 3: Copy `RSQUARE.png` to `assets/images/rsquare_logo.png` and update `pubspec.yaml`**

```bash
mkdir -p assets/images
cp RSQUARE.png assets/images/rsquare_logo.png
```

Update `pubspec.yaml`:
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/rsquare_logo.png
```

- [ ] **Step 4: Update `lib/features/settings/presentation/takt_settings_sheet.dart`**

Add the RSQUARE logo above the version text in the Creed section:
```dart
Container(
  width: 38,
  height: 38,
  margin: const EdgeInsets.only(bottom: 8),
  decoration: BoxDecoration(
    color: Colors.black.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: TaktColors.filamentAmber.withValues(alpha: 0.4),
      width: 1.0,
    ),
  ),
  padding: const EdgeInsets.all(4),
  child: Image.asset(
    'assets/images/rsquare_logo.png',
    fit: BoxFit.contain,
  ),
),
```

- [ ] **Step 5: Update `lib/features/settings/presentation/widgets/studio_pro_dialog.dart`**

In the title Row:
```dart
title: Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      'TAKT DESK STUDIO PRO',
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: primary,
      ),
    ),
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/rsquare_logo.png',
          width: 18,
          height: 18,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 5),
        const Text(
          'RSQUARE',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: TaktColors.filamentAmber,
          ),
        ),
      ],
    ),
  ],
),
```

- [ ] **Step 6: Run tests and verify PASS (GREEN)**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/settings/takt_settings_sheet_test.dart test/features/settings/studio_pro_dialog_test.dart
```

- [ ] **Step 7: Commit changes**

```bash
git add pubspec.yaml assets/images/rsquare_logo.png lib/features/settings/ test/features/settings/
git commit -m "feat(branding): bundle RSQUARE logo asset and integrate into settings and studio pro dialogs"
```

---

### Task 3: Procedural Vector Opening Screen (`TaktOpeningScreen`) & Components

**Files:**
- Create: `lib/features/opening/presentation/takt_opening_screen.dart`
- Create: `test/features/opening/takt_opening_screen_test.dart`

**Interfaces:**
- Produces:
  - `TaktOpeningScreen` widget with 2.4s multi-phase animated horological calibration sequence and tap-to-skip.
  - Parameter `VoidCallback? onComplete` or navigation replacement to `DeskCanvasScreen`.

- [ ] **Step 1: Write failing widget tests in `test/features/opening/takt_opening_screen_test.dart`**

Test scenarios:
1. `TaktOpeningScreen renders initial ignition phase with micro-LED and RSQUARE branding`
2. `TaktOpeningScreen tap-to-skip immediately invokes navigation to DeskCanvasScreen`
3. `TaktOpeningScreen automatically navigates to DeskCanvasScreen upon animation completion`
4. `TaktOpeningScreen disposes AnimationController cleanly without exceptions`

- [ ] **Step 2: Run test to confirm failure (RED)**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/opening/takt_opening_screen_test.dart
```

- [ ] **Step 3: Implement `lib/features/opening/presentation/takt_opening_screen.dart`**

Features:
- Single `AnimationController` with duration 2400ms.
- Curved sub-intervals:
  - `ledGlowAnimation`: 0.0 -> 0.20 (0 - 480ms), `Curves.easeIn`
  - `dialExpandAnimation`: 0.15 -> 0.45 (360ms - 1080ms), `Curves.easeOutBack`
  - `needleSweepAnimation`: 0.40 -> 0.80 (960ms - 1920ms), `Curves.easeInOutCubic` (sweeps 0 to 2*pi radians)
  - `textRevealAnimation`: 0.70 -> 0.95 (1680ms - 2280ms), `Curves.easeOut`
- Dial canvas painter rendering the circular bezel, ticks, and sweeping amber needle.
- Lower section rendering `RSQUARE.png` emblem with monospace label `ENGINEERED BY RSQUARE`.
- Header / footer with subtle `[ TAP ANYWHERE TO SKIP ]` hint or tap anywhere handler.
- Audio and haptics triggered at calibration points.
- On complete or on tap, navigates via `Navigator.of(context).pushReplacement(PageRouteBuilder(... DeskCanvasScreen ...))`.

- [ ] **Step 4: Run test to confirm PASS (GREEN)**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/opening/takt_opening_screen_test.dart
```

- [ ] **Step 5: Run static analysis**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter analyze
```

- [ ] **Step 6: Commit changes**

```bash
git add lib/features/opening/ test/features/opening/
git commit -m "feat(opening): implement procedural vector TaktOpeningScreen with 360 needle sweep and tap-to-skip"
```

---

### Task 4: Root Application Wiring (`main.dart`) & End-to-End Verification

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `TaktOpeningScreen`
- Produces: App launches directly into `TaktOpeningScreen` before navigating to `DeskCanvasScreen`.

- [ ] **Step 1: Write/update root widget test**

`test/widget_test.dart`:
Verify that `TaktDeskApp` mounts `TaktOpeningScreen` initially, and that pumping settles into `DeskCanvasScreen`.

- [ ] **Step 2: Update `lib/main.dart`**

```dart
home: const TaktOpeningScreen(),
```

- [ ] **Step 3: Run full test suite across entire repository**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test
```
Verify 100% pass rate across all tests.

- [ ] **Step 4: Run static analysis**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter analyze
```
Verify 0 issues found.

- [ ] **Step 5: Check namespace hygiene**

```bash
git grep -i "tuneeca" lib/ test/ android/app/src/
```
Verify 0 occurrences found.

- [ ] **Step 6: Commit changes**

```bash
git commit -am "feat(app): wire TaktOpeningScreen as initial route in main.dart"
```

- [ ] **Step 7: Push to `origin/main`**

```bash
git push origin main
```
