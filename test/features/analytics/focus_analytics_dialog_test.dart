import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/analytics/presentation/widgets/focus_analytics_dialog.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('FocusAnalyticsDialog renders tabs, chart, and metrics', (tester) async {
    final now = DateTime.now();
    await db.recordTimerSession(
      targetMinutes: 25,
      durationSeconds: 1500,
      completed: true,
      startedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => FocusAnalyticsDialog.show(context),
                child: const Text('OPEN ANALYTICS'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN ANALYTICS'));
    await tester.pumpAndSettle();

    // Verify title and tabs
    expect(find.text('FOCUS ANALYTICS'), findsOneWidget);
    expect(find.text('DAY'), findsOneWidget);
    expect(find.text('WEEK'), findsOneWidget);
    expect(find.text('MONTH'), findsOneWidget);

    // Verify metric cards
    expect(find.text('TOTAL SESSIONS'), findsOneWidget);
    expect(find.text('COMPLETED CYCLES'), findsOneWidget);
    expect(find.text('DAILY AVERAGE'), findsOneWidget);

    // Verify switching tabs
    await tester.tap(find.text('DAY'));
    await tester.pumpAndSettle();
    expect(find.text('00h'), findsOneWidget);

    await tester.tap(find.text('MONTH'));
    await tester.pumpAndSettle();
    // Month = 4 near-equal day ranges, the first always starts on day 1
    expect(find.textContaining(RegExp(r'^1–\d+$')), findsOneWidget);

    // Verify close
    await tester.tap(find.byKey(const ValueKey('focus_analytics_close_btn')));
    await tester.pumpAndSettle();
    expect(find.text('FOCUS ANALYTICS'), findsNothing);

    // Unmount and flush drift stream cancel timer
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
