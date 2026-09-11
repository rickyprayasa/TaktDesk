# Android Home Screen AppWidget (2x2 Modular Horological Cube) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a native 2x2 Android Home Screen AppWidget displaying Takt Desk's daily Pomodoro telemetry (cycles completed, 4 amber micro-LEDs, minutes focused, and status) adhering to Dieter Rams / Braun modernist industrial aesthetics with smart direct launch and zero external dependencies.

**Architecture:** A native Android `AppWidgetProvider` with `RemoteViews` XML layout reads persisted telemetry from `SharedPreferences`. Flutter updates this state via `MethodChannel('com.takt.desk/app_widget')` from an event-driven `AppWidgetService` observing Drift SQLite today sessions and `ChronoDialController` state.

**Tech Stack:** Android AppWidget SDK (`AppWidgetProvider`, `RemoteViews`, `PendingIntent`), Kotlin, Android XML Drawables/Layouts, Flutter 3.x, Dart, Riverpod, Drift (SQLite).

## Global Constraints
- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetic (honest materials, uncluttered typography, amber `#FF9E00` accent, matte `#141414` chassis).
- Clean namespace: Absolutely 0 occurrences of `tuneeca` across Kotlin, Dart, XML, and Gradle files (`com.takt.desk`).
- Zero external package bloat: Native Android RemoteViews + standard Flutter `MethodChannel` without third-party plugins.
- Battery-first: Event-driven updates triggered exclusively on session completion and timer state transitions; zero background polling loops.
- 0 analyzer issues (`/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`).
- 100% test pass rate across repository (`/home/tuneeca/RSQUARE/flutter/bin/flutter test`).
- Clean Kotlin compilation via local Gradle daemon.

---

### Task 1: Android Native Layout & Vector Resources

**Files:**
- Create: `android/app/src/main/res/drawable/widget_chassis_bg.xml`
- Create: `android/app/src/main/res/drawable/ic_widget_led_amber.xml`
- Create: `android/app/src/main/res/drawable/ic_widget_led_dim.xml`
- Create: `android/app/src/main/res/drawable/widget_divider.xml`
- Create: `android/app/src/main/res/layout/takt_appwidget_2x2.xml`
- Create: `android/app/src/main/res/xml/takt_appwidget_info.xml`

**Interfaces:**
- Produces: RemoteViews layout ID `R.layout.takt_appwidget_2x2`, view IDs `widget_root`, `led_1`, `led_2`, `led_3`, `led_4`, `widget_cycles_text`, `widget_minutes_text`, `widget_status_text`, and widget info metadata `@xml/takt_appwidget_info`.

- [ ] **Step 1: Create drawables and background resources**

`android/app/src/main/res/drawable/widget_chassis_bg.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <solid android:color="#141414" />
    <stroke
        android:width="1.5dp"
        android:color="#2A2A2A" />
    <corners android:radius="20dp" />
</shape>
```

`android/app/src/main/res/drawable/ic_widget_led_amber.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="12dp"
    android:height="12dp"
    android:viewportWidth="12"
    android:viewportHeight="12">
    <path
        android:pathData="M6,6m-5,0a5,5 0 1,0 10,0a5,5 0 1,0 -10,0"
        android:fillColor="#FF9E00" />
</vector>
```

`android/app/src/main/res/drawable/ic_widget_led_dim.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="12dp"
    android:height="12dp"
    android:viewportWidth="12"
    android:viewportHeight="12">
    <path
        android:pathData="M6,6m-5,0a5,5 0 1,0 10,0a5,5 0 1,0 -10,0"
        android:fillColor="#222222" />
</vector>
```

`android/app/src/main/res/drawable/widget_divider.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <solid android:color="#2A2A2A" />
    <size android:height="1dp" />
</shape>
```

- [ ] **Step 2: Create AppWidget Provider Info metadata**

`android/app/src/main/res/xml/takt_appwidget_info.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="140dp"
    android:minHeight="140dp"
    android:targetCellWidth="2"
    android:targetCellHeight="2"
    android:updatePeriodMillis="0"
    android:initialLayout="@layout/takt_appwidget_2x2"
    android:resizeMode="none"
    android:widgetCategory="home_screen"
    android:description="@string/app_name" />
```

- [ ] **Step 3: Create RemoteViews XML Layout**

