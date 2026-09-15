import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/takt_colors.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_profile.dart';
import 'package:takt_desk/features/timer/domain/timer_state.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';
import 'package:takt_desk/features/timer/presentation/widgets/chrono_profile_selector_widget.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

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

  testWidgets('ChronoProfileSelectorWidget preserves custom intervals across preset switching', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Tune custom durations to 42 min focus, 8 min short break, 22 min long break
    container.read(chronoDialProvider.notifier).updateCustomDurations(
      focusMinutes: 42,
      shortBreakMinutes: 8,
      longBreakMinutes: 22,
    );

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

    // Tap CUSTOM segment
    await tester.tap(find.text('CUSTOM'));
    await tester.pump();

    var state = container.read(chronoDialProvider);
    expect(state.profile.type, equals(PomodoroProfileType.custom));
    expect(state.targetMinutes, equals(42));
    expect(state.profile.focusMinutes, equals(42));
    expect(state.profile.shortBreakMinutes, equals(8));
    expect(state.profile.longBreakMinutes, equals(22));

    // Switch to Classic
    await tester.tap(find.text('25/5 CLS'));
    await tester.pump();

    state = container.read(chronoDialProvider);
    expect(state.profile.type, equals(PomodoroProfileType.classic));
    expect(state.targetMinutes, equals(25));

    // Switch back to CUSTOM - should still retain 42/8/22
    await tester.tap(find.text('CUSTOM'));
    await tester.pump();

    state = container.read(chronoDialProvider);
    expect(state.profile.type, equals(PomodoroProfileType.custom));
    expect(state.targetMinutes, equals(42));
    expect(state.profile.focusMinutes, equals(42));
    expect(state.profile.shortBreakMinutes, equals(8));
    expect(state.profile.longBreakMinutes, equals(22));
  });

  testWidgets('long-pressing CUSTOM cassette button invokes enterCustomCalibration()', (tester) async {
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

    // Verify initial setupStage is none
    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.none));

    // Long-press CUSTOM button
    await tester.longPress(find.text('CUSTOM'));
    await tester.pump();

    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.focus));
    expect(find.text('SET 1/4 // FOCUS'), findsOneWidget);
  });

  testWidgets('tapping CUSTOM button when already active invokes enterCustomCalibration()', (tester) async {
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

    // First tap CUSTOM to select it
    await tester.tap(find.text('CUSTOM'));
    await tester.pump();
    expect(container.read(chronoDialProvider).profile.type, equals(PomodoroProfileType.custom));
    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.none));

    // Second tap on CUSTOM while active should enter custom calibration
    await tester.tap(find.text('CUSTOM'));
    await tester.pump();
    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.focus));
    expect(find.text('SET 1/4 // FOCUS'), findsOneWidget);
  });

  testWidgets('telemetry status plaque displays setup stage labels and exits calibration on tap', (tester) async {
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

    // Enter calibration
    container.read(chronoDialProvider.notifier).enterCustomCalibration();
    await tester.pump();

    expect(find.text('SET 1/4 // FOCUS'), findsOneWidget);

    // Verify text color is filamentAmber
    final textWidget = tester.widget<Text>(find.text('SET 1/4 // FOCUS'));
    expect(textWidget.style?.color, equals(TaktColors.filamentAmber));

    // Advance to short break
    container.read(chronoDialProvider.notifier).advanceCalibrationStage();
    await tester.pump();
    expect(find.text('SET 2/4 // SHORT BRK'), findsOneWidget);

    // Advance to long break
    container.read(chronoDialProvider.notifier).advanceCalibrationStage();
    await tester.pump();
    expect(find.text('SET 3/4 // LONG BRK'), findsOneWidget);

    // Advance to cycle count
    container.read(chronoDialProvider.notifier).advanceCalibrationStage();
    await tester.pump();
    expect(find.text('SET 4/4 // CYCLES'), findsOneWidget);

    // Tap telemetry plaque to cancel/exit calibration
    await tester.tap(find.text('SET 4/4 // CYCLES'));
    await tester.pump();

    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.none));
    expect(find.text('PULL CROWN // SET'), findsOneWidget);
  });

  testWidgets('telemetry status plaque displays PULL CROWN // SET when custom profile is idle in standby', (tester) async {
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

    // Initially CLASSIC 25: plaque should display STANDBY // READY
    expect(find.text('STANDBY // READY'), findsOneWidget);

    // Switch to CUSTOM profile
    await tester.tap(find.text('CUSTOM'));
    await tester.pump();

    // Plaque should now guide user with PULL CROWN // SET in filamentAmber
    expect(find.text('PULL CROWN // SET'), findsOneWidget);
    final plaqueText = tester.widget<Text>(find.text('PULL CROWN // SET'));
    expect(plaqueText.style?.color, equals(TaktColors.filamentAmber));

    // Switch back to 25/5 CLS: plaque returns to STANDBY // READY
    await tester.tap(find.text('25/5 CLS'));
    await tester.pump();
    expect(find.text('STANDBY // READY'), findsOneWidget);
  });
}

