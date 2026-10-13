import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/receipt_task.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_effect.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';

void _logDbError(Object e) => debugPrint('ZYKL: task database write failed: $e');

class ReceiptRunnerState {
  final List<ReceiptTask> tasks;
  final List<ReceiptTask> archivedTasks;
  final double tearDragProgress; // 0.0 to 1.0
  final bool isArchiveOpen;

  /// Focus seconds per slip id (active and archived), kept current from the database.
  final Map<String, int> focusSecondsById;

  const ReceiptRunnerState({
    this.tasks = const [],
    this.archivedTasks = const [],
    this.tearDragProgress = 0.0,
    this.isArchiveOpen = false,
    this.focusSecondsById = const {},
  });

  /// Whole minutes focused on a slip (rounded), 0 when none.
  int focusMinutesOf(String id) => ((focusSecondsById[id] ?? 0) / 60).round();

  /// The slip the next focus session counts for: the top open (not stamped) slip.
  String? get currentTaskId => tasks.where((t) => !t.isDone).firstOrNull?.id;

  ReceiptRunnerState copyWith({
    List<ReceiptTask>? tasks,
    List<ReceiptTask>? archivedTasks,
    double? tearDragProgress,
    bool? isArchiveOpen,
    Map<String, int>? focusSecondsById,
  }) {
    return ReceiptRunnerState(
      tasks: tasks ?? this.tasks,
      archivedTasks: archivedTasks ?? this.archivedTasks,
      tearDragProgress: tearDragProgress ?? this.tearDragProgress,
      isArchiveOpen: isArchiveOpen ?? this.isArchiveOpen,
      focusSecondsById: focusSecondsById ?? this.focusSecondsById,
    );
  }
}

class ReceiptRunnerController extends StateNotifier<ReceiptRunnerState> {
  final AudioService? _audioService;
  final AppDatabase? _database;

  StreamSubscription<void>? _focusSubscription;

  ReceiptRunnerController([this._audioService, this._database])
      : super(const ReceiptRunnerState()) {
    final db = _database;
    if (db != null) {
      loadFromDatabase();
      loadArchivedTasks();
      // The timer adds focus time to slips; follow it so the minutes on the paper stay current.
      refreshFocusTimes();
      _focusSubscription = db.taskFocusChanges.listen((_) => refreshFocusTimes());
    }
  }

  Future<void> refreshFocusTimes() async {
    final db = _database;
    if (db == null) return;
    try {
      final byId = await db.taskFocusSeconds();
      if (!mounted) return;
      state = state.copyWith(focusSecondsById: {for (final e in byId.entries) '${e.key}': e.value});
    } catch (_) {}
  }

