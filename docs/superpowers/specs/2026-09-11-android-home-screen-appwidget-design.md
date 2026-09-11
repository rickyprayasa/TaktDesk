# Design Spec: Android Home Screen AppWidget (2x2 Modular Horological Cube)

**Date:** 2026-09-11  
**Feature:** Android Home Screen AppWidget (2x2 Modular Horological Cube)  
**Platform:** Android Mobile Console (Takt Desk, Braun / Dieter Rams Industrial Aesthetic)

---

## 1. Overview & Philosophy

Takt Desk is an analog monastic desk console inspired by Dieter Rams' 1960s Braun design principles (*"Weniger, aber besser"* / *"Less, but better"*). 

While the console primarily serves as an immersive tabletop instrument when open, users need a seamless, glanceable presence on their Android home screen to monitor daily progress without breaking their current workflow.

This feature introduces a native **2x2 Modular Horological Cube AppWidget** on Android homescreens:
- **Glanceable Telemetry:** Displays today's completed Pomodoro cycles (`TODAY: X / 4 CYCLES`), 4 glowing micro-LED indicators (`● ● ○ ○`), total minutes focused, and current console state (`STANDBY`, `FOCUSING`, `BREAK`).
- **Dieter Rams / Braun Modernist Aesthetic:** Matte charcoal chassis (`#141414`), fine metallic border (`#2A2A2A`), debossed plate header, warm bone typography (`#F2EFE9`), and signature amber glow (`#FF9E00`).
- **Zero External Dependencies:** Implemented using Android native `RemoteViews` + `AppWidgetProvider` paired with a Flutter Riverpod listener over `MethodChannel('com.takt.desk/app_widget')`. No third-party packages or native build bloat.
- **Battery-First Architecture:** Event-driven updates triggered exclusively on session completion and timer state transitions. Zero continuous background polling or CPU wakeups.
- **Smart Direct Launch:** Tapping anywhere on the widget smoothly brings Takt Desk to the foreground via `PendingIntent.getActivity` targeting `MainActivity` without restarting the process if already in memory.

---

## 2. Architecture & Data Flow

```
┌───────────────────────────────────────────────────────────────┐
│                        FLUTTER LAYER                          │
│                                                               │
│  AppDatabase (Drift SQLite)       ChronoDialProvider          │
│          │                                │                   │
│          ▼                                ▼                   │
│   watchTodaySessions()             TimerState updates         │
│          │                                │                   │
│          └────────────────┬───────────────┘                   │
│                           ▼                                   │
│            AppWidgetService (Riverpod Listener)               │
└───────────────────────────┬───────────────────────────────────┘
                            │ MethodChannel:
                            │ 'com.takt.desk/app_widget'
                            │   invokeMethod('updateWidgetData', {
                            │     'cyclesCompleted': 2,
                            │     'cyclesTarget': 4,
                            │     'minutesFocused': 50,
                            │     'status': 'STANDBY'
                            │   })
                            ▼
┌───────────────────────────────────────────────────────────────┐
│                    NATIVE ANDROID LAYER                       │
│                                                               │
│  MainActivity.kt (MethodCallHandler)                          │
│          │                                                    │
│          ├──> TaktWidgetPreferences (SharedPreferences)       │
│          │    (Stores latest telemetry locally)               │
│          │                                                    │
│          └──> TaktAppWidgetProvider.updateAll(context)        │
│                    │                                          │
│                    ▼                                          │
│               RemoteViews (takt_appwidget_2x2.xml)            │
│               - Update 4 Micro-LED drawables (Amber / Dim)    │
│               - Update text: 'TODAY: 2 / 4 CYCLES'            │
│               - Update text: '50 MIN FOCUSED'                 │
│               - Update text: 'STATUS: STANDBY'                │
│               - AppWidgetManager.updateAppWidget(...)         │
└───────────────────────────────────────────────────────────────┘
```

---

## 3. Visual & Layout Specifications

### 3.1 Dimensions & Grid
- **Widget Category:** Home Screen 2x2 Cell (`targetCellWidth="2"`, `targetCellHeight="2"`).
- **Default Resolution:** 140dp x 140dp minimum, expanding adaptively up to launcher grid dimensions (~180dp x 180dp).
- **Corner Radius:** 20dp smooth squircle corners conforming to modern Android widget design guidelines while retaining industrial sharpness.

### 3.2 Visual Mockup
```
┌──────────────────────────────────────┐
│ [●] TAKT DESK         MOD. 01 · 1960 │ <- Header debossed metal plate
│ ──────────────────────────────────── │ <- Divider line (#2A2A2A)
│                                      │
│           ●  ●  ○  ○                 │ <- 4 Micro-LED indicators
│                                      │    (Amber glow #FF9E00 vs Dim #2A2A2A)
│         TODAY: 2 / 4 CYCLES          │ <- Primary telemetry (Warm Bone #F2EFE9)
│                                      │
│           50 MIN FOCUSED             │ <- Secondary telemetry (Muted Gray #8E8E93)
│                                      │
│ ──────────────────────────────────── │
│  STATUS: STANDBY       [ OPEN ↗ ]   │ <- Footer status & tactile glyph
└──────────────────────────────────────┘
```

