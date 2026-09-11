import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/core/focus/focus_lock_service.dart';
import 'package:takt_desk/core/services/app_widget_service.dart';
import 'package:takt_desk/features/desk/presentation/desk_canvas_screen.dart';
import 'package:takt_desk/features/desk/presentation/widgets/desk_telemetry_slip_widget.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_phase.dart';
import 'package:takt_desk/features/timer/domain/timer_state.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';

class MockFocusLockService extends FocusLockService {
  @override
  Future<bool> enableFocusLock() async => true;
  @override
  Future<bool> disableFocusLock() async => true;
}

class TestChronoDialController extends ChronoDialController {
  TestChronoDialController([TimerState? initialState]) {
    if (initialState != null) {
      state = initialState;
    }
  }

  void setTimerState(TimerState newState) {
    state = newState;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase testDb;
  final List<MethodCall> channelCalls = [];
  late StreamController<TodayFocusStats> statsStreamController;
  late TestChronoDialController chronoDialController;

  setUp(() {
    testDb = AppDatabase.forTesting(NativeDatabase.memory());
    channelCalls.clear();
    statsStreamController = StreamController<TodayFocusStats>.broadcast(sync: true);
    chronoDialController = TestChronoDialController();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      AppWidgetService.channel,
      (MethodCall call) async {
        channelCalls.add(call);
        return true;
      },
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AppWidgetService.channel, null);
    await statsStreamController.close();
    await testDb.close();
  });

  List<Override> createOverrides() {
    return [
      appDatabaseProvider.overrideWithValue(testDb),
      focusLockServiceProvider.overrideWithValue(MockFocusLockService()),
      todayFocusStatsProvider.overrideWith((ref) => statsStreamController.stream),
      lifetimeFocusStatsProvider.overrideWith(
        (ref) => Stream.value(const LifetimeFocusStats(totalSessions: 0, totalHours: 0)),
      ),
      todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value(const [])),
      chronoDialControllerProvider.overrideWith((ref) => chronoDialController),
    ];
  }

  testWidgets('DeskCanvasScreen syncs initial STANDBY telemetry to AppWidget channel',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: createOverrides(),
        child: const MaterialApp(
          home: DeskCanvasScreen(
            gyroscopeStream: Stream.empty(),
            accelerometerStream: Stream.empty(),
          ),
        ),
      ),
    );

    // Initial pump: no stats yet emitted
    expect(channelCalls, isEmpty);

    // Emit stats for a user with 2 completed cycles and 50 focus minutes
    statsStreamController.add(const TodayFocusStats(
      completedCount: 2,
      totalMinutes: 50,
    ));
    await tester.pump();

    expect(channelCalls, hasLength(1));
    expect(channelCalls.first.method, equals('updateWidgetData'));
    expect(channelCalls.first.arguments, equals({
      'cyclesCompleted': 2,
      'cyclesTarget': 4,
      'minutesFocused': 50,
      'status': 'STANDBY',
    }));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('DeskCanvasScreen sends FOCUS status when timer is running in focus phase',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: createOverrides(),
        child: const MaterialApp(
          home: DeskCanvasScreen(
            gyroscopeStream: Stream.empty(),
            accelerometerStream: Stream.empty(),
          ),
        ),
      ),
    );

    statsStreamController.add(const TodayFocusStats(
      completedCount: 1,
      totalMinutes: 25,
    ));
    await tester.pump();
    expect(channelCalls, hasLength(1));

    // Transition timer to running in focus phase
    chronoDialController.setTimerState(
      chronoDialController.state.copyWith(
        isRunning: true,
        phase: PomodoroPhase.focus,
      ),
    );
    await tester.pump();

    expect(channelCalls, hasLength(2));
    expect(channelCalls.last.method, equals('updateWidgetData'));
    expect(channelCalls.last.arguments, equals({
      'cyclesCompleted': 1,
      'cyclesTarget': 4,
      'minutesFocused': 25,
      'status': 'FOCUS',
    }));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('DeskCanvasScreen sends BREAK status when timer is running in break phase',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: createOverrides(),
        child: const MaterialApp(
          home: DeskCanvasScreen(
            gyroscopeStream: Stream.empty(),
            accelerometerStream: Stream.empty(),
          ),
        ),
      ),
    );

    statsStreamController.add(const TodayFocusStats(
      completedCount: 1,
      totalMinutes: 25,
    ));
    await tester.pump();

    // Transition timer to running in short break phase
    chronoDialController.setTimerState(
      chronoDialController.state.copyWith(
        isRunning: true,
        phase: PomodoroPhase.shortBreak,
      ),
    );
    await tester.pump();

    expect(channelCalls.last.arguments['status'], equals('BREAK'));

    // Transition timer to running in long break phase
    chronoDialController.setTimerState(
      chronoDialController.state.copyWith(
        isRunning: true,
        phase: PomodoroPhase.longBreak,
      ),
    );
    await tester.pump();

    expect(channelCalls.last.arguments['status'], equals('BREAK'));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('DeskCanvasScreen maps cyclesCompleted correctly on quadrant boundaries',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: createOverrides(),
        child: const MaterialApp(
          home: DeskCanvasScreen(
            gyroscopeStream: Stream.empty(),
            accelerometerStream: Stream.empty(),
          ),
        ),
      ),
    );

    // 0 completed -> cyclesCompleted: 0
    statsStreamController.add(const TodayFocusStats(
      completedCount: 0,
      totalMinutes: 0,
    ));
    await tester.pump();
    expect(channelCalls.last.arguments['cyclesCompleted'], equals(0));

    // 4 completed -> cyclesCompleted: 4 (full cycle)
    statsStreamController.add(const TodayFocusStats(
      completedCount: 4,
      totalMinutes: 100,
    ));
    await tester.pump();
    expect(channelCalls.last.arguments['cyclesCompleted'], equals(4));

    // 7 completed -> cyclesCompleted: 3
    statsStreamController.add(const TodayFocusStats(
      completedCount: 7,
      totalMinutes: 175,
    ));
    await tester.pump();
    expect(channelCalls.last.arguments['cyclesCompleted'], equals(3));

    // 8 completed -> cyclesCompleted: 4 (second full quadrant)
    statsStreamController.add(const TodayFocusStats(
      completedCount: 8,
      totalMinutes: 200,
    ));
    await tester.pump();
    expect(channelCalls.last.arguments['cyclesCompleted'], equals(4));

    await tester.pumpWidget(const SizedBox());
  });
}
