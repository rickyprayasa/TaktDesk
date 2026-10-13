import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../domain/focus_analytics_models.dart';
import '../domain/focus_session_rules.dart';
import '../../settings/presentation/settings_controller.dart';

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

  FocusAnalyticsController(this._db, {this.dayStartHour = 0, this.weekStartsOnSunday = false})
      : super(_computeState(
          period: FocusAnalyticsPeriod.week,
          selectedDate: DateTime.now(),
          sessions: const [],
          dayStartHour: dayStartHour,
          weekStartsOnSunday: weekStartsOnSunday,
        )) {
    _initStream();
  }

  /// Settings → DAY STARTS AT / WEEK STARTS.
  final int dayStartHour;
  final bool weekStartsOnSunday;

  /// Slip titles by id, for TOP SLIPS (a slip deleted since is missing).
  Map<int, String> _taskTitles = const {};

  void _initStream() {
    _subscription = _db.watchAllTimerSessions().listen((sessions) async {
      _cachedSessions = sessions;
      await _loadSlipTitles();
      if (mounted) _recompute();
    });
  }

  Future<void> _loadSlipTitles() async {
    try {
      _taskTitles = {for (final t in await _db.select(_db.tasks).get()) t.id: t.title};
    } catch (_) {
      // Keep the titles we had (the database may be closing).
    }
  }

  /// Slips can be renamed or deleted without a new session: the dialog refreshes the titles when it opens.
  Future<void> reloadSlipTitles() async {
    await _loadSlipTitles();
    if (mounted) _recompute();
  }

  FocusAnalyticsState _compute(FocusAnalyticsPeriod period, DateTime selectedDate) => _computeState(
        period: period,
        selectedDate: selectedDate,
        sessions: _cachedSessions,
        dayStartHour: dayStartHour,
        weekStartsOnSunday: weekStartsOnSunday,
        taskTitles: _taskTitles,
      );

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void setPeriod(FocusAnalyticsPeriod period) {
    if (state.period == period) return;
    state = _compute(period, state.selectedDate);
  }

  void previousPeriod() {
    DateTime nextDate;
    switch (state.period) {
      case FocusAnalyticsPeriod.day:
        nextDate = _shiftDays(state.selectedDate, -1);
        break;
      case FocusAnalyticsPeriod.week:
        nextDate = _shiftDays(state.selectedDate, -7);
        break;
      case FocusAnalyticsPeriod.month:
        final month = state.selectedDate.month == 1 ? 12 : state.selectedDate.month - 1;
        final year = state.selectedDate.month == 1 ? state.selectedDate.year - 1 : state.selectedDate.year;
        nextDate = DateTime(year, month, 1);
        break;
      case FocusAnalyticsPeriod.year:
        nextDate = DateTime(state.selectedDate.year - 1, 1, 1);
        break;
    }
    state = _compute(state.period, nextDate);
  }

  void nextPeriod() {
    DateTime nextDate;
    switch (state.period) {
      case FocusAnalyticsPeriod.day:
        nextDate = _shiftDays(state.selectedDate, 1);
        break;
      case FocusAnalyticsPeriod.week:
        nextDate = _shiftDays(state.selectedDate, 7);
        break;
      case FocusAnalyticsPeriod.month:
        final month = state.selectedDate.month == 12 ? 1 : state.selectedDate.month + 1;
        final year = state.selectedDate.month == 12 ? state.selectedDate.year + 1 : state.selectedDate.year;
        nextDate = DateTime(year, month, 1);
        break;
      case FocusAnalyticsPeriod.year:
        nextDate = DateTime(state.selectedDate.year + 1, 1, 1);
        break;
    }
    state = _compute(state.period, nextDate);
  }

  void resetToToday() {
    state = _compute(state.period, DateTime.now());
  }

  void _recompute() {
    state = _compute(state.period, state.selectedDate);
  }

  static FocusAnalyticsState _computeState({
    required FocusAnalyticsPeriod period,
    required DateTime selectedDate,
    required List<TimerSession> sessions,
    int dayStartHour = 0,
    bool weekStartsOnSunday = false,
    Map<int, String> taskTitles = const {},
  }) {
    // Days start at [dayStartHour]: every bucket below works on times moved back by that many hours, so a 01:30
    // session lands on the previous day everywhere (day, week, month, today's cycles).
    DateTime shift(DateTime t) =>
        dayStartHour == 0 ? t : DateTime(t.year, t.month, t.day, t.hour - dayStartHour, t.minute, t.second);
    final rawSessions = sessions;
    if (dayStartHour != 0) {
      sessions = [for (final s in sessions) s.copyWith(startedAt: shift(s.startedAt))];
    }
    final today = shift(DateTime.now());

    final base = switch (period) {
      FocusAnalyticsPeriod.day => _computeDayState(selectedDate, today, sessions, dayStartHour: dayStartHour),
      FocusAnalyticsPeriod.week =>
        _computeWeekState(selectedDate, today, sessions, weekStartsOnSunday: weekStartsOnSunday),
      FocusAnalyticsPeriod.month => _computeMonthState(selectedDate, today, sessions),
      FocusAnalyticsPeriod.year => _computeYearState(selectedDate, today, sessions),
    };
    final streak = FocusStreak.compute(rawSessions, DateTime.now(), dayStartHour: dayStartHour);
    final startOfToday = DateTime(today.year, today.month, today.day);
    final todayCycles = sessions
        .where((s) => s.isCompletedCycle && !s.startedAt.isBefore(startOfToday) && _sameDay(s.startedAt, today))
        .length;
    final (periodStart, periodEnd) = _periodRange(period, selectedDate, weekStartsOnSunday: weekStartsOnSunday);
    return base.copyWith(
      currentStreak: streak.current,
      bestStreak: streak.best,
      todayCycles: todayCycles,
      topSlips: _topSlips(
        sessions.where((s) => !s.startedAt.isBefore(periodStart) && s.startedAt.isBefore(periodEnd)),
        taskTitles,
      ),
    );
  }

  static const int topSlipCount = 3;

  /// The slips that took the most focus in the period (sessions remember their slip since schema v12). Sessions of
  /// slips deleted since are pooled as "DELETED SLIPS".
  static List<FocusSlipShare> _topSlips(Iterable<TimerSession> sessions, Map<int, String> taskTitles) {
    const deleted = -1;
    final seconds = <int, int>{};
    for (final s in sessions) {
      final id = s.taskId;
      if (id == null) continue;
      final key = taskTitles.containsKey(id) ? id : deleted;
      seconds[key] = (seconds[key] ?? 0) + s.elapsedSeconds;
    }
    String titleOf(int key) => key == deleted ? 'DELETED SLIPS' : taskTitles[key]!;
    final ranked = seconds.entries.where((e) => (e.value / 60).round() > 0).toList()
      ..sort((a, b) => b.value != a.value ? b.value.compareTo(a.value) : titleOf(a.key).compareTo(titleOf(b.key)));
    return [
      for (final e in ranked.take(topSlipCount)) FocusSlipShare(title: titleOf(e.key), minutes: (e.value / 60).round()),
    ];
  }

  /// [start, end) of the period that holds [selectedDate], in calendar days.
  static (DateTime, DateTime) _periodRange(
    FocusAnalyticsPeriod period,
    DateTime selectedDate, {
    bool weekStartsOnSunday = false,
  }) {
    final day = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    switch (period) {
      case FocusAnalyticsPeriod.day:
        return (day, _shiftDays(day, 1));
      case FocusAnalyticsPeriod.week:
        final first = _shiftDays(day, -_weekIndexOf(day, weekStartsOnSunday));
        return (first, _shiftDays(first, 7));
      case FocusAnalyticsPeriod.month:
        return (DateTime(day.year, day.month, 1), DateTime(day.year, day.month + 1, 1));
      case FocusAnalyticsPeriod.year:
        return (DateTime(day.year, 1, 1), DateTime(day.year + 1, 1, 1));
    }
  }

  /// Position in the week: Monday- or Sunday-first.
  static int _weekIndexOf(DateTime d, bool weekStartsOnSunday) => weekStartsOnSunday ? d.weekday % 7 : d.weekday - 1;

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Days of [start, end) that have already begun, so averages for the period
  /// in progress are not diluted by days that haven't happened yet.
  /// Calendar days, not 24 h steps: Duration(days: 1) is 23 or 25 h around a DST change, which moved day and week
  /// bounds by an hour (a session at 23:30 fell out of its day) and could skip a week when paging.
  static DateTime _shiftDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

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
    List<TimerSession> allSessions, {
    int dayStartHour = 0,
  }) {
    final (startOfDay, endOfDay) = _periodRange(FocusAnalyticsPeriod.day, selectedDate);

    final daySessions = allSessions.where((s) =>
        s.startedAt.isAfter(startOfDay.subtract(const Duration(microseconds: 1))) &&
        s.startedAt.isBefore(endOfDay)).toList();

    final (totalMins, completed, totalCount) = _totals(daySessions);
    final compRate = totalCount > 0 ? (completed / totalCount) : 0.0;

    // 6 4-hour bins: 00h, 04h, 08h, 12h, 16h, 20h
    final binSeconds = List<int>.filled(6, 0);
    for (final s in daySessions) {
      final hour = s.startedAt.hour;
      final binIndex = (hour ~/ 4).clamp(0, 5);
      binSeconds[binIndex] += s.elapsedSeconds;
    }
    // Rounded per bar, not per session: ten 90 s sessions are 15 m, not 20 m (the total said 15).
    final binMinutes = [for (final secs in binSeconds) (secs / 60).round()];

    final currentHourBin = (today.hour ~/ 4).clamp(0, 5);
    final isToday = selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;

    final bars = <FocusBarData>[];
    // Bins are 4 h of the (shifted) day; label them with the real clock hour.
    final binLabels = [for (var i = 0; i < 6; i++) '${((i * 4 + dayStartHour) % 24).toString().padLeft(2, '0')}h'];
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
    List<TimerSession> allSessions, {
    bool weekStartsOnSunday = false,
  }) {
    int dayIndexOf(DateTime d) => _weekIndexOf(d, weekStartsOnSunday);
    final names = weekStartsOnSunday ? const ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'] : _weekdayNames;
    // First day of the week (Monday, or Sunday with WEEK STARTS ON SUNDAY).
    final (monday, _) =
        _periodRange(FocusAnalyticsPeriod.week, selectedDate, weekStartsOnSunday: weekStartsOnSunday);
    final sunday = _shiftDays(monday, 6); // last day of the week
    final endOfWeek = _shiftDays(monday, 7);

    final weekSessions = allSessions.where((s) =>
        s.startedAt.isAfter(monday.subtract(const Duration(microseconds: 1))) &&
        s.startedAt.isBefore(endOfWeek)).toList();

    final daySeconds = List<int>.filled(7, 0);
    for (final s in weekSessions) {
      final dayIndex = dayIndexOf(s.startedAt).clamp(0, 6);
      daySeconds[dayIndex] += s.elapsedSeconds;
    }
    final dayMinutes = [for (final secs in daySeconds) (secs / 60).round()];

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
        ? '${names[bestDayIndex]} · ${maxDayMins}m'
        : '—';

    final isSameWeekAsToday = today.isAfter(monday.subtract(const Duration(microseconds: 1))) &&
        today.isBefore(endOfWeek);

    final bars = <FocusBarData>[];
    for (int i = 0; i < 7; i++) {
      bars.add(FocusBarData(
        label: names[i],
        valueMinutes: dayMinutes[i],
        isHighlighted: dayMinutes[i] > 0 && dayMinutes[i] == maxDayMins,
        isToday: isSameWeekAsToday && dayIndexOf(today) == i,
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
    final weekSeconds = List<int>.filled(4, 0);
    for (final s in monthSessions) {
      weekSeconds[bucketOf(s.startedAt.day)] += s.elapsedSeconds;
    }
    final weekMinutes = [for (final secs in weekSeconds) (secs / 60).round()];

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

  /// Whole days between two calendar dates (UTC, so a DST change never makes a day 23 h).
  static int _daysBetween(DateTime from, DateTime to) =>
      DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  /// Twelve month bars plus the minutes of every day for the heatmap.
  static FocusAnalyticsState _computeYearState(
    DateTime selectedDate,
    DateTime today,
    List<TimerSession> allSessions,
  ) {
    final year = selectedDate.year;
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year + 1, 1, 1);
    final yearSessions = allSessions.where((s) => s.startedAt.year == year).toList();

    final daySeconds = List<int>.filled(_daysBetween(startOfYear, endOfYear), 0);
    final monthSeconds = List<int>.filled(12, 0);
    for (final s in yearSessions) {
      daySeconds[_daysBetween(startOfYear, s.startedAt)] += s.elapsedSeconds;
      monthSeconds[s.startedAt.month - 1] += s.elapsedSeconds;
    }
    final dayMinutes = [for (final secs in daySeconds) (secs / 60).round()];
    final monthMinutes = [for (final secs in monthSeconds) (secs / 60).round()];

    final (totalMins, completed, totalCount) = _totals(yearSessions);
    final elapsed = _elapsedDays(startOfYear, endOfYear, today);

    var bestDay = -1;
    for (var i = 0; i < dayMinutes.length; i++) {
      if (dayMinutes[i] > 0 && (bestDay < 0 || dayMinutes[i] > dayMinutes[bestDay])) bestDay = i;
    }
    final bestDate = _shiftDays(startOfYear, bestDay);
    var bestMonth = -1;
    for (var i = 0; i < 12; i++) {
      if (monthMinutes[i] > 0 && (bestMonth < 0 || monthMinutes[i] > monthMinutes[bestMonth])) bestMonth = i;
    }
    final isThisYear = today.year == year;

    return FocusAnalyticsState(
      period: FocusAnalyticsPeriod.year,
      selectedDate: selectedDate,
      dateRangeLabel: '$year',
      totalMinutes: totalMins,
      completedSessions: completed,
      totalSessions: totalCount,
      completionRate: totalCount > 0 ? completed / totalCount : 0.0,
      dailyAverageMinutes: elapsed > 0 ? totalMins / elapsed : 0.0,
      bestDayLabel: bestDay < 0 ? '—' : '${bestDate.day} ${_monthNames[bestDate.month - 1]} · ${dayMinutes[bestDay]}m',
      bars: [
        for (var i = 0; i < 12; i++)
          FocusBarData(
            label: _monthNames[i],
            valueMinutes: monthMinutes[i],
            isHighlighted: i == bestMonth,
            isToday: isThisYear && today.month == i + 1,
          ),
      ],
      heatmapMinutes: dayMinutes,
      heatmapTodayIndex: isThisYear ? _daysBetween(startOfYear, today) : -1,
    );
  }
}

final focusAnalyticsControllerProvider =
    StateNotifierProvider<FocusAnalyticsController, FocusAnalyticsState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final calendar = ref.watch(deskPreferencesControllerProvider.select((p) => (p.dayStartHour, p.weekStartsOnSunday)));
  return FocusAnalyticsController(db, dayStartHour: calendar.$1, weekStartsOnSunday: calendar.$2);
});
