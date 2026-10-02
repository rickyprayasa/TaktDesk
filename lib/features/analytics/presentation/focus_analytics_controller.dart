import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../domain/focus_analytics_models.dart';
import '../domain/focus_session_rules.dart';

const List<String> _monthNames = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
];

const List<String> _weekdayNames = [
  'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'
];

class FocusAnalyticsController extends StateNotifier<FocusAnalyticsState> {
  final AppDatabase _db;
  StreamSubscription<List<TimerSession>>? _subscription;
  List<TimerSession> _cachedSessions = [];

  FocusAnalyticsController(this._db)
      : super(_initialState()) {
    _initStream();
  }

  static FocusAnalyticsState _initialState() {
    final now = DateTime.now();
    return _computeState(
      period: FocusAnalyticsPeriod.week,
      selectedDate: now,
      sessions: const [],
    );
  }

  void _initStream() {
    _subscription = _db.watchAllTimerSessions().listen((sessions) {
      _cachedSessions = sessions;
      _recompute();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void setPeriod(FocusAnalyticsPeriod period) {
    if (state.period == period) return;
    state = _computeState(
      period: period,
      selectedDate: state.selectedDate,
      sessions: _cachedSessions,
    );
  }

  void previousPeriod() {
    DateTime nextDate;
    switch (state.period) {
      case FocusAnalyticsPeriod.day:
        nextDate = state.selectedDate.subtract(const Duration(days: 1));
        break;
      case FocusAnalyticsPeriod.week:
        nextDate = state.selectedDate.subtract(const Duration(days: 7));
        break;
      case FocusAnalyticsPeriod.month:
        final month = state.selectedDate.month == 1 ? 12 : state.selectedDate.month - 1;
        final year = state.selectedDate.month == 1 ? state.selectedDate.year - 1 : state.selectedDate.year;
        nextDate = DateTime(year, month, 1);
        break;
    }
    state = _computeState(
      period: state.period,
      selectedDate: nextDate,
      sessions: _cachedSessions,
    );
  }

  void nextPeriod() {
    DateTime nextDate;
    switch (state.period) {
      case FocusAnalyticsPeriod.day:
        nextDate = state.selectedDate.add(const Duration(days: 1));
        break;
      case FocusAnalyticsPeriod.week:
        nextDate = state.selectedDate.add(const Duration(days: 7));
        break;
      case FocusAnalyticsPeriod.month:
        final month = state.selectedDate.month == 12 ? 1 : state.selectedDate.month + 1;
        final year = state.selectedDate.month == 12 ? state.selectedDate.year + 1 : state.selectedDate.year;
        nextDate = DateTime(year, month, 1);
        break;
    }
    state = _computeState(
      period: state.period,
      selectedDate: nextDate,
      sessions: _cachedSessions,
    );
  }

  void resetToToday() {
    state = _computeState(
      period: state.period,
      selectedDate: DateTime.now(),
      sessions: _cachedSessions,
    );
  }

  void _recompute() {
    state = _computeState(
      period: state.period,
      selectedDate: state.selectedDate,
      sessions: _cachedSessions,
    );
  }

  static FocusAnalyticsState _computeState({
    required FocusAnalyticsPeriod period,
    required DateTime selectedDate,
    required List<TimerSession> sessions,
  }) {
    final today = DateTime.now();

    final base = switch (period) {
      FocusAnalyticsPeriod.day => _computeDayState(selectedDate, today, sessions),
      FocusAnalyticsPeriod.week => _computeWeekState(selectedDate, today, sessions),
      FocusAnalyticsPeriod.month => _computeMonthState(selectedDate, today, sessions),
    };
    final streak = FocusStreak.compute(sessions, today);
    final startOfToday = DateTime(today.year, today.month, today.day);
    final todayCycles = sessions
        .where((s) => s.isCompletedCycle && !s.startedAt.isBefore(startOfToday) && _sameDay(s.startedAt, today))
        .length;
    return base.copyWith(
      currentStreak: streak.current,
      bestStreak: streak.best,
      todayCycles: todayCycles,
    );
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Days of [start, end) that have already begun, so averages for the period
  /// in progress are not diluted by days that haven't happened yet.
  static int _elapsedDays(DateTime start, DateTime end, DateTime today) {
    final startOfToday = DateTime(today.year, today.month, today.day);
    if (!startOfToday.isAfter(start) && !_sameDay(start, startOfToday)) return 0; // future period
    if (!startOfToday.isBefore(end)) {
      return DateTime.utc(end.year, end.month, end.day).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
    }
    return DateTime.utc(today.year, today.month, today.day)
            .difference(DateTime.utc(start.year, start.month, start.day))
            .inDays +
        1;
  }

  /// (focus minutes, completed cycles, timer sessions) under FocusSessionRules.
  static (int, int, int) _totals(Iterable<TimerSession> sessions) {
    var secs = 0, cycles = 0, timerSessions = 0;
    for (final s in sessions) {
      secs += s.elapsedSeconds;
      if (s.isTimerSession) timerSessions++;
      if (s.isCompletedCycle) cycles++;
    }
    return ((secs / 60).round(), cycles, timerSessions);
  }

  static FocusAnalyticsState _computeDayState(
    DateTime selectedDate,
    DateTime today,
    List<TimerSession> allSessions,
  ) {
    final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final daySessions = allSessions.where((s) =>
        s.startedAt.isAfter(startOfDay.subtract(const Duration(microseconds: 1))) &&
        s.startedAt.isBefore(endOfDay)).toList();

    final (totalMins, completed, totalCount) = _totals(daySessions);
    final compRate = totalCount > 0 ? (completed / totalCount) : 0.0;

    // 6 4-hour bins: 00h, 04h, 08h, 12h, 16h, 20h
    final binMinutes = List<int>.filled(6, 0);
    for (final s in daySessions) {
      final hour = s.startedAt.hour;
      final binIndex = (hour ~/ 4).clamp(0, 5);
      binMinutes[binIndex] += (s.elapsedSeconds / 60).round();
    }

    final currentHourBin = (today.hour ~/ 4).clamp(0, 5);
    final isToday = selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;

    final bars = <FocusBarData>[];
    const binLabels = ['00h', '04h', '08h', '12h', '16h', '20h'];
    for (int i = 0; i < 6; i++) {
      bars.add(FocusBarData(
        label: binLabels[i],
        valueMinutes: binMinutes[i],
        isHighlighted: binMinutes[i] > 0,
        isToday: isToday && i == currentHourBin,
      ));
    }

    final dateLabel = '${selectedDate.day} ${_monthNames[selectedDate.month - 1]} ${selectedDate.year}';

    return FocusAnalyticsState(
      period: FocusAnalyticsPeriod.day,
      selectedDate: selectedDate,
      dateRangeLabel: dateLabel,
      totalMinutes: totalMins,
      completedSessions: completed,
      totalSessions: totalCount,
      completionRate: compRate,
      dailyAverageMinutes: totalMins.toDouble(),
      bestDayLabel: _peakLabel(binLabels, binMinutes),
      bars: bars,
    );
  }

  /// "08h · 50m" for the busiest bin, or "—".
  static String _peakLabel(List<String> labels, List<int> minutes) {
    var best = -1;
    for (var i = 0; i < minutes.length; i++) {
      if (minutes[i] > 0 && (best < 0 || minutes[i] > minutes[best])) best = i;
    }
    return best < 0 ? '—' : '${labels[best]} · ${minutes[best]}m';
  }

  static FocusAnalyticsState _computeWeekState(
    DateTime selectedDate,
    DateTime today,
    List<TimerSession> allSessions,
  ) {
    final monday = DateTime(selectedDate.year, selectedDate.month, selectedDate.day)
        .subtract(Duration(days: selectedDate.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final endOfWeek = DateTime(sunday.year, sunday.month, sunday.day).add(const Duration(days: 1));

    final weekSessions = allSessions.where((s) =>
        s.startedAt.isAfter(monday.subtract(const Duration(microseconds: 1))) &&
        s.startedAt.isBefore(endOfWeek)).toList();

    final dayMinutes = List<int>.filled(7, 0);
    for (final s in weekSessions) {
      final dayIndex = (s.startedAt.weekday - 1).clamp(0, 6);
      dayMinutes[dayIndex] += (s.elapsedSeconds / 60).round();
    }

    final (totalMins, completed, totalCount) = _totals(weekSessions);
    final compRate = totalCount > 0 ? (completed / totalCount) : 0.0;
    final elapsed = _elapsedDays(monday, endOfWeek, today);
    final dailyAvg = elapsed > 0 ? totalMins / elapsed : 0.0;

    int maxDayMins = 0;
    int bestDayIndex = -1;
    for (int i = 0; i < 7; i++) {
      if (dayMinutes[i] > maxDayMins) {
        maxDayMins = dayMinutes[i];
        bestDayIndex = i;
      }
    }

    final bestDayStr = bestDayIndex >= 0
        ? '${_weekdayNames[bestDayIndex]} · ${maxDayMins}m'
        : '—';

    final isSameWeekAsToday = today.isAfter(monday.subtract(const Duration(microseconds: 1))) &&
        today.isBefore(endOfWeek);

    final bars = <FocusBarData>[];
    for (int i = 0; i < 7; i++) {
      bars.add(FocusBarData(
        label: _weekdayNames[i],
        valueMinutes: dayMinutes[i],
        isHighlighted: dayMinutes[i] > 0 && dayMinutes[i] == maxDayMins,
        isToday: isSameWeekAsToday && (today.weekday - 1) == i,
      ));
    }

    final dateLabel =
        '${monday.day} ${_monthNames[monday.month - 1]} – ${sunday.day} ${_monthNames[sunday.month - 1]} ${sunday.year}';

    return FocusAnalyticsState(
      period: FocusAnalyticsPeriod.week,
      selectedDate: selectedDate,
      dateRangeLabel: dateLabel,
      totalMinutes: totalMins,
      completedSessions: completed,
      totalSessions: totalCount,
      completionRate: compRate,
      dailyAverageMinutes: dailyAvg,
      bestDayLabel: bestDayStr,
      bars: bars,
    );
  }

  static FocusAnalyticsState _computeMonthState(
    DateTime selectedDate,
    DateTime today,
    List<TimerSession> allSessions,
  ) {
    final startOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final endOfMonth = selectedDate.month == 12
        ? DateTime(selectedDate.year + 1, 1, 1)
        : DateTime(selectedDate.year, selectedDate.month + 1, 1);

    final monthSessions = allSessions.where((s) =>
        s.startedAt.isAfter(startOfMonth.subtract(const Duration(microseconds: 1))) &&
        s.startedAt.isBefore(endOfMonth)).toList();

    // 4 near-equal buckets (31 days -> 8/8/8/7, 28 -> 7 each). The old 5 x 7-day
    // split left a 0-3 day "W5" that always looked empty.
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final bucketLen = (daysInMonth / 4).ceil();
    int bucketOf(int day) => ((day - 1) ~/ bucketLen).clamp(0, 3);
    final bucketLabels = List<String>.generate(4, (i) {
      final from = i * bucketLen + 1;
      final to = i == 3 ? daysInMonth : (from + bucketLen - 1).clamp(1, daysInMonth);
      return '$from–$to';
    });
    final weekMinutes = List<int>.filled(4, 0);
    for (final s in monthSessions) {
      weekMinutes[bucketOf(s.startedAt.day)] += (s.elapsedSeconds / 60).round();
    }

    final (totalMins, completed, totalCount) = _totals(monthSessions);
    final compRate = totalCount > 0 ? (completed / totalCount) : 0.0;
    final elapsed = _elapsedDays(startOfMonth, endOfMonth, today);
    final dailyAvg = elapsed > 0 ? (totalMins / elapsed) : 0.0;

    int maxWeekMins = 0;
    int bestWeekIndex = -1;
    for (int i = 0; i < 4; i++) {
      if (weekMinutes[i] > maxWeekMins) {
        maxWeekMins = weekMinutes[i];
        bestWeekIndex = i;
      }
    }

    final bestStr = bestWeekIndex >= 0 ? '${bucketLabels[bestWeekIndex]} · ${maxWeekMins}m' : '—';
    final isCurrentMonth = today.year == selectedDate.year && today.month == selectedDate.month;
    final currentBucket = bucketOf(today.day);

    final bars = <FocusBarData>[];
    for (int i = 0; i < 4; i++) {
      bars.add(FocusBarData(
        label: bucketLabels[i],
        valueMinutes: weekMinutes[i],
        isHighlighted: weekMinutes[i] > 0 && weekMinutes[i] == maxWeekMins,
        isToday: isCurrentMonth && currentBucket == i,
      ));
    }

    final dateLabel = '${_monthNames[selectedDate.month - 1]} ${selectedDate.year}';

    return FocusAnalyticsState(
      period: FocusAnalyticsPeriod.month,
      selectedDate: selectedDate,
      dateRangeLabel: dateLabel,
      totalMinutes: totalMins,
      completedSessions: completed,
      totalSessions: totalCount,
      completionRate: compRate,
      dailyAverageMinutes: dailyAvg,
      bestDayLabel: bestStr,
      bars: bars,
    );
  }
}

final focusAnalyticsControllerProvider =
    StateNotifierProvider<FocusAnalyticsController, FocusAnalyticsState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return FocusAnalyticsController(db);
});
