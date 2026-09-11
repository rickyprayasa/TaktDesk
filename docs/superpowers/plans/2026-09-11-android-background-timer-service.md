# Android Background Timer Service & Lockscreen/AOD Telemetry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a native Android Foreground Service with zero-CPU OS Chronometer countdown on Lockscreen/Always-On Display (AOD), screen-off analog bell chime reliability, and namespace harmonization from `com.tuneeca.takt_desk` to `com.takt.desk`.

**Architecture:** Flutter orchestrates timer state transitions via `MethodChannel('com.takt.desk/timer_service')`. Native Android `TimerForegroundService` publishes a low-importance, public-visibility notification using Android's native `setUsesChronometer` for battery-free lockscreen countdown, keeps vinyl audio playing in deep sleep, and fires `foley_bell_chime.wav` and mechanical haptic pulses upon session completion.

**Tech Stack:** Flutter 3.x, Dart, Riverpod, Kotlin, Android NotificationCompat, Android Foreground Service, Android MethodChannel.

## Global Constraints

- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetics (honest materials, uncluttered typography, amber accent `#FF9E00`).
- Target platform: Mobile Android handheld console (Lockscreen and Always-On Display).
- Battery-first: 0 CPU wakeups per second during countdown; use native Android chronometer.
- Clean namespace: Eliminate all instances of `tuneeca`, migrating to `com.takt.desk`.
- 0 analyzer issues (`/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`).
- 100% test pass rate across the entire repository.

---

### Task 1: Namespace Harmonization (`com.takt.desk`)

**Files:**
- Modify: `lib/core/audio/audio_service.dart:10-15`
- Modify: `lib/core/focus/focus_lock_service.dart:8-12`
- Modify: `android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt:15-20`
- Test: `test/core/audio_service_test.dart`
- Test: `test/core/focus_lock_service_test.dart`

**Interfaces:**
- Consumes: Existing audio and focus lock methods.
- Produces: Normalized `com.takt.desk/audio` and `com.takt.desk/focus_lock` MethodChannels.

- [ ] **Step 1: Write tests verifying new channel names**

Check and verify tests in `test/core/audio_service_test.dart` and `test/core/focus_lock_service_test.dart` expect `com.takt.desk/audio` and `com.takt.desk/focus_lock`.

```dart
// test/core/audio_service_test.dart
test('AudioService registers channel com.takt.desk/audio', () {
  expect(AudioService.channel.name, equals('com.takt.desk/audio'));
});
```

- [ ] **Step 2: Run tests and verify failure**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/`
Expected: FAIL due to channel name mismatch `'com.tuneeca.takt_desk/audio' != 'com.takt.desk/audio'`.

- [ ] **Step 3: Update channel names in Dart and Kotlin**

In `lib/core/audio/audio_service.dart`:
```dart
static const MethodChannel channel = MethodChannel('com.takt.desk/audio');
```

In `lib/core/focus/focus_lock_service.dart`:
```dart
static const MethodChannel channel = MethodChannel('com.takt.desk/focus_lock');
```

In `android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt`:
```kotlin
private val FOCUS_CHANNEL = "com.takt.desk/focus_lock"
private val AUDIO_CHANNEL = "com.takt.desk/audio"
```

- [ ] **Step 4: Run tests to verify PASS**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test`
Expected: PASS with 0 failures.

