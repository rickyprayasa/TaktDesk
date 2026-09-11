# Extended Hardware Editions & Procedural Textures Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand Takt Desk hardware editions to 7 curated finishes (adding Free `Braun Atelier Cream`, Pro `Mid-Century Dark Walnut`, and Pro `Forged Carbon Horology`), implement authentic procedural wood grain and forged carbon shaders, and build an interactive Live Theme Preview with horological showcase plaque for Free users.

**Architecture:** Extend `HardwareEdition` model with 3 new curated editions and `HardwareTextureType` with `organicWalnut` and `forgedCarbon`. Implement mathematical vector canvas shaders in `MaterialTexturePainter` and `ChronoDialPainter`. Enhance `studio_pro_dialog.dart` with a physical showcase plaque rendering real textures and needle accents, and update `takt_settings_sheet.dart` carousel.

**Tech Stack:** Flutter 3.x, Dart, Riverpod, Drift (SQLite), CustomPainter, Vector Canvas Shaders.

## Global Constraints
- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetic (honest materials, uncluttered typography, amber `#FF9E00` accent, matte `#141414` chassis).
- Clean namespace: Absolutely 0 occurrences of `tuneeca` across Kotlin, Dart, XML, and Gradle files (`com.takt.desk`).
- Zero raster asset bloat: All textures procedural vector canvas shaders; zero external PNG/WebP texture files.
- 0 analyzer issues (`/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`).
- 100% test pass rate across repository (`/home/tuneeca/RSQUARE/flutter/bin/flutter test`).
- Free accessibility: `braunClassic` and `braunAtelierCream` must have `isPremium == false` and be directly equipable without Pro clearance.

---

### Task 1: Domain Model & Catalog Expansion (`HardwareEdition` & `HardwareTextureType`)

**Files:**
- Modify: `lib/app/theme/hardware_edition.dart`
- Create: `test/app/theme/hardware_edition_test.dart`

**Interfaces:**
- Produces:
  - `HardwareTextureType.organicWalnut`, `HardwareTextureType.forgedCarbon`
  - `HardwareEditionType.braunAtelierCream`, `HardwareEditionType.midCenturyWalnut`, `HardwareEditionType.forgedCarbon`
  - `HardwareEdition.braunAtelierCream`, `HardwareEdition.midCenturyWalnut`, `HardwareEdition.forgedCarbon`
  - `HardwareEdition.all` with exactly 7 entries (2 Free, 5 Pro)

- [ ] **Step 1: Write failing unit test for 7 hardware editions**

`test/app/theme/hardware_edition_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';

void main() {
  group('HardwareEdition Catalog', () {
    test('catalog contains exactly 7 curated editions', () {
      expect(HardwareEdition.all.length, equals(7));
    });

    test('free editions are braunClassic and braunAtelierCream', () {
      final freeEditions = HardwareEdition.all.where((e) => !e.isPremium).toList();
      expect(freeEditions.length, equals(2));
      expect(freeEditions.map((e) => e.type), containsAll([
        HardwareEditionType.braunClassic,
        HardwareEditionType.braunAtelierCream,
      ]));
    });

    test('pro editions are titaniumStealth, bauhausHeritage, rawBrassPatina, midCenturyWalnut, and forgedCarbon', () {
      final proEditions = HardwareEdition.all.where((e) => e.isPremium).toList();
      expect(proEditions.length, equals(5));
      expect(proEditions.map((e) => e.type), containsAll([
        HardwareEditionType.titaniumStealth,
        HardwareEditionType.bauhausHeritage,
        HardwareEditionType.rawBrassPatina,
        HardwareEditionType.midCenturyWalnut,
        HardwareEditionType.forgedCarbon,
      ]));
    });

    test('fromType resolves all 7 editions correctly', () {
      for (final type in HardwareEditionType.values) {
        final edition = HardwareEdition.fromType(type);
        expect(edition.type, equals(type));
        expect(edition.title, isNotEmpty);
        expect(edition.plateGradientDark.length, greaterThanOrEqualTo(2));
        expect(edition.plateGradientLight.length, greaterThanOrEqualTo(2));
      }
    });

    test('fromString safely resolves known keys and defaults unknown to braunClassic', () {
      expect(HardwareEdition.fromString('braunAtelierCream').type, equals(HardwareEditionType.braunAtelierCream));
      expect(HardwareEdition.fromString('midCenturyWalnut').type, equals(HardwareEditionType.midCenturyWalnut));
      expect(HardwareEdition.fromString('forgedCarbon').type, equals(HardwareEditionType.forgedCarbon));
      expect(HardwareEdition.fromString('unknown_key').type, equals(HardwareEditionType.braunClassic));
      expect(HardwareEdition.fromString(null).type, equals(HardwareEditionType.braunClassic));
    });

    test('texture types are correctly assigned', () {
      expect(HardwareEdition.midCenturyWalnut.textureType, equals(HardwareTextureType.organicWalnut));
      expect(HardwareEdition.forgedCarbon.textureType, equals(HardwareTextureType.forgedCarbon));
      expect(HardwareEdition.braunAtelierCream.textureType, equals(HardwareTextureType.matteAbsGrain));
    });
  });
}
```

