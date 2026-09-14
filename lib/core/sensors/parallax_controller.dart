import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ParallaxState {
  final double tiltX;
  final double tiltY;
  final double lightX;
  final double lightY;
  final double lightIntensity;

  const ParallaxState({
    this.tiltX = 0.0,
    this.tiltY = 0.0,
    this.lightX = -0.4,
    this.lightY = -0.6,
    this.lightIntensity = 0.5,
  });

  ParallaxState copyWith({
    double? tiltX,
    double? tiltY,
    double? lightX,
    double? lightY,
    double? lightIntensity,
  }) {
    return ParallaxState(
      tiltX: tiltX ?? this.tiltX,
      tiltY: tiltY ?? this.tiltY,
      lightX: lightX ?? this.lightX,
      lightY: lightY ?? this.lightY,
      lightIntensity: lightIntensity ?? this.lightIntensity,
    );
  }
}

class ParallaxController extends StateNotifier<ParallaxState> {
  ParallaxController() : super(const ParallaxState());

  static const double _alpha = 0.15; // Low-pass filter smoothing coefficient
  static const double maxTiltRadians = 0.05; // ~3 degrees

  void updateSensorInput({required double rawX, required double rawY}) {
    final targetX = (rawX * 0.01).clamp(-maxTiltRadians, maxTiltRadians);
    final targetY = (rawY * 0.01).clamp(-maxTiltRadians, maxTiltRadians);

    final smoothX = _alpha * targetX + (1 - _alpha) * state.tiltX;
    final smoothY = _alpha * targetY + (1 - _alpha) * state.tiltY;

    _updateStateWithLight(smoothX, smoothY);
  }

  void updateTiltFromAccelerometer({
    required double x,
    required double y,
    double? z,
  }) {
    final double norm;
    if (z != null) {
      final mag = math.sqrt(x * x + y * y + z * z);
      norm = mag > 0.001 ? mag : 9.80665;
    } else {
      norm = 9.80665;
    }

    final targetX = (x / norm).clamp(-maxTiltRadians, maxTiltRadians);
    final targetY = (y / norm).clamp(-maxTiltRadians, maxTiltRadians);

    final smoothX = _alpha * targetX + (1 - _alpha) * state.tiltX;
    final smoothY = _alpha * targetY + (1 - _alpha) * state.tiltY;

    _updateStateWithLight(smoothX, smoothY);
  }

  void _updateStateWithLight(double smoothX, double smoothY) {
    // Virtual overhead light source at (-0.4, -0.6) shifted dynamically by device tilt
    final lx = (-0.4 - (smoothX / maxTiltRadians) * 0.6).clamp(-1.0, 1.0);
    final ly = (-0.6 - (smoothY / maxTiltRadians) * 0.4).clamp(-1.0, 1.0);
    final tiltMag = math.sqrt(smoothX * smoothX + smoothY * smoothY) / maxTiltRadians;
    final intensity = (0.5 + tiltMag * 0.4).clamp(0.2, 0.95);

    state = ParallaxState(
      tiltX: smoothX,
      tiltY: smoothY,
      lightX: lx,
      lightY: ly,
      lightIntensity: intensity,
    );
  }

  void reset() {
    state = const ParallaxState();
  }
}

final parallaxProvider = StateNotifierProvider<ParallaxController, ParallaxState>((ref) {
  return ParallaxController();
});
