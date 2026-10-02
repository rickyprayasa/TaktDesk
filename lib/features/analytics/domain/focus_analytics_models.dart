import 'package:flutter/foundation.dart';

/// Temporal grouping mode for focus analytics.
enum FocusAnalyticsPeriod {
  day('DAY', 'D'),
  week('WEEK', 'W'),
  month('MONTH', 'M');

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
          todayCycles == other.todayCycles;

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
      );
}
