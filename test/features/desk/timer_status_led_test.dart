import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/takt_colors.dart';
import 'package:takt_desk/features/desk/presentation/widgets/timer_status_led.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_phase.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';

class _Dial extends ChronoDialController {
  void set({required bool running, PomodoroPhase phase = PomodoroPhase.focus}) =>
      state = state.copyWith(isRunning: running, phase: phase);
}

void main() {
  testWidgets('the LED is dark on standby, amber while focusing, green on a break', (tester) async {
    final dial = _Dial();
    await tester.pumpWidget(ProviderScope(
      overrides: [chronoDialControllerProvider.overrideWith((ref) => dial)],
      child: const MaterialApp(home: Scaffold(body: Center(child: TimerStatusLed()))),
    ));

    Color ledColor() {
      final box = tester.widget<AnimatedContainer>(find.byKey(const ValueKey('desk_status_led')));
      return (box.decoration! as BoxDecoration).color!;
    }

    bool glows() {
      final box = tester.widget<AnimatedContainer>(find.byKey(const ValueKey('desk_status_led')));
      return (box.decoration! as BoxDecoration).boxShadow != null;
    }

    expect(ledColor(), isNot(TaktColors.filamentAmber));
    expect(ledColor(), isNot(TaktColors.patinaOlive));
    expect(glows(), isFalse);
    expect(find.bySemanticsLabel('Timer on standby'), findsOneWidget);

    dial.set(running: true);
    await tester.pumpAndSettle();
    expect(ledColor(), TaktColors.filamentAmber);
    expect(glows(), isTrue);

    dial.set(running: true, phase: PomodoroPhase.shortBreak);
    await tester.pumpAndSettle();
    expect(ledColor(), TaktColors.patinaOlive);
    expect(find.bySemanticsLabel('Break running'), findsOneWidget);

    dial.set(running: false);
    await tester.pumpAndSettle();
    expect(glows(), isFalse);
  });
}
