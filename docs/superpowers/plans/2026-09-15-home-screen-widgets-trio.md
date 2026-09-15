# ZYKL Android Home Screen Widgets Trio (4x1 Strip, 2x2 Analog Dial, 4x2 Task Dispenser) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and deploy a complete suite of three hardware-inspired Android Home Screen Widgets (4x1 Monastic Focus Strip, 2x2 AW10 Pure Analog Dial Face, 4x2 Rotary Task Dispenser Strip) adhering to Dieter Rams / Braun modernist industrial aesthetics.

**Architecture:**
- **Flutter Sync:** `AppWidgetService` and `appWidgetSyncProvider` observe `todayFocusStatsProvider`, `chronoDialControllerProvider`, and `appDatabase.watchActiveTasks()`, batching updates across `com.takt.desk/app_widget` MethodChannel (`updateAllWidgetData`).
- **Native Android Layer:** `MainActivity.kt` stores the unified state into `takt_widget_prefs` SharedPreferences and notifies all registered AppWidgetProviders via `AppWidgetManager.updateAppWidget()`.
- **Three AppWidgetProviders:**
  1. `TaktFocusStripWidgetProvider` (4x1): Ultra-compact horizontal bar showing status, 4 quadrant Micro-LEDs, and direct start/pause action button.
  2. `TaktAnalogDialWidgetProvider` (2x2): Pure Braun AW10 dial face with procedural Kotlin Canvas rendering the amber needle (`#FF9E00`) indicating real-time focus elapsed angle.
  3. `TaktTaskDispenserWidgetProvider` (4x2): Thermal receipt slip presentation with serrated sawtooth edge displaying up to 5 active tasks with checkboxes and direct app drawer shortcut.

**Tech Stack:** Flutter, Dart, Android SDK, Kotlin, RemoteViews, AppWidgetProvider, SharedPreferences.

## Global Constraints
- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetics (honest materials, basalt slate `#14171A`, warm bone `#F5F3EB`, filament amber `#FF9E00`, monospace typography).
- Clean namespace: Absolutely 0 occurrences of `tuneeca` across Kotlin, Dart, XML, and Gradle files (`com.zykl.app` / `com.takt.desk`).
- 0 analyzer issues (`/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`).
- 100% test pass rate across repository (`/home/tuneeca/RSQUARE/flutter/bin/flutter test`).
- Production release APK successfully compiled and deployed to `/home/tuneeca/RSQUARE/ZYKL_Release.apk` and `Takt_Desk_Release.apk`.

---

### Task 1: Flutter Data Sync Pipeline Enhancement (`AppWidgetService` & `appWidgetSyncProvider`)

**Files:**
- Modify: `lib/core/services/app_widget_service.dart`
- Test: `test/core/services/app_widget_service_test.dart`

**Interfaces:**
- Consumes: `todayFocusStatsProvider`, `chronoDialControllerProvider`, `appDatabaseProvider.watchActiveTasks()`.
- Produces: `AppWidgetService.updateAllWidgetData(...)` broadcasting consolidated widget state payload over `MethodChannel('com.takt.desk/app_widget')`.

- [ ] **Step 1: Write failing unit tests in test/core/services/app_widget_service_test.dart**

```dart
test('AppWidgetService invokes updateAllWidgetData with full payload', () async {
  // Verify channel receives cyclesCompleted, minutesFocused, status, remainingSeconds, targetMinutes, tasks
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/services/app_widget_service_test.dart
```

- [ ] **Step 3: Implement updateAllWidgetData in app_widget_service.dart**

Add `updateAllWidgetData` method and update `appWidgetSyncProvider` to watch active tasks and timer details.

- [ ] **Step 4: Run test to verify it passes**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/services/app_widget_service_test.dart
```

- [ ] **Step 5: Commit changes**

```bash
git add lib/core/services/app_widget_service.dart test/core/services/app_widget_service_test.dart
git commit -m "feat(widget): enhance AppWidgetService and sync provider to broadcast consolidated multi-widget state"
```

---

### Task 2: Android Native Platform Channel Handler in `MainActivity.kt`

**Files:**
- Modify: `android/app/src/main/kotlin/com/zykl/app/MainActivity.kt`

**Interfaces:**
- Consumes: `updateAllWidgetData` call on `WIDGET_CHANNEL`.
- Produces: Persists state to `takt_widget_prefs` and dispatches update broadcasts to all 4 AppWidgetProviders.

- [ ] **Step 1: Implement updateAllWidgetData in MainActivity.kt**

Extract and serialize cycles, minutes, status, remainingSeconds, targetMinutes, and tasks JSON into SharedPreferences.

- [ ] **Step 2: Verify Kotlin compilation**

```bash
cd android && ./gradlew compileReleaseKotlin && cd ..
```

- [ ] **Step 3: Commit changes**

```bash
git add android/app/src/main/kotlin/com/zykl/app/MainActivity.kt
git commit -m "feat(widget): implement updateAllWidgetData handler in MainActivity"
```

---

### Task 3: Widget 1 — "Monastic Focus Strip" (4x1) Implementation

**Files:**
- Create: `android/app/src/main/res/layout/takt_appwidget_focus_strip_4x1.xml`
- Create: `android/app/src/main/res/xml/takt_appwidget_focus_strip_info.xml`
- Create: `android/app/src/main/kotlin/com/zykl/app/TaktFocusStripWidgetProvider.kt`
- Modify: `android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Consumes: `takt_widget_prefs` (cycles, minutes, status, remainingSeconds).
- Produces: 4x1 horizontal bar widget with 4 Micro-LEDs, timer status, and start/pause action button.

