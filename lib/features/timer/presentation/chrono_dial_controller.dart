import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/pomodoro_phase.dart';
import '../domain/pomodoro_profile.dart';
import '../domain/timer_state.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_effect.dart';
import '../../../core/database/app_database.dart';
import '../../../core/focus/focus_lock_controller.dart';
import '../../settings/presentation/settings_controller.dart';

class ChronoDialController extends StateNotifier<TimerState> {
  final AudioService? _audioService;
  final AppDatabase? _database;
  final FocusLockController? _focusLockController;
  final DeskPreferencesController? _preferencesController;
  DateTime? _sessionStartedAt;

  ChronoDialController([
    this._audioService,
    this._database,
    this._focusLockController,
    this._preferencesController,
  ])  : super(const TimerState(
          targetMinutes: 25,
          remainingSeconds: 25 * 60.0,
          isRunning: false,
          lastTickMinute: 25,
        ));

  void setProfile(PomodoroProfile profile) {
    if (state.isRunning) return;
    _sessionStartedAt = null;
    state = state.copyWith(
      profile: profile,
      customProfile: profile.type == PomodoroProfileType.custom ? profile : state.customProfile,
      phase: PomodoroPhase.focus,
      cycleCount: 1,
      targetMinutes: profile.focusMinutes,
      remainingSeconds: profile.focusMinutes * 60.0,
      lastTickMinute: profile.focusMinutes,
    );
    HapticService.dialTick();
    _audioService?.playFoley(SoundEffect.dialClick);
  }

  void setTargetMinutes(int minutes) {
    if (state.isRunning) return;
    final clamped = minutes.clamp(1, 90);
    _sessionStartedAt = null;
    state = state.copyWith(
      targetMinutes: clamped,
      remainingSeconds: clamped * 60.0,
      lastTickMinute: clamped,
    );
    HapticService.dialTick();
  }

  void updateCustomDurations({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
  }) {
    if (state.isRunning) return;
    final updatedCustom = PomodoroProfile.custom(
      focusMinutes: (focusMinutes ?? state.customProfile.focusMinutes).clamp(1, 90),
      shortBreakMinutes: (shortBreakMinutes ?? state.customProfile.shortBreakMinutes).clamp(1, 30),
      longBreakMinutes: (longBreakMinutes ?? state.customProfile.longBreakMinutes).clamp(1, 45),
    );

    if (state.profile.type == PomodoroProfileType.custom) {
      final int currentPhaseMinutes;
      switch (state.phase) {
        case PomodoroPhase.focus:
          currentPhaseMinutes = updatedCustom.focusMinutes;
          break;
        case PomodoroPhase.shortBreak:
          currentPhaseMinutes = updatedCustom.shortBreakMinutes;
          break;
        case PomodoroPhase.longBreak:
          currentPhaseMinutes = updatedCustom.longBreakMinutes;
          break;
      }
      state = state.copyWith(
        customProfile: updatedCustom,
        profile: updatedCustom,
        targetMinutes: currentPhaseMinutes,
        remainingSeconds: currentPhaseMinutes * 60.0,
        lastTickMinute: currentPhaseMinutes,
      );
    } else {
      state = state.copyWith(
        customProfile: updatedCustom,
      );
    }
  }

  void start() {
    if (state.remainingSeconds <= 0) {
      state = state.copyWith(
        remainingSeconds: state.targetMinutes * 60.0,
        lastTickMinute: state.targetMinutes,
        isRunning: true,
      );
      _sessionStartedAt = DateTime.now();
    } else {
      state = state.copyWith(isRunning: true);
      _sessionStartedAt ??= DateTime.now();
    }
    HapticService.mechanicalPress();
    _audioService?.playFoley(SoundEffect.springButton);
  }

  void pause() {
    state = state.copyWith(isRunning: false);
    HapticService.mechanicalPress();
    _audioService?.playFoley(SoundEffect.springButton);
  }

  void reset() {
    state = state.copyWith(
      isRunning: false,
      remainingSeconds: state.targetMinutes * 60.0,
      lastTickMinute: state.targetMinutes,
    );
    _sessionStartedAt = null;
  }

