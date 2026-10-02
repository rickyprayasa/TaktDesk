import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';

void main() {
  testWidgets('wall clock set backwards does not add time back', (tester) async {
    var now = DateTime(2026, 10, 1, 9);
    await withClock(Clock(() => now), () async {
      final controller = ChronoDialController();
      controller.start();
      final startRemaining = controller.state.remainingSeconds;

      now = now.add(const Duration(seconds: 10));
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.state.remainingSeconds, closeTo(startRemaining - 10, 0.01));

      // User or NTP moves the clock back one hour.
      now = now.subtract(const Duration(hours: 1));
      await tester.pump(const Duration(milliseconds: 300));
      now = now.add(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 300));

      expect(controller.state.remainingSeconds, closeTo(startRemaining - 12, 0.01));
      expect(controller.state.isRunning, isTrue);

      controller.pause();
      controller.dispose();
    });
  });
}