`android/app/src/main/res/layout/takt_appwidget_2x2.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/widget_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@drawable/widget_chassis_bg"
    android:orientation="vertical"
    android:padding="14dp"
    android:gravity="center_horizontal">

    <!-- Header: Braun Monastic Console -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:gravity="center_vertical">

        <TextView
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="TAKT DESK"
            android:textColor="#F2EFE9"
            android:textSize="10sp"
            android:textStyle="bold"
            android:letterSpacing="0.08"
            android:fontFamily="monospace" />

        <TextView
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="MOD. 01"
            android:textColor="#8E8E93"
            android:textSize="9sp"
            android:letterSpacing="0.05"
            android:fontFamily="monospace" />
    </LinearLayout>

    <View
        android:layout_width="match_parent"
        android:layout_height="1dp"
        android:layout_marginTop="6dp"
        android:layout_marginBottom="10dp"
        android:background="@drawable/widget_divider" />

    <!-- 4 Micro-LED indicators -->
    <LinearLayout
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:gravity="center">

        <ImageView
            android:id="@+id/led_1"
            android:layout_width="10dp"
            android:layout_height="10dp"
            android:layout_marginEnd="6dp"
            android:src="@drawable/ic_widget_led_dim"
            android:contentDescription="Cycle 1 LED" />

        <ImageView
            android:id="@+id/led_2"
            android:layout_width="10dp"
            android:layout_height="10dp"
            android:layout_marginEnd="6dp"
            android:src="@drawable/ic_widget_led_dim"
            android:contentDescription="Cycle 2 LED" />

        <ImageView
            android:id="@+id/led_3"
            android:layout_width="10dp"
            android:layout_height="10dp"
            android:layout_marginEnd="6dp"
            android:src="@drawable/ic_widget_led_dim"
            android:contentDescription="Cycle 3 LED" />

        <ImageView
            android:id="@+id/led_4"
            android:layout_width="10dp"
            android:layout_height="10dp"
            android:src="@drawable/ic_widget_led_dim"
            android:contentDescription="Cycle 4 LED" />
    </LinearLayout>

    <!-- Primary Telemetry: TODAY: X / 4 CYCLES -->
    <TextView
        android:id="@+id/widget_cycles_text"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="8dp"
        android:text="TODAY: 0 / 4 CYCLES"
        android:textColor="#F2EFE9"
        android:textSize="12sp"
        android:textStyle="bold"
        android:letterSpacing="0.05"
        android:fontFamily="monospace" />

    <!-- Secondary Telemetry: 0 MIN FOCUSED -->
    <TextView
        android:id="@+id/widget_minutes_text"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="4dp"
        android:text="0 MIN FOCUSED"
        android:textColor="#8E8E93"
        android:textSize="11sp"
        android:letterSpacing="0.04"
        android:fontFamily="monospace" />

    <View
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1" />

    <View
        android:layout_width="match_parent"
        android:layout_height="1dp"
        android:layout_marginBottom="6dp"
        android:background="@drawable/widget_divider" />

    <!-- Footer: STATUS and OPEN glyph -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:gravity="center_vertical">

        <TextView
            android:id="@+id/widget_status_text"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="STATUS: STANDBY"
            android:textColor="#FF9E00"
            android:textSize="9sp"
            android:textStyle="bold"
            android:letterSpacing="0.05"
            android:fontFamily="monospace" />

        <TextView
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="OPEN ↗"
            android:textColor="#8E8E93"
            android:textSize="9sp"
            android:textStyle="bold"
            android:fontFamily="monospace" />
    </LinearLayout>

</LinearLayout>
```

- [ ] **Step 4: Verify XML syntax**

Run:
```bash
xmllint --noout android/app/src/main/res/drawable/widget_chassis_bg.xml
xmllint --noout android/app/src/main/res/drawable/ic_widget_led_amber.xml
xmllint --noout android/app/src/main/res/drawable/ic_widget_led_dim.xml
xmllint --noout android/app/src/main/res/drawable/widget_divider.xml
xmllint --noout android/app/src/main/res/xml/takt_appwidget_info.xml
xmllint --noout android/app/src/main/res/layout/takt_appwidget_2x2.xml
```
Expected: Exit code 0 (no syntax errors).

- [ ] **Step 5: Commit**

```bash
git add android/app/src/main/res/
git commit -m "chore(android): create 2x2 AppWidget layout and Braun drawables"
```

---

### Task 2: Native Android `TaktAppWidgetProvider` & `MainActivity` Wiring

