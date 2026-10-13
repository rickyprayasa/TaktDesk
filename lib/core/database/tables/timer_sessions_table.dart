import 'package:drift/drift.dart';

class TimerSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get targetMinutes => integer()();
  IntColumn get elapsedSeconds => integer()();
  BoolColumn get isFinished => boolean().withDefault(const Constant(false))();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get finishedAt => dateTime().nullable()();

  /// Monastic Lockdown used WITHOUT a running timer (schema v8). Counts as focus
  /// minutes but not as a Pomodoro cycle, and is excluded from completion rate.
  BoolColumn get isLockdownOnly => boolean().withDefault(const Constant(false))();

  /// The task slip the session counted for (top open slip when it started), null for none (schema v12).
  IntColumn get taskId => integer().nullable()();
}
