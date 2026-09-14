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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParallaxState &&
          runtimeType == other.runtimeType &&
          tiltX == other.tiltX &&
          tiltY == other.tiltY &&
          lightX == other.lightX &&
          lightY == other.lightY &&
          lightIntensity == other.lightIntensity;

  @override
  int get hashCode => Object.hash(tiltX, tiltY, lightX, lightY, lightIntensity);
}

class ParallaxController extends StateNotifier<ParallaxState> {
  ParallaxController() : super(const ParallaxState());

  static const double _alpha = 0.08; // Low-pass filter smoothing coefficient (smooth dampening)
  static const double maxTiltRadians = 0.05; // ~2.8 degrees subtle tactile tilt (calm, non-dizzying)
  static const double deadband = 0.0001; // Deadband to suppress idle sensor noise

  void updateSensorInput({required double rawX, required double rawY}) {
    final targetX = (rawX * 0.005).clamp(-maxTiltRadians, maxTiltRadians);
    final targetY = (rawY * 0.005).clamp(-maxTiltRadians, maxTiltRadians);

    _applyTarget(targetX, targetY);
  }

  void updateFromGyroscope({required double x, required double y}) {
    // Damped gyroscope response to eliminate rapid twitching while responding naturally to intentional turns
    final dynamicX = (y * 0.01).clamp(-maxTiltRadians, maxTiltRadians);
    final dynamicY = (-x * 0.01).clamp(-maxTiltRadians, maxTiltRadians);

    final targetX = (state.tiltX + dynamicX * 0.10).clamp(-maxTiltRadians, maxTiltRadians);
    final targetY = (state.tiltY + dynamicY * 0.10).clamp(-maxTiltRadians, maxTiltRadians);

    _applyTarget(targetX, targetY);
  }

  void updateTiltFromAccelerometer({
    required double x,
    required double y,
    double? z,
    bool isLandscape = false,
  }) {
    final double norm;
    if (z != null) {
      final mag = math.sqrt(x * x + y * y + z * z);
      norm = mag > 0.001 ? mag : 9.80665;
    } else {
      norm = 9.80665;
    }

    final double targetX;
    final double targetY;

    if (isLandscape) {
      targetX = (y / norm * 0.35).clamp(-maxTiltRadians, maxTiltRadians);
      targetY = (-x / norm * 0.35).clamp(-maxTiltRadians, maxTiltRadians);
    } else if (z != null) {
      final pitch = math.atan2(y, z.abs());
      if (pitch > 0.50) {
        // Handheld portrait mode (pitch > ~28°): center around ~41°-45° resting angle (~0.72 rad)
        final deltaPitch = pitch - 0.72;
        targetX = (x / norm * 0.35).clamp(-maxTiltRadians, maxTiltRadians);
        targetY = (deltaPitch * 0.40).clamp(-maxTiltRadians, maxTiltRadians);
      } else {
        // Desk / flat mode (pitch <= ~28°): direct gravity projection
        targetX = (x / norm * 0.35).clamp(-maxTiltRadians, maxTiltRadians);
        targetY = (y / norm * 0.35).clamp(-maxTiltRadians, maxTiltRadians);
      }
    } else {
      targetX = (x / norm * 0.35).clamp(-maxTiltRadians, maxTiltRadians);
      targetY = (y / norm * 0.35).clamp(-maxTiltRadians, maxTiltRadians);
    }

    _applyTarget(targetX, targetY);
  }

  void _applyTarget(double targetX, double targetY) {
    final diffX = (targetX - state.tiltX).abs();
    final diffY = (targetY - state.tiltY).abs();

    if (diffX < deadband && diffY < deadband) {
      return;
    }

    final smoothX = _alpha * targetX + (1 - _alpha) * state.tiltX;
    final smoothY = _alpha * targetY + (1 - _alpha) * state.tiltY;

    _updateStateWithLight(smoothX, smoothY);
  }

  void _updateStateWithLight(double smoothX, double smoothY) {
    if (smoothX == state.tiltX && smoothY == state.tiltY) {
      return;
    }

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
