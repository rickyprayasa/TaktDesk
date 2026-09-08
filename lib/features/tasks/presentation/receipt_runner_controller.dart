import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/receipt_task.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_effect.dart';
import '../../../core/database/app_database.dart';

class ReceiptRunnerState {
  final List<ReceiptTask> tasks;
  final double tearDragProgress; // 0.0 to 1.0

  const ReceiptRunnerState({
    this.tasks = const [],
    this.tearDragProgress = 0.0,
  });

  ReceiptRunnerState copyWith({
    List<ReceiptTask>? tasks,
    double? tearDragProgress,
  }) {
    return ReceiptRunnerState(
      tasks: tasks ?? this.tasks,
      tearDragProgress: tearDragProgress ?? this.tearDragProgress,
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
    }
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
    state = state.copyWith(
      tasks: state.tasks.where((t) => t.id != id).toList(),
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
}

final receiptRunnerProvider =
    StateNotifierProvider<ReceiptRunnerController, ReceiptRunnerState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  final database = ref.watch(appDatabaseProvider);
  return ReceiptRunnerController(audioService, database);
});

final receiptRunnerControllerProvider = receiptRunnerProvider;