- [ ] **Step 5: Run flutter analyze**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`
Expected: No issues found!

- [ ] **Step 6: Commit changes**

```bash
git add lib/core/audio/audio_service.dart lib/core/focus/focus_lock_service.dart android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt test/core/
git commit -m "refactor(core): migrate namespace from com.tuneeca to com.takt.desk"
```

---

### Task 2: Flutter Background Timer Service Client

**Files:**
- Create: `lib/core/services/timer_background_service.dart`
- Create: `test/core/timer_background_service_test.dart`

**Interfaces:**
- Consumes: `PomodoroPhase` from `lib/features/timer/domain/pomodoro_phase.dart`
- Produces: `TimerBackgroundService` class and `timerBackgroundServiceProvider` Riverpod provider.

- [ ] **Step 1: Write failing unit test for `TimerBackgroundService`**

Create `test/core/timer_background_service_test.dart`:
```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/services/timer_background_service.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_phase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<MethodCall> log;
  late TimerBackgroundService service;

  setUp(() {
    log = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(TimerBackgroundService.channel, (call) async {
      log.add(call);
      return true;
    });
    service = const TimerBackgroundService();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(TimerBackgroundService.channel, null);
  });

  test('startService sends expected arguments to native channel', () async {
    await service.start(
      remainingSeconds: 1500.0,
      targetMinutes: 25,
      phase: PomodoroPhase.focus,
      cycleCount: 1,
      profileName: 'CLASSIC 25/5',
    );

    expect(log, hasLength(1));
    expect(log.first.method, equals('startService'));
    expect(log.first.arguments['remainingSeconds'], equals(1500.0));
    expect(log.first.arguments['targetMinutes'], equals(25));
    expect(log.first.arguments['phase'], equals('focus'));
    expect(log.first.arguments['cycleCount'], equals(1));
    expect(log.first.arguments['profileName'], equals('CLASSIC 25/5'));
  });

  test('stopService invokes stopService on native channel', () async {
    await service.stop();

    expect(log, hasLength(1));
    expect(log.first.method, equals('stopService'));
  });
}
```

- [ ] **Step 2: Run test and verify failure**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/timer_background_service_test.dart`
Expected: FAIL (file not found / class not defined).

- [ ] **Step 3: Implement `TimerBackgroundService`**

Create `lib/core/services/timer_background_service.dart`:
```dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/timer/domain/pomodoro_phase.dart';

final timerBackgroundServiceProvider = Provider<TimerBackgroundService>((ref) {
  return const TimerBackgroundService();
});

class TimerBackgroundService {
  static const MethodChannel channel = MethodChannel('com.takt.desk/timer_service');

  const TimerBackgroundService();

  Future<bool> start({
    required double remainingSeconds,
    required int targetMinutes,
    required PomodoroPhase phase,
    required int cycleCount,
    required String profileName,
  }) async {
    try {
      final res = await channel.invokeMethod<bool>('startService', {
        'remainingSeconds': remainingSeconds,
        'targetMinutes': targetMinutes,
        'phase': phase.name,
        'cycleCount': cycleCount,
        'profileName': profileName,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> stop() async {
    try {
      final res = await channel.invokeMethod<bool>('stopService');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
```

- [ ] **Step 4: Run test to verify PASS**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/timer_background_service_test.dart`
Expected: PASS (2 tests passed).

- [ ] **Step 5: Run flutter analyze**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`
Expected: No issues found!

- [ ] **Step 6: Commit changes**

```bash
git add lib/core/services/timer_background_service.dart test/core/timer_background_service_test.dart
git commit -m "feat(service): implement TimerBackgroundService MethodChannel client"
```

---

### Task 3: Connect Chrono Dial to `TimerBackgroundService`

**Files:**
- Modify: `lib/features/timer/presentation/chrono_dial_widget.dart`
- Modify: `test/features/timer/chrono_dial_widget_test.dart`

**Interfaces:**
- Consumes: `timerBackgroundServiceProvider`
- Produces: Automatic start/stop background service dispatch synchronized with timer state.

- [ ] **Step 1: Write integration test verifying background service triggers on dial start/pause**

Add test in `test/features/timer/chrono_dial_widget_test.dart`:
```dart
  testWidgets('ChronoDialWidget starts and stops background timer service on state changes', (tester) async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(TimerBackgroundService.channel, (call) async {
      calls.add(call.method);
      return true;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(TimerBackgroundService.channel, null);
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoDialWidget(),
            ),
          ),
        ),
      ),
    );

    // Tap dial to start -> triggers startService
    await tester.tap(dialFinder);
    await tester.pump();
    expect(calls, contains('startService'));

    // Tap dial to pause -> triggers stopService
    await tester.tap(dialFinder);
    await tester.pump();
    expect(calls, contains('stopService'));

    await tester.pumpWidget(const SizedBox());
  });
```

