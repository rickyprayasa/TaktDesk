enum PomodoroProfileType {
  classic,
  monastic,
  sprint,
  custom;

  String get label {
    switch (this) {
      case PomodoroProfileType.classic:
        return 'CLASSIC 25/5';
      case PomodoroProfileType.monastic:
        return 'MONASTIC 50/10';
      case PomodoroProfileType.sprint:
        return 'SPRINT 15/3';
      case PomodoroProfileType.custom:
        return 'CUSTOM';
    }
  }
}

class PomodoroProfile {
  final PomodoroProfileType type;
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  const PomodoroProfile({
    required this.type,
    required this.focusMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
  });

  static const classic = PomodoroProfile(
    type: PomodoroProfileType.classic,
    focusMinutes: 25,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
  );

  static const monastic = PomodoroProfile(
    type: PomodoroProfileType.monastic,
    focusMinutes: 50,
    shortBreakMinutes: 10,
    longBreakMinutes: 30,
  );

  static const sprint = PomodoroProfile(
    type: PomodoroProfileType.sprint,
    focusMinutes: 15,
    shortBreakMinutes: 3,
    longBreakMinutes: 10,
  );

  factory PomodoroProfile.custom({
    int focusMinutes = 25,
    int shortBreakMinutes = 5,
    int longBreakMinutes = 15,
  }) {
    return PomodoroProfile(
      type: PomodoroProfileType.custom,
      focusMinutes: focusMinutes.clamp(1, 90),
      shortBreakMinutes: shortBreakMinutes.clamp(1, 30),
      longBreakMinutes: longBreakMinutes.clamp(1, 45),
    );
  }

  PomodoroProfile copyWith({
    PomodoroProfileType? type,
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
  }) {
    return PomodoroProfile(
      type: type ?? this.type,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
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
          longBreakMinutes == other.longBreakMinutes;

  @override
  int get hashCode =>
      type.hashCode ^
      focusMinutes.hashCode ^
      shortBreakMinutes.hashCode ^
      longBreakMinutes.hashCode;
}
