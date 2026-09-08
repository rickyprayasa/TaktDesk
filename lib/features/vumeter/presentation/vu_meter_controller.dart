import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/vu_meter_state.dart';

class VuMeterController extends StateNotifier<VuMeterState> {
  VuMeterController() : super(const VuMeterState());

  void toggleBallistics() {
    state = state.copyWith(isFastBallistics: !state.isFastBallistics);
  }

  void pulseTick([double strength = 0.5]) {
    final nextLeft = (state.leftLevel + strength * 0.9).clamp(0.0, 1.0);
    final nextRight = (state.rightLevel + strength * 1.05).clamp(0.0, 1.0);
    state = state.copyWith(
      leftLevel: nextLeft,
      rightLevel: nextRight,
      peakLeft: nextLeft > 0.88,
      peakRight: nextRight > 0.88,
    );
  }

  void updateLevels({required double left, required double right}) {
    final clampedL = left.clamp(0.0, 1.0);
    final clampedR = right.clamp(0.0, 1.0);
    state = state.copyWith(
      leftLevel: clampedL,
      rightLevel: clampedR,
      peakLeft: clampedL > 0.88,
      peakRight: clampedR > 0.88,
    );
  }

  void tickDecay(double dt) {
    final decayRate = state.isFastBallistics ? 4.5 : 2.0;
    final factor = (1.0 - decayRate * dt).clamp(0.0, 1.0);
    final nextLeft = state.leftLevel * factor;
    final nextRight = state.rightLevel * factor;

    state = state.copyWith(
      leftLevel: nextLeft < 0.001 ? 0.0 : nextLeft,
      rightLevel: nextRight < 0.001 ? 0.0 : nextRight,
      peakLeft: nextLeft > 0.88,
      peakRight: nextRight > 0.88,
    );
  }
}

final analogVuMeterProvider =
    StateNotifierProvider<VuMeterController, VuMeterState>((ref) {
  return VuMeterController();
});
