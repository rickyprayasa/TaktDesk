enum PomodoroPhase {
  focus,
  shortBreak,
  longBreak;

  String get label {
    switch (this) {
      case PomodoroPhase.focus:
        return 'FOCUS';
      case PomodoroPhase.shortBreak:
        return 'SHORT BRK';
      case PomodoroPhase.longBreak:
        return 'LONG BRK';
    }
  }

  int get defaultMinutes {
    switch (this) {
      case PomodoroPhase.focus:
        return 25;
      case PomodoroPhase.shortBreak:
        return 5;
      case PomodoroPhase.longBreak:
        return 15;
    }
  }
}
