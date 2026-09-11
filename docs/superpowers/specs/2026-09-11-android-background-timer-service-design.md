# Design Spec: Android Background Timer Service & Lockscreen/AOD Telemetry

**Date:** 2026-09-11  
**Feature:** Android Background Timer Service & Lockscreen/AOD Telemetry (Approach 1)  
**Platform:** Android Mobile Console (Takt Desk, Braun / Dieter Rams Industrial Aesthetic)

---

## 1. Overview & Philosophy

Takt Desk is designed as an analog monastic desk console—a dedicated, single-purpose focus instrument inspired by Dieter Rams' 1960 Braun aesthetics. When placed on a desk stand with screen-on mode active, it serves as a tabletop horological clock.

However, during extended focus sessions (e.g., 50-minute Monastic blocks), users frequently press the hardware power button to turn off the screen to conserve battery or reduce ambient illumination in dim environments. Without a dedicated Android system integration:
1. Android OS Doze Mode and aggressive OEM battery optimizers suspend CPU threads, causing Flutter tickers and background timers to freeze or drift.
2. Background ambient audio (vinyl rain/cafe) is terminated by the OS media manager.
3. The session completion chime fails to ring on time, compromising trust in the instrument.

This specification details the implementation of **Approach 1: Native Android Foreground Service + Native OS Chronometer**. This approach ensures:
- **Zero CPU wakeups during countdown:** The lockscreen and Always-On Display (AOD) countdown is rendered natively by Android's SystemUI using `setUsesChronometer(true)` and `setChronometerCountDown(true)` without waking Flutter or draining battery.
- **Read-Only Lockscreen Telemetry:** Clean, unobtrusive status reporting on Lockscreen/AOD without interactive buttons to prevent accidental pocket taps.
- **Screen-Off Audio & Bell Chime Reliability:** Keeps ambient vinyl tracks running and guarantees the analog bell chime (`foley_bell_chime.wav`) and tactile haptic pulse sound exactly on time.
- **Clean Namespace Harmonization:** Replaces all legacy `com.tuneeca.takt_desk` identifiers across Kotlin and Dart with `com.takt.desk`.

---

## 2. Architecture & Data Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                         FLUTTER CLIENT                           │
│  ChronoDialController ──> ChronoDialProvider (TimerState)         │
│          │                                                       │
│          ▼                                                       │
│  TimerBackgroundService (Riverpod Listener)                      │
└─────────────────────────────────┬────────────────────────────────┘
                                  │ MethodChannel:
                                  │ 'com.takt.desk/timer_service'
                                  ▼
┌──────────────────────────────────────────────────────────────────┐
│                     NATIVE ANDROID LAYER                         │
│  MainActivity ──> TimerForegroundService (Android Service)        │
│          ├── NotificationManager (Lockscreen / AOD Chronometer)  │
│          ├── SystemClock.elapsedRealtime() Base Countdown        │
│          ├── FoleyBellPlayer (Completion Chime & Dual-Tap Pulse) │
│          └── WakeLock (Transient 2.5s wake for bell chime)       │
└──────────────────────────────────────────────────────────────────┘
```

### 2.1 Namespace Harmonization
Update existing MethodChannels and package namespace from `com.tuneeca.takt_desk` to `com.takt.desk`:
- Audio Channel: `com.takt.desk/audio`
- Focus Lock Channel: `com.takt.desk/focus_lock`
- Timer Service Channel: `com.takt.desk/timer_service`

Files impacted:
- `lib/core/audio/audio_service.dart`
- `lib/core/focus/focus_lock_service.dart`
- `android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt`

---

## 3. Flutter Client Layer

### 3.1 `TimerBackgroundService` (`lib/core/services/timer_background_service.dart`)

The Flutter client acts as an orchestrator, translating `TimerState` lifecycle events into native service calls:

```dart
class TimerBackgroundService {
  static const MethodChannel _channel = MethodChannel('com.takt.desk/timer_service');

