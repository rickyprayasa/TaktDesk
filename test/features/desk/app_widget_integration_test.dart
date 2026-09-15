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
      activeTasksStreamProvider.overrideWith((ref) => Stream.value(const [])),
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
    expect(channelCalls.first.method, equals('updateAllWidgetData'));
    expect(channelCalls.first.arguments, equals({
      'cyclesCompleted': 2,
      'cyclesTarget': 4,
      'minutesFocused': 50,
      'status': 'STANDBY',
      'remainingSeconds': 1500,
      'targetMinutes': 25,
      'tasks': [],
      'isPro': true,
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
    expect(channelCalls.last.method, equals('updateAllWidgetData'));
    expect(channelCalls.last.arguments, equals({
      'cyclesCompleted': 1,
      'cyclesTarget': 4,
      'minutesFocused': 25,
      'status': 'FOCUS',
      'remainingSeconds': 1500,
      'targetMinutes': 25,
      'tasks': [],
      'isPro': true,
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

  testWidgets('timer ticks do not trigger redundant MethodChannel IPC updates while status is unchanged', (tester) async {
    final dialController = TestChronoDialController(
      const TimerState(
        remainingSeconds: 1500,
        targetMinutes: 25,
        isRunning: true,
        phase: PomodoroPhase.focus,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
          focusLockServiceProvider.overrideWithValue(MockFocusLockService()),
          todayFocusStatsProvider.overrideWith((ref) => statsStreamController.stream),
          todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value(const [])),
          activeTasksStreamProvider.overrideWith((ref) => Stream.value(const [])),
          chronoDialControllerProvider.overrideWith((ref) => dialController),
        ],
        child: const MaterialApp(
          home: DeskCanvasScreen(),
        ),
      ),
    );

    statsStreamController.add(const TodayFocusStats(
      completedCount: 1,
      totalMinutes: 25,
    ));
    await tester.pump();

    final initialCallCount = channelCalls.length;
    expect(initialCallCount, greaterThan(0));
    expect(channelCalls.last.arguments['status'], equals('FOCUS'));

    // Simulate 1-second countdown tick with status remaining FOCUS
    dialController.setTimerState(
      const TimerState(
        remainingSeconds: 1499,
        targetMinutes: 25,
        isRunning: true,
        phase: PomodoroPhase.focus,
      ),
    );
    await tester.pump();

    // Assert zero additional MethodChannel calls were sent
    expect(channelCalls.length, equals(initialCallCount));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('DeskCanvasScreen syncs active tasks payload to AppWidget channel when tasks stream emits', (tester) async {
    final tasksStreamController = StreamController<List<Task>>.broadcast(sync: true);
    addTearDown(tasksStreamController.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
          focusLockServiceProvider.overrideWithValue(MockFocusLockService()),
          todayFocusStatsProvider.overrideWith((ref) => statsStreamController.stream),
          lifetimeFocusStatsProvider.overrideWith(
            (ref) => Stream.value(const LifetimeFocusStats(totalSessions: 0, totalHours: 0)),
          ),
          todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value(const [])),
          activeTasksStreamProvider.overrideWith((ref) => tasksStreamController.stream),
          chronoDialControllerProvider.overrideWith((ref) => chronoDialController),
        ],
        child: const MaterialApp(
          home: DeskCanvasScreen(
            gyroscopeStream: Stream.empty(),
            accelerometerStream: Stream.empty(),
          ),
        ),
      ),
    );

    statsStreamController.add(const TodayFocusStats(
      completedCount: 2,
      totalMinutes: 50,
    ));
    await tester.pump();
    expect(channelCalls, hasLength(1));
    expect(channelCalls.last.arguments['tasks'], equals([]));

    // Emit 2 active tasks
    tasksStreamController.add([
      Task(
        id: 10,
        title: 'Calibrate Chrono',
        isCompleted: false,
        isArchived: false,
        sortOrder: 0,
        createdAt: DateTime(2026, 9, 15),
      ),
      Task(
        id: 11,
        title: 'Review Analog Dial',
        isCompleted: true,
        isArchived: false,
        sortOrder: 1,
        createdAt: DateTime(2026, 9, 15),
      ),
    ]);
    await tester.pump();

    expect(channelCalls, hasLength(2));
    expect(channelCalls.last.method, equals('updateAllWidgetData'));
    expect(channelCalls.last.arguments['tasks'], equals([
      {'id': 10, 'title': 'Calibrate Chrono', 'is_completed': false},
      {'id': 11, 'title': 'Review Analog Dial', 'is_completed': true},
    ]));

    await tester.pumpWidget(const SizedBox());
  });
}