- [ ] **Step 2: Run test to confirm failure**

Run:
```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/app/theme/hardware_edition_test.dart
```
Expected: FAIL with compilation errors (missing enum values).

- [ ] **Step 3: Update `lib/app/theme/hardware_edition.dart`**

Update `HardwareTextureType`:
```dart
enum HardwareTextureType {
  matteAbsGrain,
  brushedTitanium,
  tubularChrome,
  burnishedBrass,
  organicWalnut,
  forgedCarbon,
}
```

Update `HardwareEditionType`:
```dart
enum HardwareEditionType {
  braunClassic,
  braunAtelierCream,
  titaniumStealth,
  bauhausHeritage,
  rawBrassPatina,
  midCenturyWalnut,
  forgedCarbon,
}
```

Add constants in `HardwareEdition`:
```dart
  static const HardwareEdition braunAtelierCream = HardwareEdition(
    type: HardwareEditionType.braunAtelierCream,
    textureType: HardwareTextureType.matteAbsGrain,
    title: 'BRAUN ATELIER CREAM',
    subtitle: 'WARM BONE & SIGNAL ORANGE',
    yearLabel: 'MOD. 05 · 1965',
    isPremium: false,
    darkCanvas: Color(0xFF242321),
    lightCanvas: Color(0xFFEAE6DC),
    darkModuleBg: Color(0xFF1E1D1B),
    lightModuleBg: Color(0xFFDDD9CE),
    darkBorder: Color(0xFF3A3835),
    lightBorder: Color(0xFFBDB8AB),
    needleColor: Color(0xFFFF5500), // Braun Signal Orange
    filamentColor: Color(0xFFFFB703), // Warm Amber Glow
    accentColor: Color(0xFF4A5568),
    plateGradientDark: [Color(0xFF2C2A27), Color(0xFF211F1D), Color(0xFF181716)],
    plateGradientLight: [Color(0xFFF4F1EA), Color(0xFFEAE6DC), Color(0xFFDFDBD0)],
    rivetDark: Color(0xFF4D4944),
    rivetLight: Color(0xFFA8A398),
  );

  static const HardwareEdition midCenturyWalnut = HardwareEdition(
    type: HardwareEditionType.midCenturyWalnut,
    textureType: HardwareTextureType.organicWalnut,
    title: 'MID-CENTURY WALNUT',
    subtitle: 'NATURAL TIMBER & SATIN GOLD',
    yearLabel: 'MOD. 06 · 1958',
    isPremium: true,
    darkCanvas: Color(0xFF1C140E),
    lightCanvas: Color(0xFF8D5B3A),
    darkModuleBg: Color(0xFF16100B),
    lightModuleBg: Color(0xFF73472A),
    darkBorder: Color(0xFF4A3525),
    lightBorder: Color(0xFFB07C54),
    needleColor: Color(0xFFF3C68F), // Champagne Gold
    filamentColor: Color(0xFFFF9233), // Warm Hearthfire Glow
    accentColor: Color(0xFF5E4028),
    plateGradientDark: [Color(0xFF2E2218), Color(0xFF221811), Color(0xFF18100A)],
    plateGradientLight: [Color(0xFFA8734C), Color(0xFF8D5B3A), Color(0xFF6E4426)],
    rivetDark: Color(0xFFC99A40), // Satin Brass Rivet
    rivetLight: Color(0xFFE0B858),
  );

  static const HardwareEdition forgedCarbon = HardwareEdition(
    type: HardwareEditionType.forgedCarbon,
    textureType: HardwareTextureType.forgedCarbon,
    title: 'FORGED CARBON',
    subtitle: 'COMPOSITE MARBLE & AMBER',
    yearLabel: 'MOD. 07 · 2024',
    isPremium: true,
    darkCanvas: Color(0xFF0F1012),
    lightCanvas: Color(0xFF4A4D55),
    darkModuleBg: Color(0xFF15161A),
    lightModuleBg: Color(0xFF3A3D44),
    darkBorder: Color(0xFF2D3039),
    lightBorder: Color(0xFF636773),
    needleColor: Color(0xFFFF3B00), // Electric Racing Amber
    filamentColor: Color(0xFFFFAA00), // Phosphor Neon Amber
    accentColor: Color(0xFF00B4D8),
    plateGradientDark: [Color(0xFF1E2025), Color(0xFF141518), Color(0xFF0B0C0E)],
    plateGradientLight: [Color(0xFF6B707B), Color(0xFF535760), Color(0xFF3E4148)],
    rivetDark: Color(0xFF3D424F), // Gunmetal Rivet
    rivetLight: Color(0xFF8E939E),
  );
```

