import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/sensors/parallax_controller.dart';

void main() {
  group('ParallaxController', () {
    test('ParallaxController applies low pass filter correctly', () {
      final controller = ParallaxController();
      expect(controller.state.tiltX, 0.0);
      expect(controller.state.tiltY, 0.0);

      controller.updateSensorInput(rawX: 2.0, rawY: 3.0);
      expect(controller.state.tiltX, isNonZero);
      expect(controller.state.tiltY, isNonZero);

      // Verify low-pass filter math:
      // rawX = 2.0 -> targetX = 0.02
      // smoothX = 0.15 * 0.02 + 0.85 * 0.0 = 0.003
      expect(controller.state.tiltX, closeTo(0.003, 1e-5));
      // rawY = 3.0 -> targetY = 0.03
      // smoothY = 0.15 * 0.03 + 0.85 * 0.0 = 0.0045
      expect(controller.state.tiltY, closeTo(0.0045, 1e-5));
    });

    test('ParallaxController clamps target values to maximum +/- 0.05 radians (~3 degrees)', () {
      final controller = ParallaxController();

      // Extreme raw inputs exceeding clamp bounds
      controller.updateSensorInput(rawX: 100.0, rawY: -100.0);
      // targetX clamped to 0.05, targetY clamped to -0.05
      // First tick: 0.15 * 0.05 = 0.0075, 0.15 * -0.05 = -0.0075
      expect(controller.state.tiltX, closeTo(0.0075, 1e-5));
      expect(controller.state.tiltY, closeTo(-0.0075, 1e-5));

      // Repeated updates converge towards 0.05 and -0.05 without exceeding
      for (int i = 0; i < 100; i++) {
        controller.updateSensorInput(rawX: 100.0, rawY: -100.0);
      }
      expect(controller.state.tiltX, closeTo(0.05, 1e-4));
      expect(controller.state.tiltX, lessThanOrEqualTo(0.05));
      expect(controller.state.tiltY, closeTo(-0.05, 1e-4));
      expect(controller.state.tiltY, greaterThanOrEqualTo(-0.05));
    });

    test('ParallaxController smooths successive input over time', () {
      final controller = ParallaxController();

      controller.updateSensorInput(rawX: 1.0, rawY: 1.0);
      final step1X = controller.state.tiltX;

      controller.updateSensorInput(rawX: 1.0, rawY: 1.0);
      final step2X = controller.state.tiltX;

      // Second step should move closer to target (0.01) than first step
      expect(step2X, greaterThan(step1X));
    });

    test('parallaxProvider creates ParallaxController with default zero tilt', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(parallaxProvider);
      expect(state.tiltX, 0.0);
      expect(state.tiltY, 0.0);

      container.read(parallaxProvider.notifier).updateSensorInput(rawX: 4.0, rawY: 4.0);
      final updatedState = container.read(parallaxProvider);
      expect(updatedState.tiltX, isNonZero);
      expect(updatedState.tiltY, isNonZero);
    });

    test('updateTiltFromAccelerometer sustains tilt angle and clamps to +/- 0.05 rad', () {
      final controller = ParallaxController();

      for (int i = 0; i < 50; i++) {
        controller.updateTiltFromAccelerometer(x: 0.3, y: 0.4, z: 9.8);
      }
      expect(controller.state.tiltX, greaterThan(0.02));
      expect(controller.state.tiltY, greaterThan(0.02));
      expect(controller.state.tiltX, lessThanOrEqualTo(0.05));
      expect(controller.state.tiltY, lessThanOrEqualTo(0.05));

      // Sustains tilt angle rather than decaying
      controller.updateTiltFromAccelerometer(x: 0.3, y: 0.4, z: 9.8);
      expect(controller.state.tiltX, greaterThan(0.02));
    });
  });
}
