import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/core/focus/focus_lock_controller.dart';
import 'package:takt_desk/core/focus/focus_lock_service.dart';
import 'package:takt_desk/core/sensors/parallax_controller.dart';
import 'package:takt_desk/features/desk/presentation/ambient_lighting_layer.dart';
import 'package:takt_desk/features/desk/presentation/desk_canvas_screen.dart';
import 'package:takt_desk/features/desk/presentation/isometric_desk_layout.dart';
import 'package:takt_desk/features/desk/presentation/widgets/chassis_theme_switch.dart';
import 'package:takt_desk/features/desk/presentation/widgets/desk_spec_plate_widget.dart';
import 'package:takt_desk/features/desk/presentation/widgets/desk_telemetry_slip_widget.dart';
import 'package:takt_desk/features/desk/presentation/widgets/emergency_unlatch_widget.dart';
import 'package:takt_desk/features/desk/presentation/widgets/monastic_switch_widget.dart';
import 'package:takt_desk/features/desk/presentation/widgets/settings_rivet_button.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';
import 'package:takt_desk/features/settings/presentation/takt_settings_sheet.dart';
import 'package:takt_desk/features/tasks/presentation/receipt_runner_widget.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_widget.dart';
import 'package:takt_desk/features/vinyl/presentation/vinyl_player_widget.dart';

class MockFocusLockService extends FocusLockService {
  @override
  Future<bool> enableFocusLock() async => true;
  @override
  Future<bool> disableFocusLock() async => true;
}

List<Override> deskTestOverrides(AppDatabase testDb) => [
  appDatabaseProvider.overrideWithValue(testDb),
  focusLockServiceProvider.overrideWithValue(MockFocusLockService()),
  todayFocusStatsProvider.overrideWith(
    (ref) => Stream.value(const TodayFocusStats(completedCount: 0, totalMinutes: 0)),
  ),
  lifetimeFocusStatsProvider.overrideWith(
    (ref) => Stream.value(const LifetimeFocusStats(totalSessions: 0, totalHours: 0)),
  ),
  todayTimerSessionsStreamProvider.overrideWith(
    (ref) => Stream.value(const []),
  ),
];