- [ ] **Step 1: Create layout takt_appwidget_focus_strip_4x1.xml**
- [ ] **Step 2: Create metadata takt_appwidget_focus_strip_info.xml**
- [ ] **Step 3: Create TaktFocusStripWidgetProvider.kt**
- [ ] **Step 4: Register receiver in AndroidManifest.xml**
- [ ] **Step 5: Verify Kotlin compilation**

```bash
cd android && ./gradlew compileReleaseKotlin && cd ..
```

- [ ] **Step 6: Commit changes**

```bash
git add android/app/src/main/res/ android/app/src/main/kotlin/ android/app/src/main/AndroidManifest.xml
git commit -m "feat(widget): implement Monastic Focus Strip 4x1 home screen widget"
```

---

### Task 4: Widget 2 — "AW10 Pure Analog Dial Face" (2x2) Implementation

**Files:**
- Create: `android/app/src/main/res/layout/takt_appwidget_analog_dial_2x2.xml`
- Create: `android/app/src/main/res/xml/takt_appwidget_analog_dial_info.xml`
- Create: `android/app/src/main/kotlin/com/zykl/app/TaktAnalogDialWidgetProvider.kt`
- Modify: `android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Consumes: `takt_widget_prefs` (remainingSeconds, targetMinutes, status).
- Produces: 2x2 circular AW10 dial widget with procedural Kotlin Canvas rendering the amber needle at the exact elapsed angle.

- [ ] **Step 1: Create layout takt_appwidget_analog_dial_2x2.xml**
- [ ] **Step 2: Create metadata takt_appwidget_analog_dial_info.xml**
- [ ] **Step 3: Create TaktAnalogDialWidgetProvider.kt with Canvas needle rendering**
- [ ] **Step 4: Register receiver in AndroidManifest.xml**
- [ ] **Step 5: Verify Kotlin compilation**

```bash
cd android && ./gradlew compileReleaseKotlin && cd ..
```

- [ ] **Step 6: Commit changes**

```bash
git add android/app/src/main/res/ android/app/src/main/kotlin/ android/app/src/main/AndroidManifest.xml
git commit -m "feat(widget): implement AW10 Pure Analog Dial Face 2x2 widget with procedural needle rendering"
```

---

### Task 5: Widget 3 — "Rotary Task Dispenser Strip" (4x2) Implementation

**Files:**
- Create: `android/app/src/main/res/layout/takt_appwidget_task_dispenser_4x2.xml`
- Create: `android/app/src/main/res/xml/takt_appwidget_task_dispenser_info.xml`
- Create: `android/app/src/main/kotlin/com/zykl/app/TaktTaskDispenserWidgetProvider.kt`
- Modify: `android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Consumes: `takt_widget_prefs` (`tasks_json`).
- Produces: 4x2 thermal receipt slip widget presenting up to 5 active tasks with monospace checkboxes and direct app drawer launching.

- [ ] **Step 1: Create layout takt_appwidget_task_dispenser_4x2.xml**
- [ ] **Step 2: Create metadata takt_appwidget_task_dispenser_info.xml**
- [ ] **Step 3: Create TaktTaskDispenserWidgetProvider.kt**
- [ ] **Step 4: Register receiver in AndroidManifest.xml**
- [ ] **Step 5: Verify Kotlin compilation**

```bash
cd android && ./gradlew compileReleaseKotlin && cd ..
```

- [ ] **Step 6: Commit changes**

```bash
git add android/app/src/main/res/ android/app/src/main/kotlin/ android/app/src/main/AndroidManifest.xml
git commit -m "feat(widget): implement Rotary Task Dispenser 4x2 thermal receipt widget"
```

---

### Task 6: Verification, Static Analysis, and Production Release APK Build

**Files:**
- Output APKs: `/home/tuneeca/RSQUARE/ZYKL_Release.apk` and `/home/tuneeca/RSQUARE/Takt_Desk_Release.apk`

- [ ] **Step 1: Run full test suite**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test
```
Expected: 100% tests pass.

- [ ] **Step 2: Run static analyzer**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter analyze
```
Expected: 0 issues found.

- [ ] **Step 3: Verify namespace hygiene**

```bash
git diff edc4c0a..HEAD | grep -i "tuneeca" || true
```
Expected: 0 occurrences.

- [ ] **Step 4: Build release APK**

```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter build apk --release
```

- [ ] **Step 5: Deploy release APKs**

```bash
cp build/app/outputs/flutter-apk/app-release.apk /home/tuneeca/RSQUARE/ZYKL_Release.apk
cp build/app/outputs/flutter-apk/app-release.apk /home/tuneeca/RSQUARE/Takt_Desk_Release.apk
```
