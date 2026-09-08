import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/receipt_task.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_effect.dart';

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

  ReceiptRunnerController([this._audioService]) : super(const ReceiptRunnerState());

  bool get canAddTask => state.tasks.length < 5;

  void addTask(String title) {
    if (!canAddTask || title.trim().isEmpty) return;
    final newTask = ReceiptTask(
      id: '${DateTime.now().microsecondsSinceEpoch}_${state.tasks.length}',
      title: title.trim(),
    );
    state = state.copyWith(tasks: [...state.tasks, newTask]);
    HapticService.mechanicalPress();
    _audioService?.playFoley(SoundEffect.stepperPrint);
  }

  void stampDone(String id) {
    state = state.copyWith(
      tasks: state.tasks.map((t) => t.id == id ? t.copyWith(isDone: !t.isDone) : t).toList(),
    );
    HapticService.stampDone();
    _audioService?.playFoley(SoundEffect.inkStamp);
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
  }
}

final receiptRunnerProvider =
    StateNotifierProvider<ReceiptRunnerController, ReceiptRunnerState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return ReceiptRunnerController(audioService);
});

final receiptRunnerControllerProvider = receiptRunnerProvider;
