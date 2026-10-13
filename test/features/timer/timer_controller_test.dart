import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/audio/sound_effect.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_phase.dart';
import 'package:takt_desk/features/timer/domain/timer_state.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';

class MockAudioService extends AudioService {
  final List<SoundEffect> playedEffects = [];

  @override
  void playFoley(SoundEffect effect) {
    playedEffects.add(effect);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('TimerState', () {
    test('calculates progressPercent correctly', () {
      const stateStart = TimerState(
        targetMinutes: 25,
        remainingSeconds: 25 * 60.0,
        isRunning: false,
      );
      expect(stateStart.progressPercent, 0.0);

      const stateHalf = TimerState(
        targetMinutes: 25,
        remainingSeconds: 12.5 * 60.0,
        isRunning: true,
      );
      expect(stateHalf.progressPercent, closeTo(0.5, 0.001));

      const stateFinished = TimerState(
        targetMinutes: 25,
        remainingSeconds: 0.0,
        isRunning: false,
      );
      expect(stateFinished.progressPercent, 1.0);

      const stateZero = TimerState(
        targetMinutes: 0,
        remainingSeconds: 0.0,
        isRunning: false,
      );
      expect(stateZero.progressPercent, 0.0);
    });

    test('copyWith works as expected', () {
      const state = TimerState(
        targetMinutes: 25,
        remainingSeconds: 1500.0,
        isRunning: false,
        lastTickMinute: 25,
      );

      final updated = state.copyWith(isRunning: true, remainingSeconds: 1400.0);
      expect(updated.targetMinutes, 25);
      expect(updated.remainingSeconds, 1400.0);
      expect(updated.isRunning, isTrue);
      expect(updated.lastTickMinute, 25);
    });
  });

  group('ChronoDialController', () {
    test('ChronoDialController sets duration and updates progress', () {
      final controller = ChronoDialController();
      expect(controller.state.targetMinutes, 25);
      expect(controller.state.isRunning, isFalse);

      controller.setTargetMinutes(45);
      expect(controller.state.targetMinutes, 45);

      controller.start();
      expect(controller.state.isRunning, isTrue);

      controller.pause();
      expect(controller.state.isRunning, isFalse);
    });

    test('setTargetMinutes clamps between 1 and 90 and ignores while running', () {
      final controller = ChronoDialController();

      controller.setTargetMinutes(0);
      expect(controller.state.targetMinutes, 1);
      expect(controller.state.remainingSeconds, 60.0);

      controller.setTargetMinutes(100);
      expect(controller.state.targetMinutes, 90);
      expect(controller.state.remainingSeconds, 90 * 60.0);

      controller.start();
      controller.setTargetMinutes(30);
      // Ignored while running
      expect(controller.state.targetMinutes, 90);
    });

    test('reset restores remainingSeconds to targetMinutes * 60 and stops timer', () {
      final controller = ChronoDialController();
      controller.setTargetMinutes(20);
      controller.start();
      controller.tick(10.0);

      expect(controller.state.remainingSeconds, 20 * 60.0 - 10.0);
      expect(controller.state.isRunning, isTrue);

      controller.reset();
      expect(controller.state.remainingSeconds, 20 * 60.0);
      expect(controller.state.isRunning, isFalse);
    });

    test('tick decrements remainingSeconds and auto-advances to Short Break in standby on completion', () {
      final controller = ChronoDialController();
      controller.setTargetMinutes(1);
      controller.start();

      // Tick 30 seconds
      controller.tick(30.0);
      expect(controller.state.remainingSeconds, 30.0);
      expect(controller.state.isRunning, isTrue);

      // Tick 35 more seconds (exceeding remaining)
      controller.tick(35.0);
      // Auto-advances to Short Break (5 mins = 300s) in Standby
      expect(controller.state.phase, PomodoroPhase.shortBreak);
      expect(controller.state.remainingSeconds, 300.0);
      expect(controller.state.isRunning, isFalse);
    });

    test('tick does nothing if not running', () {
      final controller = ChronoDialController();
      controller.tick(10.0);
      expect(controller.state.remainingSeconds, 25 * 60.0);
    });

    test('start begins ticking the standby phase after previous session completed', () {
      final controller = ChronoDialController();
      controller.setTargetMinutes(25);
      controller.start();

      // Exhaust the focus session
      controller.tick(1500.0);
      // Auto-advances to Short Break in Standby
      expect(controller.state.phase, PomodoroPhase.shortBreak);
      expect(controller.state.remainingSeconds, 300.0);
      expect(controller.state.isRunning, isFalse);

      // Start the short break session
      controller.start();
      expect(controller.state.isRunning, isTrue);
      expect(controller.state.remainingSeconds, 300.0);

      // Ticks smoothly from short break time
      controller.tick(1.0);
      expect(controller.state.remainingSeconds, 299.0);
    });

    test('initial state and setTargetMinutes initialize lastTickMinute to prevent spurious first tick', () {
      final controller = ChronoDialController();
      expect(controller.state.lastTickMinute, 25);

      controller.setTargetMinutes(40);
      expect(controller.state.lastTickMinute, 40);

      controller.reset();
      expect(controller.state.lastTickMinute, 40);
    });

    test('triggers AudioService springButton on start and pause, and dialClick on minute tick', () {
      final mockAudio = MockAudioService();
      final controller = ChronoDialController(mockAudio);

      // Start triggers springButton
      controller.start();
      expect(mockAudio.playedEffects, [SoundEffect.springButton]);

      // Sub-minute tick should NOT trigger dialClick
      controller.tick(0.5);
      expect(mockAudio.playedEffects, [SoundEffect.springButton]);

      // Ticking past the 24-minute boundary triggers dialClick
      controller.tick(60.0);
      expect(mockAudio.playedEffects, [SoundEffect.springButton, SoundEffect.dialClick]);

      // Pause triggers springButton
      controller.pause();
      expect(mockAudio.playedEffects, [
        SoundEffect.springButton,
        SoundEffect.dialClick,
        SoundEffect.springButton,
      ]);
    });

    test('records timer session to AppDatabase when timer finishes', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final controller = ChronoDialController(null, db);

      controller.setTargetMinutes(25);
      controller.start();
      // Tick until completion
      controller.tick(1500.0);
      expect(controller.state.phase, PomodoroPhase.shortBreak);
      expect(controller.state.remainingSeconds, 300.0);
      expect(controller.state.isRunning, isFalse);

      // The row is written once the slip it counted for is known (one database round trip).
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final sessions = await db.select(db.timerSessions).get();
      expect(sessions.length, 1);
      expect(sessions.first.targetMinutes, 25);
      expect(sessions.first.elapsedSeconds, 1500);
      expect(sessions.first.isFinished, isTrue);
    });
  });
}
