import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/timer_background_service.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/pomodoro_phase.dart';
import '../domain/timer_state.dart';
import 'chrono_dial_controller.dart';

/// What the paused notification shows; null when the timer is not paused part-way.
typedef PausedTimerCard = ({
  double remainingSeconds,
  int targetMinutes,
  PomodoroPhase phase,
  int cycleCount,
  String profileName,
});

/// A session counts as paused when it is stopped with time already used and time left. A fresh phase (full time),
/// a running timer or the dial setup are not.
PausedTimerCard? pausedCardOf(TimerState s) {
  if (s.isRunning || s.setupStage.isActive) return null;
  final full = s.targetMinutes * 60.0;
  if (s.remainingSeconds < 1 || s.remainingSeconds >= full) return null;
  return (
    remainingSeconds: s.remainingSeconds,
    targetMinutes: s.targetMinutes,
    phase: s.phase,
    cycleCount: s.cycleCount,
    profileName: s.profile.label,
  );
}

/// Keeps the paused notification in step with the timer: posted when a session is paused, cleared on start, reset,
/// phase change and app start (a card left from a session the app no longer knows). Pausing only stops the native
/// countdown, so without this nothing would stay on the lock screen.
final pausedTimerNotificationSyncProvider = Provider.autoDispose<void>((ref) {
  final service = ref.watch(timerBackgroundServiceProvider);
  ref.listen<PausedTimerCard?>(
    chronoDialControllerProvider.select(pausedCardOf),
    (_, card) {
      if (card == null) {
        service.clearPaused();
        return;
      }
      service.showPaused(
        remainingSeconds: card.remainingSeconds,
        targetMinutes: card.targetMinutes,
        phase: card.phase,
        cycleCount: card.cycleCount,
        profileName: card.profileName,
        alarmChimeId: ref.read(deskPreferencesControllerProvider).alarmChimeId,
      );
    },
    fireImmediately: true,
  );
});
