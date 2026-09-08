import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/timer_state.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_effect.dart';

class ChronoDialController extends StateNotifier<TimerState> {
  final AudioService? _audioService;

  ChronoDialController([this._audioService])
      : super(const TimerState(
          targetMinutes: 25,
          remainingSeconds: 25 * 60.0,
          isRunning: false,
          lastTickMinute: 25,
        ));

  void setTargetMinutes(int minutes) {
    if (state.isRunning) return;
    final clamped = minutes.clamp(1, 90);
    state = state.copyWith(
      targetMinutes: clamped,
      remainingSeconds: clamped * 60.0,
      lastTickMinute: clamped,
    );
    HapticService.dialTick();
  }

  void start() {
    if (state.remainingSeconds <= 0) {
      state = state.copyWith(
        remainingSeconds: state.targetMinutes * 60.0,
        lastTickMinute: state.targetMinutes,
        isRunning: true,
      );
    } else {
      state = state.copyWith(isRunning: true);
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
      state = state.copyWith(remainingSeconds: 0, isRunning: false, lastTickMinute: 0);
      HapticService.mechanicalPress();
    } else {
      state = state.copyWith(
        remainingSeconds: nextRemaining,
        lastTickMinute: currentMinute,
      );
    }
  }
}

final chronoDialProvider = StateNotifierProvider<ChronoDialController, TimerState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return ChronoDialController(audioService);
});

final chronoDialControllerProvider = chronoDialProvider;
