# Crown Three-Position Physical Mechanics & Zykl.app Portal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish three distinct, mechanically authentic physical elevations for the watch crown (Normal, Start/Running, and Pull Crown) to eliminate pre-started submerged visuals, and integrate a native portal link to `https://zykl.app` in the application settings sheet.

**Architecture:** Re-anchor `CrownPushButton` with $24\text{px}$ dial headroom in `ChronoDialWidget` so the stem collar sits flush on the outer 12 o'clock bezel socket, with the cap resting proudly outside the dial in Normal ($0\text{px}$), depressing $+4\text{px}$ into the case when running, and elevating $-8\text{px}$ with an exposed $8\text{px}$ stem shaft during calibration. A native Android `Intent.ACTION_VIEW` MethodChannel handler powers `UrlService` without third-party package dependencies.

**Tech Stack:** Flutter 3.29, Dart 3.7, Kotlin, Android Intent, Riverpod 2.6, Dieter Rams / Braun Modernist Industrial Design.

## Global Constraints

- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetics (honest materials, uncluttered typography, amber accent `#FF9E00` / `TaktColors.filamentAmber`).
- Clean namespace: Absolutely 0 occurrences of `tuneeca` across Kotlin, Dart, XML, and Gradle files (`com.takt.desk` / `com.zykl.app`).
- Zero external package bloat: Native Android `Intent` via `MethodChannel('com.takt.desk/focus_lock')` without third-party plugins.
- 0 analyzer issues (`/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`).
- 100% test pass rate across repository (`/home/tuneeca/RSQUARE/flutter/bin/flutter test`).
- High-fidelity haptic and audio synchronization on all physical interactions.

---

### Task 1: Crown Three-Position Mechanical Geometry & Vertical Animation

**Files:**
- Modify: `lib/features/timer/presentation/widgets/crown_push_button.dart`
- Modify: `lib/features/timer/presentation/chrono_dial_widget.dart`
- Modify: `test/features/timer/crown_push_button_test.dart`
- Modify: `test/features/timer/chrono_dial_widget_test.dart`

**Interfaces:**
- Consumes: `isPressed`, `isPulledOut`, `onTap`, `onPullOut`, `onPushIn`.
- Produces: 3 distinct physical levels:
  - Normal: `top: 12.0` (resting proud above dial rim $y = 24$, collar flush at $y = 24$).
  - Start/Running: `top: 16.0` ($+4\text{px}$ depression into collar).
  - Pull Crown: `top: 4.0` ($-8\text{px}$ elevation outward, exposing $8\text{px}$ stem shaft).

- [ ] **Step 1: Write failing tests in `crown_push_button_test.dart` and `chrono_dial_widget_test.dart`**

In `test/features/timer/crown_push_button_test.dart`:
```dart
testWidgets('CrownPushButton renders at top: 12.0 in normal resting state and spans 28px height', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: CrownPushButton(
            isPressed: false,
            isPulledOut: false,
            onTap: () {},
          ),
        ),
      ),
    ),
  );

  final sizedBoxFinder = find.byWidgetPredicate(
    (w) => w is SizedBox && w.width == 36 && w.height == 28,
  );
  expect(sizedBoxFinder, findsOneWidget);

  final capPositionedFinder = find.ancestor(
    of: find.byKey(const Key('crown_cap')),
    matching: find.byType(Positioned),
  );
  final capPositioned = tester.widget<Positioned>(capPositionedFinder);
  expect(capPositioned.top, equals(12.0));
});

testWidgets('CrownPushButton moves to top: 16.0 when isPressed is true', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: CrownPushButton(
            isPressed: true,
            isPulledOut: false,
            onTap: () {},
          ),
        ),
      ),
    ),
  );

  final capPositionedFinder = find.ancestor(
    of: find.byKey(const Key('crown_cap')),
    matching: find.byType(Positioned),
  );
  final capPositioned = tester.widget<Positioned>(capPositionedFinder);
  expect(capPositioned.top, equals(16.0));
});

testWidgets('CrownPushButton moves to top: 4.0 when isPulledOut is true', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: CrownPushButton(
            isPressed: false,
            isPulledOut: true,
            onTap: () {},
          ),
        ),
      ),
    ),
  );

  final capPositionedFinder = find.ancestor(
    of: find.byKey(const Key('crown_cap')),
    matching: find.byType(Positioned),
  );
  final capPositioned = tester.widget<Positioned>(capPositionedFinder);
  expect(capPositioned.top, equals(4.0));
});
```

