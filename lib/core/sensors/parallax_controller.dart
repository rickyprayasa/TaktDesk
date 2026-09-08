import 'package:flutter_riverpod/flutter_riverpod.dart';

class ParallaxState {
  final double tiltX;
  final double tiltY;

  const ParallaxState({this.tiltX = 0.0, this.tiltY = 0.0});
}

class ParallaxController extends StateNotifier<ParallaxState> {
  ParallaxController() : super(const ParallaxState());

  static const double _alpha = 0.15; // Low-pass filter smoothing coefficient

  void updateSensorInput({required double rawX, required double rawY}) {
    // Clamp to max 3 degrees (approx 0.05 radians)
    final targetX = (rawX * 0.01).clamp(-0.05, 0.05);
    final targetY = (rawY * 0.01).clamp(-0.05, 0.05);

    final smoothX = _alpha * targetX + (1 - _alpha) * state.tiltX;
    final smoothY = _alpha * targetY + (1 - _alpha) * state.tiltY;

    state = ParallaxState(tiltX: smoothX, tiltY: smoothY);
  }

  void reset() {
    state = const ParallaxState();
  }
}

final parallaxProvider = StateNotifierProvider<ParallaxController, ParallaxState>((ref) {
  return ParallaxController();
});
