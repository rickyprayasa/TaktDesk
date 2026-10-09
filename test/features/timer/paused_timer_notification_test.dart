import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/services/timer_background_service.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_phase.dart';
import 'package:takt_desk/features/timer/domain/timer_state.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';
import 'package:takt_desk/features/timer/presentation/paused_timer_notification.dart';

class _RecordingBackground extends TimerBackgroundService {
  final List<String> calls = [];
  double? lastRemaining;
  String? lastChime;

  @override
  Future<bool> start({
    required double remainingSeconds,
    required int targetMinutes,
    required PomodoroPhase phase,
    required int cycleCount,
    required String profileName,
    String alarmChimeId = 'braunBell',
  }) async {
    calls.add('start');
    return true;
  }

  @override
  Future<bool> stop() async {
    calls.add('stop');
    return true;
  }

  @override
  Future<void> showPaused({
    required double remainingSeconds,
    required int targetMinutes,
    required PomodoroPhase phase,
    required int cycleCount,
    required String profileName,
    String alarmChimeId = 'braunBell',
  }) async {
    calls.add('showPaused');
    lastRemaining = remainingSeconds;
    lastChime = alarmChimeId;
  }

  @override
  Future<void> clearPaused() async => calls.add('clearPaused');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pausedCardOf', () {
    const fresh = TimerState(targetMinutes: 25, remainingSeconds: 1500, isRunning: false);

    test('a fresh phase, a running timer or the dial setup are not paused', () {
      expect(pausedCardOf(fresh), isNull);
      expect(pausedCardOf(fresh.copyWith(remainingSeconds: 900, isRunning: true)), isNull);
      expect(pausedCardOf(fresh.copyWith(remainingSeconds: 900, setupStage: ChronoSetupStage.focus)), isNull);
      expect(pausedCardOf(fresh.copyWith(remainingSeconds: 0.4)), isNull);
    });

    test('stopped part-way is paused, with what the card shows', () {
      final card = pausedCardOf(fresh.copyWith(remainingSeconds: 754, cycleCount: 3));
      expect(card, isNotNull);
      expect(card!.remainingSeconds, 754);
      expect(card.targetMinutes, 25);
      expect(card.phase, PomodoroPhase.focus);
      expect(card.cycleCount, 3);
      expect(card.profileName, fresh.profile.label);
    });
  });

  group('pausedTimerNotificationSyncProvider', () {
    late _RecordingBackground background;
    late ChronoDialController controller;
    late ProviderContainer container;

    setUp(() {
      background = _RecordingBackground();
      controller = ChronoDialController(null, null, null, null, null, background);
      container = ProviderContainer(overrides: [
        timerBackgroundServiceProvider.overrideWithValue(background),
        chronoDialControllerProvider.overrideWith((ref) => controller),
        deskPreferencesControllerProvider.overrideWith(
          (ref) => DeskPreferencesController()..setAlarmChime('tibetanBowl'),
        ),
      ]);
      container.listen(pausedTimerNotificationSyncProvider, (_, __) {});
    });

    tearDown(() => container.dispose());

    test('clears a stale card on start, posts on pause, clears on resume and reset', () {
      expect(background.calls, ['clearPaused']);

      controller.start();
      controller.tick(60);
      controller.pause();
      expect(background.calls, ['clearPaused', 'start', 'showPaused', 'stop']);
      expect(background.lastRemaining, closeTo(1440, 0.5));
      expect(background.lastChime, 'tibetanBowl');

      background.calls.clear();
      controller.start();
      expect(background.calls, ['clearPaused', 'start']);

      controller.pause();
      background.calls.clear();
      controller.reset();
      expect(background.calls, ['clearPaused']);
    });
  });
}
