import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/audio/sound_effect.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_phase.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_profile.dart';
import 'package:takt_desk/features/timer/domain/timer_state.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';

class MockAudioService extends AudioService {
  final List<SoundEffect> playedEffects = [];
  final List<String> playedChimes = [];

  @override
  void playFoley(SoundEffect effect) {
    playedEffects.add(effect);
  }

  @override
  void playAlarmChime(String chimeId) {
    playedChimes.add(chimeId);
  }
}

extension AppDatabaseTestExtensions on AppDatabase {
  Future<List<TimerSession>> getTodayTimerSessions() => watchTodayTimerSessions().first;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChronoDialController Pomodoro State Machine', () {
    test(
      'ChronoDialController auto-advances to Short Break, rings chime, logs focus, and enters standby',
      () async {
        final mockAudio = MockAudioService();
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(testDb.close);

        final controller = ChronoDialController(mockAudio, testDb);
        controller.setProfile(PomodoroProfile.classic);
        expect(controller.state.targetMinutes, equals(25));
        expect(controller.state.phase, equals(PomodoroPhase.focus));

        controller.start();
        expect(controller.state.isRunning, isTrue);

        // Complete the 25 minute focus session
        controller.tick(25 * 60.0);

        // Verifications:
        // 1. Chime played
        expect(mockAudio.playedChimes, contains('braunBell'));
        // 2. Switched to Short Break (Cycle 1/4)
        expect(controller.state.phase, equals(PomodoroPhase.shortBreak));
        expect(controller.state.targetMinutes, equals(5));
        expect(controller.state.remainingSeconds, equals(300.0));
        // 3. Standby mode awaiting user crown press
        expect(controller.state.isRunning, isFalse);

        // 4. Focus session was recorded in database
        final sessions = await testDb.getTodayTimerSessions();
        expect(sessions.length, equals(1));
        expect(sessions.first.targetMinutes, equals(25));

        // Now start and complete short break
        mockAudio.playedChimes.clear();
        controller.start();
        controller.tick(5 * 60.0);

        // Verifications for Break completion:
        // 1. Chime played
        expect(mockAudio.playedChimes, contains('braunBell'));
        // 2. Switched to Focus (Cycle 2/4)
        expect(controller.state.phase, equals(PomodoroPhase.focus));
        expect(controller.state.cycleCount, equals(2));
        expect(controller.state.targetMinutes, equals(25));
        expect(controller.state.isRunning, isFalse);

        // 3. Break was NOT recorded in database (still only 1 session)
        final sessionsAfterBreak = await testDb.getTodayTimerSessions();
        expect(sessionsAfterBreak.length, equals(1));
      },
    );

    test('completes full 4-cycle Pomodoro progression through long break and resets to cycle 1', () {
      final mockAudio = MockAudioService();
      final controller = ChronoDialController(mockAudio);
      controller.setProfile(PomodoroProfile.classic);

      // Cycle 1: Focus (25m) -> Short Break (5m)
      controller.start();
      controller.tick(25 * 60.0);
      expect(controller.state.phase, PomodoroPhase.shortBreak);
      expect(controller.state.cycleCount, 1);
      expect(controller.state.targetMinutes, 5);
      expect(controller.state.remainingSeconds, 300.0);
      expect(controller.state.isRunning, isFalse);

      // Cycle 1: Short Break (5m) -> Focus Cycle 2 (25m)
      controller.start();
      controller.tick(5 * 60.0);
      expect(controller.state.phase, PomodoroPhase.focus);
      expect(controller.state.cycleCount, 2);
      expect(controller.state.targetMinutes, 25);
      expect(controller.state.remainingSeconds, 1500.0);
      expect(controller.state.isRunning, isFalse);

      // Cycle 2: Focus (25m) -> Short Break (5m)
      controller.start();
      controller.tick(25 * 60.0);
      expect(controller.state.phase, PomodoroPhase.shortBreak);
      expect(controller.state.cycleCount, 2);

      // Cycle 2: Short Break (5m) -> Focus Cycle 3 (25m)
      controller.start();
      controller.tick(5 * 60.0);
      expect(controller.state.phase, PomodoroPhase.focus);
      expect(controller.state.cycleCount, 3);

      // Cycle 3: Focus (25m) -> Short Break (5m)
      controller.start();
      controller.tick(25 * 60.0);
      expect(controller.state.phase, PomodoroPhase.shortBreak);
      expect(controller.state.cycleCount, 3);

      // Cycle 3: Short Break (5m) -> Focus Cycle 4 (25m)
      controller.start();
      controller.tick(5 * 60.0);
      expect(controller.state.phase, PomodoroPhase.focus);
      expect(controller.state.cycleCount, 4);

      // Cycle 4: Focus (25m) -> LONG BREAK (15m, cycle 4)
      controller.start();
      controller.tick(25 * 60.0);
      expect(controller.state.phase, PomodoroPhase.longBreak);
      expect(controller.state.cycleCount, 4);
      expect(controller.state.targetMinutes, 15);
      expect(controller.state.remainingSeconds, 900.0);
      expect(controller.state.isRunning, isFalse);

      // Cycle 4: Long Break (15m) -> Focus Cycle 1 (resets to cycle 1)
      controller.start();
      controller.tick(15 * 60.0);
      expect(controller.state.phase, PomodoroPhase.focus);
      expect(controller.state.cycleCount, 1);
      expect(controller.state.targetMinutes, 25);
      expect(controller.state.remainingSeconds, 1500.0);
      expect(controller.state.isRunning, isFalse);
    });

