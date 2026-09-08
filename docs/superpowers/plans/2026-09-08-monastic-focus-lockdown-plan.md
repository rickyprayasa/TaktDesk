# Monastic Focus Lockdown (Anti-Brainrot Mode) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a Monastic Focus Lockdown mode for mobile Android that enforces deep focus by preventing app exit (`startLockTask`), silencing notifications (DND), keeping the screen awake with an amber vacuum glow (wakelock), providing a 5-second emergency unlatch mechanism, and streamlining the console as a pure mobile handheld interface.

**Architecture:** A native Android MethodChannel (`com.tuneeca.takt_desk/focus_lock`) connects to a Riverpod-managed `FocusLockController`. The presentation layer in `desk_canvas_screen.dart` encapsulates the mobile console in a `PopScope(canPop: !isLocked)`, featuring an industrial knurled `MonasticSwitchWidget` at the top and a 5-second continuous press `EmergencyUnlatchWidget` at the bottom.

**Tech Stack:** Flutter 3.27+, Kotlin Android Activity (`startLockTask`, `FLAG_KEEP_SCREEN_ON`, `NotificationManager`), Flutter Riverpod 2.5+, Drift SQLite 2.18+.

## Global Constraints
- Strictly adhere to Braun / Dieter Rams minimalist industrial aesthetic (TaktPalette: Obsidian `#141517`, Basalt `#24272C`, Warm Bone `#EFECE6`, Filament Amber `#D99B59`, Muted Ochre `#C85A32`).
- Target platform: Mobile Android. Desktop wide-rack layout removed in favor of pure responsive handheld console (zero vertical scrolling).
- 0 analyzer warnings, 100% test pass rate across the whole repository.

---

### Task 1: Android Native MethodChannel & Focus Lock Service

**Files:**
- Create: `lib/core/focus/focus_lock_service.dart`
- Modify: `android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt`
- Test: `test/core/focus_lock_service_test.dart`

**Interfaces:**
- Consumes: Flutter Services `MethodChannel`
- Produces: `FocusLockService` class and `focusLockServiceProvider` with `Future<bool> enableFocusLock()`, `Future<bool> disableFocusLock()`, and `Future<bool> isLockTaskPermitted()`

