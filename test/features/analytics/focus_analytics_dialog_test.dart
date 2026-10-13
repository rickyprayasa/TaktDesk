import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';
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

  Future<ProviderContainer> openYear(WidgetTester tester, {required bool pro}) async {
    final container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    await container.read(deskPreferencesControllerProvider.notifier).setProSimulated(pro);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
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
    await tester.tap(find.text('YEAR'));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('YEAR shows the heatmap to PRO owners; a tapped day reads out its focus time', (tester) async {
    final now = DateTime.now();
    await db.recordTimerSession(
      targetMinutes: 25,
      durationSeconds: 1500,
      completed: true,
      startedAt: DateTime(now.year, 1, 1, 9),
    );
    await openYear(tester, pro: true);

    expect(find.text('JAN'), findsWidgets);
    final heatmap = find.byKey(const ValueKey('analytics_year_heatmap'));
    expect(heatmap, findsOneWidget);
    expect(find.byKey(const ValueKey('analytics_heatmap_unlock')), findsNothing);
    expect(find.text('TAP A DAY'), findsOneWidget);

    // 1 January is the top-left cell of the grid (right of the month labels).
    await tester.ensureVisible(heatmap);
    await tester.pumpAndSettle();
    final grid = find.descendant(of: heatmap, matching: find.byType(CustomPaint)).first;
    await tester.tapAt(tester.getTopLeft(grid) + const Offset(2, 2));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const ValueKey('analytics_heatmap_readout'))).data, '1 JAN · 25m');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('YEAR without PRO: a dimmed sample and an unlock that opens Studio PRO', (tester) async {
    await openYear(tester, pro: false);

    expect(find.text('YEAR HEATMAP · STUDIO PRO'), findsOneWidget);
    expect(find.text('TAP A DAY'), findsNothing);
    final unlock = find.byKey(const ValueKey('analytics_heatmap_unlock'));
    await tester.ensureVisible(unlock);
    await tester.pumpAndSettle();
    await tester.tap(unlock);
    await tester.pumpAndSettle();
    expect(find.text('ZYKL STUDIO PRO'), findsOneWidget);
    expect(find.textContaining('year heatmap'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