    test('respects custom/monastic PomodoroProfile durations during auto-advance', () {
      final mockAudio = MockAudioService();
      final controller = ChronoDialController(mockAudio);
      controller.setProfile(PomodoroProfile.monastic); // 50 focus / 10 short / 30 long

      expect(controller.state.targetMinutes, 50);
      expect(controller.state.remainingSeconds, 50 * 60.0);

      // Start & complete 50 min focus
      controller.start();
      controller.tick(50 * 60.0);
      expect(controller.state.phase, PomodoroPhase.shortBreak);
      expect(controller.state.cycleCount, 1);
      expect(controller.state.targetMinutes, 10);
      expect(controller.state.remainingSeconds, 600.0);

      // Complete 10 min break -> Focus cycle 2 (50m)
      controller.start();
      controller.tick(10 * 60.0);
      expect(controller.state.phase, PomodoroPhase.focus);
      expect(controller.state.cycleCount, 2);
      expect(controller.state.targetMinutes, 50);
      expect(controller.state.remainingSeconds, 3000.0);
    });

    test('setProfile is ignored while timer is running', () {
      final controller = ChronoDialController();
      controller.setProfile(PomodoroProfile.classic);
      controller.start();
      expect(controller.state.isRunning, isTrue);

      controller.setProfile(PomodoroProfile.monastic);
      expect(controller.state.profile, PomodoroProfile.classic);
      expect(controller.state.targetMinutes, 25);
    });

    test('setTargetMinutes adjusts duration when stopped and is ignored when running', () {
      final controller = ChronoDialController();
      controller.setTargetMinutes(40);
      expect(controller.state.targetMinutes, 40);
      expect(controller.state.remainingSeconds, 40 * 60.0);

      controller.start();
      controller.setTargetMinutes(10);
      expect(controller.state.targetMinutes, 40);
    });

    test('reset restores remainingSeconds to targetMinutes * 60 and stops timer', () {
      final controller = ChronoDialController();
      controller.setTargetMinutes(20);
      controller.start();
      controller.tick(30.0);
      expect(controller.state.isRunning, isTrue);

      controller.reset();
      expect(controller.state.isRunning, isFalse);
      expect(controller.state.remainingSeconds, 20 * 60.0);
    });

    test('manual advancePhase steps through phases using active profile durations', () {
      final controller = ChronoDialController();
      controller.setProfile(PomodoroProfile.monastic); // 50 / 10 / 30

      expect(controller.state.phase, PomodoroPhase.focus);
      expect(controller.state.targetMinutes, 50);

      controller.advancePhase();
      expect(controller.state.phase, PomodoroPhase.shortBreak);
      expect(controller.state.targetMinutes, 10);

      controller.advancePhase();
      expect(controller.state.phase, PomodoroPhase.focus);
      expect(controller.state.cycleCount, 2);
      expect(controller.state.targetMinutes, 50);
    });

