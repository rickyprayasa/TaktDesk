# ZYKL Rebranding & Studio Pro Widget Tiering (1 Free + 2 Pro) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:**
1. Replace all remaining "Takt Desk" app strings with "ZYKL" across Android foreground service notifications and settings dialogs.
2. Implement Studio Pro Widget Tiering:
   - **Free Access:** Monastic Focus Strip (4x1) & Telemetry Console (2x2).
   - **Studio Pro Exclusive:** AW10 Pure Analog Dial Face (2x2) & Rotary Task Dispenser Strip (4x2).
   - Non-pro users placing or viewing Pro widgets see a refined Dieter Rams Pro state (`[ STUDIO PRO // UNLOCK ]` and feature preview receipt) with a direct tap action opening the `StudioProDialog` (Founder Lifetime Rp 69.000).

**Tech Stack:** Flutter, Riverpod, Drift SQLite, Android Kotlin, RemoteViews, AppWidgetProvider, SharedPreferences.

---

## Global Constraints
- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetics (honest materials, basalt slate `#14171A`, warm bone `#F5F3EB`, filament amber `#FF9E00`, monospace typography).
- Clean namespace: Absolutely 0 occurrences of `tuneeca` across Kotlin, Dart, XML, and Gradle files (`com.zykl.app` / `com.takt.desk`).
- 0 analyzer issues (`/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`).
- 100% test pass rate across repository (`/home/tuneeca/RSQUARE/flutter/bin/flutter test`).
- Production release APK successfully compiled and deployed to `/home/tuneeca/RSQUARE/ZYKL_Release.apk` and `Takt_Desk_Release.apk`.

---

### Task 1: Complete "Takt Desk" -> "ZYKL" String Rebranding

**Files:**
- Modify: `android/app/src/main/kotlin/com/zykl/app/TimerForegroundService.kt`
- Modify: `lib/features/settings/presentation/takt_settings_sheet.dart`
- Modify: `test/features/settings/takt_settings_sheet_test.dart`

- [ ] **Step 1: Update TimerForegroundService.kt**
  - Replace notification title `"TAKT DESK · $phaseLabel COMPLETED"` with `"ZYKL · $phaseLabel COMPLETED"`.
  - Replace `"TAKT DESK · SHORT BRK"` with `"ZYKL · SHORT BRK"`.
  - Replace `"TAKT DESK · LONG BRK"` with `"ZYKL · LONG BRK"`.
  - Replace `"TAKT DESK · FOCUS (CYCLE $cycleCount/4)"` with `"ZYKL · FOCUS (CYCLE $cycleCount/4)"`.
  - Replace `"Takt Desk Active Timer"` with `"ZYKL Active Timer"`.
  - Replace `"Takt Desk Session Alerts"` with `"ZYKL Session Alerts"`.

- [ ] **Step 2: Update takt_settings_sheet.dart and its tests**
  - Update version string: `'Takt Desk v1.0.0 (Build 2026.09) · Developed by RSQUARE'` -> `'ZYKL v1.0.0 (Build 2026.09) · Developed by RSQUARE'`.
  - Update license dialog: `applicationName: 'Takt Desk by RSQUARE'` -> `applicationName: 'ZYKL by RSQUARE'`.
  - Update test expectation in `test/features/settings/takt_settings_sheet_test.dart`.

- [ ] **Step 3: Verify tests and Kotlin build**
  ```bash
  flutter test test/features/settings/takt_settings_sheet_test.dart
  cd android && ./gradlew compileReleaseKotlin && cd ..
  ```

- [ ] **Step 4: Commit changes**
  ```bash
  git add android/app/src/main/kotlin/com/zykl/app/TimerForegroundService.kt lib/features/settings/presentation/takt_settings_sheet.dart test/features/settings/takt_settings_sheet_test.dart
  git commit -m "chore(branding): rebrand application strings and notification titles from Takt Desk to ZYKL"
  ```

---

### Task 2: Flutter Data Sync Pipeline Pro State Propagation

**Files:**
- Modify: `lib/core/services/app_widget_service.dart`
- Modify: `test/core/services/app_widget_service_test.dart`
- Modify: `test/features/desk/app_widget_integration_test.dart`

- [ ] **Step 1: Add isPro parameter to updateAllWidgetData in app_widget_service.dart**
  - Signature: `updateAllWidgetData({..., required bool isPro})`.
  - MethodChannel payload includes `'isPro': isPro`.
  - `appWidgetSyncProvider` watches `settingsControllerProvider.select((s) => s.isProSimulated)`.

- [ ] **Step 2: Update unit & integration tests**
  - Update `test/core/services/app_widget_service_test.dart` to assert `isPro` in payload.
  - Update `test/features/desk/app_widget_integration_test.dart` with `isPro: true` (or test fallback).

- [ ] **Step 3: Run Flutter tests**
  ```bash
  flutter test test/core/services/app_widget_service_test.dart test/features/desk/app_widget_integration_test.dart
  ```

- [ ] **Step 4: Commit changes**
  ```bash
  git add lib/core/services/app_widget_service.dart test/core/services/app_widget_service_test.dart test/features/desk/app_widget_integration_test.dart
  git commit -m "feat(widget): propagate Studio Pro subscription status through app widget sync pipeline"
  ```

---

### Task 3: Android Native Pro State Persistence & Action Dispatching in `MainActivity.kt`

**Files:**
- Modify: `android/app/src/main/kotlin/com/zykl/app/TaktAppWidgetProvider.kt`
- Modify: `android/app/src/main/kotlin/com/zykl/app/MainActivity.kt`

- [ ] **Step 1: Add KEY_IS_PRO in TaktAppWidgetProvider.kt**
  - `const val KEY_IS_PRO = "is_pro"`