Update `all`:
```dart
  static const List<HardwareEdition> all = [
    braunClassic,
    braunAtelierCream,
    titaniumStealth,
    bauhausHeritage,
    rawBrassPatina,
    midCenturyWalnut,
    forgedCarbon,
  ];
```

Update `fromType`:
```dart
  static HardwareEdition fromType(HardwareEditionType type) {
    switch (type) {
      case HardwareEditionType.braunClassic:
        return braunClassic;
      case HardwareEditionType.braunAtelierCream:
        return braunAtelierCream;
      case HardwareEditionType.titaniumStealth:
        return titaniumStealth;
      case HardwareEditionType.bauhausHeritage:
        return bauhausHeritage;
      case HardwareEditionType.rawBrassPatina:
        return rawBrassPatina;
      case HardwareEditionType.midCenturyWalnut:
        return midCenturyWalnut;
      case HardwareEditionType.forgedCarbon:
        return forgedCarbon;
    }
  }
```

- [ ] **Step 4: Run test to confirm PASS**

Run:
```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/app/theme/hardware_edition_test.dart
```
Expected: PASS (all 6 tests pass).

- [ ] **Step 5: Run flutter analyze**

Run:
```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter analyze
```
Expected: `No issues found!`.

- [ ] **Step 6: Commit**

```bash
git add lib/app/theme/hardware_edition.dart test/app/theme/hardware_edition_test.dart
git commit -m "feat(theme): expand HardwareEdition with Free Atelier Cream and Pro Walnut & Carbon"
```

---

### Task 2: Authentic Procedural Texture Canvas Shaders (`MaterialTexturePainter` & `ChronoDialPainter`)

**Files:**
- Modify: `lib/app/theme/widgets/material_texture_painter.dart`
- Modify: `lib/features/timer/presentation/chrono_dial_painter.dart`
- Create: `test/app/theme/material_texture_painter_test.dart`

**Interfaces:**
- Consumes: `HardwareTextureType.organicWalnut`, `HardwareTextureType.forgedCarbon`
- Produces: Mathematical vector shaders `_paintOrganicWalnut` and `_paintForgedCarbon` in `MaterialTexturePainter` and dial ring renderers in `ChronoDialPainter`.

- [ ] **Step 1: Write failing unit test for texture painter**

`test/app/theme/material_texture_painter_test.dart`:
```dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/widgets/material_texture_painter.dart';

void main() {
  group('MaterialTexturePainter', () {
    test('renders all HardwareTextureType variants without throwing', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(280, 180);

      for (final texture in HardwareTextureType.values) {
        for (final isDark in [true, false]) {
          final painter = MaterialTexturePainter(
            textureType: texture,
            isDark: isDark,
            chassisColor: Colors.black,
          );

          expect(() => painter.paint(canvas, size), returnsNormally);
        }
      }

      final picture = recorder.endRecording();
      picture.dispose();
    });

    test('shouldRepaint returns true when textureType, isDark, or chassisColor changes', () {
      const painter1 = MaterialTexturePainter(
        textureType: HardwareTextureType.organicWalnut,
        isDark: true,
        chassisColor: Colors.black,
      );

      const painter2 = MaterialTexturePainter(
        textureType: HardwareTextureType.forgedCarbon,
        isDark: true,
        chassisColor: Colors.black,
      );

      const painter3 = MaterialTexturePainter(
        textureType: HardwareTextureType.organicWalnut,
        isDark: false,
        chassisColor: Colors.black,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
      expect(painter1.shouldRepaint(painter3), isTrue);
      expect(painter1.shouldRepaint(painter1), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm failure**

Run:
```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/app/theme/material_texture_painter_test.dart
```
Expected: FAIL (missing cases in switch statement for `organicWalnut` and `forgedCarbon`).

- [ ] **Step 3: Implement `_paintOrganicWalnut` and `_paintForgedCarbon` in `material_texture_painter.dart`**

In `lib/app/theme/widgets/material_texture_painter.dart`:
```dart
    switch (textureType) {
      case HardwareTextureType.brushedTitanium:
        _paintBrushedTitanium(canvas, size);
        break;
      case HardwareTextureType.burnishedBrass:
        _paintBurnishedBrass(canvas, size);
        break;
      case HardwareTextureType.tubularChrome:
        _paintTubularChrome(canvas, size);
        break;
      case HardwareTextureType.matteAbsGrain:
        _paintMatteAbsGrain(canvas, size);
        break;
      case HardwareTextureType.organicWalnut:
        _paintOrganicWalnut(canvas, size);
        break;
      case HardwareTextureType.forgedCarbon:
        _paintForgedCarbon(canvas, size);
        break;
    }
