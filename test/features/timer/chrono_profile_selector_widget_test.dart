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
    expect(find.text('SET 1/3 // FOCUS'), findsOneWidget);
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
    expect(find.text('SET 1/3 // FOCUS'), findsOneWidget);
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

    expect(find.text('SET 1/3 // FOCUS'), findsOneWidget);

    // Verify text color is filamentAmber
    final textWidget = tester.widget<Text>(find.text('SET 1/3 // FOCUS'));
    expect(textWidget.style?.color, equals(TaktColors.filamentAmber));

    // Advance to short break
    container.read(chronoDialProvider.notifier).advanceCalibrationStage();
    await tester.pump();
    expect(find.text('SET 2/3 // SHORT BRK'), findsOneWidget);

    // Advance to long break
    container.read(chronoDialProvider.notifier).advanceCalibrationStage();
    await tester.pump();
    expect(find.text('SET 3/3 // LONG BRK'), findsOneWidget);

    // Tap telemetry plaque to cancel/exit calibration
    await tester.tap(find.text('SET 3/3 // LONG BRK'));
    await tester.pump();

    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.none));
    expect(find.text('PULL CROWN // SET'), findsOneWidget);
  });

  testWidgets('tapping cycle gauge increments cycle count target', (tester) async {
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

    expect(find.text('CYCLE 1/4'), findsOneWidget);
    expect(find.byKey(const ValueKey('chrono_cycle_gauge_button')), findsOneWidget);
    expect(find.byIcon(Icons.autorenew_rounded), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('chrono_cycle_gauge_button')));
    await tester.pump();

    expect(find.text('CYCLE 1/5'), findsOneWidget);
    expect(container.read(chronoDialProvider).profile.longBreakInterval, equals(5));

    // Start timer: button displays lock icon and ignores tap
    container.read(chronoDialProvider.notifier).start();
    await tester.pump();
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('chrono_cycle_gauge_button')));
    await tester.pump();
    expect(find.text('CYCLE 1/5'), findsOneWidget);
    expect(container.read(chronoDialProvider).profile.longBreakInterval, equals(5));
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

    // Initially CLASSIC 25: plaque should display STANDBY // READY in muted textColor
    expect(find.text('STANDBY // READY'), findsOneWidget);
    var readyText = tester.widget<Text>(find.text('STANDBY // READY'));
    expect(readyText.style?.color, isNot(equals(TaktColors.filamentAmber)));

    // Switch to CUSTOM profile
    await tester.tap(find.text('CUSTOM'));
    await tester.pump();

    // Plaque should now guide user with PULL CROWN // SET in filamentAmber
    expect(find.text('PULL CROWN // SET'), findsOneWidget);
    var plaqueText = tester.widget<Text>(find.text('PULL CROWN // SET'));
    expect(plaqueText.style?.color, equals(TaktColors.filamentAmber));

    // When running under CUSTOM profile, RUNNING // SEC-ROLL takes priority
    container.read(chronoDialProvider.notifier).start();
    await tester.pump();
    expect(find.text('RUNNING // SEC-ROLL'), findsOneWidget);
    var runningText = tester.widget<Text>(find.text('RUNNING // SEC-ROLL'));
    expect(runningText.style?.color, equals(TaktColors.filamentAmber));

    // When paused, reverts to PULL CROWN // SET
    container.read(chronoDialProvider.notifier).pause();
    await tester.pump();
    expect(find.text('PULL CROWN // SET'), findsOneWidget);

    // Switch back to 25/5 CLS: plaque returns to STANDBY // READY and textColor reverts
    await tester.tap(find.text('25/5 CLS'));
    await tester.pump();
    expect(find.text('STANDBY // READY'), findsOneWidget);
    readyText = tester.widget<Text>(find.text('STANDBY // READY'));
    expect(readyText.style?.color, isNot(equals(TaktColors.filamentAmber)));
  });
}