- [ ] **Step 2: Run test to verify failure (RED)**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/crown_push_button_test.dart
```
Expected: FAIL due to previous height (24) and top (8.0).

- [ ] **Step 3: Implement 3-position geometry in `crown_push_button.dart` and `chrono_dial_widget.dart`**

In `lib/features/timer/presentation/widgets/crown_push_button.dart`:
- Set `_pullAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(...)`.
- Set `_pressAnimation = Tween<double>(begin: 0.0, end: 4.0).animate(...)`.
- Update container height to `width: 36, height: 28`.
- In `AnimatedBuilder`:
  ```dart
  Positioned(
    top: 12.0 + _pressAnimation.value + _pullAnimation.value,
    child: child!,
  )
  ```
- Stem collar at `bottom: 0, height: 4`.
- Stem shaft at `bottom: 4, height: 8`.

In `lib/features/timer/presentation/chrono_dial_widget.dart`:
- Dial stack: `height: dialDimensions.height + 24`.
- Dial canvas `Positioned(top: 24, child: ...)`.
- Crown button `Positioned(top: 0, child: CrownPushButton(...))`.

- [ ] **Step 4: Run test to verify pass (GREEN)**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/crown_push_button_test.dart test/features/timer/chrono_dial_widget_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/timer/presentation/widgets/crown_push_button.dart lib/features/timer/presentation/chrono_dial_widget.dart test/features/timer/crown_push_button_test.dart test/features/timer/chrono_dial_widget_test.dart
git commit -m "feat(crown): calibrate 3 distinct physical positions (Normal, Start, Pull Crown) with 24px dial headroom"
```

---

### Task 2: Native Android `openUrl` Handler, Flutter `UrlService`, & Settings Portal UI

**Files:**
- Modify: `android/app/src/main/kotlin/com/zykl/app/MainActivity.kt`
- Create: `lib/core/services/url_service.dart`
- Modify: `lib/features/settings/presentation/takt_settings_sheet.dart`
- Create: `test/core/services/url_service_test.dart`
- Modify: `test/features/settings/takt_settings_sheet_test.dart`

**Interfaces:**
- Consumes: MethodChannel `'com.takt.desk/focus_lock'`, method `'openUrl'`, argument `'url'`.
- Produces: `UrlService.openUrl(String url) -> Future<bool>`.
- UI: Interactive `ZYKL.APP // PORTAL & PRIVACY` button in `TaktSettingsSheet`.

- [ ] **Step 1: Write failing unit and widget tests**

Create `test/core/services/url_service_test.dart`:
```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/services/url_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.takt.desk/focus_lock');
  final List<MethodCall> log = [];

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      if (methodCall.method == 'openUrl') {
        return true;
      }
      return null;
    });
    log.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('UrlService.openUrl dispatches openUrl with URL string over focus_lock channel', () async {
    final result = await UrlService.openUrl('https://zykl.app');
    expect(result, isTrue);
    expect(log, hasLength(1));
    expect(log.first.method, equals('openUrl'));
    expect(log.first.arguments, equals({'url': 'https://zykl.app'}));
  });
}
```

