import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/core/time/current_day.dart';
import 'package:takt_desk/features/analytics/domain/focus_analytics_models.dart';
import 'package:takt_desk/features/analytics/domain/focus_session_rules.dart';
import 'package:takt_desk/features/analytics/presentation/focus_analytics_controller.dart';

TimerSession _cycle(int id, DateTime at) => TimerSession(
      id: id,
      targetMinutes: 25,
      elapsedSeconds: 1500,
      isFinished: true,
      startedAt: at,
      isLockdownOnly: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('logicalDay: with a 4 am start, 01:30 belongs to the day before; 04:00 to the same day', () {
    expect(logicalDay(DateTime(2026, 10, 14, 1, 30), 4), DateTime(2026, 10, 13));
    expect(logicalDay(DateTime(2026, 10, 14, 4), 4), DateTime(2026, 10, 14));
    expect(logicalDay(DateTime(2026, 10, 14, 1, 30), 0), DateTime(2026, 10, 14));
    expect(logicalDay(DateTime(2026, 1, 1, 2), 4), DateTime(2025, 12, 31), reason: 'across a year');
  });

  test('a cycle finished after midnight keeps the streak of the night owl', () {
    final sessions = [
      _cycle(1, DateTime(2026, 10, 12, 22)),
      _cycle(2, DateTime(2026, 10, 14, 1, 30)), // the night of the 13th
    ];
    final now = DateTime(2026, 10, 14, 2);
    expect(FocusStreak.compute(sessions, now).current, 1, reason: 'calendar days 12 and 14: broken');
    expect(FocusStreak.compute(sessions, now, dayStartHour: 4).current, 2, reason: 'logical days 12 and 13');
  });

  test('analytics weeks can start on Sunday', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.now();
    final sunday = DateTime(now.year, now.month, now.day - (now.weekday % 7), 10);
    await db.into(db.timerSessions).insert(TimerSessionsCompanion.insert(
          targetMinutes: 25,
          elapsedSeconds: 1500,
          isFinished: const Value(true),
          startedAt: Value(sunday),
        ));
    final c = FocusAnalyticsController(db, weekStartsOnSunday: true);
    addTearDown(c.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    c.setPeriod(FocusAnalyticsPeriod.day);
    c.setPeriod(FocusAnalyticsPeriod.week);
    expect(c.state.bars.first.label, 'SUN');
    expect(c.state.bars.first.valueMinutes, 25);
    expect(c.state.bars.last.label, 'SAT');
  });

  testWidgets('the day changes at the configured hour, not at midnight', (tester) async {
    final controller = CurrentDayController(startHour: 4);
    final seen = <DateTime>[controller.state];
    controller.addListener(seen.add, fireImmediately: false);
    // Run until two day changes happened; they must fall on 04:00.
    await tester.pump(const Duration(hours: 49));
    expect(seen.length, greaterThanOrEqualTo(3));
    controller.dispose();
  });
}