- [ ] **Step 2: Run test and verify failure**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_dial_widget_test.dart`
Expected: FAIL because `ChronoDialWidget` does not yet call `timerBackgroundService`.

- [ ] **Step 3: Update `ChronoDialWidget` to listen to `isRunning` transitions**

In `lib/features/timer/presentation/chrono_dial_widget.dart`:
Add listener in `build()`:
```dart
    ref.listen<bool>(
      chronoDialProvider.select((s) => s.isRunning),
      (previous, isRunning) {
        final currentTimerState = ref.read(chronoDialProvider);
        final bgService = ref.read(timerBackgroundServiceProvider);

        if (isRunning) {
          _lastElapsed = null;
          _accumulatedDelta = 0.0;
          _remainingSecondsNotifier.value = currentTimerState.remainingSeconds;
          if (!_ticker.isActive) {
            _ticker.start();
          }
          bgService.start(
            remainingSeconds: currentTimerState.remainingSeconds,
            targetMinutes: currentTimerState.targetMinutes,
            phase: currentTimerState.phase,
            cycleCount: currentTimerState.cycleCount,
            profileName: currentTimerState.profile.label,
          );
        } else {
          if (_ticker.isActive) {
            _ticker.stop();
          }
          _lastElapsed = null;
          _accumulatedDelta = 0.0;
          _remainingSecondsNotifier.value = currentTimerState.remainingSeconds;
          bgService.stop();
        }
      },
    );
```

- [ ] **Step 4: Run test to verify PASS**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_dial_widget_test.dart`
Expected: PASS (all 17 tests passed).

- [ ] **Step 5: Run flutter analyze**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`
Expected: No issues found!

- [ ] **Step 6: Commit changes**

```bash
git add lib/features/timer/presentation/chrono_dial_widget.dart test/features/timer/chrono_dial_widget_test.dart
git commit -m "feat(timer): connect ChronoDialWidget lifecycle to TimerBackgroundService"
```

---

### Task 4: Android Manifest Permissions & Notification Resources

**Files:**
- Create: `android/app/src/main/res/drawable/ic_takt_timer.xml`
- Modify: `android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Produces: System notification drawable and permission manifest registrations required for Android 14+ foreground service.

- [ ] **Step 1: Create minimalist vector drawable `ic_takt_timer.xml`**

Create `android/app/src/main/res/drawable/ic_takt_timer.xml`:
```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <!-- Outer dial circle -->
    <path
        android:fillColor="@android:color/transparent"
        android:strokeColor="#FFFFFF"
        android:strokeWidth="1.8"
        android:pathData="M12,2A10,10 0,1,0 22,12A10,10 0,0,0 12,2Z"/>
    <!-- Top crown button -->
    <path
        android:fillColor="#FFFFFF"
        android:pathData="M10,0.5h4v1.5h-4z"/>
    <!-- Dial center hand at 15 past -->
    <path
        android:fillColor="@android:color/transparent"
        android:strokeColor="#FFFFFF"
        android:strokeWidth="1.8"
        android:strokeLineCap="round"
        android:pathData="M12,12h4.5M12,12v-3.5"/>
</vector>
```

- [ ] **Step 2: Update `AndroidManifest.xml` with permissions and service**

In `android/app/src/main/AndroidManifest.xml`:
```xml
    <uses-permission android:name="android.permission.ACCESS_NOTIFICATION_POLICY" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.VIBRATE" />
```
And inside `<application>`:
```xml
        <service
            android:name=".TimerForegroundService"
            android:exported="false"
            android:foregroundServiceType="specialUse">
            <property
                android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
                android:value="Analog mechanical pomodoro countdown and screen-off foley audio synchronization" />
        </service>
```

- [ ] **Step 3: Verify XML validity**

Run: `xmllint --noout android/app/src/main/AndroidManifest.xml`
Expected: 0 errors.

- [ ] **Step 4: Commit changes**

```bash
git add android/app/src/main/res/drawable/ic_takt_timer.xml android/app/src/main/AndroidManifest.xml
git commit -m "chore(android): declare foreground service permissions and create ic_takt_timer icon"
```

---

### Task 5: Native Android `TimerForegroundService` & `MainActivity` MethodChannel Wiring

**Files:**
- Create: `android/app/src/main/kotlin/com/example/takt_desk/TimerForegroundService.kt`
- Modify: `android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt`

**Interfaces:**
- Consumes: Calls from `com.takt.desk/timer_service` MethodChannel.
- Produces: Lockscreen/AOD native chronometer notification, background sound & haptic alarm on completion.

