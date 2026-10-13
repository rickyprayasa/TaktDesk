import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/analytics/domain/focus_analytics_models.dart';
import 'package:takt_desk/features/analytics/presentation/focus_analytics_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
    container.read(focusAnalyticsControllerProvider.notifier);
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

  test('YEAR: twelve month bars, every day of the year for the heatmap, paging by year', () async {
    final notifier = container.read(focusAnalyticsControllerProvider.notifier);
    final now = DateTime.now();
    final y = now.year;
    int dayIndex(int month, int day) => DateTime.utc(y, month, day).difference(DateTime.utc(y)).inDays;
    await db.recordTimerSession(targetMinutes: 25, durationSeconds: 1500, completed: true, startedAt: DateTime(y, 1, 1, 9));
    await db.recordTimerSession(targetMinutes: 50, durationSeconds: 3000, completed: true, startedAt: DateTime(y, 3, 1, 10));
    await db.recordTimerSession(
        targetMinutes: 25, durationSeconds: 1500, completed: true, startedAt: DateTime(y - 1, 12, 31, 22));
    await pumpEventQueue();

    notifier.setPeriod(FocusAnalyticsPeriod.year);
    var state = container.read(focusAnalyticsControllerProvider);
    expect(state.dateRangeLabel, '$y');
    expect(state.bars.map((b) => b.label),
        ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC']);
    expect(state.heatmapMinutes, hasLength(DateTime.utc(y + 1).difference(DateTime.utc(y)).inDays));
    expect(state.heatmapMinutes[0], 25);
    expect(state.heatmapMinutes[dayIndex(3, 1)], 50);
    expect(state.heatmapMinutes.fold<int>(0, (a, b) => a + b), 75);
    expect(state.totalMinutes, 75);
    expect(state.bars[0].valueMinutes, 25);
    expect(state.bars[2].valueMinutes, 50);
    expect(state.bars[2].isHighlighted, isTrue);
    expect(state.bestDayLabel, '1 MAR · 50m');
    expect(state.heatmapTodayIndex, dayIndex(now.month, now.day));
    expect(state.bars[now.month - 1].isToday, isTrue);

    notifier.previousPeriod();
    state = container.read(focusAnalyticsControllerProvider);
    expect(state.dateRangeLabel, '${y - 1}');
    expect(state.totalMinutes, 25);
    expect(state.heatmapMinutes.last, 25, reason: '31 December is the last cell');
    expect(state.heatmapTodayIndex, -1);
    expect(state.bars.every((b) => !b.isToday), isTrue);

    notifier.nextPeriod();
    expect(container.read(focusAnalyticsControllerProvider).dateRangeLabel, '$y');
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
    expect(state.bars.length, 4); // 4 near-equal day ranges (no empty "W5")
    expect(state.bars.first.label, startsWith('1–'));
    expect(state.bars.last.label, endsWith('–${DateTime(state.selectedDate.year, state.selectedDate.month + 1, 0).day}'));

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
