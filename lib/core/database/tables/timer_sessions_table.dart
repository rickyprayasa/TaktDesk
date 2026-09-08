import 'package:drift/drift.dart';

class TimerSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get targetMinutes => integer()();
  IntColumn get elapsedSeconds => integer()();
  BoolColumn get isFinished => boolean().withDefault(const Constant(false))();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get finishedAt => dateTime().nullable()();
}
