import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/audio/sound_effect.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/core/focus/focus_lock_service.dart';
import 'package:takt_desk/core/focus/focus_lock_state.dart';
import 'package:takt_desk/core/haptics/haptic_service.dart';

final focusLockProvider = StateNotifierProvider<FocusLockController, FocusLockState>((ref) {
  final service = ref.watch(focusLockServiceProvider);
  final audio = ref.watch(audioServiceProvider);
  final database = ref.watch(appDatabaseProvider);
  return FocusLockController(
    service: service,
    audioService: audio,
    database: database,
  );
});

class FocusLockController extends StateNotifier<FocusLockState> {
  final FocusLockService _service;
  final AudioService? _audioService;
  final AppDatabase? _database;
  bool _isProcessing = false;

  /// Set by the chronometer provider; true while a Pomodoro countdown runs.
  bool Function() isTimerRunning = () => false;

  /// The timer ran at some point during the current lock. Then the timer
  /// already records the session and the lock must not record it again
  /// (it used to, doubling focus minutes and sessions).
  bool _timerUsedDuringLock = false;

  /// Called by the chronometer when a countdown starts or finishes.
  void noteTimerActivity() {
    if (state.isLocked) _timerUsedDuringLock = true;
  }

  FocusLockController({
    required FocusLockService service,
    AudioService? audioService,
    AppDatabase? database,
  })  : _service = service,
        _audioService = audioService,
        _database = database,
        super(const FocusLockState());

  Future<void> engageLock() async {
    if (state.isLocked || _isProcessing) return;
    _isProcessing = true;
    try {
      _audioService?.play(SoundEffect.switchClick);
      HapticService.heavyClick();
      await _service.enableFocusLock();
      _timerUsedDuringLock = isTimerRunning();
      state = state.copyWith(
        isLocked: true,
        unlockProgress: 0.0,
        isHolding: false,
        sessionStartTime: DateTime.now(),
      );
    } finally {
      _isProcessing = false;
    }
  }

  void updateHoldProgress(double progress) {
    if (!state.isLocked || _isProcessing) return;
    state = state.copyWith(
      isHolding: true,
      unlockProgress: progress.clamp(0.0, 1.0),
    );
  }

  void cancelHold() {
    if (!state.isLocked || _isProcessing) return;
    if (!state.isHolding && state.unlockProgress == 0.0) return;
    if (state.isHolding) {
      _audioService?.play(SoundEffect.springButton);
    }
    state = state.copyWith(
      isHolding: false,
      unlockProgress: 0.0,
    );
  }

  Future<void> completeUnlock() async {
    if (!state.isLocked || _isProcessing) return;
    _isProcessing = true;
    try {
      _audioService?.play(SoundEffect.drawerLatch);
      HapticService.heavyClick();
      await _service.disableFocusLock();

      // Lockdown on its own is still focus time: record it, flagged so it is
      // not counted as a Pomodoro cycle. Skipped when the timer ran during the
      // lock (the timer records that session) or for accidental < 1 min locks.
      final start = state.sessionStartTime;
      if (start != null && _database != null && !_timerUsedDuringLock && !isTimerRunning()) {
        final elapsedSeconds = DateTime.now().difference(start).inSeconds;
        if (elapsedSeconds >= 60) {
          try {
            await _database.recordTimerSession(
              startedAt: start,
              durationSeconds: elapsedSeconds,
              completed: true,
              isLockdownOnly: true,
            );
          } catch (_) {
            // Non-fatal database persistence error
          }
        }
      }
      _timerUsedDuringLock = false;
    } finally {
      state = state.copyWith(
        isLocked: false,
        isHolding: false,
        unlockProgress: 0.0,
        clearStartTime: true,
      );
      _isProcessing = false;
    }
  }
}