- [ ] **Step 2: Run test to verify failure (RED)**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/services/url_service_test.dart
```
Expected: FAIL with compilation error (UrlService does not exist yet).

- [ ] **Step 3: Implement native `openUrl` in `MainActivity.kt` and `UrlService`**

In `android/app/src/main/kotlin/com/zykl/app/MainActivity.kt`:
```kotlin
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (!url.isNullOrBlank()) {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url)).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("URL_ERROR", e.localizedMessage, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "URL is null or empty", null)
                    }
                }
```

Create `lib/core/services/url_service.dart`:
```dart
import 'package:flutter/services.dart';

/// Service providing native deep-linking and browser navigation.
class UrlService {
  static const MethodChannel _channel = MethodChannel('com.takt.desk/focus_lock');

  /// Launches [url] in the system default browser or application handler.
  static Future<bool> openUrl(String url) async {
    try {
      final success = await _channel.invokeMethod<bool>('openUrl', {'url': url});
      return success ?? false;
    } catch (_) {
      return false;
    }
  }
}
```

In `lib/features/settings/presentation/takt_settings_sheet.dart`:
In `_buildBraunCreedCard`, add the `ZYKL.APP // PORTAL & PRIVACY` button:
```dart
          const SizedBox(height: 14),
          InkWell(
            key: const ValueKey('zykl_portal_button'),
            onTap: () {
              HapticService.selectionClick();
              UrlService.openUrl('https://zykl.app');
            },
            borderRadius: BorderRadius.circular(4.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2125) : const Color(0xFFDDD9CE),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: TaktColors.filamentAmber.withValues(alpha: 0.6),
                  width: 1.0,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.language, size: 14, color: TaktColors.filamentAmber),
                  SizedBox(width: 8),
                  Text(
                    'ZYKL.APP // PORTAL & PRIVACY',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: TaktColors.filamentAmber,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_outward, size: 12, color: TaktColors.filamentAmber),
                ],
              ),
            ),
          ),
```

- [ ] **Step 4: Run tests to verify pass (GREEN)**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/services/url_service_test.dart test/features/settings/takt_settings_sheet_test.dart
```
Expected: All tests pass.

- [ ] **Step 5: Verify Kotlin compilation**

```bash
cd android && ./gradlew compileDebugKotlin && cd ..
```
Expected: BUILD SUCCESSFUL.

- [ ] **Step 6: Commit**

```bash
git add android/app/src/main/kotlin/com/zykl/app/MainActivity.kt lib/core/services/url_service.dart lib/features/settings/presentation/takt_settings_sheet.dart test/core/services/url_service_test.dart test/features/settings/takt_settings_sheet_test.dart
git commit -m "feat(portal): integrate native openUrl handler and ZYKL.APP portal button in settings"
```

---

### Task 3: Full Suite Verification & Production Release APK Build

**Files:**
- Output: `build/app/outputs/flutter-apk/app-release.apk`
- Deploy: `/home/tuneeca/RSQUARE/ZYKL_Release.apk`, `/home/tuneeca/RSQUARE/Takt_Desk_Release.apk`

- [ ] **Step 1: Run full test suite across repository**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test
```
Expected: 100% PASS (363+ tests).

- [ ] **Step 2: Run static analysis**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter analyze
```
Expected: 0 errors, 0 warnings, 0 lints.

- [ ] **Step 3: Verify clean namespace**

```bash
git diff 361f6ca..HEAD | grep -i "tuneeca" || true
```
Expected: 0 occurrences.

- [ ] **Step 4: Build production release APK**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter build apk --release
```

- [ ] **Step 5: Deploy APK artifacts**

```bash
cp build/app/outputs/flutter-apk/app-release.apk /home/tuneeca/RSQUARE/ZYKL_Release.apk
cp build/app/outputs/flutter-apk/app-release.apk /home/tuneeca/RSQUARE/Takt_Desk_Release.apk
ls -lh /home/tuneeca/RSQUARE/*Release.apk
```

- [ ] **Step 6: Whole-branch review & report**
