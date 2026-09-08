import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_phase.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';
import 'package:takt_desk/features/timer/presentation/widgets/split_flap_board_widget.dart';
import 'package:takt_desk/features/timer/presentation/widgets/split_flap_tile.dart';

void main() {
  group('PomodoroPhase Domain & Controller', () {
    test('PomodoroPhase labels and default minutes', () {
      expect(PomodoroPhase.focus.label, 'FOCUS');
      expect(PomodoroPhase.focus.defaultMinutes, 25);

      expect(PomodoroPhase.shortBreak.label, 'SHORT BRK');
      expect(PomodoroPhase.shortBreak.defaultMinutes, 5);

      expect(PomodoroPhase.longBreak.label, 'LONG BRK');
      expect(PomodoroPhase.longBreak.defaultMinutes, 15);
    });

    test('ChronoDialController advancePhase cycles through Focus -> ShortBreak -> LongBreak', () {
      final controller = ChronoDialController();

      // Starts in focus phase cycle 1 (25m)
      expect(controller.state.phase, PomodoroPhase.focus);
      expect(controller.state.cycleCount, 1);
      expect(controller.state.targetMinutes, 25);

      // Advance to short break
      controller.advancePhase();
      expect(controller.state.phase, PomodoroPhase.shortBreak);
      expect(controller.state.cycleCount, 1);
      expect(controller.state.targetMinutes, 5);

      // Advance to focus cycle 2
      controller.advancePhase();
      expect(controller.state.phase, PomodoroPhase.focus);
      expect(controller.state.cycleCount, 2);
      expect(controller.state.targetMinutes, 25);

      // Advance cycle 2 break -> cycle 3 focus -> cycle 3 break -> cycle 4 focus
      controller.advancePhase(); // short break 2
      controller.advancePhase(); // focus 3
      controller.advancePhase(); // short break 3
      controller.advancePhase(); // focus 4
      expect(controller.state.phase, PomodoroPhase.focus);
      expect(controller.state.cycleCount, 4);

      // After 4th focus cycle, advance triggers LONG BREAK!
      controller.advancePhase();
      expect(controller.state.phase, PomodoroPhase.longBreak);
      expect(controller.state.cycleCount, 4);
      expect(controller.state.targetMinutes, 15);

      // After long break, cycles reset back to focus cycle 1!
      controller.advancePhase();
      expect(controller.state.phase, PomodoroPhase.focus);
      expect(controller.state.cycleCount, 1);
      expect(controller.state.targetMinutes, 25);
    });
  });

  group('SplitFlapBoardWidget', () {
    testWidgets('renders split flap tiles and updates phase on tap', (tester) async {
      final testDb = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(testDb.close);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: SplitFlapBoardWidget(),
              ),
            ),
          ),
        ),
      );

      // Verify SplitFlapTiles exist for both rows
      expect(find.byType(SplitFlapTile), findsWidgets);

      // Verify initial phase is focus (25m)
      expect(container.read(chronoDialProvider).phase, PomodoroPhase.focus);

      // Tap board to advance phase
      await tester.tap(find.byType(SplitFlapBoardWidget));
      await tester.pumpAndSettle();

      // Should now be in Short Break (5m)
      expect(container.read(chronoDialProvider).phase, PomodoroPhase.shortBreak);
      expect(container.read(chronoDialProvider).targetMinutes, 5);
    });
  });
}
