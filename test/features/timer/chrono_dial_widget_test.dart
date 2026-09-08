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
}