- [ ] **Step 1: Implement `TimerForegroundService.kt`**

Create `android/app/src/main/kotlin/com/example/takt_desk/TimerForegroundService.kt`:
```kotlin
package com.example.takt_desk

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat

class TimerForegroundService : Service() {
    companion object {
        const val CHANNEL_TIMER_ID = "takt_desk_timer_channel"
        const val CHANNEL_ALERT_ID = "takt_desk_alert_channel"
        const val NOTIFICATION_ID = 1001
        const val ALERT_NOTIFICATION_ID = 1002

        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"

        const val EXTRA_REMAINING_SECONDS = "EXTRA_REMAINING_SECONDS"
        const val EXTRA_TARGET_MINUTES = "EXTRA_TARGET_MINUTES"
        const val EXTRA_PHASE = "EXTRA_PHASE"
        const val EXTRA_CYCLE_COUNT = "EXTRA_CYCLE_COUNT"
        const val EXTRA_PROFILE_NAME = "EXTRA_PROFILE_NAME"
    }

    private val handler = Handler(Looper.getMainLooper())
    private var completionRunnable: Runnable? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var bellPlayer: MediaPlayer? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val remainingSeconds = intent.getDoubleExtra(EXTRA_REMAINING_SECONDS, 0.0)
                val targetMinutes = intent.getIntExtra(EXTRA_TARGET_MINUTES, 25)
                val phase = intent.getStringExtra(EXTRA_PHASE) ?: "focus"
                val cycleCount = intent.getIntExtra(EXTRA_CYCLE_COUNT, 1)
                val profileName = intent.getStringExtra(EXTRA_PROFILE_NAME) ?: "CLASSIC 25/5"

                startCountdown(remainingSeconds, targetMinutes, phase, cycleCount, profileName)
            }
            ACTION_STOP -> {
                stopCountdown()
            }
        }
        return START_NOT_STICKY
    }

    private fun startCountdown(
        remainingSeconds: Double,
        targetMinutes: Int,
        phase: String,
        cycleCount: Int,
        profileName: String
    ) {
        cancelScheduledCompletion()

        val remainingMillis = (remainingSeconds * 1000).toLong()
        val baseTime = SystemClock.elapsedRealtime() + remainingMillis

        val title = formatTitle(phase, cycleCount)
        val content = "$targetMinutes MIN · $profileName"

        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_TIMER_ID)
            .setSmallIcon(R.drawable.ic_takt_timer)
            .setContentTitle(title)
            .setContentText(content)
            .setOngoing(true)
            .setColor(0xFFFF9E00.toInt())
            .setShowWhen(false)
            .setUsesChronometer(true)
            .setChronometerCountDown(true)
            .setBase(baseTime)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(pendingIntent)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .build()

        startForeground(NOTIFICATION_ID, notification)

        // Schedule completion alarm
        if (remainingMillis > 0) {
            completionRunnable = Runnable {
                onTimerFinished(phase)
            }
            handler.postDelayed(completionRunnable!, remainingMillis)
        }
    }

    private fun onTimerFinished(phase: String) {
        // 1. Acquire temporary 3-second wakelock to play bell sound
        acquireTransientWakeLock()

        // 2. Play analog bell chime
        playBellChime()

        // 3. Trigger dual-tap mechanical haptics
        triggerMechanicalHaptics()

        // 4. Post alert notification
        val phaseLabel = when (phase) {
            "shortBreak" -> "SHORT BREAK"
            "longBreak" -> "LONG BREAK"
            else -> "FOCUS"
        }

        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            1,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val alertNotif = NotificationCompat.Builder(this, CHANNEL_ALERT_ID)
            .setSmallIcon(R.drawable.ic_takt_timer)
            .setContentTitle("TAKT DESK · $phaseLabel COMPLETED")
            .setContentText("Standby active. Tap to enter console and begin next phase.")
            .setAutoCancel(true)
            .setColor(0xFFFF9E00.toInt())
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .build()

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(ALERT_NOTIFICATION_ID, alertNotif)

        // Stop foreground state
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun stopCountdown() {
        cancelScheduledCompletion()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun cancelScheduledCompletion() {
        completionRunnable?.let { handler.removeCallbacks(it) }
        completionRunnable = null
    }

    private fun formatTitle(phase: String, cycleCount: Int): String {
        return when (phase) {
            "shortBreak" -> "TAKT DESK · SHORT BRK"
            "longBreak" -> "TAKT DESK · LONG BRK"
            else -> "TAKT DESK · FOCUS (CYCLE $cycleCount/4)"
        }
    }

    private fun playBellChime() {
        try {
            bellPlayer?.release()
            val afd = assets.openFd("flutter_assets/assets/audio/foley_bell_chime.wav")
            bellPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                prepare()
                start()
                setOnCompletionListener {
                    it.release()
                    bellPlayer = null
                }
            }
        } catch (_: Exception) {}
    }

    private fun triggerMechanicalHaptics() {
        try {
            val timings = longArrayOf(0, 120, 80, 120)
            val amplitudes = intArrayOf(0, 200, 0, 255)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vibratorManager?.defaultVibrator?.vibrate(
                    VibrationEffect.createWaveform(timings, amplitudes, -1)
                )
            } else {
                @Suppress("DEPRECATION")
                val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator?.vibrate(VibrationEffect.createWaveform(timings, amplitudes, -1))
                } else {
                    @Suppress("DEPRECATION")
                    vibrator?.vibrate(timings, -1)
                }
            }
        } catch (_: Exception) {}
    }

    private fun acquireTransientWakeLock() {
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager
            wakeLock = pm?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "TaktDesk::CompletionWakeLock")
            wakeLock?.acquire(3500)
        } catch (_: Exception) {}
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val timerChannel = NotificationChannel(
                CHANNEL_TIMER_ID,
                "Takt Desk Active Timer",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Live analog timer telemetry on Lockscreen and Always-On Display"
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }

            val alertChannel = NotificationChannel(
                CHANNEL_ALERT_ID,
                "Takt Desk Session Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Pomodoro focus and break interval completion alarms"
                enableVibration(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }

            manager.createNotificationChannel(timerChannel)
            manager.createNotificationChannel(alertChannel)
        }
    }

    override fun onDestroy() {
        cancelScheduledCompletion()
        bellPlayer?.release()
        bellPlayer = null
        wakeLock?.let {
            if (it.isHeld) it.release()
        }
        wakeLock = null
        super.onDestroy()
    }
}
```

