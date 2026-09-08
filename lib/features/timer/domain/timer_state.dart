class TimerState {
  final int targetMinutes;
  final double remainingSeconds;
  final bool isRunning;
  final int lastTickMinute;

  const TimerState({
    required this.targetMinutes,
    required this.remainingSeconds,
    required this.isRunning,
    this.lastTickMinute = 0,
  });

  double get progressPercent => targetMinutes > 0
      ? 1.0 - (remainingSeconds / (targetMinutes * 60.0)).clamp(0.0, 1.0)
      : 0.0;

  TimerState copyWith({
    int? targetMinutes,
    double? remainingSeconds,
    bool? isRunning,
    int? lastTickMinute,
  }) {
    return TimerState(
      targetMinutes: targetMinutes ?? this.targetMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      lastTickMinute: lastTickMinute ?? this.lastTickMinute,
    );
  }
}
