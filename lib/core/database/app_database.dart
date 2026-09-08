import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/desk_preferences_table.dart';
import 'tables/tasks_table.dart';
import 'tables/timer_sessions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tasks, TimerSessions, DeskPreferences])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  Stream<List<Task>> watchActiveTasks() {
    return (select(tasks)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .watch();
  }

  Future<int> addTask(String title) async {
    final activeCount = await (select(tasks)..where((t) => t.isArchived.equals(false))).get();
    if (activeCount.length >= 5) {
      throw Exception('Maksimal 5 tugas aktif per batch kerja');
    }
    return into(tasks).insert(TasksCompanion.insert(
      title: title,
      sortOrder: Value(activeCount.length),
    ));
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'takt_desk.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
