import 'dart:async';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
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
import '../../../core/services/timer_background_service.dart';
import '../../settings/presentation/settings_controller.dart';

class ChronoDialController extends StateNotifier<TimerState> {
  final AudioService? _audioService;
  final AppDatabase? _database;
  final FocusLockController? _focusLockController;
  final DeskPreferencesController? _preferencesController;
  final MediaNotificationService? _mediaNotificationService;
  final TimerBackgroundService? _backgroundService;
  DateTime? _sessionStartedAt;

  /// The slip this focus session counts for (top open slip when it started); resolved from the database.
  Future<int?>? _sessionTaskId;

  /// Id of the native countdown started last (sent with start, echoed by the native status), so a late status or
  /// "phase finished" about a previous phase is never applied to the one running now.
  int? _nativeSessionId;

  /// The countdown is driven here, not by the dial widget, so it keeps running
  /// while the dial is off screen (portrait TASKS/VINYL tabs, home screen
  /// widget). Wall-clock deltas also catch up after the app was suspended.
  Timer? _clock;
  DateTime? _clockLastAt;
  double _clockPending = 0.0;

  ChronoDialController([
    this._audioService,
    this._database,
    this._focusLockController,
    this._preferencesController,
    this._mediaNotificationService,
    this._backgroundService,
  ])  : super(const TimerState(
          targetMinutes: 25,
          remainingSeconds: 25 * 60.0,
          isRunning: false,
          lastTickMinute: 25,
        ));

  void setProfile(PomodoroProfile profile) {
    if (state.isRunning) return;
    _discardSession();
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
    _discardSession();
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
    _audioService?.playFoley(SoundEffect.crownPull);
  }

  void advanceCalibrationStage() {
    if (state.isRunning || !state.setupStage.isActive) return;
    _discardSession();

    switch (state.setupStage) {
      case ChronoSetupStage.focus:
        final nextMins = state.customProfile.shortBreakMinutes;
        state = state.copyWith(
          setupStage: ChronoSetupStage.shortBreak,
          targetMinutes: nextMins,
          remainingSeconds: nextMins * 60.0,
          lastTickMinute: nextMins,
        );
        // Every step of the custom set is a press of the crown.
        HapticService.mechanicalPress();
        _audioService?.playFoley(SoundEffect.springButton);
        break;
      case ChronoSetupStage.shortBreak:
        final nextMins = state.customProfile.longBreakMinutes;
        state = state.copyWith(
          setupStage: ChronoSetupStage.longBreak,
          targetMinutes: nextMins,
          remainingSeconds: nextMins * 60.0,
          lastTickMinute: nextMins,
        );
        // Every step of the custom set is a press of the crown.
        HapticService.mechanicalPress();
        _audioService?.playFoley(SoundEffect.springButton);
        break;
      case ChronoSetupStage.longBreak:
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
    _discardSession();
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
    _discardSession();

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
        case ChronoSetupStage.none:
          activeVal = minutes.clamp(1, 90);
          updated = state.customProfile;
          break;
      }
      final changed = activeVal != state.targetMinutes;
      state = state.copyWith(
        customProfile: updated,
        profile: updated,
        targetMinutes: activeVal,
        remainingSeconds: activeVal * 60.0,
        lastTickMinute: activeVal,
      );
      if (changed) _windTick();
      return;
    }