```

Implementation of `_paintOrganicWalnut`:
```dart
  void _paintOrganicWalnut(Canvas canvas, Size size) {
    // 1. Alternating wavy wood grain lines (growth rings)
    final heartwoodPaint = Paint()
      ..color = const Color(0xFF1C140E).withValues(alpha: isDark ? 0.12 : 0.16)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final sapwoodPaint = Paint()
      ..color = const Color(0xFFD49B55).withValues(alpha: isDark ? 0.07 : 0.10)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    const double step = 3.2;
    for (double y = 1.0; y < size.height; y += step) {
      final isHeartwood = (y ~/ step) % 2 == 0;
      final path = Path();
      path.moveTo(0, y);

      // Sinusoidal grain path with variable frequency
      for (double x = 0; x <= size.width; x += 6.0) {
        final wave = math.sin(x * 0.018) * 2.2 + math.sin(x * 0.045) * 1.1;
        path.lineTo(x, (y + wave).clamp(0.0, size.height));
      }

      canvas.drawPath(path, isHeartwood ? heartwoodPaint : sapwoodPaint);
    }

    // 2. Micro-pore wood vessel stippling
    final vesselPaint = Paint()
      ..color = isDark
          ? Colors.black.withValues(alpha: 0.10)
          : const Color(0xFF3E2714).withValues(alpha: 0.08)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;

    final vesselPoints = <Offset>[];
    for (double y = 4.0; y < size.height; y += 9.0) {
      final xOffset = (y.toInt() % 7) * 4.0;
      for (double x = 4.0 + xOffset; x < size.width; x += 18.0) {
        vesselPoints.add(Offset(x, y));
      }
    }
    if (vesselPoints.isNotEmpty) {
      canvas.drawPoints(ui.PointMode.points, vesselPoints, vesselPaint);
    }

    // 3. Satin polyurethane lacquer sheen (35-degree linear gradient)
    final Rect rect = Offset.zero & size;
    final sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-0.9, -0.6),
        end: const Alignment(0.9, 0.6),
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: isDark ? 0.03 : 0.07),
          Colors.transparent,
          Colors.white.withValues(alpha: isDark ? 0.05 : 0.09),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.55, 0.75, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, sheenPaint);

    // 4. Perimeter vignette
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.0),
          Colors.black.withValues(alpha: isDark ? 0.28 : 0.15),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, vignettePaint);
  }
