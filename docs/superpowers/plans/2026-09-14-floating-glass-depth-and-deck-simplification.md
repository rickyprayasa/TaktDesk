# Floating Glass 3D Metamaterial Depth & Vinyl Deck Simplification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the soundscape mixer console from the vinyl deck to restore pure minimalist Dieter Rams aesthetics, and implement the 3D Floating Glass (Liquid Glass Metamaterial) depth engine with real-time gyroscopic specular rim caustics and 3D perspective parallax across all instrument chassis.

**Architecture:** Flutter Riverpod state management (`parallaxProvider`) streams smoothed device tilt angles and computes a 2D/3D virtual light vector. A procedural vector `GlassRimPainter` draws reactive specular caustic rim glares along the chassis border. `MaterialChassisBox` applies a dynamic `Matrix4` perspective tilt transform, counter-projected drop shadows ($Z = -18\text{px}$), and forward floating instrument elevation ($Z = +6\text{px}$). `VinylPlayerWidget` is stripped of mixer controls, retaining only pure platter, tonearm, status, and archival drawer with tactile foleys.

**Tech Stack:** Flutter / Dart, Riverpod, Sensors Plus (`sensors_plus`), Vector Math (`Matrix4`), CustomPainter, Drift SQLite.

## Global Constraints

- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetics (honest materials, uncluttered typography, amber accent #FF9E00, aluminum hardware).
- Clean namespace: Absolutely 0 occurrences of `tuneeca` across Kotlin, Dart, XML, and Gradle files (`com.takt.desk`).
- Battery-first: Parallax and gyro-driven rim lighting pause completely when `DeskPreferences.parallaxEnabled` is false.
- 0 analyzer issues (`/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`).
- 100% test pass rate across the entire repository (`/home/tuneeca/RSQUARE/flutter/bin/flutter test`).
- Clean Kotlin compilation via `./gradlew compileDebugKotlin`.

---

### Task 1: Clean Removal of Soundscape Mixer & Vinyl Deck Simplification

**Files:**
- Modify: `lib/features/vinyl/presentation/vinyl_player_widget.dart`
- Modify: `lib/features/vinyl/presentation/vinyl_controller.dart`
- Delete: `lib/features/vinyl/presentation/widgets/turntable_mixer_strip.dart`
- Delete: `test/features/vinyl/turntable_mixer_strip_test.dart`
- Modify: `test/features/vinyl/vinyl_player_widget_test.dart`
- Modify: `android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt`
- Test: `test/core/audio/audio_service_test.dart`

**Interfaces:**
- Consumes: `VinylController`, `AudioService`.
- Produces: Clean minimalist `VinylPlayerWidget` rendering only platter, tonearm, status row, and `VinylDiscDrawerWidget`.

- [ ] **Step 1: Write test asserting clean Vinyl Deck without mixer**

In `test/features/vinyl/vinyl_player_widget_test.dart`:
Remove `TurntableMixerStrip` import and assertion, and assert `find.byKey(const ValueKey('fader_rec_track'))` is nothing:
```dart
    // Verify TurntableMixerStrip is NOT present
    expect(find.byKey(const ValueKey('fader_rec_track')), findsNothing);
    expect(find.text('SOUNDSCAPE MIXER // 3-CH'), findsNothing);
```

- [ ] **Step 2: Remove mixer strip from `VinylPlayerWidget`**

In `lib/features/vinyl/presentation/vinyl_player_widget.dart`:
Remove `import 'widgets/turntable_mixer_strip.dart';`.
Remove lines 218-220 (`const SizedBox(height: 10), const TurntableMixerStrip(),`).
Delete `lib/features/vinyl/presentation/widgets/turntable_mixer_strip.dart` and `test/features/vinyl/turntable_mixer_strip_test.dart`.

- [ ] **Step 3: Simplify `VinylController`**

In `lib/features/vinyl/presentation/vinyl_controller.dart`:
Remove `_getMixerState` and `soundscape_mixer_controller.dart` import.
Call `_audioService?.startAmbient(trackIndex: state.selectedTrackIndex)` without mixer arguments.

- [ ] **Step 4: Streamline native `MainActivity.kt` audio engine**

In `android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt`:
In `startAmbient`: keep primary soundscape player cleanly prepared and started inside `.use { fd -> ... }`, and safely stop auxiliary crackle/binaural players if running.

- [ ] **Step 5: Run tests to verify pass**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/vinyl/`
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/audio/`
Expected: PASS (All tests green).

- [ ] **Step 6: Commit**

```bash
git add lib/features/vinyl/ lib/core/ test/ android/
git commit -m "refactor(vinyl): remove soundscape mixer console and restore pure minimalist deck"
```

---

### Task 2: Sensor Pipeline & Virtual Light Vector in ParallaxController

**Files:**
- Modify: `lib/core/sensors/parallax_controller.dart`
- Test: `test/core/parallax_test.dart`

**Interfaces:**
- Consumes: `sensors_plus` accelerometer & gyroscope data.
- Produces: `ParallaxState` containing:
  - `double tiltX`: normalized roll angle in radians ($\pm 0.05$).
  - `double tiltY`: normalized pitch angle in radians ($\pm 0.05$).
  - `double lightX`: normalized 2D light vector X coordinate ($-1.0 \dots 1.0$).
  - `double lightY`: normalized 2D light vector Y coordinate ($-1.0 \dots 1.0$).
  - `double lightIntensity`: specular glare intensity ($0.0 \dots 1.0$).

- [ ] **Step 1: Write failing unit test for extended ParallaxState**

Update `test/core/parallax_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/sensors/parallax_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ParallaxState provides default centered light vector', () {
    const state = ParallaxState();
    expect(state.tiltX, 0.0);
    expect(state.tiltY, 0.0);
    expect(state.lightX, -0.4);
    expect(state.lightY, -0.6);
    expect(state.lightIntensity, 0.5);
  });

  test('updateTiltFromAccelerometer computes dynamic light vector based on tilt', () {
    final controller = ParallaxController();

    // Tilt device right (+X) and forward (+Y)
    controller.updateTiltFromAccelerometer(x: 3.0, y: 3.0, z: 9.0);

    final state = controller.state;
    expect(state.tiltX, greaterThan(0.0));
    expect(state.tiltY, greaterThan(0.0));
    expect(state.lightX, isNotNull);
    expect(state.lightY, isNotNull);
  });

  test('reset restores default centered light vector and zero tilt', () {
    final controller = ParallaxController();
    controller.updateTiltFromAccelerometer(x: 5.0, y: 5.0, z: 8.0);
    controller.reset();

    expect(controller.state.tiltX, 0.0);
    expect(controller.state.tiltY, 0.0);
    expect(controller.state.lightX, -0.4);
    expect(controller.state.lightY, -0.6);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/parallax_test.dart`
Expected: FAIL (`lightX`, `lightY`, `lightIntensity` undefined).

- [ ] **Step 3: Implement light vector calculation in `ParallaxController`**

Update `lib/core/sensors/parallax_controller.dart`:
```dart
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ParallaxState {
  final double tiltX;
  final double tiltY;
  final double lightX;
  final double lightY;
  final double lightIntensity;

  const ParallaxState({
    this.tiltX = 0.0,
    this.tiltY = 0.0,
    this.lightX = -0.4,
    this.lightY = -0.6,
    this.lightIntensity = 0.5,
  });

  ParallaxState copyWith({
    double? tiltX,
    double? tiltY,
    double? lightX,
    double? lightY,
    double? lightIntensity,
  }) {
    return ParallaxState(
      tiltX: tiltX ?? this.tiltX,
      tiltY: tiltY ?? this.tiltY,
      lightX: lightX ?? this.lightX,
      lightY: lightY ?? this.lightY,
      lightIntensity: lightIntensity ?? this.lightIntensity,
    );
  }
}

class ParallaxController extends StateNotifier<ParallaxState> {
  ParallaxController() : super(const ParallaxState());

  static const double _alpha = 0.15; // Low-pass filter smoothing coefficient
  static const double maxTiltRadians = 0.05; // ~3 degrees

  void updateSensorInput({required double rawX, required double rawY}) {
    final targetX = (rawX * 0.01).clamp(-maxTiltRadians, maxTiltRadians);
    final targetY = (rawY * 0.01).clamp(-maxTiltRadians, maxTiltRadians);

    final smoothX = _alpha * targetX + (1 - _alpha) * state.tiltX;
    final smoothY = _alpha * targetY + (1 - _alpha) * state.tiltY;

    _updateStateWithLight(smoothX, smoothY);
  }

  void updateTiltFromAccelerometer({
    required double x,
    required double y,
    double? z,
  }) {
    final double norm;
    if (z != null) {
      final mag = math.sqrt(x * x + y * y + z * z);
      norm = mag > 0.001 ? mag : 9.80665;
    } else {
      norm = 9.80665;
    }

    final targetX = (x / norm).clamp(-maxTiltRadians, maxTiltRadians);
    final targetY = (y / norm).clamp(-maxTiltRadians, maxTiltRadians);

    final smoothX = _alpha * targetX + (1 - _alpha) * state.tiltX;
    final smoothY = _alpha * targetY + (1 - _alpha) * state.tiltY;

    _updateStateWithLight(smoothX, smoothY);
  }

  void _updateStateWithLight(double smoothX, double smoothY) {
    // Virtual overhead light source at (-0.4, -0.6) shifted by device tilt
    final lx = (-0.4 - (smoothX / maxTiltRadians) * 0.6).clamp(-1.0, 1.0);
    final ly = (-0.6 - (smoothY / maxTiltRadians) * 0.4).clamp(-1.0, 1.0);
    final tiltMag = math.sqrt(smoothX * smoothX + smoothY * smoothY) / maxTiltRadians;
    final intensity = (0.5 + tiltMag * 0.4).clamp(0.2, 0.95);

    state = ParallaxState(
      tiltX: smoothX,
      tiltY: smoothY,
      lightX: lx,
      lightY: ly,
      lightIntensity: intensity,
    );
  }

  void reset() {
    state = const ParallaxState();
  }
}

final parallaxProvider = StateNotifierProvider<ParallaxController, ParallaxState>((ref) {
  return ParallaxController();
});
```

- [ ] **Step 4: Run unit tests to verify pass**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/parallax_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/sensors/parallax_controller.dart test/core/parallax_test.dart
git commit -m "feat(sensors): compute 2D/3D virtual light vector and glare intensity in ParallaxController"
```

---

### Task 3: Procedural Glass Rim Caustic Painter (`GlassRimPainter`)

**Files:**
- Create: `lib/app/theme/widgets/glass_rim_painter.dart`
- Test: `test/app/theme/widgets/glass_rim_painter_test.dart`

**Interfaces:**
- Consumes: `lightX`, `lightY`, `lightIntensity`, `BorderRadius`, `isDark`.
- Produces: `GlassRimPainter` rendering dynamic curved specular rim highlights and chromatic refraction caustics.

- [ ] **Step 1: Write failing unit test for `GlassRimPainter`**

Create `test/app/theme/widgets/glass_rim_painter_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/widgets/glass_rim_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GlassRimPainter shouldRepaint returns true when light vector changes', () {
    const painter1 = GlassRimPainter(
      lightX: -0.4,
      lightY: -0.6,
      intensity: 0.5,
      isDark: true,
    );
    const painter2 = GlassRimPainter(
      lightX: 0.2,
      lightY: -0.6,
      intensity: 0.5,
      isDark: true,
    );
    expect(painter1.shouldRepaint(painter2), isTrue);
  });

  testWidgets('GlassRimPainter paints without throwing error on Canvas', (tester) async {
    await tester.pumpWidget(
      CustomPaint(
        size: const Size(280, 420),
        painter: const GlassRimPainter(
          lightX: -0.5,
          lightY: -0.5,
          intensity: 0.7,
          isDark: true,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/app/theme/widgets/glass_rim_painter_test.dart`
Expected: FAIL (`GlassRimPainter` not found).

- [ ] **Step 3: Implement `GlassRimPainter`**

Create `lib/app/theme/widgets/glass_rim_painter.dart`:
```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../takt_colors.dart';

/// Procedural vector painter rendering Liquid Glass edge caustics,
/// specular corner sweeps, and subtle chromatic glass refraction.
class GlassRimPainter extends CustomPainter {
  final double lightX;
  final double lightY;
  final double intensity;
  final BorderRadius borderRadius;
  final bool isDark;
  final double strokeWidth;

  const GlassRimPainter({
    required this.lightX,
    required this.lightY,
    required this.intensity,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.isDark = true,
    this.strokeWidth = 1.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    // 1. Primary Specular Rim Sweep aligned with light vector
    final lightAngle = math.atan2(lightY, lightX);
    final highlightStart = Offset(
      size.width / 2 + math.cos(lightAngle) * (size.width / 2),
      size.height / 2 + math.sin(lightAngle) * (size.height / 2),
    );
    final highlightEnd = Offset(
      size.width / 2 - math.cos(lightAngle) * (size.width / 2),
      size.height / 2 - math.sin(lightAngle) * (size.height / 2),
    );

    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        begin: Alignment(
          (highlightStart.dx / size.width) * 2 - 1,
          (highlightStart.dy / size.height) * 2 - 1,
        ),
        end: Alignment(
          (highlightEnd.dx / size.width) * 2 - 1,
          (highlightEnd.dy / size.height) * 2 - 1,
        ),
        colors: [
          Colors.white.withValues(alpha: (0.45 * intensity).clamp(0.1, 0.75)),
          Colors.white.withValues(alpha: (0.12 * intensity).clamp(0.02, 0.25)),
          Colors.transparent,
          isDark
              ? TaktColors.filamentAmber.withValues(alpha: (0.15 * intensity).clamp(0.02, 0.25))
              : Colors.black.withValues(alpha: 0.10),
        ],
        stops: const [0.0, 0.28, 0.70, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, highlightPaint);

    // 2. Soft Refractive Inner Caustic Glow along illuminated corner
    final causticPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
      ..shader = RadialGradient(
        center: Alignment(lightX * 0.8, lightY * 0.8),
        radius: 0.8,
        colors: [
          Colors.white.withValues(alpha: (0.20 * intensity).clamp(0.05, 0.35)),
          Colors.transparent,
        ],
      ).createShader(rect);

    canvas.drawRRect(rrect, causticPaint);
  }

  @override
  bool shouldRepaint(covariant GlassRimPainter oldDelegate) {
    return (oldDelegate.lightX - lightX).abs() > 0.01 ||
        (oldDelegate.lightY - lightY).abs() > 0.01 ||
        (oldDelegate.intensity - intensity).abs() > 0.02 ||
        oldDelegate.isDark != isDark ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
```

- [ ] **Step 4: Run unit tests to verify pass**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/app/theme/widgets/glass_rim_painter_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/app/theme/widgets/glass_rim_painter.dart test/app/theme/widgets/glass_rim_painter_test.dart
git commit -m "feat(theme): implement procedural GlassRimPainter for Liquid Glass caustic reflections"
```

---

### Task 4: Floating Glass Chassis Integration & End-to-End Verification

**Files:**
- Modify: `lib/app/theme/widgets/material_chassis_box.dart`
- Test: `test/features/desk/material_chassis_box_test.dart` (or `test/app/theme/material_chassis_box_test.dart`)
- Test: Full repository test suite (`flutter test`)
- Run: Static analysis (`flutter analyze`)
- Build: Release APK (`flutter build apk --release` -> `/home/tuneeca/RSQUARE/Takt_Desk_Release.apk`)

**Interfaces:**
- Consumes: `parallaxProvider`, `GlassRimPainter`, `MaterialChassisBox`.
- Produces: 3D Floating Glass depth effect on all instrument panels (Dial, Tasks, Vinyl) with counter-projected drop shadows and dynamic gyro glares.

- [ ] **Step 1: Write widget test verifying 3D Floating Glass integration**

Create or update `test/app/theme/widgets/material_chassis_box_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/widgets/glass_rim_painter.dart';
import 'package:takt_desk/app/theme/widgets/material_chassis_box.dart';
import 'package:takt_desk/core/sensors/parallax_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MaterialChassisBox integrates GlassRimPainter and Matrix4 perspective', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: MaterialChassisBox(
                width: 280,
                height: 420,
                child: Text('TEST CHASSIS'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify GlassRimPainter is rendered in foreground
    final glassPainterFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.foregroundPainter is GlassRimPainter,
    );
    expect(glassPainterFinder, findsOneWidget);

    // Verify child content is present
    expect(find.text('TEST CHASSIS'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Update `MaterialChassisBox` with 3D Matrix4 perspective & `GlassRimPainter`**

In `lib/app/theme/widgets/material_chassis_box.dart`:
1. Watch `parallaxProvider`.
2. Wrap chassis in `Transform` with `Matrix4.identity()..setEntry(3, 2, 0.0012)..rotateX(-parallax.tiltY)..rotateY(parallax.tiltX)`.
3. Compute dynamic counter-projected drop shadow based on `parallax.tiltX` and `parallax.tiltY`.
4. Render `GlassRimPainter` in `foregroundPainter` with `lightX: parallax.lightX`, `lightY: parallax.lightY`, `intensity: parallax.lightIntensity`.

- [ ] **Step 3: Run widget tests**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/app/theme/widgets/material_chassis_box_test.dart`
Expected: PASS.

- [ ] **Step 4: Run full repository verification**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test`
Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`
Expected: 100% test pass rate, 0 analyzer issues.

- [ ] **Step 5: Verify zero occurrences of `tuneeca`**

Run: `git diff | grep "tuneeca" || true`
Expected: 0 occurrences found.

- [ ] **Step 6: Build production release APK**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter build apk --release`
Run: `cp build/app/outputs/flutter-apk/app-release.apk /home/tuneeca/RSQUARE/Takt_Desk_Release.apk`
Run: `ls -lh /home/tuneeca/RSQUARE/Takt_Desk_Release.apk`

- [ ] **Step 7: Commit**

```bash
git add lib/app/theme/widgets/material_chassis_box.dart test/app/theme/widgets/material_chassis_box_test.dart
git commit -m "feat(glass): integrate 3D Floating Glass metamaterial depth and dynamic rim caustics into MaterialChassisBox"
```
