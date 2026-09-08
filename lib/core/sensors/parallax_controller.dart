import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ParallaxState {
  final double tiltX;
  final double tiltY;

  const ParallaxState({this.tiltX = 0.0, this.tiltY = 0.0});
}

class ParallaxController extends StateNotifier<ParallaxState> {
  ParallaxController() : super(const ParallaxState());

  static const double _alpha = 0.15; // Low-pass filter smoothing coefficient
  static const double maxTiltRadians = 0.05; // ~3 degrees

  void updateSensorInput({required double rawX, required double rawY}) {
    // Clamp to max 3 degrees (approx 0.05 radians)
    final targetX = (rawX * 0.01).clamp(-maxTiltRadians, maxTiltRadians);
    final targetY = (rawY * 0.01).clamp(-maxTiltRadians, maxTiltRadians);

    final smoothX = _alpha * targetX + (1 - _alpha) * state.tiltX;
    final smoothY = _alpha * targetY + (1 - _alpha) * state.tiltY;

    state = ParallaxState(tiltX: smoothX, tiltY: smoothY);
  }

  void updateTiltFromAccelerometer({
    required double x,
    required double y,
    double? z,
  }) {
    // Calculate tilt angles from accelerometer / gravity vector.
    // When held tilted, gravity projects onto X and Y axes sustaining subtle perspective.
    final double norm;
    if (z != null) {
      final mag = math.sqrt(x * x + y * y + z * z);
      norm = mag > 0.001 ? mag : 9.80665;
    } else {
      norm = 9.80665;
    }

    // Convert normalized gravity to tilt angle (radians), clamped to +/- 3 degrees (~0.05 rad)
    final targetX = (x / norm).clamp(-maxTiltRadians, maxTiltRadians);
    final targetY = (y / norm).clamp(-maxTiltRadians, maxTiltRadians);

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
