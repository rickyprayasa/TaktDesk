import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tables/desk_preferences_table.dart';
import 'tables/tasks_table.dart';
import 'tables/timer_sessions_table.dart';

part 'app_database.g.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

@DriftDatabase(tables: [Tasks, TimerSessions, DeskPreferences])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(deskPreferences, deskPreferences.selectedEdition);
            await m.addColumn(deskPreferences, deskPreferences.isProSimulated);
          }
          if (from < 5) {
            await m.addColumn(deskPreferences, deskPreferences.alarmChimeId);
          }
          if (from < 6) {
            await m.addColumn(deskPreferences, deskPreferences.autoUnlockMonastic);
          }
          if (from < 7) {
            await m.addColumn(deskPreferences, deskPreferences.isDarkMode);
          }
          if (from < 8) {
            await m.addColumn(timerSessions, timerSessions.isLockdownOnly);
            await m.addColumn(deskPreferences, deskPreferences.dailyGoalCycles);
          }
          if (from < 9) {
            await m.addColumn(deskPreferences, deskPreferences.deskClockMode);
          }
        },
      );

  Stream<List<Task>> watchActiveTasks() {
    return (select(tasks)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.id),
          ]))
        .watch();
  }

  Future<int> addTask(String title) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw ArgumentError('Task title cannot be blank');
    }
    return transaction(() async {
      final activeCount = await (select(tasks)..where((t) => t.isArchived.equals(false))).get();
      if (activeCount.length >= 5) {
        throw Exception('Maksimal 5 tugas aktif per batch kerja');
      }
      return into(tasks).insert(TasksCompanion.insert(
        title: cleanTitle,
        sortOrder: Value(activeCount.length),
      ));
    });
  }

  Future<void> toggleTaskCompleted(int id, bool completed) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isCompleted: Value(completed),
        completedAt: Value(completed ? DateTime.now() : null),
      ),
    );
  }

  Future<void> archiveTask(int id) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      const TasksCompanion(isArchived: Value(true)),
    );
  }

  Stream<List<Task>> watchArchivedTasks() {
    return (select(tasks)
          ..where((t) => t.isArchived.equals(true))
          ..orderBy([
            (t) => OrderingTerm(expression: t.completedAt, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<void> deleteTask(int id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  Future<void> clearArchivedTasks() {
    return (delete(tasks)..where((t) => t.isArchived.equals(true))).go();
  }

  Future<int> recordTimerSession({
    int targetMinutes = 0,
    int? elapsedSeconds,
    int? durationSeconds,
    bool isFinished = false,
    bool? completed,
    bool isLockdownOnly = false,
    required DateTime startedAt,
  }) {
    final actualElapsed = elapsedSeconds ?? durationSeconds ?? 0;
    final actualFinished = completed ?? isFinished;
    final actualTarget = targetMinutes > 0 ? targetMinutes : (actualElapsed / 60).ceil();
    return into(timerSessions).insert(TimerSessionsCompanion.insert(
      targetMinutes: actualTarget,
      elapsedSeconds: actualElapsed,
      isFinished: Value(actualFinished),
      startedAt: Value(startedAt),
      finishedAt: Value(DateTime.now()),
      isLockdownOnly: Value(isLockdownOnly),
    ));
  }

  Stream<List<TimerSession>> watchTodayTimerSessions() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day + 1);
    return (select(timerSessions)
          ..where((t) =>
              t.startedAt.isBiggerOrEqualValue(startOfDay) &
              t.startedAt.isSmallerThanValue(endOfDay))
          ..orderBy([(t) => OrderingTerm(expression: t.startedAt, mode: OrderingMode.asc)]))
        .watch();
  }

  Stream<List<TimerSession>> watchAllTimerSessions() {
    return (select(timerSessions)
          ..orderBy([(t) => OrderingTerm(expression: t.startedAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<void> clearTimerSessions() {
    return delete(timerSessions).go();
  }

  Future<DeskPreference?> getDeskPreferences() {
    return (select(deskPreferences)..limit(1)).getSingleOrNull();
  }

  Stream<DeskPreference?> watchPreferences() {
    return (select(deskPreferences)..limit(1)).watchSingleOrNull();
  }

  Future<void> updateDeskPreferences({
    double? soundVolume,
    bool? parallaxEnabled,
    int? activeAmbientTrackIndex,
    bool? foleyEnabled,
    bool? hapticsEnabled,
    String? selectedEdition,
    bool? isProSimulated,
    String? alarmChimeId,
    bool? autoUnlockMonastic,
    bool? isDarkMode,
    int? dailyGoalCycles,
    bool? deskClockMode,
  }) {
    return transaction(() async {
      final existing = await (select(deskPreferences)..limit(1)).getSingleOrNull();
      final companion = DeskPreferencesCompanion(
        soundVolume: soundVolume != null ? Value(soundVolume) : const Value.absent(),
        parallaxEnabled: parallaxEnabled != null ? Value(parallaxEnabled) : const Value.absent(),
        activeAmbientTrackIndex:
            activeAmbientTrackIndex != null ? Value(activeAmbientTrackIndex) : const Value.absent(),
        foleyEnabled: foleyEnabled != null ? Value(foleyEnabled) : const Value.absent(),
        hapticsEnabled: hapticsEnabled != null ? Value(hapticsEnabled) : const Value.absent(),
        selectedEdition: selectedEdition != null ? Value(selectedEdition) : const Value.absent(),
        isProSimulated: isProSimulated != null ? Value(isProSimulated) : const Value.absent(),
        alarmChimeId: alarmChimeId != null ? Value(alarmChimeId) : const Value.absent(),
        autoUnlockMonastic:
            autoUnlockMonastic != null ? Value(autoUnlockMonastic) : const Value.absent(),
        isDarkMode: isDarkMode != null ? Value(isDarkMode) : const Value.absent(),
        dailyGoalCycles: dailyGoalCycles != null ? Value(dailyGoalCycles) : const Value.absent(),
        deskClockMode: deskClockMode != null ? Value(deskClockMode) : const Value.absent(),
      );

      if (existing == null) {
        await into(deskPreferences).insert(companion);
      } else {
        await (update(deskPreferences)..where((t) => t.id.equals(existing.id))).write(companion);
      }
    });
  }

  Future<void> updatePreferences({
    double? soundVolume,
    bool? parallaxEnabled,
    int? activeAmbientTrackIndex,
    bool? foleyEnabled,
    bool? hapticsEnabled,
    String? selectedEdition,
    bool? isProSimulated,
    String? alarmChimeId,
    bool? autoUnlockMonastic,
    bool? isDarkMode,
    int? dailyGoalCycles,
    bool? deskClockMode,
  }) =>
      updateDeskPreferences(
        soundVolume: soundVolume,
        parallaxEnabled: parallaxEnabled,
        activeAmbientTrackIndex: activeAmbientTrackIndex,
        foleyEnabled: foleyEnabled,
        hapticsEnabled: hapticsEnabled,
        selectedEdition: selectedEdition,
        isProSimulated: isProSimulated,
        alarmChimeId: alarmChimeId,
        autoUnlockMonastic: autoUnlockMonastic,
        isDarkMode: isDarkMode,
        dailyGoalCycles: dailyGoalCycles,
        deskClockMode: deskClockMode,
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'takt_desk.sqlite'));
      return NativeDatabase.createInBackground(file);
    } catch (e) {
      // Fallback for tests or platforms without path_provider
      // print('_openConnection fallback to memory due to: $e');
      return NativeDatabase.memory();
    }
  });
}