```

Implementation of `_paintForgedCarbon`:
```dart
  void _paintForgedCarbon(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    // 1. Anisotropic chopped carbon flakes grid
    final highlightPaint = Paint()
      ..color = const Color(0xFFE0E5EC).withValues(alpha: isDark ? 0.09 : 0.14)
      ..style = PaintingStyle.fill;

    final darkAbsorbPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.16 : 0.10)
      ..style = PaintingStyle.fill;

    const double flakeW = 16.0;
    const double flakeH = 8.0;

    for (double y = 0; y < size.height; y += flakeH) {
      final row = (y / flakeH).toInt();
      final xOffset = (row % 2 == 1) ? flakeW * 0.5 : 0.0;
      for (double x = xOffset; x < size.width; x += flakeW) {
        final hash = (x.toInt() * 13 + y.toInt() * 37) % 5;
        if (hash == 0) {
          // Highlight flake
          final flakePath = Path()
            ..moveTo(x, y + 2)
            ..lineTo(x + flakeW - 2, y)
            ..lineTo(x + flakeW, y + flakeH - 2)
            ..lineTo(x + 2, y + flakeH)
            ..close();
          canvas.drawPath(flakePath, highlightPaint);
        } else if (hash == 1 || hash == 2) {
          // Dark absorbing flake
          final flakePath = Path()
            ..moveTo(x + 1, y)
            ..lineTo(x + flakeW, y + 3)
            ..lineTo(x + flakeW - 3, y + flakeH)
            ..lineTo(x, y + flakeH - 1)
            ..close();
          canvas.drawPath(flakePath, darkAbsorbPaint);
        }
      }
    }

    // 2. Anisotropic diagonal sheen
    final sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-1.0, -1.0),
        end: const Alignment(1.0, 1.0),
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: isDark ? 0.04 : 0.08),
          Colors.transparent,
          Colors.white.withValues(alpha: isDark ? 0.06 : 0.11),
          Colors.transparent,
        ],
        stops: const [0.0, 0.28, 0.5, 0.72, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, sheenPaint);
  }
```
*(Import `dart:math as math;` in `material_texture_painter.dart`)*

- [ ] **Step 4: Update `chrono_dial_painter.dart`**

In `lib/features/timer/presentation/chrono_dial_painter.dart`:
Update `_drawBezelTexture` or texture switch to handle `organicWalnut` and `forgedCarbon`:
```dart
      case HardwareTextureType.burnishedBrass:
        // ...
      case HardwareTextureType.brushedTitanium:
        // ...
      case HardwareTextureType.tubularChrome:
        // ...
      case HardwareTextureType.organicWalnut:
        // Warm organic striations on dial ring
      case HardwareTextureType.forgedCarbon:
        // Subtle marbled flecks on dial ring
      case HardwareTextureType.matteAbsGrain:
        // ...
```

- [ ] **Step 5: Run tests to confirm PASS**

Run:
```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/app/theme/material_texture_painter_test.dart
```
Expected: PASS (all tests pass).

- [ ] **Step 6: Run full test suite & flutter analyze**

Run:
```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test
/home/tuneeca/RSQUARE/flutter/bin/flutter analyze
```
Expected: 100% test pass rate, 0 analyzer issues.

- [ ] **Step 7: Commit**

```bash
git add lib/app/theme/widgets/material_texture_painter.dart lib/features/timer/presentation/chrono_dial_painter.dart test/app/theme/material_texture_painter_test.dart
git commit -m "feat(theme): implement procedural organic walnut and forged carbon canvas shaders"
```

---

### Task 3: Interactive Theme Preview & Showcase Plaque in `StudioProDialog`

**Files:**
- Modify: `lib/features/settings/presentation/widgets/studio_pro_dialog.dart`
- Modify: `lib/features/settings/presentation/takt_settings_sheet.dart`
- Create: `test/features/settings/studio_pro_dialog_test.dart`

**Interfaces:**
- Produces: `MaterialShowcasePlaque` widget inside `studio_pro_dialog.dart`, `[ PREVIEW 👁 ]` badge on locked `_EditionCard`.

- [ ] **Step 1: Write unit/widget tests for `StudioProDialog` showcase**

`test/features/settings/studio_pro_dialog_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/features/settings/presentation/widgets/studio_pro_dialog.dart';

