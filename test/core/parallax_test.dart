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
      // rawX = 2.0 -> targetX = 0.01
      // smoothX = 0.08 * 0.01 + 0.92 * 0.0 = 0.0008
      expect(controller.state.tiltX, closeTo(0.0008, 1e-5));
      // rawY = 3.0 -> targetY = 0.015
      // smoothY = 0.08 * 0.015 + 0.92 * 0.0 = 0.0012
      expect(controller.state.tiltY, closeTo(0.0012, 1e-5));
    });

    test('ParallaxController clamps target values to maximum +/- 0.05 radians (~2.8 degrees)', () {
      final controller = ParallaxController();

      // Extreme raw inputs exceeding clamp bounds
      controller.updateSensorInput(rawX: 100.0, rawY: -100.0);
      // targetX clamped to 0.05, targetY clamped to -0.05
      // First tick: 0.08 * 0.05 = 0.004, 0.08 * -0.05 = -0.004
      expect(controller.state.tiltX, closeTo(0.004, 1e-4));
      expect(controller.state.tiltY, closeTo(-0.004, 1e-4));

      // Repeated updates converge towards 0.05 and -0.05 without exceeding
      for (int i = 0; i < 100; i++) {
        controller.updateSensorInput(rawX: 100.0, rawY: -100.0);
      }
      expect(controller.state.tiltX, closeTo(0.05, 1e-3));
      expect(controller.state.tiltX, lessThanOrEqualTo(0.05));
      expect(controller.state.tiltY, closeTo(-0.05, 1e-3));
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
      expect(controller.state.tiltX, greaterThan(0.008));
      expect(controller.state.tiltY, greaterThan(0.008));
      expect(controller.state.tiltX, lessThanOrEqualTo(0.05));
      expect(controller.state.tiltY, lessThanOrEqualTo(0.05));

      // Sustains tilt angle rather than decaying
      controller.updateTiltFromAccelerometer(x: 0.3, y: 0.4, z: 9.8);
      expect(controller.state.tiltX, greaterThan(0.008));
    });

    test('ParallaxState provides default centered light vector', () {
      const state = ParallaxState();
      expect(state.tiltX, 0.0);
      expect(state.tiltY, 0.0);
      expect(state.lightX, -0.4);
      expect(state.lightY, -0.6);
      expect(state.lightIntensity, 0.5);
    });

    test('updateTiltFromAccelerometer computes dynamic light vector based on tilt', () {
      final controller = ParallaxController();

      // Tilt device right (+X) and forward (+Y)
      controller.updateTiltFromAccelerometer(x: 3.0, y: 3.0, z: 9.0);

      final state = controller.state;
      expect(state.tiltX, greaterThan(0.0));
      expect(state.tiltY, greaterThan(0.0));
      expect(state.lightX, isNotNull);
      expect(state.lightY, isNotNull);
      expect(state.lightIntensity, greaterThan(0.5));
    });

    test('reset restores default centered light vector and zero tilt', () {
      final controller = ParallaxController();
      controller.updateTiltFromAccelerometer(x: 5.0, y: 5.0, z: 8.0);
      controller.reset();

      expect(controller.state.tiltX, 0.0);
      expect(controller.state.tiltY, 0.0);
      expect(controller.state.lightX, -0.4);
      expect(controller.state.lightY, -0.6);
      expect(controller.state.lightIntensity, 0.5);
    });

    test('ParallaxState copyWith works correctly', () {
      const state1 = ParallaxState();
      final state2 = state1.copyWith(
        tiltX: 0.02,
        lightX: 0.1,
        lightIntensity: 0.8,
      );

      expect(state2.tiltX, 0.02);
      expect(state2.tiltY, 0.0);
      expect(state2.lightX, 0.1);
      expect(state2.lightY, -0.6);
      expect(state2.lightIntensity, 0.8);
    });

    test('ParallaxState implements equality and hashCode correctly', () {
      const state1 = ParallaxState(tiltX: 0.02, tiltY: -0.01, lightX: -0.5, lightY: -0.5, lightIntensity: 0.6);
      const state2 = ParallaxState(tiltX: 0.02, tiltY: -0.01, lightX: -0.5, lightY: -0.5, lightIntensity: 0.6);
      const state3 = ParallaxState(tiltX: 0.01, tiltY: -0.01, lightX: -0.5, lightY: -0.5, lightIntensity: 0.6);

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
      expect(state1, isNot(equals(state3)));
    });

    test('ParallaxController suppresses state updates below deadband threshold', () {
      final controller = ParallaxController();
      final initialState = controller.state;

      // Microscopic sensor noise below deadband (0.0001)
      controller.updateSensorInput(rawX: 0.001, rawY: 0.001);

      // State reference remains unchanged (no new state object created)
      expect(identical(controller.state, initialState), isTrue);
    });

    test('ParallaxController updateFromGyroscope updates tilt from angular velocity and clamps to maxTiltRadians', () {
      final controller = ParallaxController();

      controller.updateFromGyroscope(x: 2.0, y: -3.0);
      expect(controller.state.tiltX, isNonZero);
      expect(controller.state.tiltY, isNonZero);
      expect(controller.state.tiltX.abs(), lessThanOrEqualTo(0.05));
      expect(controller.state.tiltY.abs(), lessThanOrEqualTo(0.05));

      // Sustained angular rate accumulates smoothly without exceeding 0.05 rad
      for (int i = 0; i < 50; i++) {
        controller.updateFromGyroscope(x: -100.0, y: 100.0);
      }
      expect(controller.state.tiltX, greaterThan(0.015));
      expect(controller.state.tiltX, lessThanOrEqualTo(0.05));
      expect(controller.state.tiltY, greaterThan(0.015));
      expect(controller.state.tiltY, lessThanOrEqualTo(0.05));
    });

    test('updateTiltFromAccelerometer supports handheld orientation (y >= 2.5) without ceiling saturation', () {
      final controller = ParallaxController();

      // Handheld resting angle ~41°-45° (y ~ 6.0 m/s^2, z ~ 7.0 m/s^2) should be close to 0 tilt
      for (int i = 0; i < 30; i++) {
        controller.updateTiltFromAccelerometer(x: 0.0, y: 6.0, z: 7.0);
      }
      expect(controller.state.tiltY.abs(), lessThan(0.02));

      // Tilting forward (y = 8.0) tilts positive Y
      for (int i = 0; i < 30; i++) {
        controller.updateTiltFromAccelerometer(x: 0.0, y: 8.0, z: 5.6);
      }
      expect(controller.state.tiltY, greaterThan(0.02));
      expect(controller.state.tiltY, lessThanOrEqualTo(0.05));

      // Tilting backward (y = 4.0) tilts negative Y
      for (int i = 0; i < 30; i++) {
        controller.updateTiltFromAccelerometer(x: 0.0, y: 4.0, z: 7.0);
      }
      expect(controller.state.tiltY, lessThan(0.0));
      expect(controller.state.tiltY, greaterThanOrEqualTo(-0.05));
    });
  });
}