- [ ] **Step 1: Write failing test in test/core/focus_lock_service_test.dart**

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/focus/focus_lock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FocusLockService', () {
    late FocusLockService service;
    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      log.clear();
      service = FocusLockService();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(FocusLockService.channel, (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'enableFocusLock':
            return true;
          case 'disableFocusLock':
            return true;
          case 'isLockTaskPermitted':
            return true;
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(FocusLockService.channel, null);
    });

    test('enableFocusLock sends method call and returns true', () async {
      final result = await service.enableFocusLock();
      expect(result, isTrue);
      expect(log, hasLength(1));
      expect(log.first.method, 'enableFocusLock');
    });

    test('disableFocusLock sends method call and returns true', () async {
      final result = await service.disableFocusLock();
      expect(result, isTrue);
      expect(log, hasLength(1));
      expect(log.first.method, 'disableFocusLock');
    });

    test('handles missing channel gracefully with fallback', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(FocusLockService.channel, (MethodCall methodCall) async {
        throw MissingPluginException();
      });

      final result = await service.enableFocusLock();
      expect(result, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/focus_lock_service_test.dart`  
Expected: FAIL (file not found / class not defined)

- [ ] **Step 3: Implement FocusLockService and MainActivity.kt**

In `lib/core/focus/focus_lock_service.dart`:
```dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final focusLockServiceProvider = Provider<FocusLockService>((ref) {
  return FocusLockService();
});

class FocusLockService {
  static const MethodChannel channel = MethodChannel('com.tuneeca.takt_desk/focus_lock');

  Future<bool> enableFocusLock() async {
    try {
      final res = await channel.invokeMethod<bool>('enableFocusLock');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> disableFocusLock() async {
    try {
      final res = await channel.invokeMethod<bool>('disableFocusLock');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isLockTaskPermitted() async {
    try {
      final res = await channel.invokeMethod<bool>('isLockTaskPermitted');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
```

In `android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt`:
```kotlin
package com.example.takt_desk

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.view.WindowManager
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.tuneeca.takt_desk/focus_lock"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableFocusLock" -> {
                    try {
                        // 1. Keep Screen Awake
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

                        // 2. Hide System Bars (Immersive Sticky)
                        val controller = WindowCompat.getInsetsController(window, window.decorView)
                        controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                        controller.hide(WindowInsetsCompat.Type.systemBars())

                        // 3. Android Screen Pinning / Lock Task Mode
                        try {
                            startLockTask()
                        } catch (_: Exception) {}

                        // 4. Do Not Disturb (silence notifications if permitted)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val notifManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                            if (notifManager != null && notifManager.isNotificationPolicyAccessGranted) {
                                notifManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "disableFocusLock" -> {
                    try {
                        // 1. Clear Screen On flag
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

                        // 2. Restore System Bars
                        val controller = WindowCompat.getInsetsController(window, window.decorView)
                        controller.show(WindowInsetsCompat.Type.systemBars())

                        // 3. Stop Lock Task Mode
                        try {
                            stopLockTask()
                        } catch (_: Exception) {}

                        // 4. Restore Do Not Disturb
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val notifManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                            if (notifManager != null && notifManager.isNotificationPolicyAccessGranted) {
                                notifManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "isLockTaskPermitted" -> {
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/focus_lock_service_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/core/focus/focus_lock_service.dart android/app/src/main/kotlin/com/example/takt_desk/MainActivity.kt test/core/focus_lock_service_test.dart
git commit -m "feat(focus): implement Android MethodChannel and FocusLockService"
```

---

### Task 2: Focus Lock State & Controller (Riverpod + Audio/Haptic Integration)

**Files:**
- Create: `lib/core/focus/focus_lock_state.dart`
- Create: `lib/core/focus/focus_lock_controller.dart`
- Test: `test/core/focus_lock_controller_test.dart`

**Interfaces:**
- Consumes: `FocusLockService`, `AudioService`, `HapticService`, `AppDatabase`
- Produces: `focusLockProvider` with `FocusLockState` and methods `engageLock()`, `updateHoldProgress(double)`, `cancelHold()`, `completeUnlock()`

- [ ] **Step 1: Write failing test in test/core/focus_lock_controller_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/focus/focus_lock_controller.dart';
import 'package:takt_desk/core/focus/focus_lock_service.dart';
import 'package:takt_desk/core/focus/focus_lock_state.dart';

class FakeFocusLockService extends FocusLockService {
  bool enabled = false;
  @override
  Future<bool> enableFocusLock() async {
    enabled = true;
    return true;
  }
  @override
  Future<bool> disableFocusLock() async {
    enabled = false;
    return true;
  }
}

void main() {
  group('FocusLockController', () {
    late FakeFocusLockService fakeService;
    late FocusLockController controller;

    setUp(() {
      fakeService = FakeFocusLockService();
      controller = FocusLockController(service: fakeService);
    });

    test('initial state is unlocked with 0 progress', () {
      expect(controller.state.isLocked, isFalse);
      expect(controller.state.unlockProgress, 0.0);
      expect(controller.state.isHolding, isFalse);
    });

    test('engageLock sets isLocked to true and calls service', () async {
      await controller.engageLock();
      expect(controller.state.isLocked, isTrue);
      expect(fakeService.enabled, isTrue);
    });

    test('updateHoldProgress updates progress when locked', () async {
      await controller.engageLock();
      controller.updateHoldProgress(0.5);
      expect(controller.state.isHolding, isTrue);
      expect(controller.state.unlockProgress, 0.5);
    });

    test('cancelHold resets unlockProgress to 0.0 and isHolding to false', () async {
      await controller.engageLock();
      controller.updateHoldProgress(0.8);
      controller.cancelHold();
      expect(controller.state.isHolding, isFalse);
      expect(controller.state.unlockProgress, 0.0);
    });

    test('completeUnlock releases lock and resets state', () async {
      await controller.engageLock();
      controller.updateHoldProgress(1.0);
      await controller.completeUnlock();
      expect(controller.state.isLocked, isFalse);
      expect(controller.state.unlockProgress, 0.0);
      expect(fakeService.enabled, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/focus_lock_controller_test.dart`  
Expected: FAIL (files missing)

- [ ] **Step 3: Implement FocusLockState and FocusLockController**

In `lib/core/focus/focus_lock_state.dart`:
```dart
class FocusLockState {
  final bool isLocked;
  final bool isHolding;
  final double unlockProgress; // 0.0 to 1.0
  final DateTime? sessionStartTime;

  const FocusLockState({
    this.isLocked = false,
    this.isHolding = false,
    this.unlockProgress = 0.0,
    this.sessionStartTime,
  });

  FocusLockState copyWith({
    bool? isLocked,
    bool? isHolding,
    double? unlockProgress,
    DateTime? sessionStartTime,
    bool clearStartTime = false,
  }) {
    return FocusLockState(
      isLocked: isLocked ?? this.isLocked,
      isHolding: isHolding ?? this.isHolding,
      unlockProgress: unlockProgress ?? this.unlockProgress,
      sessionStartTime: clearStartTime ? null : (sessionStartTime ?? this.sessionStartTime),
    );
  }
}
```

In `lib/core/focus/focus_lock_controller.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/audio/sound_effect.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/core/focus/focus_lock_service.dart';
import 'package:takt_desk/core/focus/focus_lock_state.dart';
import 'package:takt_desk/core/haptics/haptic_service.dart';

final focusLockProvider = StateNotifierProvider<FocusLockController, FocusLockState>((ref) {
  final service = ref.watch(focusLockServiceProvider);
  final audio = ref.watch(audioServiceProvider);
  final database = ref.watch(appDatabaseProvider);
  return FocusLockController(
    service: service,
    audioService: audio,
    database: database,
  );
});

class FocusLockController extends StateNotifier<FocusLockState> {
  final FocusLockService _service;
  final AudioService? _audioService;
  final AppDatabase? _database;

  FocusLockController({
    required FocusLockService service,
    AudioService? audioService,
    AppDatabase? database,
  })  : _service = service,
        _audioService = audioService,
        _database = database,
        super(const FocusLockState());

  Future<void> engageLock() async {
    if (state.isLocked) return;
    _audioService?.play(SoundEffect.switchClick);
    HapticService.heavyClick();
    await _service.enableFocusLock();
    state = state.copyWith(
      isLocked: true,
      unlockProgress: 0.0,
      isHolding: false,
      sessionStartTime: DateTime.now(),
    );
  }

  void updateHoldProgress(double progress) {
    if (!state.isLocked) return;
    state = state.copyWith(
      isHolding: true,
      unlockProgress: progress.clamp(0.0, 1.0),
    );
  }

  void cancelHold() {
    if (!state.isLocked) return;
    state = state.copyWith(
      isHolding: false,
      unlockProgress: 0.0,
    );
  }

  Future<void> completeUnlock() async {
    if (!state.isLocked) return;
    _audioService?.play(SoundEffect.drawerLatch);
    HapticService.heavyClick();
    await _service.disableFocusLock();

    final start = state.sessionStartTime;
    if (start != null && _database != null) {
      final elapsedSeconds = DateTime.now().difference(start).inSeconds;
      if (elapsedSeconds > 0) {
        await _database.recordTimerSession(
          startedAt: start,
          durationSeconds: elapsedSeconds,
          completed: true,
        );
      }
    }

    state = state.copyWith(
      isLocked: false,
      isHolding: false,
      unlockProgress: 0.0,
      clearStartTime: true,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/focus_lock_controller_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/core/focus/focus_lock_state.dart lib/core/focus/focus_lock_controller.dart test/core/focus_lock_controller_test.dart
git commit -m "feat(focus): implement FocusLockController and state management"
```

---

### Task 3: Monastic Toggle Switch & Filament Glow Widget

**Files:**
- Create: `lib/features/desk/presentation/widgets/monastic_switch_widget.dart`
- Test: `test/features/desk/monastic_switch_test.dart`

**Interfaces:**
- Consumes: `focusLockProvider`, `TaktPalette`, `TaktTypography`
- Produces: `MonasticSwitchWidget` with tactile knurled sliding switch and glowing filament amber indicator lamp

- [ ] **Step 1: Write failing test in test/features/desk/monastic_switch_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/focus/focus_lock_controller.dart';
import 'package:takt_desk/core/focus/focus_lock_service.dart';
import 'package:takt_desk/features/desk/presentation/widgets/monastic_switch_widget.dart';

class MockFocusLockService extends FocusLockService {
  @override
  Future<bool> enableFocusLock() async => true;
  @override
  Future<bool> disableFocusLock() async => true;
}

void main() {
  testWidgets('MonasticSwitchWidget renders and toggles focus lock', (tester) async {
    final container = ProviderContainer(
      overrides: [
        focusLockServiceProvider.overrideWithValue(MockFocusLockService()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: MonasticSwitchWidget(),
          ),
        ),
      ),
    );

    expect(find.text('MONASTIC'), findsOneWidget);
    expect(find.text('LOCKDOWN'), findsOneWidget);

    // Tap switch to engage
    await tester.tap(find.byType(MonasticSwitchWidget));
    await tester.pump();

    expect(container.read(focusLockProvider).isLocked, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/desk/monastic_switch_test.dart`  
Expected: FAIL (file not found)

- [ ] **Step 3: Implement MonasticSwitchWidget**

In `lib/features/desk/presentation/widgets/monastic_switch_widget.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takt_desk/app/theme/takt_colors.dart';
import 'package:takt_desk/app/theme/takt_typography.dart';
import 'package:takt_desk/core/focus/focus_lock_controller.dart';

class MonasticSwitchWidget extends ConsumerWidget {
  const MonasticSwitchWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusState = ref.watch(focusLockProvider);
    final isLocked = focusState.isLocked;

    return Semantics(
      button: true,
      label: isLocked ? 'Monastic Focus Engaged' : 'Monastic Focus Inactive',
      child: GestureDetector(
        onTap: () {
          if (!isLocked) {
            ref.read(focusLockProvider.notifier).engageLock();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: TaktPalette.basalt,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isLocked
                  ? TaktPalette.filamentAmber.withOpacity(0.8)
                  : TaktPalette.thermalCarbon,
              width: 1.2,
            ),
            boxShadow: isLocked
                ? [
                    BoxShadow(
                      color: TaktPalette.filamentAmber.withOpacity(0.35),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicator vacuum tube lamp
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLocked
                      ? TaktPalette.filamentAmber
                      : TaktPalette.thermalCarbon,
                  boxShadow: isLocked
                      ? [
                          BoxShadow(
                            color: TaktPalette.filamentAmber.withOpacity(0.9),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MONASTIC',
                    style: TaktTypography.labelSmall.copyWith(
                      color: isLocked ? TaktPalette.warmBone : TaktPalette.warmBone.withOpacity(0.6),
                      fontSize: 9,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    isLocked ? 'ENGAGED' : 'LOCKDOWN',
                    style: TaktTypography.labelSmall.copyWith(
                      color: isLocked ? TaktPalette.filamentAmber : TaktPalette.warmBone.withOpacity(0.4),
                      fontSize: 8,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/desk/monastic_switch_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/features/desk/presentation/widgets/monastic_switch_widget.dart test/features/desk/monastic_switch_test.dart
git commit -m "feat(focus): implement MonasticSwitchWidget with amber filament indicator"
```

---

### Task 4: Emergency Unlatch Latch (5-Second Continuous Press Mechanism)

**Files:**
- Create: `lib/features/desk/presentation/widgets/emergency_unlatch_widget.dart`
- Test: `test/features/desk/emergency_unlatch_test.dart`

**Interfaces:**
- Consumes: `focusLockProvider`, `TaktPalette`, `TaktTypography`, `AudioService`, `SoundEffect`
- Produces: `EmergencyUnlatchWidget` with continuous 5.0s progress hold and auto-abort

- [ ] **Step 1: Write failing test in test/features/desk/emergency_unlatch_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/focus/focus_lock_controller.dart';
import 'package:takt_desk/core/focus/focus_lock_service.dart';
import 'package:takt_desk/features/desk/presentation/widgets/emergency_unlatch_widget.dart';

class MockFocusLockService extends FocusLockService {
  @override
  Future<bool> enableFocusLock() async => true;
  @override
  Future<bool> disableFocusLock() async => true;
}

void main() {
  testWidgets('EmergencyUnlatchWidget is hidden when unlocked, renders when locked', (tester) async {
    final container = ProviderContainer(
      overrides: [
        focusLockServiceProvider.overrideWithValue(MockFocusLockService()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: EmergencyUnlatchWidget(),
          ),
        ),
      ),
    );

    expect(find.text('HOLD 5s TO UNLATCH'), findsNothing);

    // Lock focus
    await container.read(focusLockProvider.notifier).engageLock();
    await tester.pump();

    expect(find.text('HOLD 5s TO UNLATCH'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/desk/emergency_unlatch_test.dart`  
Expected: FAIL (file not found)

- [ ] **Step 3: Implement EmergencyUnlatchWidget**

In `lib/features/desk/presentation/widgets/emergency_unlatch_widget.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takt_desk/app/theme/takt_colors.dart';
import 'package:takt_desk/app/theme/takt_typography.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/audio/sound_effect.dart';
import 'package:takt_desk/core/focus/focus_lock_controller.dart';
import 'package:takt_desk/core/haptics/haptic_service.dart';

class EmergencyUnlatchWidget extends ConsumerStatefulWidget {
  const EmergencyUnlatchWidget({super.key});

  @override
  ConsumerState<EmergencyUnlatchWidget> createState() => _EmergencyUnlatchWidgetState();
}

class _EmergencyUnlatchWidgetState extends ConsumerState<EmergencyUnlatchWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _holdController;
  int _lastTickSecond = 0;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _holdController.addListener(() {
      final progress = _holdController.value;
      ref.read(focusLockProvider.notifier).updateHoldProgress(progress);

      final currentSecond = (progress * 5).floor();
      if (currentSecond != _lastTickSecond && currentSecond > 0) {
        _lastTickSecond = currentSecond;
        ref.read(audioServiceProvider).play(SoundEffect.dialClick);
        HapticService.lightClick();
      }
    });

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        ref.read(focusLockProvider.notifier).completeUnlock();
        _holdController.reset();
      }
    });
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent _) {
    _lastTickSecond = 0;
    _holdController.forward();
  }

  void _onPointerUpOrCancel(PointerEvent _) {
    if (_holdController.isAnimating || _holdController.value < 1.0) {
      _holdController.reset();
      ref.read(focusLockProvider.notifier).cancelHold();
    }
  }

  @override
  Widget build(BuildContext context) {
    final focusState = ref.watch(focusLockProvider);
    if (!focusState.isLocked) {
      return const SizedBox.shrink();
    }

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUpOrCancel,
      onPointerCancel: _onPointerUpOrCancel,
      child: AnimatedBuilder(
        animation: _holdController,
        builder: (context, _) {
          final progress = _holdController.value;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 38,
            decoration: BoxDecoration(
              color: TaktPalette.obsidian,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: progress > 0.0
                    ? TaktPalette.mutedOchre
                    : TaktPalette.thermalCarbon,
                width: 1.2,
              ),
            ),
            child: Stack(
              children: [
                // Progress Fill
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: TaktPalette.mutedOchre.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                // Center Label
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.power_settings_new_rounded,
                        size: 14,
                        color: TaktPalette.mutedOchre,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        progress > 0.0
                            ? 'HOLDING... ${(5 - (progress * 5)).toStringAsFixed(1)}s'
                            : 'HOLD 5s TO UNLATCH',
                        style: TaktTypography.labelSmall.copyWith(
                          color: progress > 0.0
                              ? TaktPalette.warmBone
                              : TaktPalette.warmBone.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/desk/emergency_unlatch_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/features/desk/presentation/widgets/emergency_unlatch_widget.dart test/features/desk/emergency_unlatch_test.dart
git commit -m "feat(focus): implement EmergencyUnlatchWidget with 5-second hold"
```

---

### Task 5: Pure Mobile Console Layout Integration & Root PopScope

**Files:**
- Modify: `lib/features/desk/presentation/desk_canvas_screen.dart`
- Test: `test/features/desk/desk_screen_test.dart`

**Interfaces:**
- Consumes: `focusLockProvider`, `MonasticSwitchWidget`, `EmergencyUnlatchWidget`, `ChronoDialWidget`, `ReceiptRunnerWidget`, `VinylPlayerWidget`
- Produces: Complete pure mobile handheld console with `PopScope(canPop: !isLocked)` and zero desktop multi-column clutter

- [ ] **Step 1: Write test for mobile focus lock & PopScope in test/features/desk/desk_screen_test.dart**

Add test checking `MonasticSwitchWidget` and `EmergencyUnlatchWidget` are rendered on `DeskCanvasScreen`, and desktop rack layout is eliminated.

- [ ] **Step 2: Run test to verify it fails before screen modification**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/desk/desk_screen_test.dart`  
Expected: FAIL (missing widgets)

- [ ] **Step 3: Update DeskCanvasScreen**

Modify `lib/features/desk/presentation/desk_canvas_screen.dart`:
- Wrap root in `PopScope(canPop: !focusState.isLocked)`.
- Replace top header with `MonasticSwitchWidget` and `ChassisThemeSwitch`.
- Remove desktop multi-column horizontal rack layout completely; enforce the single-screen mobile layout everywhere.
- Place `EmergencyUnlatchWidget` at the bottom of the console when locked.

- [ ] **Step 4: Run all test suites across the repository**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test`  
Expected: 100% tests PASS

- [ ] **Step 5: Run flutter analyze**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`  
Expected: 0 issues found

- [ ] **Step 6: Commit changes**

```bash
git add lib/features/desk/presentation/desk_canvas_screen.dart test/features/desk/desk_screen_test.dart
git commit -m "feat(desk): integrate Monastic Focus Lockdown into pure mobile console"
```
