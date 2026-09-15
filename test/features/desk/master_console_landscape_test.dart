import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/core/focus/focus_lock_service.dart';
import 'package:takt_desk/features/desk/presentation/desk_canvas_screen.dart';
import 'package:takt_desk/features/desk/presentation/widgets/chassis_theme_switch.dart';
import 'package:takt_desk/features/desk/presentation/widgets/desk_spec_plate_widget.dart';
import 'package:takt_desk/features/desk/presentation/widgets/desk_telemetry_slip_widget.dart';
import 'package:takt_desk/features/desk/presentation/widgets/emergency_unlatch_widget.dart';
import 'package:takt_desk/features/desk/presentation/widgets/master_console_landscape_layout.dart';
import 'package:takt_desk/features/desk/presentation/widgets/monastic_switch_widget.dart';
import 'package:takt_desk/features/desk/presentation/widgets/settings_rivet_button.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';
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
  group('MasterConsoleLandscapeLayout & Responsive Desk Screen', () {
    late AppDatabase testDb;

    setUp(() {
      testDb = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await testDb.close();
    });

    testWidgets('DeskCanvasScreen renders dual-pane master console in landscape/tablet mode with separate right pane tab menu for Dispenser and Vinyl', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
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

      // MasterConsoleLandscapeLayout is rendered
      expect(find.byType(MasterConsoleLandscapeLayout), findsOneWidget);

      // Left pane instruments & controls
      expect(find.byType(ChronoDialWidget), findsOneWidget);
      expect(find.byType(MonasticSwitchWidget), findsOneWidget);
      expect(find.byType(EmergencyUnlatchWidget), findsOneWidget);

      // Right pane tab menu
      expect(find.text('DISPENSER'), findsOneWidget);
      expect(find.text('VINYL'), findsOneWidget);

      // Initially Dispenser is selected and Vinyl is not mounted
      expect(find.byType(ReceiptRunnerWidget), findsOneWidget);
      expect(find.byType(VinylPlayerWidget), findsNothing);

      // Tapping VINYL tab switches right pane to VinylPlayerWidget
      await tester.tap(find.text('VINYL'));
      await tester.pumpAndSettle();

      expect(find.byType(VinylPlayerWidget), findsOneWidget);
      expect(find.byType(ReceiptRunnerWidget), findsNothing);

      // Tapping DISPENSER tab switches back
      await tester.tap(find.text('DISPENSER'));
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptRunnerWidget), findsOneWidget);
      expect(find.byType(VinylPlayerWidget), findsNothing);

      // Header and footer controls
      expect(find.byType(ChassisThemeSwitch), findsOneWidget);
      expect(find.byType(SettingsRivetButton), findsOneWidget);
      expect(find.byType(DeskSpecPlateWidget), findsOneWidget);
      expect(find.text('ZYKL'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('DeskCanvasScreen falls back to mobile single-pane layout with instrument switcher on portrait/narrow viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 750);
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

      // Mobile layout has the tab buttons
      expect(find.text('DIAL'), findsOneWidget);
      expect(find.text('TASKS'), findsOneWidget);
      expect(find.text('VINYL'), findsOneWidget);

      // Initially only ChronoDial is mounted in mobile mode
      expect(find.byType(ChronoDialWidget), findsOneWidget);
      expect(find.byType(ReceiptRunnerWidget), findsNothing);
      expect(find.byType(VinylPlayerWidget), findsNothing);

      // MasterConsoleLandscapeLayout is NOT mounted
      expect(find.byType(MasterConsoleLandscapeLayout), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