    test('updateCustomDurations updates customProfile and leaves non-custom active session untouched', () {
      final controller = ChronoDialController();
      controller.setProfile(PomodoroProfile.classic);
      expect(controller.state.targetMinutes, equals(25));
      expect(controller.state.cycleCount, equals(1));

      controller.updateCustomDurations(
        focusMinutes: 33,
        shortBreakMinutes: 7,
        longBreakMinutes: 18,
      );

      // Custom profile is updated
      expect(controller.state.customProfile.focusMinutes, equals(33));
      expect(controller.state.customProfile.shortBreakMinutes, equals(7));
      expect(controller.state.customProfile.longBreakMinutes, equals(18));

      // Active session is still classic 25m
      expect(controller.state.profile.type, equals(PomodoroProfileType.classic));
      expect(controller.state.targetMinutes, equals(25));
    });

    test('updateCustomDurations updates active custom profile and clamps duration bounds', () {
      final controller = ChronoDialController();
      controller.setProfile(controller.state.customProfile);

      // Exceed bounds: focus 120 -> 90, short break 50 -> 30, long break 60 -> 45
      controller.updateCustomDurations(
        focusMinutes: 120,
        shortBreakMinutes: 50,
        longBreakMinutes: 60,
      );

      expect(controller.state.customProfile.focusMinutes, equals(90));
      expect(controller.state.customProfile.shortBreakMinutes, equals(30));
      expect(controller.state.customProfile.longBreakMinutes, equals(45));

      // Active profile is updated to clamped focus
      expect(controller.state.targetMinutes, equals(90));
      expect(controller.state.remainingSeconds, equals(90 * 60.0));
      expect(controller.state.phase, equals(PomodoroPhase.focus));
      expect(controller.state.cycleCount, equals(1));
    });
    test('updateCustomDurations with activate=true switches active profile to custom and updates duration', () {
      final controller = ChronoDialController();
      controller.setProfile(PomodoroProfile.monastic);
      expect(controller.state.targetMinutes, equals(50));
      expect(controller.state.profile.type, equals(PomodoroProfileType.monastic));

      controller.updateCustomDurations(
        focusMinutes: 52,
        longBreakInterval: 3,
        activate: true,
      );

      expect(controller.state.profile.type, equals(PomodoroProfileType.custom));
      expect(controller.state.targetMinutes, equals(52));
      expect(controller.state.profile.longBreakInterval, equals(3));
      expect(controller.state.customProfile.longBreakInterval, equals(3));
    });

    test('custom longBreakInterval triggers long break after specified cycle count', () {
      final controller = ChronoDialController();
      // Set custom profile with longBreakInterval: 2
      final custom2 = PomodoroProfile.custom(
        focusMinutes: 20,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        longBreakInterval: 2,
      );
      controller.setProfile(custom2);
      expect(controller.state.profile.longBreakInterval, equals(2));

      // Cycle 1: Focus (20m) -> Short Break (5m)
      controller.start();
      controller.tick(20 * 60.0);
      expect(controller.state.phase, equals(PomodoroPhase.shortBreak));
      expect(controller.state.cycleCount, equals(1));

      // Cycle 1: Short Break (5m) -> Focus Cycle 2 (20m)
      controller.start();
      controller.tick(5 * 60.0);
      expect(controller.state.phase, equals(PomodoroPhase.focus));
      expect(controller.state.cycleCount, equals(2));

      // Cycle 2: Focus (20m) -> LONG BREAK (since longBreakInterval is 2!)
      controller.start();
      controller.tick(20 * 60.0);
      expect(controller.state.phase, equals(PomodoroPhase.longBreak));
      expect(controller.state.cycleCount, equals(2));
      expect(controller.state.targetMinutes, equals(15));
    });

