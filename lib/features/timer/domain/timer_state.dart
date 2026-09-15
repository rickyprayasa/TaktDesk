import 'pomodoro_phase.dart';
import 'pomodoro_profile.dart';

class TimerState {
  final int targetMinutes;
  final double remainingSeconds;
  final bool isRunning;
  final int lastTickMinute;
  final PomodoroPhase phase;
  final int cycleCount; // 1 to 4
  final PomodoroProfile profile;
  final PomodoroProfile customProfile;

  const TimerState({
    required this.targetMinutes,
    required this.remainingSeconds,
    required this.isRunning,
    this.lastTickMinute = 0,
    this.phase = PomodoroPhase.focus,
    this.cycleCount = 1,
    this.profile = PomodoroProfile.classic,
    this.customProfile = const PomodoroProfile(
      type: PomodoroProfileType.custom,
      focusMinutes: 25,
      shortBreakMinutes: 5,
      longBreakMinutes: 15,
      longBreakInterval: 4,
    ),
  });

  bool get isBreak =>
      phase == PomodoroPhase.shortBreak || phase == PomodoroPhase.longBreak;

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
    PomodoroProfile? profile,
    PomodoroProfile? customProfile,
  }) {
    return TimerState(
      targetMinutes: targetMinutes ?? this.targetMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      lastTickMinute: lastTickMinute ?? this.lastTickMinute,
      phase: phase ?? this.phase,
      cycleCount: cycleCount ?? this.cycleCount,
      profile: profile ?? this.profile,
      customProfile: customProfile ?? this.customProfile,
    );
  }
}
