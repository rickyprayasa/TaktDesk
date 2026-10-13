import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_phase.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('"Start focus" starts a focus session even when the dial stands on a break', () {
    final c = ChronoDialController();
    addTearDown(c.dispose);
    c.start();
    c.tick(25 * 60); // focus done → short break, standing
    expect(c.state.phase, PomodoroPhase.shortBreak);
    expect(c.state.isRunning, isFalse);

    c.startFocus();
    expect(c.state.phase, PomodoroPhase.focus);
    expect(c.state.isRunning, isTrue);
    expect(c.state.remainingSeconds, 25 * 60);

    c.startFocus(); // already running: nothing changes
    expect(c.state.isRunning, isTrue);
  });

  test('changing the custom durations while paused ends the paused session (recorded, not resumed later)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final c = ChronoDialController(null, db);
    addTearDown(() async {
      c.dispose();
      await db.close();
    });
    c.updateCustomDurations(focusMinutes: 30, activate: true);
    c.start();
    c.tick(10 * 60);
    c.pause();

    c.updateCustomDurations(focusMinutes: 40, activate: true);
    expect(c.state.remainingSeconds, 40 * 60);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final sessions = await db.select(db.timerSessions).get();
    expect(sessions, hasLength(1), reason: 'the 10 focused minutes are kept as an unfinished session');
    expect(sessions.single.elapsedSeconds, 600);
    expect(sessions.single.isFinished, isFalse);
  });
}
