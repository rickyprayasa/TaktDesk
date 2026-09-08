import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/vumeter/presentation/vu_meter_controller.dart';

void main() {
  group('VuMeterController', () {
    test('initial state has zero levels and slow ballistics', () {
      final controller = VuMeterController();
      expect(controller.state.leftLevel, 0.0);
      expect(controller.state.rightLevel, 0.0);
      expect(controller.state.isFastBallistics, isFalse);
      expect(controller.state.peakLeft, isFalse);
      expect(controller.state.peakRight, isFalse);
    });

    test('toggleBallistics switches between slow and fast mode', () {
      final controller = VuMeterController();
      controller.toggleBallistics();
      expect(controller.state.isFastBallistics, isTrue);
      controller.toggleBallistics();
      expect(controller.state.isFastBallistics, isFalse);
    });

    test('pulseTick impulses the needles', () {
      final controller = VuMeterController();
      controller.pulseTick(0.6);
      expect(controller.state.leftLevel, greaterThan(0.0));
      expect(controller.state.rightLevel, greaterThan(0.0));
    });

    test('updateLevels updates target levels and flags peaks near 1.0', () {
      final controller = VuMeterController();
      controller.updateLevels(left: 0.95, right: 0.4);
      expect(controller.state.leftLevel, closeTo(0.95, 0.01));
      expect(controller.state.rightLevel, closeTo(0.4, 0.01));
      expect(controller.state.peakLeft, isTrue);
      expect(controller.state.peakRight, isFalse);
    });
  });
}
