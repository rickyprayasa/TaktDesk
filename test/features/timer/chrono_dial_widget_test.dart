import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_painter.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_widget.dart';

void main() {
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

    // Verify initial time display (25:00) and target duration label (25 MIN)
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('25 MIN'), findsOneWidget);

    // Verify CustomPaint with ChronoDialPainter is rendered
    final customPaintFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is ChronoDialPainter,
    );
    expect(customPaintFinder, findsOneWidget);

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
    expect(find.text('30:00'), findsOneWidget);

    // Tap '-' button twice
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pump();
    expect(find.text('25 MIN'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pump();
    expect(find.text('20 MIN'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);

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
    await tester.tap(find.text('25:00'));
    await tester.pump();

    // Advance 1 second
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('24:59'), findsOneWidget);

    // Tap dial to pause
    await tester.tap(find.text('24:59'));
    await tester.pump();

    // Advance 2 seconds and verify counter stays paused
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('24:59'), findsOneWidget);

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
    await tester.tap(find.text('25:00'));
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
    await tester.tap(find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is ChronoDialPainter,
    ));
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
    expect(find.text('05:00'), findsOneWidget);

    // Start timer
    await tester.tap(find.text('05:00'));
    await tester.pump();

    // Advance 301 seconds to expire timer
    await tester.pump(const Duration(seconds: 301));
    expect(find.text('00:00'), findsOneWidget);

    // Tap dial to restart expired timer
    await tester.tap(find.text('00:00'));
    await tester.pump();

    // Should restart to full target duration (05:00) and continue ticking
    expect(find.text('05:00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('04:59'), findsOneWidget);

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });
}
