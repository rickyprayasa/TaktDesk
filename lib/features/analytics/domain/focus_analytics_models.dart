import 'package:flutter/foundation.dart';

/// Temporal grouping mode for focus analytics.
enum FocusAnalyticsPeriod {
  day('DAY', 'D'),
  week('WEEK', 'W'),
  month('MONTH', 'M'),
  year('YEAR', 'Y');

  final String label;
  final String telemetryCode;

  const FocusAnalyticsPeriod(this.label, this.telemetryCode);
}

/// A single discrete bar in the focus histogram.
@immutable
class FocusBarData {
  final String label;
  final int valueMinutes;
  final bool isHighlighted;
  final bool isToday;

  const FocusBarData({
    required this.label,
    required this.valueMinutes,
    this.isHighlighted = false,
    this.isToday = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusBarData &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          valueMinutes == other.valueMinutes &&
          isHighlighted == other.isHighlighted &&
          isToday == other.isToday;

  @override
  int get hashCode => Object.hash(label, valueMinutes, isHighlighted, isToday);

  @override
  String toString() =>
      'FocusBarData($label: ${valueMinutes}m, high=$isHighlighted, today=$isToday)';
}

/// A slip and the focus minutes it took in the period (TOP SLIPS).
@immutable
class FocusSlipShare {
  final String title;
  final int minutes;

  const FocusSlipShare({required this.title, required this.minutes});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FocusSlipShare && title == other.title && minutes == other.minutes;

  @override
  int get hashCode => Object.hash(title, minutes);

  @override
  String toString() => 'FocusSlipShare($title: ${minutes}m)';
}

/// Immutable aggregated snapshot of focus telemetry over a selected period.
@immutable
class FocusAnalyticsState {
  final FocusAnalyticsPeriod period;
  final DateTime selectedDate;
  final String dateRangeLabel;
  final int totalMinutes;
  final int completedSessions;
  final int totalSessions;
  final double completionRate;
  final double dailyAverageMinutes;
  final String bestDayLabel;
  final List<FocusBarData> bars;

  /// Consecutive days with >= 1 completed cycle, ending today/yesterday.
  final int currentStreak;
  final int bestStreak;

  /// Completed cycles today (for the daily goal meter; independent of period).
  final int todayCycles;

  /// YEAR only: focus minutes per day of the selected year (index 0 = 1 January), for the heatmap.
  final List<int> heatmapMinutes;

  /// YEAR only: today's index in [heatmapMinutes], -1 when another year is shown.
  final int heatmapTodayIndex;

  /// The slips that took the most focus in the period, most first (at most 3).
  final List<FocusSlipShare> topSlips;

  const FocusAnalyticsState({
    required this.period,
    required this.selectedDate,
    required this.dateRangeLabel,
    this.totalMinutes = 0,
    this.completedSessions = 0,
    this.totalSessions = 0,
    this.completionRate = 0.0,
    this.dailyAverageMinutes = 0.0,
    this.bestDayLabel = '—',
    this.bars = const [],
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.todayCycles = 0,
    this.heatmapMinutes = const [],
    this.heatmapTodayIndex = -1,
    this.topSlips = const [],
  });

  FocusAnalyticsState copyWith({
    FocusAnalyticsPeriod? period,
    DateTime? selectedDate,
    String? dateRangeLabel,
    int? totalMinutes,
    int? completedSessions,
    int? totalSessions,
    double? completionRate,
    double? dailyAverageMinutes,
    String? bestDayLabel,
    List<FocusBarData>? bars,
    int? currentStreak,
    int? bestStreak,
    int? todayCycles,
    List<int>? heatmapMinutes,
    int? heatmapTodayIndex,
    List<FocusSlipShare>? topSlips,
  }) {
    return FocusAnalyticsState(
      period: period ?? this.period,
      selectedDate: selectedDate ?? this.selectedDate,
      dateRangeLabel: dateRangeLabel ?? this.dateRangeLabel,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      completedSessions: completedSessions ?? this.completedSessions,
      totalSessions: totalSessions ?? this.totalSessions,
      completionRate: completionRate ?? this.completionRate,
      dailyAverageMinutes: dailyAverageMinutes ?? this.dailyAverageMinutes,
      bestDayLabel: bestDayLabel ?? this.bestDayLabel,
      bars: bars ?? this.bars,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      todayCycles: todayCycles ?? this.todayCycles,
      heatmapMinutes: heatmapMinutes ?? this.heatmapMinutes,
      heatmapTodayIndex: heatmapTodayIndex ?? this.heatmapTodayIndex,
      topSlips: topSlips ?? this.topSlips,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusAnalyticsState &&
          runtimeType == other.runtimeType &&
          period == other.period &&
          selectedDate == other.selectedDate &&
          dateRangeLabel == other.dateRangeLabel &&
          totalMinutes == other.totalMinutes &&
          completedSessions == other.completedSessions &&
          totalSessions == other.totalSessions &&
          completionRate == other.completionRate &&
          dailyAverageMinutes == other.dailyAverageMinutes &&
          bestDayLabel == other.bestDayLabel &&
          listEquals(bars, other.bars) &&
          currentStreak == other.currentStreak &&
          bestStreak == other.bestStreak &&
          todayCycles == other.todayCycles &&
          listEquals(heatmapMinutes, other.heatmapMinutes) &&
          heatmapTodayIndex == other.heatmapTodayIndex &&
          listEquals(topSlips, other.topSlips);

  @override
  int get hashCode => Object.hash(
        period,
        selectedDate,
        dateRangeLabel,
        totalMinutes,
        completedSessions,
        totalSessions,
        completionRate,
        dailyAverageMinutes,
        bestDayLabel,
        Object.hashAll(bars),
        currentStreak,
        bestStreak,
        todayCycles,
        Object.hashAll(heatmapMinutes),
        heatmapTodayIndex,
        Object.hashAll(topSlips),
      );
}
