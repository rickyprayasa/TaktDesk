import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/pomodoro_phase.dart';
import '../domain/pomodoro_profile.dart';
import '../domain/timer_state.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_effect.dart';
import '../../../core/database/app_database.dart';
import '../../../core/focus/focus_lock_controller.dart';
import '../../../core/services/media_notification_service.dart';
import '../../settings/presentation/settings_controller.dart';

class ChronoDialController extends StateNotifier<TimerState> {
  final AudioService? _audioService;
  final AppDatabase? _database;
  final FocusLockController? _focusLockController;
  final DeskPreferencesController? _preferencesController;
  final MediaNotificationService? _mediaNotificationService;
  DateTime? _sessionStartedAt;

  ChronoDialController([
    this._audioService,
    this._database,
    this._focusLockController,
    this._preferencesController,
    this._mediaNotificationService,
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
      setupStage: ChronoSetupStage.none,
      phase: PomodoroPhase.focus,
      cycleCount: 1,
      targetMinutes: profile.focusMinutes,
      remainingSeconds: profile.focusMinutes * 60.0,
      lastTickMinute: profile.focusMinutes,
    );
    HapticService.dialTick();
    _audioService?.playFoley(SoundEffect.dialClick);
    _syncMediaTelemetry(
      phase: PomodoroPhase.focus,
      remainingSeconds: profile.focusMinutes * 60,
      cycleCount: 1,
    );
  }

  void enterCustomCalibration() {
    if (state.isRunning) return;
    _sessionStartedAt = null;
    final mins = state.customProfile.focusMinutes;
    state = state.copyWith(
      setupStage: ChronoSetupStage.focus,
      profile: state.customProfile,
      phase: PomodoroPhase.focus,
      cycleCount: 1,
      targetMinutes: mins,
      remainingSeconds: mins * 60.0,
      lastTickMinute: mins,
    );
    HapticService.selectionClick();
    _audioService?.playFoley(SoundEffect.drawerLatch);
  }

  void advanceCalibrationStage() {
    if (state.isRunning || !state.setupStage.isActive) return;
    _sessionStartedAt = null;

    switch (state.setupStage) {
      case ChronoSetupStage.focus:
        final nextMins = state.customProfile.shortBreakMinutes;
        state = state.copyWith(
          setupStage: ChronoSetupStage.shortBreak,
          targetMinutes: nextMins,
          remainingSeconds: nextMins * 60.0,
          lastTickMinute: nextMins,
        );
        HapticService.dialTick();
        _audioService?.playFoley(SoundEffect.dialClick);
        break;
      case ChronoSetupStage.shortBreak:
        final nextMins = state.customProfile.longBreakMinutes;
        state = state.copyWith(
          setupStage: ChronoSetupStage.longBreak,
          targetMinutes: nextMins,
          remainingSeconds: nextMins * 60.0,
          lastTickMinute: nextMins,
        );
        HapticService.dialTick();
        _audioService?.playFoley(SoundEffect.dialClick);
        break;
      case ChronoSetupStage.longBreak:
        final nextCycles = state.customProfile.longBreakInterval;
        state = state.copyWith(
          setupStage: ChronoSetupStage.cycleCount,
          targetMinutes: nextCycles,
          remainingSeconds: nextCycles * 60.0,
          lastTickMinute: nextCycles,
        );
        HapticService.dialTick();
        _audioService?.playFoley(SoundEffect.dialClick);
        break;
      case ChronoSetupStage.cycleCount:
        final focusMins = state.customProfile.focusMinutes;
        state = state.copyWith(
          setupStage: ChronoSetupStage.none,
          profile: state.customProfile,
          phase: PomodoroPhase.focus,
          cycleCount: 1,
          targetMinutes: focusMins,
          remainingSeconds: focusMins * 60.0,
          lastTickMinute: focusMins,
        );
        HapticService.mechanicalPress();
        _audioService?.playFoley(SoundEffect.springButton);
        break;
      case ChronoSetupStage.none:
        break;
    }
  }

  void cancelCalibration() {
    if (!state.setupStage.isActive) return;
    _sessionStartedAt = null;
    final focusMins = state.profile.focusMinutes;
    state = state.copyWith(
      setupStage: ChronoSetupStage.none,
      targetMinutes: focusMins,
      remainingSeconds: focusMins * 60.0,
      lastTickMinute: focusMins,
    );
    HapticService.mechanicalPress();
    _audioService?.playFoley(SoundEffect.springButton);
  }

