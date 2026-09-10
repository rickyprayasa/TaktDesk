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

    test('custom profile clamps values within bounds on both ends', () {
      final customUpper = PomodoroProfile.custom(
        focusMinutes: 120, // should clamp to 90
        shortBreakMinutes: 50, // should clamp to 30
        longBreakMinutes: 60, // should clamp to 45
      );
      expect(customUpper.focusMinutes, equals(90));
      expect(customUpper.shortBreakMinutes, equals(30));
      expect(customUpper.longBreakMinutes, equals(45));

      final customLower = PomodoroProfile.custom(
        focusMinutes: 0, // should clamp to 1
        shortBreakMinutes: 0, // should clamp to 1
        longBreakMinutes: 0, // should clamp to 1
      );
      expect(customLower.focusMinutes, equals(1));
      expect(customLower.shortBreakMinutes, equals(1));
      expect(customLower.longBreakMinutes, equals(1));
    });

    test('PomodoroProfileType exposes correct human-readable labels', () {
      expect(PomodoroProfileType.classic.label, equals('CLASSIC 25/5'));
      expect(PomodoroProfileType.monastic.label, equals('MONASTIC 50/10'));
      expect(PomodoroProfileType.sprint.label, equals('SPRINT 15/3'));
      expect(PomodoroProfileType.custom.label, equals('CUSTOM'));
    });

    test('PomodoroProfile supports copyWith and value equality', () {
      final modified = PomodoroProfile.classic.copyWith(focusMinutes: 30);
      expect(modified.focusMinutes, equals(30));
      expect(modified.shortBreakMinutes, equals(5));

      const identicalProfile = PomodoroProfile(
        type: PomodoroProfileType.classic,
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
      );
      expect(PomodoroProfile.classic, equals(identicalProfile));
      expect(PomodoroProfile.classic.hashCode, equals(identicalProfile.hashCode));
      expect(PomodoroProfile.classic, isNot(equals(PomodoroProfile.monastic)));
    });

    test('TimerState reports isBreak properly for focus, shortBreak, and longBreak', () {
      const focusState = TimerState(
        targetMinutes: 25,
        remainingSeconds: 1500,
        isRunning: false,
        phase: PomodoroPhase.focus,
      );
      expect(focusState.isBreak, isFalse);

      const shortBreakState = TimerState(
        targetMinutes: 5,
        remainingSeconds: 300,
        isRunning: false,
        phase: PomodoroPhase.shortBreak,
      );
      expect(shortBreakState.isBreak, isTrue);

      const longBreakState = TimerState(
        targetMinutes: 15,
        remainingSeconds: 900,
        isRunning: false,
        phase: PomodoroPhase.longBreak,
      );
      expect(longBreakState.isBreak, isTrue);

      final stateWithProfile = focusState.copyWith(profile: PomodoroProfile.monastic);
      expect(stateWithProfile.profile.type, equals(PomodoroProfileType.monastic));
    });
  });
}
