import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/timer_state.dart';
import '../../../core/haptics/haptic_service.dart';

class ChronoDialController extends StateNotifier<TimerState> {
  ChronoDialController()
      : super(const TimerState(
          targetMinutes: 25,
          remainingSeconds: 25 * 60.0,
          isRunning: false,
        ));

  void setTargetMinutes(int minutes) {
    if (state.isRunning) return;
    final clamped = minutes.clamp(1, 90);
    state = state.copyWith(
      targetMinutes: clamped,
      remainingSeconds: clamped * 60.0,
    );
    HapticService.dialTick();
  }

  void start() {
    state = state.copyWith(isRunning: true);
    HapticService.mechanicalPress();
  }

  void pause() {
    state = state.copyWith(isRunning: false);
    HapticService.mechanicalPress();
  }

  void reset() {
    state = state.copyWith(
      isRunning: false,
      remainingSeconds: state.targetMinutes * 60.0,
    );
  }

  void tick(double deltaSeconds) {
    if (!state.isRunning) return;
    final nextRemaining = (state.remainingSeconds - deltaSeconds).clamp(0.0, 90 * 60.0);
    final currentMinute = (nextRemaining / 60.0).ceil();

    if (currentMinute != state.lastTickMinute && nextRemaining > 0) {
      HapticService.dialTick();
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
  return ChronoDialController();
});

final chronoDialControllerProvider = chronoDialProvider;
