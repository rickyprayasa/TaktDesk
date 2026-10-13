import 'package:drift/drift.dart';

class DeskPreferences extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get soundVolume => real().withDefault(const Constant(0.8))();
  BoolColumn get parallaxEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get activeAmbientTrackIndex => integer().withDefault(const Constant(0))();
  BoolColumn get foleyEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get hapticsEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get selectedEdition => text().withDefault(const Constant('braunClassic'))();
  BoolColumn get isProSimulated => boolean().withDefault(const Constant(true))();
  TextColumn get alarmChimeId => text().withDefault(const Constant('braunBell'))();
  BoolColumn get autoUnlockMonastic => boolean().withDefault(const Constant(false))();
  BoolColumn get isDarkMode => boolean().withDefault(const Constant(true))();

  /// Completed focus cycles per day the user aims for (schema v8).
  IntColumn get dailyGoalCycles => integer().withDefault(const Constant(4))();

  /// Keep the screen on (dimmed when idle) while a timer runs (schema v9).
  BoolColumn get deskClockMode => boolean().withDefault(const Constant(false))();

  /// Start the next phase (break after focus, focus after break) as soon as one ends (schema v10).
  BoolColumn get autoStartNextPhase => boolean().withDefault(const Constant(false))();

  /// Hour (0..6) at which a new day starts for stats, streaks and analytics, for people who focus past midnight
  /// (schema v12).
  IntColumn get dayStartHour => integer().withDefault(const Constant(0))();

  /// Analytics weeks run Sunday..Saturday instead of Monday..Sunday (schema v12).
  BoolColumn get weekStartsOnSunday => boolean().withDefault(const Constant(false))();
}