    group('ChronoDialController Custom Calibration State Machine', () {
      test('ChronoSetupStage enum properties and telemetryLabel', () {
        expect(ChronoSetupStage.none.isActive, isFalse);
        expect(ChronoSetupStage.none.telemetryLabel, equals('STANDBY // READY'));

        expect(ChronoSetupStage.focus.isActive, isTrue);
        expect(ChronoSetupStage.focus.telemetryLabel, equals('SET 1/4 // FOCUS'));

        expect(ChronoSetupStage.shortBreak.isActive, isTrue);
        expect(ChronoSetupStage.shortBreak.telemetryLabel, equals('SET 2/4 // SHORT BRK'));

        expect(ChronoSetupStage.longBreak.isActive, isTrue);
        expect(ChronoSetupStage.longBreak.telemetryLabel, equals('SET 3/4 // LONG BRK'));

        expect(ChronoSetupStage.cycleCount.isActive, isTrue);
        expect(ChronoSetupStage.cycleCount.telemetryLabel, equals('SET 4/4 // CYCLES'));
      });

      test(
        'enterCustomCalibration transitions setupStage to focus, sets profile to custom, and loads customProfile.focusMinutes',
        () {
          final mockAudio = MockAudioService();
          final controller = ChronoDialController(mockAudio);
          controller.setProfile(PomodoroProfile.monastic); // Currently 50 min monastic
          expect(controller.state.setupStage, equals(ChronoSetupStage.none));

          controller.enterCustomCalibration();

          expect(controller.state.setupStage, equals(ChronoSetupStage.focus));
          expect(controller.state.profile.type, equals(PomodoroProfileType.custom));
          expect(controller.state.targetMinutes, equals(controller.state.customProfile.focusMinutes));
          expect(controller.state.remainingSeconds, equals(controller.state.customProfile.focusMinutes * 60.0));
          expect(mockAudio.playedEffects, contains(SoundEffect.dialClick));
        },
      );

      test('setting minutes during setup updates current stage value in customProfile with clamping', () {
        final controller = ChronoDialController();
        controller.enterCustomCalibration();
        expect(controller.state.setupStage, equals(ChronoSetupStage.focus));

        // Stage 1: Focus (1 - 90 min)
        controller.setTargetMinutes(42);
        expect(controller.state.targetMinutes, equals(42));
        expect(controller.state.customProfile.focusMinutes, equals(42));
        expect(controller.state.profile.focusMinutes, equals(42));

        // Stage 2: Short Break (1 - 30 min)
        controller.advanceCalibrationStage();
        expect(controller.state.setupStage, equals(ChronoSetupStage.shortBreak));
        controller.setTargetMinutes(12);
        expect(controller.state.targetMinutes, equals(12));
        expect(controller.state.customProfile.shortBreakMinutes, equals(12));

        // Clamp test on short break: 50 -> 30
        controller.setTargetMinutes(50);
        expect(controller.state.targetMinutes, equals(30));
        expect(controller.state.customProfile.shortBreakMinutes, equals(30));

        // Stage 3: Long Break (1 - 45 min)
        controller.advanceCalibrationStage();
        expect(controller.state.setupStage, equals(ChronoSetupStage.longBreak));
        controller.setTargetMinutes(22);
        expect(controller.state.targetMinutes, equals(22));
        expect(controller.state.customProfile.longBreakMinutes, equals(22));

        // Stage 4: Cycle Count (2 - 8 cycles)
        controller.advanceCalibrationStage();
        expect(controller.state.setupStage, equals(ChronoSetupStage.cycleCount));
        controller.setTargetMinutes(6);
        expect(controller.state.targetMinutes, equals(6));
        expect(controller.state.customProfile.longBreakInterval, equals(6));

        // Clamp test on cycles: 1 -> 2, 10 -> 8
        controller.setTargetMinutes(1);
        expect(controller.state.targetMinutes, equals(2));
        expect(controller.state.customProfile.longBreakInterval, equals(2));

        controller.setTargetMinutes(10);
        expect(controller.state.targetMinutes, equals(8));
        expect(controller.state.customProfile.longBreakInterval, equals(8));
      });

      test(
        'advanceCalibrationStage cycles through focus -> shortBreak -> longBreak -> cycleCount -> none and exits in standby',
        () {
          final mockAudio = MockAudioService();
          final controller = ChronoDialController(mockAudio);

          // Configure custom values across the flow
          controller.enterCustomCalibration();
          expect(controller.state.setupStage, equals(ChronoSetupStage.focus));
          controller.setTargetMinutes(35);

          controller.advanceCalibrationStage();
          expect(controller.state.setupStage, equals(ChronoSetupStage.shortBreak));
          controller.setTargetMinutes(8);

          controller.advanceCalibrationStage();
          expect(controller.state.setupStage, equals(ChronoSetupStage.longBreak));
          controller.setTargetMinutes(25);

          controller.advanceCalibrationStage();
          expect(controller.state.setupStage, equals(ChronoSetupStage.cycleCount));
          controller.setTargetMinutes(3);

          // Advance past cycleCount -> exits setup to none
          mockAudio.playedEffects.clear();
          controller.advanceCalibrationStage();

          expect(controller.state.setupStage, equals(ChronoSetupStage.none));
          expect(controller.state.isRunning, isFalse);
          expect(controller.state.phase, equals(PomodoroPhase.focus));
          expect(controller.state.cycleCount, equals(1));
          expect(controller.state.targetMinutes, equals(35));
          expect(controller.state.remainingSeconds, equals(35 * 60.0));
          expect(mockAudio.playedEffects, contains(SoundEffect.springButton));

          // Verify customProfile holds all calibrated values
          final custom = controller.state.customProfile;
          expect(custom.focusMinutes, equals(35));
          expect(custom.shortBreakMinutes, equals(8));
          expect(custom.longBreakMinutes, equals(25));
          expect(custom.longBreakInterval, equals(3));
          expect(controller.state.profile, equals(custom));
        },
      );

      test('cancelCalibration restores setupStage to none and resets targetMinutes', () {
        final mockAudio = MockAudioService();
        final controller = ChronoDialController(mockAudio);
        controller.enterCustomCalibration();
        expect(controller.state.setupStage, equals(ChronoSetupStage.focus));

        // Advance to shortBreak
        controller.advanceCalibrationStage();
        expect(controller.state.setupStage, equals(ChronoSetupStage.shortBreak));

        // Cancel calibration
        controller.cancelCalibration();
        expect(controller.state.setupStage, equals(ChronoSetupStage.none));
        expect(controller.state.targetMinutes, equals(controller.state.profile.focusMinutes));
        expect(controller.state.remainingSeconds, equals(controller.state.profile.focusMinutes * 60.0));
      });

      test('enterCustomCalibration and advanceCalibrationStage are ignored when timer is running', () {
        final controller = ChronoDialController();
        controller.start();
        expect(controller.state.isRunning, isTrue);

        controller.enterCustomCalibration();
        expect(controller.state.setupStage, equals(ChronoSetupStage.none));

        controller.advanceCalibrationStage();
        expect(controller.state.setupStage, equals(ChronoSetupStage.none));
      });

      test(
        'start, setPhase, and advancePhase are ignored while setupStage is active',
        () {
          final controller = ChronoDialController();
          controller.enterCustomCalibration();
          expect(controller.state.setupStage.isActive, isTrue);
          expect(controller.state.phase, equals(PomodoroPhase.focus));
          expect(controller.state.isRunning, isFalse);

          // start() is ignored and does not start the timer
          controller.start();
          expect(controller.state.isRunning, isFalse);

          // setPhase() is ignored and does not change phase
          controller.setPhase(PomodoroPhase.shortBreak);
          expect(controller.state.phase, equals(PomodoroPhase.focus));

          // advancePhase() is ignored and does not advance phase or cycle count
          controller.advancePhase();
          expect(controller.state.phase, equals(PomodoroPhase.focus));
          expect(controller.state.cycleCount, equals(1));
        },
      );

      test(
        'boundary clamps enforce limits during calibration for focus (0 -> 1, 95 -> 90) and longBreak (0 -> 1, 60 -> 45)',
        () {
          final controller = ChronoDialController();
          controller.enterCustomCalibration();
          expect(controller.state.setupStage, equals(ChronoSetupStage.focus));

          // Focus lower bound: 0 -> 1
          controller.setTargetMinutes(0);
          expect(controller.state.targetMinutes, equals(1));
          expect(controller.state.customProfile.focusMinutes, equals(1));

          // Focus upper bound: 95 -> 90
          controller.setTargetMinutes(95);
          expect(controller.state.targetMinutes, equals(90));
          expect(controller.state.customProfile.focusMinutes, equals(90));

          // Advance to shortBreak, then longBreak
          controller.advanceCalibrationStage();
          expect(controller.state.setupStage, equals(ChronoSetupStage.shortBreak));
          controller.advanceCalibrationStage();
          expect(controller.state.setupStage, equals(ChronoSetupStage.longBreak));

          // Long break lower bound: 0 -> 1
          controller.setTargetMinutes(0);
          expect(controller.state.targetMinutes, equals(1));
          expect(controller.state.customProfile.longBreakMinutes, equals(1));

          // Long break upper bound: 60 -> 45
          controller.setTargetMinutes(60);
          expect(controller.state.targetMinutes, equals(45));
          expect(controller.state.customProfile.longBreakMinutes, equals(45));
        },
      );
    });
  });
}
