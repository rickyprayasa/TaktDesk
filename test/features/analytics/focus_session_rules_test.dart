import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/analytics/domain/focus_session_rules.dart';
import 'package:takt_desk/features/analytics/presentation/focus_analytics_controller.dart';

TimerSession _s(DateTime startedAt, {bool finished = true, bool lockdown = false, int secs = 1500}) => TimerSession(
      id: 0,
      targetMinutes: 25,
      elapsedSeconds: secs,
      isFinished: finished,
      startedAt: startedAt,
      finishedAt: startedAt.add(Duration(seconds: secs)),
      isLockdownOnly: lockdown,
    );

void main() {
  group('FocusSessionRules', () {
    test('lockdown-only sessions are focus time but never cycles', () {
      final now = DateTime(2026, 10, 1, 10);
      expect(_s(now).isCompletedCycle, isTrue);
      expect(_s(now, finished: false).isCompletedCycle, isFalse);
      expect(_s(now, lockdown: true).isCompletedCycle, isFalse);
      expect(_s(now, lockdown: true).isTimerSession, isFalse);
    });
  });

  group('FocusStreak', () {
    final now = DateTime(2026, 10, 10, 15);

    test('counts consecutive days ending today', () {
      final s = FocusStreak.compute([
        _s(DateTime(2026, 10, 10, 9)),
        _s(DateTime(2026, 10, 9, 9)),
        _s(DateTime(2026, 10, 8, 22)),
        _s(DateTime(2026, 10, 6, 9)), // gap on the 7th
      ], now);
      expect(s.current, 3);
      expect(s.todayCounted, isTrue);
    });

    test('streak stays alive until today ends when today has no cycle yet', () {
      final s = FocusStreak.compute([_s(DateTime(2026, 10, 9, 9)), _s(DateTime(2026, 10, 8, 9))], now);
      expect(s.current, 2);
      expect(s.todayCounted, isFalse);
    });

    test('a missed day resets the current streak but keeps the best', () {
      final s = FocusStreak.compute([
        _s(DateTime(2026, 10, 8, 9)),
        _s(DateTime(2026, 10, 1, 9)),
        _s(DateTime(2026, 10, 2, 9)),
        _s(DateTime(2026, 10, 3, 9)),
      ], now);
      expect(s.current, 0);
      expect(s.best, 3);
    });

    test('abandoned and lockdown-only sessions do not count', () {
      final s = FocusStreak.compute([
        _s(DateTime(2026, 10, 10, 9), finished: false),
        _s(DateTime(2026, 10, 9, 9), lockdown: true),
      ], now);
      expect(s.current, 0);
      expect(s.best, 0);
    });

    test('works across a DST transition (23 h day)', () {
      final s = FocusStreak.compute([
        _s(DateTime(2026, 3, 28, 9)),
        _s(DateTime(2026, 3, 29, 9)),
        _s(DateTime(2026, 3, 30, 9)),
      ], DateTime(2026, 3, 30, 12));
      expect(s.current, 3);
    });
  });

  group('FocusAnalyticsController with the new rules', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db)]);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<void> settle() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    test('completion rate counts abandoned sessions; lockdown-only adds minutes only', () async {
      container.read(focusAnalyticsControllerProvider.notifier);
      final now = DateTime.now();
      final at = DateTime(now.year, now.month, now.day, 0, 30);
      await db.recordTimerSession(targetMinutes: 25, elapsedSeconds: 1500, isFinished: true, startedAt: at);
      await db.recordTimerSession(targetMinutes: 25, elapsedSeconds: 600, isFinished: false, startedAt: at);
      await db.recordTimerSession(
          durationSeconds: 1200, completed: true, isLockdownOnly: true, startedAt: at);
      await settle();

      final state = container.read(focusAnalyticsControllerProvider);
      expect(state.totalSessions, 2); // timer sessions only
      expect(state.completedSessions, 1);
      expect(state.completionRate, closeTo(0.5, 1e-9));
      expect(state.totalMinutes, 25 + 10 + 20);
      expect(state.todayCycles, 1);
      expect(state.currentStreak, 1);
    });

    test('weekly daily average divides by the days elapsed so far', () async {
      container.read(focusAnalyticsControllerProvider.notifier);
      final now = DateTime.now();
      await db.recordTimerSession(
        targetMinutes: 70,
        elapsedSeconds: 70 * 60,
        isFinished: true,
        startedAt: DateTime(now.year, now.month, now.day, 0, 5),
      );
      await settle();
      final state = container.read(focusAnalyticsControllerProvider);
      expect(state.dailyAverageMinutes, closeTo(70 / now.weekday, 1e-9));
    });
  });
}