    final clamped = minutes.clamp(1, 90);
    final changed = clamped != state.targetMinutes;
    state = state.copyWith(
      targetMinutes: clamped,
      remainingSeconds: clamped * 60.0,
      lastTickMinute: clamped,
    );
    if (changed) _windTick();
  }

  /// One ratchet detent per minute the hand is wound by (the pan reports far more often than that).
  void _windTick() {
    HapticService.dialTick();
    _audioService?.playFoley(SoundEffect.crownWind);
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
      // The phase restarts at the new length: the paused session (its start time and slip) ends here, or the next
      // start would continue it on the wrong day with the focus done so far dropped.
      _discardSession();
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

  void cycleLongBreakInterval() {
    if (state.isRunning) return;
    final current = state.profile.longBreakInterval;
    final next = current >= 8 ? 2 : current + 1;
    updateCustomDurations(longBreakInterval: next, activate: true);
    HapticService.selectionClick();
    _audioService?.playFoley(SoundEffect.dialClick);
  }

  /// "Start focus" (launcher shortcut): a focus session, also when the dial stands on a break. Running timers and the
  /// custom set are left alone.
  void startFocus() {
    if (state.isRunning || state.setupStage.isActive) return;
    if (state.phase != PomodoroPhase.focus) setPhase(PomodoroPhase.focus);
    start();
  }

  /// [auto]: started by "auto-start next phase" at the end of a phase, so no button press sound (the chime plays).
  void start({bool auto = false}) {
    if (state.setupStage.isActive) return;
    final newSession = _sessionStartedAt == null || state.remainingSeconds <= 0;
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
    if (newSession) {
      _sessionTaskId = state.phase == PomodoroPhase.focus
          ? _database?.currentFocusTaskId().catchError((Object _) => null)
          : null;
    }
    if (!auto) {
      HapticService.mechanicalPress();
      _audioService?.playFoley(SoundEffect.springButton);
    }
    _focusLockController?.noteTimerActivity();
    _startClock();
    _nativeSessionId = DateTime.now().microsecondsSinceEpoch;
    _backgroundService?.start(
      remainingSeconds: state.remainingSeconds,
      targetMinutes: state.targetMinutes,
      phase: state.phase,
      cycleCount: state.cycleCount,
      profileName: state.profile.label,
      alarmChimeId: _preferencesController?.state.alarmChimeId ?? 'braunBell',
      autoStartNext: _autoStartNext,
      sessionId: _nativeSessionId,
    );
  }

  bool get _autoStartNext => _preferencesController?.state.autoStartNextPhase ?? false;

  void pause() {
    _flushClock();
    _stopClock();
    state = state.copyWith(isRunning: false);
    HapticService.mechanicalPress();
    _audioService?.playFoley(SoundEffect.springButton);
    _backgroundService?.stop();
  }

  void reset() {
    final wasRunning = state.isRunning;
    _flushClock();
    _discardSession();
    _stopClock();
    state = state.copyWith(
      isRunning: false,
      remainingSeconds: state.targetMinutes * 60.0,
      lastTickMinute: state.targetMinutes,
    );
    if (wasRunning) _backgroundService?.stop();
    _syncMediaTelemetry(
      phase: state.phase,
      remainingSeconds: (state.targetMinutes * 60.0).round(),
      cycleCount: state.cycleCount,
    );
  }

  /// True while a countdown runs (read by the lockdown to avoid double logging).
  bool get isCountingDown => state.isRunning;

  /// Drops the current session. A focus session abandoned after at least a
  /// minute of real focus is recorded as unfinished, so the completion rate
  /// means something (before, only finished sessions were ever stored).
  void _discardSession() {
    final startedAt = _sessionStartedAt;
    _sessionStartedAt = null;
    final taskId = _sessionTaskId;
    _sessionTaskId = null;
    if (startedAt == null || state.phase != PomodoroPhase.focus || _database == null) return;
    final focusedSeconds = (state.targetMinutes * 60.0 - state.remainingSeconds).round();
    if (focusedSeconds < 60) return;
    _creditTask(taskId, focusedSeconds);
    _database.recordTimerSession(
      targetMinutes: state.targetMinutes,
      elapsedSeconds: focusedSeconds,
      isFinished: false,
      startedAt: startedAt,
    ).catchError((Object e) {
      debugPrint('ZYKL: failed to record abandoned session: $e');
      return -1;
    });
  }

  /// Adds the focused time to the session's slip, if one was on top when it started.
  void _creditTask(Future<int?>? taskId, int seconds) {
    final db = _database;
    if (taskId == null || db == null) return;
    taskId.then((id) {
      if (id != null) return db.addTaskFocus(id, seconds);
    }).catchError((Object e) {
      debugPrint('ZYKL: failed to add focus time to the slip: $e');
    });
  }

  /// The app is hidden: the native service owns the phase end (alarm, chime, auto-start hand-off), so the Dart clock
  /// only needs to keep the minute-level telemetry roughly current.
  bool _appHidden = false;

  static const Duration _visibleTick = Duration(milliseconds: 250);
  static const Duration _hiddenTick = Duration(seconds: 30);

  void _startClock() {
    _clock?.cancel();
    _clockLastAt = clock.now();
    _clockPending = 0.0;
    _clock = Timer.periodic(_appHidden ? _hiddenTick : _visibleTick, (_) => _onClock());
  }

  /// Desk lifecycle: hidden → tick every 30 s instead of 4×/s (120× fewer wake-ups for a 25-min session in the
  /// background); visible again → back to 250 ms. Elapsed time is kept across the switch (wall clock), and the resume
  /// resync with the native deadline corrects whatever the slow clock missed.
  void setAppHidden(bool hidden) {
    if (hidden == _appHidden) return;
    _appHidden = hidden;
    if (!state.isRunning || _clock == null) return;
    _clock?.cancel();
    _clock = Timer.periodic(hidden ? _hiddenTick : _visibleTick, (_) => _onClock());
  }

  void _stopClock() {
    _clock?.cancel();
    _clock = null;
    _clockLastAt = null;
    _clockPending = 0.0;
  }

  /// Accumulates wall-clock time and commits it once per second (or at zero),
  /// so listeners still see one state update per second.
  void _onClock() {
    if (!state.isRunning) {
      _stopClock();
      return;
    }
    final now = clock.now();
    final last = _clockLastAt ?? now;
    _clockLastAt = now;
    _clockPending += _elapsedSeconds(last, now);
    if (_clockPending >= 1.0 || state.remainingSeconds - _clockPending <= 0) {
      final delta = _clockPending;
      _clockPending = 0.0;
      tick(delta);
    }
  }

  /// Wall-clock seconds between two readings. Wall-clock (not a monotonic
  /// Stopwatch) is deliberate: Android's monotonic clock stops in deep sleep,
  /// so only wall time catches up after the app was suspended. A clock set
  /// backwards (manual change, NTP correction) must not add time back, so
  /// negative deltas count as zero.
  static double _elapsedSeconds(DateTime from, DateTime to) {
    final us = to.difference(from).inMicroseconds;
    return us <= 0 ? 0.0 : us / 1000000.0;
  }

  /// Commits the partial second before pausing, so no time is lost.
  void _flushClock() {
    if (_clockLastAt == null || !state.isRunning) return;
    final now = clock.now();
    final delta = _clockPending + _elapsedSeconds(_clockLastAt!, now);
    _clockPending = 0.0;
    _clockLastAt = now;
    if (delta > 0) tick(delta);
  }

  @override
  void dispose() {
    _stopClock();
    super.dispose();
  }

  /// Records focus sessions that finished natively while the app was closed.
  Future<void> importPendingNativeSessions() async {
    final service = _backgroundService;
    final db = _database;
    if (service == null || db == null) return;
    for (final s in await service.takePendingSessions()) {
      await db.recordTimerSession(
        targetMinutes: s.targetMinutes,
        elapsedSeconds: s.targetMinutes * 60,
        isFinished: true,
        startedAt: s.startedAt,
      ).catchError((Object e) {
        debugPrint('ZYKL: failed to import native session: $e');
        return -1;
      });
    }
  }

  /// Re-aligns the Dart countdown with the native session after the app comes
  /// back to the foreground. The native deadline uses the boot-time clock, so
  /// this corrects wall-clock jumps (either direction) and missed suspension.
  /// If native already finished (and rang), the phase advances silently.
  Future<void> resyncWithNative() async {
    final service = _backgroundService;
    if (service == null || !state.isRunning) return;
    final native = await service.status();
    if (native == null || !state.isRunning) return;
    // A status about another countdown: the previous phase (its START for the next one is still on its way) or a
    // session started from a widget. Acting on it would end the phase that just began.
    if (native.sessionId != null && _nativeSessionId != null && native.sessionId != _nativeSessionId) return;
    _flushClock();
    if (native.remainingSeconds <= 0) {
      tick(state.remainingSeconds, ringAlarm: false);
      return;
    }
    final drift = state.remainingSeconds - native.remainingSeconds;
    if (drift.abs() < 1.0) return;
    if (drift > 0) {
      tick(drift);
    } else {
      // Dart counted too much (clock jumped forward): give the time back.
      state = state.copyWith(remainingSeconds: native.remainingSeconds);
    }
  }

  void tick(double deltaSeconds, {bool ringAlarm = true}) {
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
        ).catchError((Object e) {
          debugPrint('ZYKL: failed to record focus session: $e');
          return -1;
        });
        _creditTask(_sessionTaskId, elapsed);
      }
      _sessionStartedAt = null;
      _sessionTaskId = null;

      final chimeId = _preferencesController?.state.alarmChimeId ?? 'braunBell';
      if (ringAlarm) {
        _audioService?.playAlarmChime(chimeId);
        HapticService.mechanicalPress();
      }

      _focusLockController?.noteTimerActivity();
      if (state.phase == PomodoroPhase.focus && _focusLockController?.state.isLocked == true) {
        final autoUnlock = _preferencesController?.state.autoUnlockMonastic ?? false;
        if (autoUnlock) {
          _focusLockController?.completeUnlock();
        }
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
      _stopClock();
      if (!ringAlarm && !_autoStartNext) {
        // Native ended this phase (and is ringing its chime): it stops itself once the chime is done. Stopping it
        // here released the chime player mid-ring.
      } else if (_autoStartNext) {
        // Straight into the next phase. start() restarts the native countdown in place instead of stop + start, so
        // the service never leaves the foreground (a backgrounded app may not bring it back).
        start(auto: true);
      } else {
        _backgroundService?.stop();
      }
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
    _discardSession();
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
    _discardSession();
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
    final newPhase = (phase ?? state.phase).name;
    final newSeconds = remainingSeconds ?? state.remainingSeconds.round();
    final newCycle = cycleCount ?? state.cycleCount;

    // The vinyl notification shows minutes left (MediaNotificationService.kt), so only a new minute, phase or
    // cycle is worth a re-post; this used to re-post that notification every second while a timer ran.
    final lastSeconds = _mediaNotificationService?.lastRemainingSeconds;
    if (_mediaNotificationService?.lastPhase == newPhase &&
        lastSeconds != null &&
        (lastSeconds / 60).ceil() == (newSeconds / 60).ceil() &&
        _mediaNotificationService?.lastCycleCount == newCycle) {
      return;
    }

    _mediaNotificationService?.updateTimerTelemetry(
      phase: newPhase,
      remainingSeconds: newSeconds,
      cycleCount: newCycle,
    );
  }
}

final chronoDialProvider = StateNotifierProvider<ChronoDialController, TimerState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  final database = ref.watch(appDatabaseProvider);
  final focusLockController = ref.watch(focusLockProvider.notifier);
  final preferencesController = ref.watch(deskPreferencesControllerProvider.notifier);
  final mediaService = ref.watch(mediaNotificationServiceProvider);
  final backgroundService = ref.watch(timerBackgroundServiceProvider);
  final controller = ChronoDialController(
    audioService,
    database,
    focusLockController,
    preferencesController,
    mediaService,
    backgroundService,
  );
  focusLockController.isTimerRunning = () => controller.mounted && controller.isCountingDown;
  return controller;
});

final chronoDialControllerProvider = chronoDialProvider;