  Future<void> start({
    required double remainingSeconds,
    required int targetMinutes,
    required PomodoroPhase phase,
    required int cycleCount,
    required String profileName,
  }) async {
    try {
      await _channel.invokeMethod('startService', {
        'remainingSeconds': remainingSeconds,
        'targetMinutes': targetMinutes,
        'phase': phase.name,
        'cycleCount': cycleCount,
        'profileName': profileName,
      });
    } catch (_) {
      // Graceful fallback if unsupported platform
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopService');
    } catch (_) {}
  }
}
```

### 3.2 Riverpod Integration
In `ChronoDialWidget` or app lifecycle watcher:
- When `isRunning` transitions from `false` to `true`: calls `timerBackgroundService.start(...)`.
- When `isRunning` transitions from `true` to `false`: calls `timerBackgroundService.stop()`.
- When timer completes in background and app is brought to foreground: Flutter checks `DateTime.now()` difference and seamlessly updates dial state.

---

## 4. Native Android Foreground Service

### 4.1 `TimerForegroundService.kt`
Location: `android/app/src/main/kotlin/com/example/takt_desk/TimerForegroundService.kt`

Key responsibilities:
1. **Notification Channels Creation (`onCreate`):**
   - **`takt_desk_timer_channel`:**
     - Name: `"Takt Desk Active Timer"`
     - Importance: `NotificationManager.IMPORTANCE_LOW` (no intrusive heads-up popups during deep work).
     - Sound: `null` (silent while ticking).
     - Lockscreen Visibility: `NotificationCompat.VISIBILITY_PUBLIC`.
   - **`takt_desk_alert_channel`:**
     - Name: `"Takt Desk Session Alerts"`
     - Importance: `NotificationManager.IMPORTANCE_HIGH` (wakes screen/heads-up on completion).
     - Lockscreen Visibility: `NotificationCompat.VISIBILITY_PUBLIC`.

2. **Native Chronometer Configuration:**
   Calculate exact hardware uptime target:
   ```kotlin
   val remainingMillis = (remainingSeconds * 1000).toLong()
   val baseTime = SystemClock.elapsedRealtime() + remainingMillis
   ```
   Notification builder attributes:
   - `setSmallIcon(R.drawable.ic_takt_timer)`
   - `setContentTitle(formatPhaseTitle(phase, cycleCount))`
     - Focus: `"TAKT DESK · FOCUS (CYCLE $cycleCount/4)"`
     - Short Break: `"TAKT DESK · SHORT BRK"`
     - Long Break: `"TAKT DESK · LONG BRK"`
   - `setContentText("$targetMinutes MIN · $profileName")`
   - `setOngoing(true)`
   - `setColor(0xFFFF9E00.toInt())` (Braun Amber accent)
   - `setShowWhen(false)`
   - `setUsesChronometer(true)`
   - `setChronometerCountDown(true)`
   - `setBase(baseTime)`
   - `setVisibility(NotificationCompat.VISIBILITY_PUBLIC)`
   - `setContentIntent(openAppPendingIntent)`

3. **Background Completion Watcher:**
   A native Kotlin coroutine or `Handler` scheduled at `remainingMillis`:
   - Acquires transient partial `WakeLock` (max 3 seconds).
   - Plays `foley_bell_chime.wav` via `MediaPlayer`.
   - Fires mechanical double-tap haptic pulse: `longArrayOf(0, 120, 80, 120)`.
   - Posts completion notification on `takt_desk_alert_channel`:
     - Title: `"TAKT DESK · $phaseLabel COMPLETED"`
     - Text: `"Standby active. Tap to enter console and begin next phase."`
     - Ongoing: `false`
   - Stops the foreground service (`stopForeground(STOP_FOREGROUND_DETACH)`).

---

## 5. Android Manifest & Permissions

Update `android/app/src/main/AndroidManifest.xml`:
```xml
<!-- Background Service & Notifications -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />

<application ...>
    ...
    <service
        android:name=".TimerForegroundService"
        android:exported="false"
        android:foregroundServiceType="specialUse">
        <property
            android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
            android:value="Analog mechanical pomodoro countdown and screen-off foley audio synchronization" />
    </service>
</application>
```

---

## 6. Testing & Quality Gates

1. **Flutter Tests:**
   - Unit tests for `TimerBackgroundService` verifying correct method channel invocations (`startService`, `stopService`).
   - Widget tests for `ChronoDialWidget` verifying start/stop calls when timer toggles.
   - Maintain 100% test pass rate across all existing 252+ tests.
2. **Static Analysis:**
   - 0 issues on `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`.
3. **Android Build & Lint:**
   - Clean compilation of Kotlin code with no syntax or deprecation errors.