- [ ] **Step 2: Persist isPro in MainActivity.kt**
  - In `updateAllWidgetData`: extract `val isPro = call.argument<Boolean>("isPro") ?: false` and store via `.putBoolean(TaktAppWidgetProvider.KEY_IS_PRO, isPro)`.
  - Handle `"getInitialAction"`: return intent extra `"open_feature"`, clearing it afterward.
  - In `onNewIntent(intent: Intent)`: dispatch `"onWidgetAction"` with extra `"open_feature"` over `WIDGET_CHANNEL`.

- [ ] **Step 3: Verify Kotlin compilation**
  ```bash
  cd android && ./gradlew compileReleaseKotlin && cd ..
  ```

- [ ] **Step 4: Commit changes**
  ```bash
  git add android/app/src/main/kotlin/com/zykl/app/TaktAppWidgetProvider.kt android/app/src/main/kotlin/com/zykl/app/MainActivity.kt
  git commit -m "feat(widget): persist Pro status in SharedPreferences and support widget deep-link action dispatching"
  ```

---

### Task 4: Pro Gating in Widget 2 (AW10 Analog Dial) & Widget 3 (Rotary Task Dispenser)

**Files:**
- Modify: `android/app/src/main/kotlin/com/zykl/app/TaktAnalogDialWidgetProvider.kt`
- Modify: `android/app/src/main/kotlin/com/zykl/app/TaktTaskDispenserWidgetProvider.kt`

- [ ] **Step 1: Update TaktAnalogDialWidgetProvider.kt**
  - Read `val isPro = prefs.getBoolean(TaktAppWidgetProvider.KEY_IS_PRO, false)`.
  - When `!isPro`:
    - Time badge displays `"[ STUDIO PRO // UNLOCK ]"` in filament amber (`#FF9E00`).
    - Dial needle remains parked in standby alignment (0°).
    - `launchIntent` adds `putExtra("open_feature", "studio_pro")`.
  - When `isPro`:
    - Full live analog tracking and normal timer launch.

- [ ] **Step 2: Update TaktTaskDispenserWidgetProvider.kt**
  - Read `val isPro = prefs.getBoolean(TaktAppWidgetProvider.KEY_IS_PRO, false)`.
  - When `!isPro`:
    - Header displays `ZYKL // TASK DISPENSER` · `STUDIO PRO`.
    - 5 preview rows:
      1. `[★] STUDIO PRO // UNLOCK`
      2. `[ ] SYNC ACTIVE TASKS`
      3. `[ ] MONOSPACE RECEIPT`
      4. `[ ] ROTARY DISPENSER`
      5. `[ ] LIFETIME Rp 69.000`
    - Footer displays: `[ ★ TAP TO UNLOCK PRO ↗ ]`.
    - `launchIntent` adds `putExtra("open_feature", "studio_pro")`.
  - When `isPro`:
    - Full active tasks from `tasks_json` and normal launch.

- [ ] **Step 3: Verify Kotlin compilation**
  ```bash
  cd android && ./gradlew compileReleaseKotlin && cd ..
  ```

- [ ] **Step 4: Commit changes**
  ```bash
  git add android/app/src/main/kotlin/com/zykl/app/TaktAnalogDialWidgetProvider.kt android/app/src/main/kotlin/com/zykl/app/TaktTaskDispenserWidgetProvider.kt
  git commit -m "feat(widget): implement refined Dieter Rams Studio Pro gating for AW10 Dial and Task Dispenser widgets"
  ```

---

### Task 5: Deep-Link Paywall Navigation in `DeskCanvasScreen`

**Files:**
- Modify: `lib/features/desk/presentation/desk_canvas_screen.dart`
- Modify: `test/features/desk/desk_screen_test.dart`

- [ ] **Step 1: Wire widget deep-link in DeskCanvasScreen**
  - On mount (postFrameCallback), query `AppWidgetService.channel.invokeMethod<String>('getInitialAction')`. If `'studio_pro'`, call `showStudioProDialog(context: context, ref: ref)`.
  - Listen to `AppWidgetService.channel.setMethodCallHandler` for `'onWidgetAction'` with `'studio_pro'`.
  - Clean up channel handler on dispose.

- [ ] **Step 2: Verify tests**
  ```bash
  flutter test test/features/desk/desk_screen_test.dart
  ```

- [ ] **Step 3: Commit changes**
  ```bash
  git add lib/features/desk/presentation/desk_canvas_screen.dart test/features/desk/desk_screen_test.dart
  git commit -m "feat(desk): open Studio Pro dialog when launched via Studio Pro widget deep-link"
  ```

---

### Task 6: Full Verification, Static Analysis, and Release APK Build

**Files:**
- Output APKs: `/home/tuneeca/RSQUARE/ZYKL_Release.apk` and `/home/tuneeca/RSQUARE/Takt_Desk_Release.apk`

- [ ] **Step 1: Run full test suite**
  ```bash
  flutter test
  ```
  Expected: 100% PASS.

- [ ] **Step 2: Run static analyzer**
  ```bash
  flutter analyze
  ```
  Expected: 0 issues.

- [ ] **Step 3: Verify namespace cleanliness**
  ```bash
  git diff 4d57f22..HEAD | grep -i "tuneeca" || true
  ```
  Expected: 0 occurrences.

- [ ] **Step 4: Build release APK**
  ```bash
  flutter build apk --release
  ```

- [ ] **Step 5: Deploy release APK**
  ```bash
  cp build/app/outputs/flutter-apk/app-release.apk /home/tuneeca/RSQUARE/ZYKL_Release.apk
  cp build/app/outputs/flutter-apk/app-release.apk /home/tuneeca/RSQUARE/Takt_Desk_Release.apk
  ```
