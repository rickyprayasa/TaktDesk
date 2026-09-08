import 'pomodoro_phase.dart';

class TimerState {
  final int targetMinutes;
  final double remainingSeconds;
  final bool isRunning;
  final int lastTickMinute;
  final PomodoroPhase phase;
  final int cycleCount; // 1 to 4

  const TimerState({
    required this.targetMinutes,
    required this.remainingSeconds,
    required this.isRunning,
    this.lastTickMinute = 0,
    this.phase = PomodoroPhase.focus,
    this.cycleCount = 1,
  });

  double get progressPercent => targetMinutes > 0
      ? 1.0 - (remainingSeconds / (targetMinutes * 60.0)).clamp(0.0, 1.0)
      : 0.0;

  TimerState copyWith({
    int? targetMinutes,
    double? remainingSeconds,
    bool? isRunning,
    int? lastTickMinute,
    PomodoroPhase? phase,
    int? cycleCount,
  }) {
    return TimerState(
      targetMinutes: targetMinutes ?? this.targetMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      lastTickMinute: lastTickMinute ?? this.lastTickMinute,
      phase: phase ?? this.phase,
      cycleCount: cycleCount ?? this.cycleCount,
    );
  }
}