- [ ] **Step 2: Wire `TIMER_CHANNEL` in `MainActivity.kt`**

In `android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt`:
Add:
```kotlin
private val TIMER_CHANNEL = "com.takt.desk/timer_service"
```
And in `configureFlutterEngine`:
```kotlin
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TIMER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    try {
                        val remainingSeconds = call.argument<Double>("remainingSeconds") ?: 0.0
                        val targetMinutes = call.argument<Int>("targetMinutes") ?: 25
                        val phase = call.argument<String>("phase") ?: "focus"
                        val cycleCount = call.argument<Int>("cycleCount") ?: 1
                        val profileName = call.argument<String>("profileName") ?: "CLASSIC 25/5"

                        val serviceIntent = Intent(this, TimerForegroundService::class.java).apply {
                            action = TimerForegroundService.ACTION_START
                            putExtra(TimerForegroundService.EXTRA_REMAINING_SECONDS, remainingSeconds)
                            putExtra(TimerForegroundService.EXTRA_TARGET_MINUTES, targetMinutes)
                            putExtra(TimerForegroundService.EXTRA_PHASE, phase)
                            putExtra(TimerForegroundService.EXTRA_CYCLE_COUNT, cycleCount)
                            putExtra(TimerForegroundService.EXTRA_PROFILE_NAME, profileName)
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "stopService" -> {
                    try {
                        val serviceIntent = Intent(this, TimerForegroundService::class.java).apply {
                            action = TimerForegroundService.ACTION_STOP
                        }
                        startService(serviceIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
```

- [ ] **Step 3: Run full flutter tests to ensure 100% pass rate**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test`
Expected: All 253+ tests pass.

- [ ] **Step 4: Run flutter analyze**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`
Expected: No issues found!

- [ ] **Step 5: Commit changes**

```bash
git add android/app/src/main/kotlin/com/example/takt_desk/TimerForegroundService.kt android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt
git commit -m "feat(android): implement TimerForegroundService with native chronometer and completion alarm"
```
