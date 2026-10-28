enum PomodoroProfileType {
  classic,
  monastic,
  sprint,
  custom;

  /// Named for what the rhythm is for; shown on the notification, widgets and in Settings.
  String get label {
    switch (this) {
      case PomodoroProfileType.classic:
        return 'DAILY FOCUS 25/5';
      case PomodoroProfileType.monastic:
        return 'DEEP WORK 50/10';
      case PomodoroProfileType.sprint:
        return 'QUICK START 15/3';
      case PomodoroProfileType.custom:
        return 'CUSTOM';
    }
  }

  /// Key on the dial's preset cassette (four keys share the console width).
  String get keyLabel {
    switch (this) {
      case PomodoroProfileType.classic:
        return '25/5 DAILY';
      case PomodoroProfileType.monastic:
        return '50/10 DEEP';
      case PomodoroProfileType.sprint:
        return '15/3 QUICK';
      case PomodoroProfileType.custom:
        return 'CUSTOM';
    }
  }

  /// One line on when to pick it.
  String get purpose {
    switch (this) {
      case PomodoroProfileType.classic:
        return 'Everyday work and study. The classic Pomodoro rhythm.';
      case PomodoroProfileType.monastic:
        return 'Long, absorbing work: writing, coding, design.';
      case PomodoroProfileType.sprint:
        return 'When starting is the hard part: chores, inbox, a first step.';
      case PomodoroProfileType.custom:
        return 'Your own rhythm, set with the crown.';
    }
  }
}

class PomodoroProfile {
  final PomodoroProfileType type;
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int longBreakInterval;

  const PomodoroProfile({
    required this.type,
    required this.focusMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    this.longBreakInterval = 4,
  });

  String get label => type.label;

  static const classic = PomodoroProfile(
    type: PomodoroProfileType.classic,
    focusMinutes: 25,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
    longBreakInterval: 4,
  );

  static const monastic = PomodoroProfile(
    type: PomodoroProfileType.monastic,
    focusMinutes: 50,
    shortBreakMinutes: 10,
    longBreakMinutes: 30,
    longBreakInterval: 4,
  );

  static const sprint = PomodoroProfile(
    type: PomodoroProfileType.sprint,
    focusMinutes: 15,
    shortBreakMinutes: 3,
    longBreakMinutes: 10,
    longBreakInterval: 4,
  );

  factory PomodoroProfile.custom({
    int focusMinutes = 25,
    int shortBreakMinutes = 5,
    int longBreakMinutes = 15,
    int longBreakInterval = 4,
  }) {
    return PomodoroProfile(
      type: PomodoroProfileType.custom,
      focusMinutes: focusMinutes.clamp(1, 90),
      shortBreakMinutes: shortBreakMinutes.clamp(1, 30),
      longBreakMinutes: longBreakMinutes.clamp(1, 45),
      longBreakInterval: longBreakInterval.clamp(2, 8),
    );
  }

  PomodoroProfile copyWith({
    PomodoroProfileType? type,
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? longBreakInterval,
  }) {
    return PomodoroProfile(
      type: type ?? this.type,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      longBreakInterval: longBreakInterval ?? this.longBreakInterval,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroProfile &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          focusMinutes == other.focusMinutes &&
          shortBreakMinutes == other.shortBreakMinutes &&
          longBreakMinutes == other.longBreakMinutes &&
          longBreakInterval == other.longBreakInterval;

  @override
  int get hashCode =>
      type.hashCode ^
      focusMinutes.hashCode ^
      shortBreakMinutes.hashCode ^
      longBreakMinutes.hashCode ^
      longBreakInterval.hashCode;
}