  void setTargetMinutes(int minutes) {
    if (state.isRunning) return;
    _sessionStartedAt = null;

    if (state.setupStage.isActive) {
      final PomodoroProfile updated;
      final int activeVal;
      switch (state.setupStage) {
        case ChronoSetupStage.focus:
          activeVal = minutes.clamp(1, 90);
          updated = state.customProfile.copyWith(focusMinutes: activeVal);
          break;
        case ChronoSetupStage.shortBreak:
          activeVal = minutes.clamp(1, 30);
          updated = state.customProfile.copyWith(shortBreakMinutes: activeVal);
          break;
        case ChronoSetupStage.longBreak:
          activeVal = minutes.clamp(1, 45);
          updated = state.customProfile.copyWith(longBreakMinutes: activeVal);
          break;
        case ChronoSetupStage.cycleCount:
          activeVal = minutes.clamp(2, 8);
          updated = state.customProfile.copyWith(longBreakInterval: activeVal);
          break;
        case ChronoSetupStage.none:
          activeVal = minutes.clamp(1, 90);
          updated = state.customProfile;
          break;
      }
      state = state.copyWith(
        customProfile: updated,
        profile: updated,
        targetMinutes: activeVal,
        remainingSeconds: activeVal * 60.0,
        lastTickMinute: activeVal,
      );
      HapticService.dialTick();
      return;
    }

    final clamped = minutes.clamp(1, 90);
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
    int? longBreakInterval,
    bool activate = false,
  }) {
    if (state.isRunning) return;
    final base = (activate || state.profile.type == PomodoroProfileType.custom)
        ? (state.profile.type == PomodoroProfileType.custom ? state.customProfile : state.profile)
        : state.customProfile;
    final updatedCustom = PomodoroProfile.custom(
      focusMinutes: (focusMinutes ?? base.focusMinutes).clamp(1, 90),
      shortBreakMinutes: (shortBreakMinutes ?? base.shortBreakMinutes).clamp(1, 30),
      longBreakMinutes: (longBreakMinutes ?? base.longBreakMinutes).clamp(1, 45),
      longBreakInterval: (longBreakInterval ?? base.longBreakInterval).clamp(2, 8),
    );

    if (activate || state.profile.type == PomodoroProfileType.custom) {
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
    if (state.setupStage.isActive) return;
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
    _syncMediaTelemetry(
      phase: state.phase,
      remainingSeconds: (state.targetMinutes * 60.0).round(),
      cycleCount: state.cycleCount,
    );
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
      _syncMediaTelemetry(
        phase: nextPhase,
        remainingSeconds: nextMins * 60,
        cycleCount: nextCycle,
      );
    } else {
      state = state.copyWith(
        remainingSeconds: nextRemaining,
        lastTickMinute: currentMinute,
      );
      _syncMediaTelemetry(
        phase: state.phase,
        remainingSeconds: nextRemaining.round(),
        cycleCount: state.cycleCount,
      );
    }
  }

  ({PomodoroPhase phase, int cycleCount}) _nextPhaseAndCycle() {
    final maxCycles = state.profile.longBreakInterval;
    switch (state.phase) {
      case PomodoroPhase.focus:
        if (state.cycleCount < maxCycles) {
          return (phase: PomodoroPhase.shortBreak, cycleCount: state.cycleCount);
        } else {
          return (phase: PomodoroPhase.longBreak, cycleCount: state.cycleCount);
        }
      case PomodoroPhase.shortBreak:
        return (phase: PomodoroPhase.focus, cycleCount: (state.cycleCount + 1).clamp(1, maxCycles));
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
    if (state.setupStage.isActive) return;
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
    _syncMediaTelemetry(
      phase: nextPhase,
      remainingSeconds: mins * 60,
      cycleCount: state.cycleCount,
    );
  }

  void advancePhase() {
    if (state.isRunning) return;
    if (state.setupStage.isActive) return;
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
    _syncMediaTelemetry(
      phase: next.phase,
      remainingSeconds: mins * 60,
      cycleCount: next.cycleCount,
    );
  }

  void _syncMediaTelemetry({PomodoroPhase? phase, int? remainingSeconds, int? cycleCount}) {
    _mediaNotificationService?.updateTimerTelemetry(
      phase: (phase ?? state.phase).name,
      remainingSeconds: remainingSeconds ?? state.remainingSeconds.round(),
      cycleCount: cycleCount ?? state.cycleCount,
    );
  }
}

final chronoDialProvider = StateNotifierProvider<ChronoDialController, TimerState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  final database = ref.watch(appDatabaseProvider);
  final focusLockController = ref.watch(focusLockProvider.notifier);
  final preferencesController = ref.watch(deskPreferencesControllerProvider.notifier);
  final mediaService = ref.watch(mediaNotificationServiceProvider);
  return ChronoDialController(
    audioService,
    database,
    focusLockController,
    preferencesController,
    mediaService,
  );
});

final chronoDialControllerProvider = chronoDialProvider;