### 3.3 Color Palette & Resources
- **Chassis Background:** `@drawable/widget_chassis_bg` (`#141414` charcoal with `#2A2A2A` 1.5dp rim border).
- **LED Active (Amber Glow):** `@drawable/ic_widget_led_amber` (`#FF9E00` solid fill with diffuse outer halo).
- **LED Inactive (Dim Slate):** `@drawable/ic_widget_led_dim` (`#222222` recessed bezel with `#141414` core).
- **Divider:** `@drawable/widget_divider` (`#2A2A2A` 1dp solid bar).
- **Typography:**
  - Primary Text: `#F2EFE9` (Warm Bone White), Sans-Serif Monospaced, Bold / Medium.
  - Secondary Text: `#8E8E93` (Muted Metallic Gray).
  - Accent Text: `#FF9E00` (Braun Amber).

---

## 4. Detailed Component Implementation

### 4.1 Flutter Layer: `AppWidgetService`
- **Location:** `lib/core/services/app_widget_service.dart`
- **Responsibilities:**
  - Expose `appWidgetServiceProvider` via Riverpod.
  - Expose `updateWidgetData({required int cyclesCompleted, required int cyclesTarget, required int minutesFocused, required String status})`.
  - Listen to `AppDatabase.watchTodaySessions()` and `chronoDialControllerProvider` in application lifecycle or main widget tree.
  - Calculate total minutes focused from completed today sessions (`durationSeconds / 60`).
  - Calculate completed cycles (`completedSessions.length % 4` or total count depending on desk spec definition).
  - Safely invoke MethodChannel `com.takt.desk/app_widget`.

### 4.2 Native Android Layer: `TaktAppWidgetProvider`
- **Location:** `android/app/src/main/kotlin/com/example/takt_desk/TaktAppWidgetProvider.kt`
- **Responsibilities:**
  - Extends `AppWidgetProvider`.
  - Companion method `updateAllWidgets(context: Context)` query all active widget IDs from `AppWidgetManager` and re-renders them.
  - In `onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray)`:
    1. Read persisted values from `SharedPreferences` (`"takt_widget_prefs"`).
    2. Inflate `RemoteViews(context.packageName, R.layout.takt_appwidget_2x2)`.
    3. Update TextView contents (`widget_cycles_text`, `widget_minutes_text`, `widget_status_text`).
    4. Update ImageView drawables for the 4 LED indicators (`led_1` through `led_4`).
    5. Attach `PendingIntent.getActivity` to root layout (`widget_root`) with flags:
       `Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP`.
    6. Call `appWidgetManager.updateAppWidget(appWidgetId, views)`.

### 4.3 Native Android Resources
- `android/app/src/main/res/layout/takt_appwidget_2x2.xml` (RemoteViews XML layout).
- `android/app/src/main/res/xml/takt_appwidget_info.xml` (AppWidget metadata definition).
- `android/app/src/main/res/drawable/widget_chassis_bg.xml` (Matte dark rounded background).
- `android/app/src/main/res/drawable/ic_widget_led_amber.xml` (Active amber micro-LED).
- `android/app/src/main/res/drawable/ic_widget_led_dim.xml` (Inactive recessed micro-LED).
- `android/app/src/main/res/drawable/widget_divider.xml` (Thin metallic separator).

### 4.4 Manifest Declaration
Register the broadcast receiver in `android/app/src/main/AndroidManifest.xml`:
```xml
<receiver
    android:name=".TaktAppWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/takt_appwidget_info" />
</receiver>
```

---

## 5. Error Handling & Edge Cases

1. **Cold Boot & Device Restart:**
   - Android system automatically triggers `ACTION_APPWIDGET_UPDATE` on device boot.
   - `TaktAppWidgetProvider` instantly reads from `SharedPreferences` without waiting for the Flutter engine or Dart VM to start.
2. **First Run / Zero Data:**
   - Default fallbacks: `cyclesCompleted = 0`, `cyclesTarget = 4`, `minutesFocused = 0`, `status = "STANDBY"`.
   - All 4 LEDs default to inactive dim state.
3. **App in Memory vs Killed:**
   - `PendingIntent.getActivity` with `FLAG_ACTIVITY_SINGLE_TOP` brings the existing activity to front without destroying active timer states.
   - If app was killed, standard launch brings user to initial console state.
4. **Namespace Integrity:**
   - All MethodChannel strings strictly adhere to `com.takt.desk/app_widget`.
   - Zero occurrences of `tuneeca` anywhere in Dart, Kotlin, XML, or Gradle files.

---

## 6. Testing & Quality Gates

1. **Flutter Unit & Integration Tests:**
   - `test/core/app_widget_service_test.dart`: Test `AppWidgetService` method channel communication and payload serialization.
   - Test integration with `AppDatabase.watchTodaySessions()` and `TimerState`.
2. **Android XML Validation:**
   - Run `xmllint --noout` on all created XML layouts and drawables.
3. **Static Analysis & Full Suite:**
   - `flutter analyze`: 0 warnings, 0 errors.
   - `flutter test`: 100% pass rate across entire repository (260+ tests).
4. **Kotlin Compilation:**
   - Clean compilation via local Gradle daemon.