void main() {
  group('DeskCanvasScreen & IsometricDeskLayout', () {
    late AppDatabase testDb;

    setUp(() {
      testDb = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await testDb.close();
    });

    testWidgets('DeskCanvasScreen renders pure mobile console with switcher, MonasticSwitchWidget, and theme switch', (tester) async {
      tester.view.physicalSize = const Size(400, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: deskTestOverrides(testDb),
          child: const MaterialApp(
            home: DeskCanvasScreen(),
          ),
        ),
      );

      expect(find.byType(AmbientLightingLayer), findsOneWidget);
      expect(find.byType(IsometricDeskLayout), findsOneWidget);
      expect(find.byType(ChronoDialWidget), findsOneWidget);
      expect(find.byType(ChassisThemeSwitch), findsOneWidget);
      expect(find.byType(MonasticSwitchWidget), findsOneWidget);

      // PopScope should initially allow pop when unlocked
      final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
      expect(popScopeFinder, findsOneWidget);
      final popScopeWidget = tester.widget<PopScope>(popScopeFinder);
      expect(popScopeWidget.canPop, isTrue);

      // Switcher allows viewing tasks and vinyl
      expect(find.text('DIAL'), findsOneWidget);
      expect(find.text('TASKS'), findsOneWidget);
      expect(find.text('VINYL'), findsOneWidget);

      await tester.tap(find.text('TASKS'));
      await tester.pump();
      expect(find.byType(ReceiptRunnerWidget), findsOneWidget);

      await tester.tap(find.text('VINYL'));
      await tester.pump();
      expect(find.byType(VinylPlayerWidget), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('DeskCanvasScreen renders Settings rivet button and DeskSpecPlateWidget anchored at bottom across tabs', (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: deskTestOverrides(testDb),
          child: const MaterialApp(
            home: DeskCanvasScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SettingsRivetButton), findsOneWidget);
      expect(find.byType(DeskSpecPlateWidget), findsOneWidget);

      final plateInitialY = tester.getTopLeft(find.byType(DeskSpecPlateWidget)).dy;

      // Switch to TASKS tab: plate stays at the exact same bottom position
      await tester.tap(find.text('TASKS'));
      await tester.pumpAndSettle();
      final plateTasksY = tester.getTopLeft(find.byType(DeskSpecPlateWidget)).dy;
      expect(plateTasksY, equals(plateInitialY));

      // Switch to VINYL tab: plate stays at the exact same bottom position
      await tester.tap(find.text('VINYL'));
      await tester.pumpAndSettle();
      final plateVinylY = tester.getTopLeft(find.byType(DeskSpecPlateWidget)).dy;
      expect(plateVinylY, equals(plateInitialY));

      // Tapping settings button displays TaktSettingsSheet
      await tester.tap(find.byType(SettingsRivetButton));
      await tester.pumpAndSettle();

      expect(find.byType(TaktSettingsSheet), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('DeskCanvasScreen enforces PopScope and shows EmergencyUnlatchWidget when focus is locked', (tester) async {
      final container = ProviderContainer(
        overrides: deskTestOverrides(testDb),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DeskCanvasScreen(),
          ),
        ),
      );

      // Initially no unlatch widget label visible
      expect(find.text('HOLD 5s TO UNLATCH'), findsNothing);

      // Engage Monastic Focus Lock
      await container.read(focusLockProvider.notifier).engageLock();
      await tester.pump();

      // Now PopScope blocks popping
      final popScopeWidget = tester.widget<PopScope>(find.byWidgetPredicate((w) => w is PopScope));
      expect(popScopeWidget.canPop, isFalse);

      // Emergency unlatch widget is now visible
      expect(find.byType(EmergencyUnlatchWidget), findsOneWidget);
      expect(find.text('HOLD 5s TO UNLATCH'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('EmergencyUnlatchWidget remains anchored at bottom dock across DIAL, TASKS, and VINYL tabs when locked', (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: deskTestOverrides(testDb),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DeskCanvasScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Engage Monastic Focus Lock
      await container.read(focusLockProvider.notifier).engageLock();
      await tester.pumpAndSettle();

      expect(find.byType(EmergencyUnlatchWidget), findsOneWidget);
      final unlatchDialY = tester.getTopLeft(find.byType(EmergencyUnlatchWidget)).dy;
      final plateDialY = tester.getTopLeft(find.byType(DeskSpecPlateWidget)).dy;
      expect(unlatchDialY, lessThan(plateDialY));

      // Switch to TASKS tab
      await tester.tap(find.text('TASKS'));
      await tester.pumpAndSettle();
      final unlatchTasksY = tester.getTopLeft(find.byType(EmergencyUnlatchWidget)).dy;
      expect(unlatchTasksY, equals(unlatchDialY), reason: 'Unlatch button must not jump up on TASKS tab');

      // Switch to VINYL tab
      await tester.tap(find.text('VINYL'));
      await tester.pumpAndSettle();
      final unlatchVinylY = tester.getTopLeft(find.byType(EmergencyUnlatchWidget)).dy;
      expect(unlatchVinylY, equals(unlatchDialY), reason: 'Unlatch button must not jump up on VINYL tab');

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('DeskCanvasScreen renders master console layout on wide screens with simultaneous modules', (tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: deskTestOverrides(testDb),
          child: const MaterialApp(
            home: DeskCanvasScreen(),
          ),
        ),
      );

      // Verifies branding and presence of MonasticSwitchWidget
      expect(find.text('ZYKL'), findsOneWidget);
      expect(find.byType(MonasticSwitchWidget), findsOneWidget);

      // In master console mode on wide screens, left pane shows dial and right pane shows dispenser tab
      expect(find.byType(ChronoDialWidget), findsOneWidget);
      expect(find.byType(ReceiptRunnerWidget), findsOneWidget);
      expect(find.byType(VinylPlayerWidget), findsNothing);

      // Switching right pane tab displays vinyl player
      await tester.tap(find.text('VINYL'));
      await tester.pumpAndSettle();
      expect(find.byType(VinylPlayerWidget), findsOneWidget);
      expect(find.byType(ReceiptRunnerWidget), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('IsometricDeskLayout applies 3D perspective and parallax transform', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
        ],
      );
      addTearDown(container.dispose);

      container.read(parallaxProvider.notifier).updateSensorInput(rawX: 4.0, rawY: -3.0);
      final parallaxState = container.read(parallaxProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: IsometricDeskLayout(
                child: Text('Desk Surface'),
              ),
            ),
          ),
        ),
      );

      final transformFinder = find.descendant(
        of: find.byType(IsometricDeskLayout),
        matching: find.byType(Transform),
      );
      expect(transformFinder, findsOneWidget);

      final transformWidget = tester.widget<Transform>(transformFinder);
      final matrix = transformWidget.transform;

      expect(matrix.entry(3, 2), closeTo(0.001, 1e-5));
      expect(transformWidget.alignment, Alignment.center);
      expect(parallaxState.tiltX, isNonZero);
      expect(parallaxState.tiltY, isNonZero);
    });

    testWidgets('DeskCanvasScreen updates parallaxProvider from gyroscope stream', (tester) async {
      final streamController = StreamController<GyroscopeEvent>.broadcast();
      addTearDown(streamController.close);

      final container = ProviderContainer(
        overrides: deskTestOverrides(testDb),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: DeskCanvasScreen(gyroscopeStream: streamController.stream),
          ),
        ),
      );

      expect(container.read(parallaxProvider).tiltX, 0.0);
      expect(container.read(parallaxProvider).tiltY, 0.0);

      streamController.add(GyroscopeEvent(2.5, 1.5, 0.0));
      await tester.pump();

      expect(container.read(parallaxProvider).tiltX, isNonZero);
      expect(container.read(parallaxProvider).tiltY, isNonZero);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('DeskCanvasScreen handles gyroscope stream error gracefully without crashing', (tester) async {
      final streamController = StreamController<GyroscopeEvent>.broadcast();
      addTearDown(streamController.close);

      final container = ProviderContainer(
        overrides: deskTestOverrides(testDb),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: DeskCanvasScreen(gyroscopeStream: streamController.stream),
          ),
        ),
      );

      streamController.addError(Exception('Sensor not available on device'));
      await tester.pump();

      expect(find.byType(DeskCanvasScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('DeskCanvasScreen updates parallaxProvider from accelerometer stream', (tester) async {
      final streamController = StreamController<AccelerometerEvent>.broadcast();
      addTearDown(streamController.close);

      final container = ProviderContainer(
        overrides: deskTestOverrides(testDb),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: DeskCanvasScreen(accelerometerStream: streamController.stream),
          ),
        ),
      );

      expect(container.read(parallaxProvider).tiltX, 0.0);
      expect(container.read(parallaxProvider).tiltY, 0.0);

      streamController.add(AccelerometerEvent(0.4, 0.3, 9.8));
      await tester.pump();

      expect(container.read(parallaxProvider).tiltX, isNonZero);
      expect(container.read(parallaxProvider).tiltY, isNonZero);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('DeskCanvasScreen handles accelerometer stream error gracefully without crashing', (tester) async {
      final streamController = StreamController<AccelerometerEvent>.broadcast();
      addTearDown(streamController.close);

      final container = ProviderContainer(
        overrides: deskTestOverrides(testDb),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: DeskCanvasScreen(accelerometerStream: streamController.stream),
          ),
        ),
      );

      streamController.addError(Exception('Accelerometer not available'));
      await tester.pump();

      expect(find.byType(DeskCanvasScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
