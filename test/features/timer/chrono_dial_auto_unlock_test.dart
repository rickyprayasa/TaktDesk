import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/focus/focus_lock_controller.dart';
import 'package:takt_desk/core/focus/focus_lock_service.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_phase.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';

class MockFocusLockService extends FocusLockService {
  bool lockEnabled = false;

  @override
  Future<bool> enableFocusLock() async {
    lockEnabled = true;
    return true;
  }

  @override
  Future<bool> disableFocusLock() async {
    lockEnabled = false;
    return true;
  }
}

class MockAudioService extends AudioService {
  final List<String> playedChimes = [];
  MockAudioService() : super(isMock: true);

  @override
  void playAlarmChime(String chimeId) {
    playedChimes.add(chimeId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChronoDialController Auto-Unlock Monastic Focus & Natural Chimes', () {
    late MockFocusLockService mockFocusLockService;
    late MockAudioService mockAudioService;

    setUp(() {
      mockFocusLockService = MockFocusLockService();
      mockAudioService = MockAudioService();
    });

    test('automatically unlocks Monastic Focus and plays selected alarm chime when focus timer finishes', () async {
      final focusLockController = FocusLockController(
        service: mockFocusLockService,
        audioService: mockAudioService,
      );

      final preferencesController = DeskPreferencesController(null, mockAudioService);
      preferencesController.state = preferencesController.state.copyWith(
        alarmChimeId: 'zenGong',
      );

      final chronoDialController = ChronoDialController(
        mockAudioService,
        null,
        focusLockController,
        preferencesController,
      );

      // 1. Engage monastic focus lock
      await focusLockController.engageLock();
      expect(focusLockController.state.isLocked, isTrue);

      // 2. Start Pomodoro focus session with 1 minute
      chronoDialController.setTargetMinutes(1);
      chronoDialController.start();
      expect(chronoDialController.state.phase, equals(PomodoroPhase.focus));

      // Tick down to 0
      chronoDialController.tick(60.0);
      await Future<void>.delayed(Duration.zero);

      // 3. Verify monastic lock is automatically unlatched
      expect(focusLockController.state.isLocked, isFalse);
      expect(focusLockController.state.isHolding, isFalse);

      // 4. Verify user-selected alarm chime (zenGong) was played
      expect(mockAudioService.playedChimes, contains('zenGong'));
    });

    test('plays default braunBell chime if no preferences controller is supplied', () async {
      final focusLockController = FocusLockController(
        service: mockFocusLockService,
        audioService: mockAudioService,
      );

      final chronoDialController = ChronoDialController(
        mockAudioService,
        null,
        focusLockController,
      );

      chronoDialController.start();
      chronoDialController.tick(25 * 60.0);

      expect(mockAudioService.playedChimes, contains('braunBell'));
    });
  });
}
