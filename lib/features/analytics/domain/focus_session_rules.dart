import '../../../core/database/app_database.dart';
import '../../../core/time/current_day.dart';

/// Single source of truth for how a recorded session counts. Every screen
/// (analytics, the desk "TODAY" plate, lifetime stats) must use these rules so
/// the numbers agree.
///
/// - Focus minutes: every session, including lockdown-only ones.
/// - Cycle: a timer session that ran to the end (`isFinished`).
/// - Completion rate: finished timer sessions / all timer sessions
///   (abandoned = reset after >= 1 min, recorded with `isFinished = false`).
///   Lockdown-only sessions are neither cycles nor part of the rate.
extension FocusSessionRules on TimerSession {
  bool get isTimerSession => !isLockdownOnly;
  bool get isCompletedCycle => isTimerSession && isFinished;
}


/// Consecutive days with at least one completed cycle.
class FocusStreak {
  /// Run that ends today, or yesterday if today has no cycle yet (the streak
  /// is still alive until the day is over).
  final int current;
  final int best;
  final bool todayCounted;

  const FocusStreak({this.current = 0, this.best = 0, this.todayCounted = false});

  /// [dayStartHour]: days change at that hour (a 01:00 cycle with a 4 am start counts for the day before).
  static FocusStreak compute(Iterable<TimerSession> sessions, DateTime now, {int dayStartHour = 0}) {
    final days = <DateTime>{
      for (final s in sessions)
        if (s.isCompletedCycle) logicalDay(s.startedAt, dayStartHour),
    };
    if (days.isEmpty) return const FocusStreak();

    final sorted = days.toList()..sort();
    var best = 1;
    var run = 1;
    for (var i = 1; i < sorted.length; i++) {
      // Calendar-day difference, robust to DST (23/25 h days)
      final gap = DateTime.utc(sorted[i].year, sorted[i].month, sorted[i].day)
          .difference(DateTime.utc(sorted[i - 1].year, sorted[i - 1].month, sorted[i - 1].day))
          .inDays;
      run = gap == 1 ? run + 1 : 1;
      if (run > best) best = run;
    }

    final today = logicalDay(now, dayStartHour);
    final todayCounted = days.contains(today);
    var cursor = todayCounted ? today : DateTime(today.year, today.month, today.day - 1);
    var current = 0;
    while (days.contains(cursor)) {
      current++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return FocusStreak(current: current, best: best, todayCounted: todayCounted);
  }
}