  @override
  void dispose() {
    _focusSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadArchivedTasks() async {
    final db = _database;
    if (db == null) return;
    try {
      final archived = await (db.select(db.tasks)
            ..where((t) => t.isArchived.equals(true))
            ..orderBy([
              (t) => OrderingTerm(expression: t.completedAt, mode: OrderingMode.desc),
              (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
            ]))
          .get();
      state = state.copyWith(
        archivedTasks: archived
            .map((t) => ReceiptTask(
                  id: t.id.toString(),
                  title: t.title,
                  isDone: t.isCompleted,
                  createdAt: t.createdAt,
                ))
            .toList(),
      );
    } catch (_) {}
  }

  /// Everything again from the database: after a restore wrote slips behind the dispenser's back.
  Future<void> reloadFromDatabase() async {
    await loadFromDatabase(reload: true);
    await loadArchivedTasks();
    await refreshFocusTimes();
  }

  Future<void> loadFromDatabase({bool reload = false}) async {
    final db = _database;
    if (db == null) return;
    try {
      final active = await (db.select(db.tasks)
            ..where((t) => t.isArchived.equals(false))
            ..orderBy([
              (t) => OrderingTerm(expression: t.sortOrder),
              (t) => OrderingTerm(expression: t.id),
            ]))
          .get();
      if (active.isNotEmpty || reload) {
        state = state.copyWith(
          tasks: active
              .map((t) => ReceiptTask(
                    id: t.id.toString(),
                    title: t.title,
                    isDone: t.isCompleted,
                    createdAt: t.createdAt,
                  ))
              .toList(),
        );
      }
    } catch (_) {}
  }

  bool get canAddTask => state.tasks.length < 5;

  Future<void> addTask(String title) async {
    if (!canAddTask || title.trim().isEmpty) return;
    final tempId = '${DateTime.now().microsecondsSinceEpoch}_${state.tasks.length}';
    final newTask = ReceiptTask(
      id: tempId,
      title: title.trim(),
    );
    state = state.copyWith(tasks: [...state.tasks, newTask]);
    HapticService.mechanicalPress();
    _audioService?.playFoley(SoundEffect.stepperPrint);

    final db = _database;
    if (db != null) {
      try {
        final insertedId = await db.addTask(title.trim());
        state = state.copyWith(
          tasks: state.tasks
              .map((t) => t.id == tempId ? t.copyWith(id: insertedId.toString()) : t)
              .toList(),
        );
      } catch (_) {}
    }
  }

  void stampDone(String id) {
    state = state.copyWith(
      tasks: state.tasks.map((t) => t.id == id ? t.copyWith(isDone: !t.isDone) : t).toList(),
    );
    HapticService.stampDone();
    _audioService?.playFoley(SoundEffect.inkStamp);

    if (_database != null) {
      final intId = int.tryParse(id);
      if (intId != null) {
        final task = state.tasks.where((t) => t.id == id).firstOrNull;
        if (task != null) {
          _database.toggleTaskCompleted(intId, task.isDone).catchError(_logDbError);
        }
      }
    }
  }

  /// A task checked off on the home-screen widget while the app is open. The widget already wrote the row
  /// natively; this mirrors it into the in-memory list (no stamp sound) and rewrites it through Drift so the
  /// active-task stream, and with it the next widget sync, see the same state instead of reverting it.
  void applyExternalCompletion(String id, bool isDone) {
    final index = state.tasks.indexWhere((t) => t.id == id);
    if (index < 0) return;
    if (state.tasks[index].isDone != isDone) {
      state = state.copyWith(
        tasks: [for (final t in state.tasks) t.id == id ? t.copyWith(isDone: isDone) : t],
      );
    }
    final intId = int.tryParse(id);
    if (intId != null) {
      _database?.toggleTaskCompleted(intId, isDone).catchError(_logDbError);
    }
  }

  void updateTearProgress(double progress) {
    state = state.copyWith(tearDragProgress: progress.clamp(0.0, 1.0));
  }

  void tearTask(String id) {
    final tornTask = state.tasks.where((t) => t.id == id).firstOrNull;
    state = state.copyWith(
      tasks: state.tasks.where((t) => t.id != id).toList(),
      archivedTasks: tornTask != null ? [tornTask, ...state.archivedTasks] : state.archivedTasks,
      tearDragProgress: 0.0,
    );
    HapticService.paperTorn();
    _audioService?.playFoley(SoundEffect.paperTear);

    if (_database != null) {
      final intId = int.tryParse(id);
      if (intId != null) {
        _database.archiveTask(intId).catchError(_logDbError);
      }
    }
  }

  void toggleArchiveDrawer() {
    final nextOpen = !state.isArchiveOpen;
    state = state.copyWith(isArchiveOpen: nextOpen);
    HapticService.mechanicalPress();
    _audioService?.playFoley(
      nextOpen ? SoundEffect.drawerSlide : SoundEffect.drawerLatch,
    );
    if (nextOpen) {
      loadArchivedTasks();
    }
  }

  Future<void> reprintTask(ReceiptTask task) async {
    if (!canAddTask) return;
    await addTask(task.title);
  }

  Future<void> deleteArchivedTask(String id) async {
    state = state.copyWith(
      archivedTasks: state.archivedTasks.where((t) => t.id != id).toList(),
    );
    final db = _database;
    if (db != null) {
      final intId = int.tryParse(id);
      if (intId != null) {
        await db.deleteTask(intId).catchError(_logDbError);
      }
    }
  }

  @override
  set state(ReceiptRunnerState value) => super.state = value;

  Future<void> purgeTasks(List<ReceiptTask> tasksToPurge) async {
    final idsToPurge = tasksToPurge.map((t) => t.id).toSet();
    state = state.copyWith(
      archivedTasks: state.archivedTasks.where((t) => !idsToPurge.contains(t.id)).toList(),
    );
    final db = _database;
    if (db != null) {
      for (final task in tasksToPurge) {
        final intId = int.tryParse(task.id);
        if (intId != null) {
          await db.deleteTask(intId).catchError(_logDbError);
        }
      }
    }
  }

  Future<void> clearArchive() async {
    state = state.copyWith(archivedTasks: const []);
    final db = _database;
    if (db != null) {
      await db.clearArchivedTasks().catchError(_logDbError);
    }
  }
}

final receiptRunnerProvider =
    StateNotifierProvider<ReceiptRunnerController, ReceiptRunnerState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  final database = ref.watch(appDatabaseProvider);
  return ReceiptRunnerController(audioService, database);
});

final receiptRunnerControllerProvider = receiptRunnerProvider;