void main() {
  testWidgets('showStudioProDialog renders material showcase plaque for hardware edition', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () => showStudioProDialog(
                    context,
                    ref,
                    edition: HardwareEdition.midCenturyWalnut,
                  ),
                  child: const Text('OPEN PRO DIALOG'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN PRO DIALOG'));
    await tester.pumpAndSettle();

    expect(find.text('TAKT DESK STUDIO PRO'), findsOneWidget);
    expect(find.textContaining('MID-CENTURY WALNUT'), findsOneWidget);
    expect(find.byKey(const ValueKey('material_showcase_plaque')), findsOneWidget);
    expect(find.byKey(const ValueKey('pro_dialog_unlock_button')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Implement `MaterialShowcasePlaque` inside `studio_pro_dialog.dart`**

Add `_MaterialShowcasePlaque`:
```dart
class _MaterialShowcasePlaque extends StatelessWidget {
  final HardwareEdition edition;
  final bool isDark;

  const _MaterialShowcasePlaque({
    required this.edition,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? edition.darkBorder : edition.lightBorder;
    final rivetColor = isDark ? edition.rivetDark : edition.rivetLight;

    return Container(
      key: const ValueKey('material_showcase_plaque'),
      height: 96,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: borderColor, width: 1.2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? edition.plateGradientDark : edition.plateGradientLight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5.0),
        child: Stack(
          children: [
            // Procedural surface texture
            Positioned.fill(
              child: CustomPaint(
                painter: MaterialTexturePainter(
                  textureType: edition.textureType,
                  isDark: isDark,
                  chassisColor: isDark ? edition.darkModuleBg : edition.lightModuleBg,
                ),
              ),
            ),
            // Rivets at 4 corners
            Positioned(top: 5, left: 5, child: _PlaqueRivet(color: rivetColor)),
            Positioned(top: 5, right: 5, child: _PlaqueRivet(color: rivetColor)),
            Positioned(bottom: 5, left: 5, child: _PlaqueRivet(color: rivetColor)),
            Positioned(bottom: 5, right: 5, child: _PlaqueRivet(color: rivetColor)),

            // Interactive showcase content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // Mini Horological Dial & Needle
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.black45 : Colors.white54,
                      border: Border.all(color: borderColor, width: 1.0),
                    ),
                    child: Center(
                      child: Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          color: edition.needleColor,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: edition.filamentColor.withValues(alpha: 0.6),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          edition.title,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark ? TaktColors.warmBone : const Color(0xFF141618),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${edition.yearLabel} · ${edition.subtitle}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8.5,
                            color: isDark ? const Color(0xFF9E9B93) : const Color(0xFF5A5D64),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: edition.filamentColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'STUDIO PRO FINISH',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 7.5,
                                fontWeight: FontWeight.w700,
                                color: edition.filamentColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Embed `_MaterialShowcasePlaque` inside the `content` Column of `AlertDialog` when `edition != null`.

- [ ] **Step 3: Update `_EditionCard` in `takt_settings_sheet.dart` with `[ PREVIEW 👁 ]`**

When `!isUnlocked`, update the action button container to show:
```dart
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(3.0),
        border: Border.all(
          color: TaktColors.mutedOchre.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 9, color: TaktColors.mutedOchre),
          SizedBox(width: 4),
          Text(
            'LOCKED // PREVIEW 👁',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: TaktColors.mutedOchre,
            ),
          ),
        ],
      ),
    );
```

- [ ] **Step 4: Run test to verify PASS**

Run:
```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/settings/studio_pro_dialog_test.dart
```
Expected: PASS.

- [ ] **Step 5: Run flutter analyze**

Run:
```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter analyze
```
Expected: `No issues found!`.

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/presentation/widgets/studio_pro_dialog.dart lib/features/settings/presentation/takt_settings_sheet.dart test/features/settings/studio_pro_dialog_test.dart
git commit -m "feat(settings): add material showcase plaque and preview indicator for Pro editions"
```

---

### Task 4: Settings Sheet Gallery Carousel & End-to-End Verification

**Files:**
- Modify: `test/features/settings/takt_settings_sheet_test.dart`

**Interfaces:**
- Consumes: 7 Hardware Editions, Free Atelier Cream, Pro Walnut & Carbon.
- Produces: 100% verified UI tests for 7 editions carousel, free edition direct equip, and Pro gating.

- [ ] **Step 1: Update `test/features/settings/takt_settings_sheet_test.dart`**

Update existing assertions from 4 editions to 7 editions:
- Carousel counter asserts `[ 01 / 07 ]` or `[ 02 / 07 ]`.
- 7 page indicator dots (`edition_dot_0` through `edition_dot_6`).
- Test that tapping `braunAtelierCream` card immediately equips it without prompting `showStudioProDialog`.
- Test that tapping `midCenturyWalnut` or `forgedCarbon` opens `showStudioProDialog` when not Pro.

- [ ] **Step 2: Run test suite**

Run:
```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/settings/takt_settings_sheet_test.dart
```
Expected: PASS.

- [ ] **Step 3: Run full test suite**

Run:
```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test
```
Expected: 100% test pass rate across repository (271+ tests).

- [ ] **Step 4: Run flutter analyze**

Run:
```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter analyze
```
Expected: `No issues found!`.

- [ ] **Step 5: Check zero namespace pollution**

Run:
```bash
grep -rn "tuneeca" lib/ android/ test/
```
Expected: 0 results found.

- [ ] **Step 6: Commit**

```bash
git add test/features/settings/takt_settings_sheet_test.dart
git commit -m "test(settings): update settings sheet tests for 7 hardware editions and free tier equip"
```
