import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_phase.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_profile.dart';
import 'package:takt_desk/features/timer/domain/timer_state.dart';

void main() {
  group('PomodoroProfile', () {
    test('standard presets have accurate focus and break intervals', () {
      expect(PomodoroProfile.classic.focusMinutes, equals(25));
      expect(PomodoroProfile.classic.shortBreakMinutes, equals(5));
      expect(PomodoroProfile.classic.longBreakMinutes, equals(15));

      expect(PomodoroProfile.monastic.focusMinutes, equals(50));
      expect(PomodoroProfile.monastic.shortBreakMinutes, equals(10));
      expect(PomodoroProfile.monastic.longBreakMinutes, equals(30));

      expect(PomodoroProfile.sprint.focusMinutes, equals(15));
      expect(PomodoroProfile.sprint.shortBreakMinutes, equals(3));
      expect(PomodoroProfile.sprint.longBreakMinutes, equals(10));
    });

    test('custom profile clamps values within bounds', () {
      final custom = PomodoroProfile.custom(
        focusMinutes: 120, // should clamp to 90
        shortBreakMinutes: 0, // should clamp to 1
        longBreakMinutes: 60, // should clamp to 45
      );
      expect(custom.focusMinutes, equals(90));
      expect(custom.shortBreakMinutes, equals(1));
      expect(custom.longBreakMinutes, equals(45));
    });

    test('TimerState reports isBreak properly', () {
      const focusState = TimerState(
        targetMinutes: 25,
        remainingSeconds: 1500,
        isRunning: false,
        phase: PomodoroPhase.focus,
      );
      expect(focusState.isBreak, isFalse);

      const breakState = TimerState(
        targetMinutes: 5,
        remainingSeconds: 300,
        isRunning: false,
        phase: PomodoroPhase.shortBreak,
      );
      expect(breakState.isBreak, isTrue);
    });
  });
}
