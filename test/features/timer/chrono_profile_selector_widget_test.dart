import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_profile.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';
import 'package:takt_desk/features/timer/presentation/widgets/chrono_profile_selector_widget.dart';

void main() {
  testWidgets('ChronoProfileSelectorWidget displays 4 cassette segments and selects profile on tap', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoProfileSelectorWidget(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('25/5 CLS'), findsOneWidget);
    expect(find.text('50/10 MON'), findsOneWidget);
    expect(find.text('15/3 SPR'), findsOneWidget);
    expect(find.text('CUSTOM'), findsOneWidget);

    // Tap 50/10 MON
    await tester.tap(find.text('50/10 MON'));
    await tester.pump();

    final state = container.read(chronoDialProvider);
    expect(state.profile.type, equals(PomodoroProfileType.monastic));
    expect(state.targetMinutes, equals(50));
  });

  testWidgets('ChronoProfileSelectorWidget disables segment switching while running', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoProfileSelectorWidget(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Start timer
    container.read(chronoDialProvider.notifier).start();
    await tester.pump();

    // Tap 15/3 SPR while running
    await tester.tap(find.text('15/3 SPR'));
    await tester.pump();

    // Should remain classic
    final state = container.read(chronoDialProvider);
    expect(state.profile.type, equals(PomodoroProfileType.classic));
    expect(state.targetMinutes, equals(25));
  });
}
