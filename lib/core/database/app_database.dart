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
  int get schemaVersion => 1;

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
    required int targetMinutes,
    required int elapsedSeconds,
    required bool isFinished,
    required DateTime startedAt,
  }) {
    return into(timerSessions).insert(TimerSessionsCompanion.insert(
      targetMinutes: targetMinutes,
      elapsedSeconds: elapsedSeconds,
      isFinished: Value(isFinished),
      startedAt: Value(startedAt),
      finishedAt: Value(DateTime.now()),
    ));
  }

  Stream<DeskPreference?> watchPreferences() {
    return (select(deskPreferences)..limit(1)).watchSingleOrNull();
  }

  Future<void> updatePreferences({
    double? soundVolume,
    bool? parallaxEnabled,
    int? activeAmbientTrackIndex,
  }) async {
    final existing = await (select(deskPreferences)..limit(1)).getSingleOrNull();
    if (existing == null) {
      await into(deskPreferences).insert(DeskPreferencesCompanion.insert(
        soundVolume: soundVolume != null ? Value(soundVolume) : const Value.absent(),
        parallaxEnabled: parallaxEnabled != null ? Value(parallaxEnabled) : const Value.absent(),
        activeAmbientTrackIndex:
            activeAmbientTrackIndex != null ? Value(activeAmbientTrackIndex) : const Value.absent(),
      ));
    } else {
      await (update(deskPreferences)..where((p) => p.id.equals(existing.id))).write(
        DeskPreferencesCompanion(
          soundVolume: soundVolume != null ? Value(soundVolume) : const Value.absent(),
          parallaxEnabled: parallaxEnabled != null ? Value(parallaxEnabled) : const Value.absent(),
          activeAmbientTrackIndex:
              activeAmbientTrackIndex != null ? Value(activeAmbientTrackIndex) : const Value.absent(),
        ),
      );
    }
  }
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
