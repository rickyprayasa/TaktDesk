import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/analytics/domain/focus_analytics_models.dart';
import 'package:takt_desk/features/analytics/presentation/focus_analytics_controller.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('FocusAnalyticsController starts on week period with 7 days', () async {
    final state = container.read(focusAnalyticsControllerProvider);
    expect(state.period, FocusAnalyticsPeriod.week);
    expect(state.bars.length, 7);
    expect(state.bars.map((b) => b.label).toList(), [
      'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'
    ]);
    expect(state.totalMinutes, 0);
    expect(state.completedSessions, 0);
  });

  test('FocusAnalyticsController computes aggregated weekly focus metrics from database sessions', () async {
    // Initialize controller so listener is active
    final notifier = container.read(focusAnalyticsControllerProvider.notifier);
    final now = DateTime.now();
    // Insert 2 sessions on Monday and 1 on Tuesday
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    
    await db.recordTimerSession(
      targetMinutes: 25,
      durationSeconds: 1500, // 25m
      completed: true,
      startedAt: monday.add(const Duration(hours: 9)),
    );
    await db.recordTimerSession(
      targetMinutes: 25,
      durationSeconds: 1500, // 25m
      completed: true,
      startedAt: monday.add(const Duration(hours: 11)),
    );
    await db.recordTimerSession(
      targetMinutes: 25,
      durationSeconds: 600, // 10m (interrupted)
      completed: false,
      startedAt: monday.add(const Duration(days: 1, hours: 14)), // Tuesday
    );

    // Allow stream to emit
    await pumpEventQueue();

    final state = container.read(focusAnalyticsControllerProvider);
    expect(state.totalMinutes, 60); // 25 + 25 + 10 = 60m
    expect(state.completedSessions, 2);
    expect(state.totalSessions, 3);
    expect(state.completionRate, closeTo(2 / 3, 0.01));
    expect(state.bars[0].valueMinutes, 50); // Monday
    expect(state.bars[1].valueMinutes, 10); // Tuesday
  });

  test('FocusAnalyticsController handles day and month period switching and navigation', () async {
    final notifier = container.read(focusAnalyticsControllerProvider.notifier);

    // Switch to DAY
    notifier.setPeriod(FocusAnalyticsPeriod.day);
    var state = container.read(focusAnalyticsControllerProvider);
    expect(state.period, FocusAnalyticsPeriod.day);
    expect(state.bars.length, 6); // 6 4-hour intervals
    expect(state.bars.first.label, '00h');
    expect(state.bars.last.label, '20h');

    // Switch to MONTH
    notifier.setPeriod(FocusAnalyticsPeriod.month);
    state = container.read(focusAnalyticsControllerProvider);
    expect(state.period, FocusAnalyticsPeriod.month);
    expect(state.bars.length, 5); // 5 weeks (W1..W5)
    expect(state.bars.first.label, 'W1');

    // Test previous and next navigation
    final originalDate = state.selectedDate;
    notifier.previousPeriod();
    state = container.read(focusAnalyticsControllerProvider);
    expect(state.selectedDate.month, (originalDate.month == 1) ? 12 : originalDate.month - 1);

    notifier.nextPeriod();
    state = container.read(focusAnalyticsControllerProvider);
    expect(state.selectedDate.month, originalDate.month);
  });
}