  void tick(double deltaSeconds) {
    if (!state.isRunning) return;
    final nextRemaining = (state.remainingSeconds - deltaSeconds).clamp(0.0, 90 * 60.0);
    final currentMinute = (nextRemaining / 60.0).ceil();

    if (currentMinute != state.lastTickMinute && nextRemaining > 0) {
      HapticService.dialTick();
      _audioService?.playFoley(SoundEffect.dialClick);
    }

    if (nextRemaining <= 0) {
      final startedAt =
          _sessionStartedAt ?? DateTime.now().subtract(Duration(minutes: state.targetMinutes));
      final targetMins = state.targetMinutes;
      final elapsed = targetMins * 60;

      if (state.phase == PomodoroPhase.focus && _database != null) {
        _database.recordTimerSession(
          targetMinutes: targetMins,
          elapsedSeconds: elapsed,
          isFinished: true,
          startedAt: startedAt,
        ).catchError((_) => -1);
      }
      _sessionStartedAt = null;

      final chimeId = _preferencesController?.state.alarmChimeId ?? 'braunBell';
      _audioService?.playAlarmChime(chimeId);
      HapticService.mechanicalPress();

      if (state.phase == PomodoroPhase.focus && _focusLockController?.state.isLocked == true) {
        _focusLockController?.completeUnlock();
      }

      final next = _nextPhaseAndCycle();
      final nextPhase = next.phase;
      final nextCycle = next.cycleCount;
      final nextMins = _minutesForPhase(nextPhase, state.profile);

      state = state.copyWith(
        phase: nextPhase,
        cycleCount: nextCycle,
        targetMinutes: nextMins,
        remainingSeconds: nextMins * 60.0,
        lastTickMinute: nextMins,
        isRunning: false,
      );
    } else {
      state = state.copyWith(
        remainingSeconds: nextRemaining,
        lastTickMinute: currentMinute,
      );
    }
  }

  ({PomodoroPhase phase, int cycleCount}) _nextPhaseAndCycle() {
    switch (state.phase) {
      case PomodoroPhase.focus:
        if (state.cycleCount < 4) {
          return (phase: PomodoroPhase.shortBreak, cycleCount: state.cycleCount);
        } else {
          return (phase: PomodoroPhase.longBreak, cycleCount: state.cycleCount);
        }
      case PomodoroPhase.shortBreak:
        return (phase: PomodoroPhase.focus, cycleCount: (state.cycleCount + 1).clamp(1, 4));
      case PomodoroPhase.longBreak:
        return (phase: PomodoroPhase.focus, cycleCount: 1);
    }
  }

  int _minutesForPhase(PomodoroPhase phase, PomodoroProfile profile) {
    switch (phase) {
      case PomodoroPhase.focus:
        return profile.focusMinutes;
      case PomodoroPhase.shortBreak:
        return profile.shortBreakMinutes;
      case PomodoroPhase.longBreak:
        return profile.longBreakMinutes;
    }
  }

  void setPhase(PomodoroPhase nextPhase) {
    if (state.isRunning) return;
    final mins = _minutesForPhase(nextPhase, state.profile);
    _sessionStartedAt = null;
    state = state.copyWith(
      phase: nextPhase,
      targetMinutes: mins,
      remainingSeconds: mins * 60.0,
      lastTickMinute: mins,
    );
    HapticService.dialTick();
    _audioService?.playFoley(SoundEffect.dialClick);
  }

  void advancePhase() {
    if (state.isRunning) return;
    final next = _nextPhaseAndCycle();
    final mins = _minutesForPhase(next.phase, state.profile);
    _sessionStartedAt = null;
    state = state.copyWith(
      phase: next.phase,
      cycleCount: next.cycleCount,
      targetMinutes: mins,
      remainingSeconds: mins * 60.0,
      lastTickMinute: mins,
    );
    HapticService.dialTick();
    _audioService?.playFoley(SoundEffect.dialClick);
  }
}

final chronoDialProvider = StateNotifierProvider<ChronoDialController, TimerState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  final database = ref.watch(appDatabaseProvider);
  final focusLockController = ref.watch(focusLockProvider.notifier);
  final preferencesController = ref.watch(deskPreferencesControllerProvider.notifier);
  return ChronoDialController(
    audioService,
    database,
    focusLockController,
    preferencesController,
  );
});

final chronoDialControllerProvider = chronoDialProvider;
