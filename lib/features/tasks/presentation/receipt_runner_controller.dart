import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/receipt_task.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_effect.dart';
import '../../../core/database/app_database.dart';

class ReceiptRunnerState {
  final List<ReceiptTask> tasks;
  final List<ReceiptTask> archivedTasks;
  final double tearDragProgress; // 0.0 to 1.0
  final bool isArchiveOpen;

  const ReceiptRunnerState({
    this.tasks = const [],
    this.archivedTasks = const [],
    this.tearDragProgress = 0.0,
    this.isArchiveOpen = false,
  });

  ReceiptRunnerState copyWith({
    List<ReceiptTask>? tasks,
    List<ReceiptTask>? archivedTasks,
    double? tearDragProgress,
    bool? isArchiveOpen,
  }) {
    return ReceiptRunnerState(
      tasks: tasks ?? this.tasks,
      archivedTasks: archivedTasks ?? this.archivedTasks,
      tearDragProgress: tearDragProgress ?? this.tearDragProgress,
      isArchiveOpen: isArchiveOpen ?? this.isArchiveOpen,
    );
  }
}

class ReceiptRunnerController extends StateNotifier<ReceiptRunnerState> {
  final AudioService? _audioService;
  final AppDatabase? _database;

  ReceiptRunnerController([this._audioService, this._database])
      : super(const ReceiptRunnerState()) {
    if (_database != null) {
      loadFromDatabase();
      loadArchivedTasks();
    }
  }

  Future<void> loadArchivedTasks() async {
    final db = _database;
    if (db == null) return;
    try {
      final archived = await db.watchArchivedTasks().first;
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

  Future<void> loadFromDatabase() async {
    final db = _database;
    if (db == null) return;
    try {
      final active = await db.watchActiveTasks().first;
      if (active.isNotEmpty) {
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
          _database.toggleTaskCompleted(intId, task.isDone).catchError((_) {});
        }
      }
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
        _database.archiveTask(intId).catchError((_) {});
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
        await db.deleteTask(intId).catchError((_) {});
      }
    }
  }

  Future<void> clearArchive() async {
    state = state.copyWith(archivedTasks: const []);
    final db = _database;
    if (db != null) {
      await db.clearArchivedTasks().catchError((_) {});
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
