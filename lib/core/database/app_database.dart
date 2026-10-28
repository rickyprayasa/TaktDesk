import 'dart:async';
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

  /// Fires after focus time was added to a slip (a plain stream: drift's watch() leaves timers in widget tests).
  final StreamController<void> _taskFocusChanges = StreamController<void>.broadcast();
  Stream<void> get taskFocusChanges => _taskFocusChanges.stream;

  @override
  Future<void> close() async {
    await _taskFocusChanges.close();
    return super.close();
  }

  @override
  int get schemaVersion => 14;

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
          if (from < 10) {
            await m.addColumn(deskPreferences, deskPreferences.autoStartNextPhase);
          }
          if (from < 11) {
            await m.addColumn(tasks, tasks.focusSeconds);
          }
          if (from < 12) {
            await m.addColumn(deskPreferences, deskPreferences.dayStartHour);
            await m.addColumn(deskPreferences, deskPreferences.weekStartsOnSunday);
            await m.addColumn(timerSessions, timerSessions.taskId);
          }
          if (from < 13) {
            await m.addColumn(deskPreferences, deskPreferences.reviewAskedAt);
          }
          if (from < 14) {
            await m.addColumn(deskPreferences, deskPreferences.onboardingDone);
            // Anyone updating already knows the app: no walkthrough for them.
            await customStatement('UPDATE desk_preferences SET onboarding_done = 1');
            final hasPrefs = await (select(deskPreferences)..limit(1)).getSingleOrNull() != null;
            final hasHistory = await (select(timerSessions)..limit(1)).getSingleOrNull() != null ||
                await (select(tasks)..limit(1)).getSingleOrNull() != null;
            if (!hasPrefs && hasHistory) {
              await into(deskPreferences).insert(const DeskPreferencesCompanion(onboardingDone: Value(true)));
            }
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
      final active = await (select(tasks)..where((t) => t.isArchived.equals(false))).get();
      if (active.length >= 5) {
        throw Exception('At most 5 active tasks in the dispenser');
      }
      return into(tasks).insert(TasksCompanion.insert(
        title: cleanTitle,
        sortOrder: Value(await nextTaskSortOrder()),
      ));
    });
  }

  /// Sort position for a slip printed now: after every active slip. The active count collided once slips above had
  /// been torn off (a new slip sorted before older ones), so focus time went to a slip other than the one on top.
  Future<int> nextTaskSortOrder() async {
    final maxOrder = tasks.sortOrder.max();
    final row = await (selectOnly(tasks)
          ..addColumns([maxOrder])
          ..where(tasks.isArchived.equals(false)))
        .getSingle();
    final current = row.read(maxOrder);
    return current == null ? 0 : current + 1;
  }

  /// The slip a focus session works on: the top open (not stamped) slip in the dispenser, null when there is none.
  Future<int?> currentFocusTaskId() async {
    final row = await (select(tasks)
          ..where((t) => t.isArchived.equals(false) & t.isCompleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.id),
          ])
          ..limit(1))
        .getSingleOrNull();
    return row?.id;
  }

  /// Adds focused time to a slip (also after it was stamped or torn off during the session).
  Future<void> addTaskFocus(int id, int seconds) async {
    if (seconds <= 0) return;
    await customUpdate(
      'UPDATE tasks SET focus_seconds = focus_seconds + ? WHERE id = ?',
      variables: [Variable.withInt(seconds), Variable.withInt(id)],
      updates: {tasks},
    );
    if (!_taskFocusChanges.isClosed) _taskFocusChanges.add(null);
  }

  /// Focus seconds per slip id (active and archived), for the dispenser and the archive drawer.
  Future<Map<int, int>> taskFocusSeconds() async {
    final rows = await (selectOnly(tasks)..addColumns([tasks.id, tasks.focusSeconds])).get();
    return {for (final r in rows) r.read(tasks.id)!: r.read(tasks.focusSeconds) ?? 0};
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
    int? taskId,
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
      taskId: Value(taskId),
    ));
  }

  /// Sessions started on [day] (local date; today when null). The bounds are fixed when the stream is created, so
  /// callers that live across midnight pass the day explicitly (currentDayProvider).
  Stream<List<TimerSession>> watchTodayTimerSessions({DateTime? day, int dayStartHour = 0}) {
    final d = day ?? DateTime.now();
    final startOfDay = DateTime(d.year, d.month, d.day, dayStartHour);
    final endOfDay = DateTime(d.year, d.month, d.day + 1, dayStartHour);
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
    bool? autoStartNextPhase,
    int? dayStartHour,
    bool? weekStartsOnSunday,
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
        autoStartNextPhase: autoStartNextPhase != null ? Value(autoStartNextPhase) : const Value.absent(),
        dayStartHour: dayStartHour != null ? Value(dayStartHour) : const Value.absent(),
        weekStartsOnSunday: weekStartsOnSunday != null ? Value(weekStartsOnSunday) : const Value.absent(),
      );

      if (existing == null) {
        await into(deskPreferences).insert(companion);
      } else {
        await (update(deskPreferences)..where((t) => t.id.equals(existing.id))).write(companion);
      }
    });
  }

  /// Completed focus cycles ever (FocusSessionRules.isCompletedCycle: a timer session that ran to the end).
  Future<int> completedCycleCount() async {
    final count = timerSessions.id.count();
    final query = selectOnly(timerSessions)
      ..addColumns([count])
      ..where(timerSessions.isFinished.equals(true) & timerSessions.isLockdownOnly.equals(false));
    return (await query.getSingle()).read(count) ?? 0;
  }

  /// Whether the first-run walkthrough is behind us (finished, skipped, or an install from before v14).
  Future<bool> isOnboardingDone() async =>
      (await (select(deskPreferences)..limit(1)).getSingleOrNull())?.onboardingDone ?? false;

  Future<void> markOnboardingDone() {
    return transaction(() async {
      final existing = await (select(deskPreferences)..limit(1)).getSingleOrNull();
      const companion = DeskPreferencesCompanion(onboardingDone: Value(true));
      if (existing == null) {
        await into(deskPreferences).insert(companion);
      } else {
        await (update(deskPreferences)..where((t) => t.id.equals(existing.id))).write(companion);
      }
    });
  }

  Future<DateTime?> reviewAskedAt() async =>
      (await (select(deskPreferences)..limit(1)).getSingleOrNull())?.reviewAskedAt;

  Future<void> markReviewAsked(DateTime at) {
    return transaction(() async {
      final existing = await (select(deskPreferences)..limit(1)).getSingleOrNull();
      final companion = DeskPreferencesCompanion(reviewAskedAt: Value(at));
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
    bool? autoStartNextPhase,
    int? dayStartHour,
    bool? weekStartsOnSunday,
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
        autoStartNextPhase: autoStartNextPhase,
        dayStartHour: dayStartHour,
        weekStartsOnSunday: weekStartsOnSunday,
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