**Files:**
- Create: `android/app/src/main/kotlin/com/example/takt_desk/TaktAppWidgetProvider.kt`
- Modify: `android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt`
- Modify: `android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Consumes: `R.layout.takt_appwidget_2x2`, `@xml/takt_appwidget_info`, SharedPreferences `"takt_widget_prefs"`.
- Produces: MethodChannel handler for `'com.takt.desk/app_widget'` with method `'updateWidgetData'`.

- [ ] **Step 1: Implement `TaktAppWidgetProvider.kt`**

`android/app/src/main/kotlin/com/example/takt_desk/TaktAppWidgetProvider.kt`:
```kotlin
package com.example.takt_desk

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class TaktAppWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        const val PREFS_NAME = "takt_widget_prefs"
        const val KEY_CYCLES_COMPLETED = "cycles_completed"
        const val KEY_CYCLES_TARGET = "cycles_target"
        const val KEY_MINUTES_FOCUSED = "minutes_focused"
        const val KEY_STATUS = "status"

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, TaktAppWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val cycles = prefs.getInt(KEY_CYCLES_COMPLETED, 0)
            val target = prefs.getInt(KEY_CYCLES_TARGET, 4)
            val minutes = prefs.getInt(KEY_MINUTES_FOCUSED, 0)
            val status = prefs.getString(KEY_STATUS, "STANDBY") ?: "STANDBY"

            val views = RemoteViews(context.packageName, R.layout.takt_appwidget_2x2)

            // Update text telemetries
            views.setTextViewText(R.id.widget_cycles_text, "TODAY: $cycles / $target CYCLES")
            views.setTextViewText(R.id.widget_minutes_text, "$minutes MIN FOCUSED")
            views.setTextViewText(R.id.widget_status_text, "STATUS: $status")

            // Update 4 Micro-LED drawables
            val activeLed = R.drawable.ic_widget_led_amber
            val dimLed = R.drawable.ic_widget_led_dim

            views.setImageViewResource(R.id.led_1, if (cycles >= 1) activeLed else dimLed)
            views.setImageViewResource(R.id.led_2, if (cycles >= 2) activeLed else dimLed)
            views.setImageViewResource(R.id.led_3, if (cycles >= 3) activeLed else dimLed)
            views.setImageViewResource(R.id.led_4, if (cycles >= 4) activeLed else dimLed)

            // Smart direct launch PendingIntent
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
```

- [ ] **Step 2: Wire MethodChannel in `MainActivity.kt`**

In `android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt`:
Register `com.takt.desk/app_widget`:
```kotlin
val widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.takt.desk/app_widget")
widgetChannel.setMethodCallHandler { call, result ->
    when (call.method) {
        "updateWidgetData" -> {
            val cycles = call.argument<Int>("cyclesCompleted") ?: 0
            val target = call.argument<Int>("cyclesTarget") ?: 4
            val minutes = call.argument<Int>("minutesFocused") ?: 0
            val status = call.argument<String>("status") ?: "STANDBY"

            val prefs = getSharedPreferences(TaktAppWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .putInt(TaktAppWidgetProvider.KEY_CYCLES_COMPLETED, cycles)
                .putInt(TaktAppWidgetProvider.KEY_CYCLES_TARGET, target)
                .putInt(TaktAppWidgetProvider.KEY_MINUTES_FOCUSED, minutes)
                .putString(TaktAppWidgetProvider.KEY_STATUS, status)
                .apply()

            TaktAppWidgetProvider.updateAllWidgets(this)
            result.success(true)
        }
        else -> result.notImplemented()
    }
}
```

- [ ] **Step 3: Register receiver in `AndroidManifest.xml`**

In `android/app/src/main/AndroidManifest.xml`:
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

- [ ] **Step 4: Verify Kotlin compilation**

Run:
```bash
cd android && ./gradlew compileDebugKotlin && cd ..
```
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 5: Commit**

```bash
git add android/app/src/main/kotlin/com/example/takt_desk/ android/app/src/main/AndroidManifest.xml
git commit -m "feat(android): implement TaktAppWidgetProvider and MainActivity channel wiring"
```

---

### Task 3: Flutter `AppWidgetService` MethodChannel Client

**Files:**
- Create: `test/core/services/app_widget_service_test.dart`
- Create: `lib/core/services/app_widget_service.dart`

**Interfaces:**
- Produces: `AppWidgetService` class, `appWidgetServiceProvider` Riverpod provider, and `updateWidgetData({required int cyclesCompleted, required int cyclesTarget, required int minutesFocused, required String status})`.

- [ ] **Step 1: Write failing test for `AppWidgetService`**

`test/core/services/app_widget_service_test.dart`:
```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/services/app_widget_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppWidgetService service;
  final List<MethodCall> methodCalls = [];

  setUp(() {
    methodCalls.clear();
    service = const AppWidgetService();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      AppWidgetService.channel,
      (MethodCall call) async {
        methodCalls.add(call);
        return true;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AppWidgetService.channel, null);
  });

  test('channel name matches com.takt.desk/app_widget', () {
    expect(AppWidgetService.channel.name, equals('com.takt.desk/app_widget'));
  });

  test('updateWidgetData invokes method with expected payload', () async {
    final result = await service.updateWidgetData(
      cyclesCompleted: 2,
      cyclesTarget: 4,
      minutesFocused: 50,
      status: 'STANDBY',
    );

    expect(result, isTrue);
    expect(methodCalls, hasLength(1));
    expect(methodCalls.first.method, equals('updateWidgetData'));
    expect(methodCalls.first.arguments, equals({
      'cyclesCompleted': 2,
      'cyclesTarget': 4,
      'minutesFocused': 50,
      'status': 'STANDBY',
    }));
  });

  test('updateWidgetData handles channel errors gracefully without throwing', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      AppWidgetService.channel,
      (MethodCall call) async {
        throw PlatformException(code: 'UNAVAILABLE', message: 'Not supported');
      },
    );

    final result = await service.updateWidgetData(
      cyclesCompleted: 1,
      cyclesTarget: 4,
      minutesFocused: 25,
      status: 'FOCUS',
    );

    expect(result, isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/services/app_widget_service_test.dart
```
Expected: FAIL (file `lib/core/services/app_widget_service.dart` does not exist).

- [ ] **Step 3: Implement `AppWidgetService`**

`lib/core/services/app_widget_service.dart`:
```dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appWidgetServiceProvider = Provider<AppWidgetService>((ref) {
  return const AppWidgetService();
});

class AppWidgetService {
  static const MethodChannel channel = MethodChannel('com.takt.desk/app_widget');

  const AppWidgetService();

  Future<bool> updateWidgetData({
    required int cyclesCompleted,
    required int cyclesTarget,
    required int minutesFocused,
    required String status,
  }) async {
    try {
      final res = await channel.invokeMethod<bool>('updateWidgetData', {
        'cyclesCompleted': cyclesCompleted,
        'cyclesTarget': cyclesTarget,
        'minutesFocused': minutesFocused,
        'status': status,
      });
      return res ?? false;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/services/app_widget_service_test.dart
```
Expected: PASS (3 tests passed).

- [ ] **Step 5: Run flutter analyze**

Run:
```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter analyze
```
Expected: `No issues found!`.

- [ ] **Step 6: Commit**

```bash
git add lib/core/services/app_widget_service.dart test/core/services/app_widget_service_test.dart
git commit -m "feat(service): implement AppWidgetService MethodChannel client"
```

---

### Task 4: Desk Telemetry Synchronization & End-to-End Verification

**Files:**
- Modify: `lib/features/desk/presentation/desk_screen.dart` (or dedicated telemetry sync provider)
- Create: `test/features/desk/app_widget_integration_test.dart`

**Interfaces:**
- Consumes: `todaySessionsProvider`, `chronoDialControllerProvider`, `appWidgetServiceProvider`.
- Produces: Automatic background synchronization to Android homescreen widget on session completion and timer state changes.

- [ ] **Step 1: Create telemetry sync provider or widget binding**

In `lib/core/services/app_widget_service.dart`, add a reactive synchronizer `appWidgetSyncProvider`:
```dart
final appWidgetSyncProvider = Provider.autoDispose<void>((ref) {
  final sessionsAsync = ref.watch(todaySessionsProvider);
  final timerState = ref.watch(chronoDialControllerProvider);
  final widgetService = ref.watch(appWidgetServiceProvider);

  sessionsAsync.whenData((sessions) {
    final completedCount = sessions.where((s) => s.isCompleted).length;
    final totalDuration = sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
    final totalMinutes = totalDuration ~/ 60;
    final cycles = completedCount % 4;

    final String status;
    if (timerState.isRunning) {
      status = timerState.isBreak ? 'BREAK' : 'FOCUS';
    } else {
      status = 'STANDBY';
    }

    widgetService.updateWidgetData(
      cyclesCompleted: cycles,
      cyclesTarget: 4,
      minutesFocused: totalMinutes,
      status: status,
    );
  });
});
```

Mount `ref.watch(appWidgetSyncProvider);` in `DeskScreen` (`lib/features/desk/presentation/desk_screen.dart`).

- [ ] **Step 2: Write integration test**

`test/features/desk/app_widget_integration_test.dart`:
Verify that when `DeskScreen` is mounted with mock today sessions and dial state, `com.takt.desk/app_widget` is called with calculated values.

- [ ] **Step 3: Run test suite**

Run:
```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter test
```
Expected: 100% test pass rate (263+ tests).

- [ ] **Step 4: Run flutter analyze**

Run:
```bash
/home/tuneeca/RSQUARE/flutter/bin/flutter analyze
```
Expected: `No issues found!`.

- [ ] **Step 5: Verify zero namespace pollution**

Run:
```bash
grep -rn "tuneeca" lib/ android/ test/
```
Expected: 0 results found.

- [ ] **Step 6: Commit**

```bash
git add lib/ test/
git commit -m "feat(telemetry): wire reactive appWidgetSyncProvider to sync desk telemetry to Android homescreen"
```
