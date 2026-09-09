import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_painter.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_widget.dart';
import 'package:takt_desk/features/timer/presentation/widgets/mechanical_flip_digit.dart';

void main() {
  final dialFinder = find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is ChronoDialPainter,
  );

  void expectDisplay(WidgetTester tester, int minutes, int seconds) {
    final display = tester.widget<MechanicalCounterDisplay>(
      find.byType(MechanicalCounterDisplay, skipOffstage: false),
    );
    expect(display.minutes, minutes);
    expect(display.seconds, seconds);
  }

  testWidgets('ChronoDialWidget renders initial state and custom painter', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoDialWidget(),
            ),
          ),
        ),
      ),
    );

    // Verify initial time display and target duration label (25 MIN)
    expect(find.byType(MechanicalCounterDisplay, skipOffstage: false), findsOneWidget);
    expectDisplay(tester, 25, 0);
    expect(find.text('25 MIN'), findsOneWidget);

    // Verify CustomPaint with ChronoDialPainter is rendered
    expect(dialFinder, findsOneWidget);

    // Verify adjust duration buttons exist
    expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ChronoDialWidget increments and decrements target minutes', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoDialWidget(),
            ),
          ),
        ),
      ),
    );

    // Tap '+' button
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();
    expect(find.text('30 MIN'), findsOneWidget);
    expectDisplay(tester, 30, 0);

    // Tap '-' button twice
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pump();
    expect(find.text('25 MIN'), findsOneWidget);
    expectDisplay(tester, 25, 0);

    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pump();
    expect(find.text('20 MIN'), findsOneWidget);
    expectDisplay(tester, 20, 0);

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ChronoDialWidget starts and pauses on dial tap', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoDialWidget(),
            ),
          ),
        ),
      ),
    );

    // Tap dial to start
    await tester.tap(dialFinder);
    await tester.pump();

    // Advance 1 second
    await tester.pump(const Duration(seconds: 1));
    expectDisplay(tester, 24, 59);

    // Tap dial to pause
    await tester.tap(dialFinder);
    await tester.pump();

    // Advance 2 seconds and verify counter stays paused
    await tester.pump(const Duration(seconds: 2));
    expectDisplay(tester, 24, 59);

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ChronoDialWidget disables duration buttons while running', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoDialWidget(),
            ),
          ),
        ),
      ),
    );

    // Initial state: buttons enabled
    final removeFinder = find.widgetWithIcon(IconButton, Icons.remove_circle_outline);
    final addFinder = find.widgetWithIcon(IconButton, Icons.add_circle_outline);

    IconButton removeButton = tester.widget(removeFinder);
    IconButton addButton = tester.widget(addFinder);
    expect(removeButton.onPressed, isNotNull);
    expect(addButton.onPressed, isNotNull);

    // Start timer
    await tester.tap(dialFinder);
    await tester.pump();

    // While running: buttons disabled
    removeButton = tester.widget(removeFinder);
    addButton = tester.widget(addFinder);
    expect(removeButton.onPressed, isNull);
    expect(addButton.onPressed, isNull);

    // Tapping disabled button should have no effect
    await tester.tap(addFinder);
    await tester.pump();
    expect(find.text('25 MIN'), findsOneWidget);

    // Pause timer
    await tester.tap(dialFinder);
    await tester.pump();

    // Paused: buttons enabled again
    removeButton = tester.widget(removeFinder);
    addButton = tester.widget(addFinder);
    expect(removeButton.onPressed, isNotNull);
    expect(addButton.onPressed, isNotNull);

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ChronoDialWidget restarts after expiration on dial tap', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoDialWidget(),
            ),
          ),
        ),
      ),
    );

    // Decrement to 5 MIN
    final removeFinder = find.widgetWithIcon(IconButton, Icons.remove_circle_outline);
    for (int i = 0; i < 4; i++) {
      await tester.tap(removeFinder);
      await tester.pump();
    }
    expect(find.text('5 MIN'), findsOneWidget);
    expectDisplay(tester, 5, 0);

    // Start timer
    await tester.tap(dialFinder);
    await tester.pump();

    // Advance 301 seconds to expire timer
    await tester.pump(const Duration(seconds: 301));
    expectDisplay(tester, 0, 0);

    // Tap dial to restart expired timer
    await tester.tap(dialFinder);
    await tester.pump();

    // Should restart to full target duration (05:00) and continue ticking
    expectDisplay(tester, 5, 0);
    await tester.pump(const Duration(seconds: 1));
    expectDisplay(tester, 4, 59);

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ChronoDialWidget sets target minutes via rotary pan drag', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoDialWidget(),
            ),
          ),
        ),
      ),
    );

    // Initial state is 25 MIN
    expect(find.text('25 MIN'), findsOneWidget);

    // Drag from center rightwards (3 o'clock position = 15 MIN)
    final dialCenter = tester.getCenter(dialFinder);
    final gesture = await tester.startGesture(dialCenter + const Offset(50, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    // The dial target minutes should update to 15 MIN
    expect(find.text('15 MIN'), findsOneWidget);
    expectDisplay(tester, 15, 0);

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ChronoDialWidget passes themeState.needleColor to ChronoDialPainter when edition changes', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(chassisThemeProvider.notifier).setHardwareEdition(HardwareEditionType.titaniumStealth);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoDialWidget(),
            ),
          ),
        ),
      ),
    );

    final customPaint = tester.widget<CustomPaint>(dialFinder);
    final painter = customPaint.painter as ChronoDialPainter;
    expect(painter.needleColor, equals(const Color(0xFF3A86FF)));
  });
}
