import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/audio/sound_effect.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/tasks/domain/receipt_task.dart';
import 'package:takt_desk/features/tasks/presentation/receipt_runner_controller.dart';

class MockAudioService extends AudioService {
  final List<SoundEffect> playedEffects = [];

  MockAudioService() : super(isMock: true);

  @override
  bool get isInitialized => true;

  @override
  void playFoley(SoundEffect effect) {
    playedEffects.add(effect);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('ReceiptTask domain', () {
    test('ReceiptTask initializes with defaults and copyWith works', () {
      final task = ReceiptTask(id: 't-1', title: 'Deep Work');
      expect(task.id, 't-1');
      expect(task.title, 'Deep Work');
      expect(task.isDone, isFalse);
      expect(task.createdAt, isNotNull);

      final completed = task.copyWith(isDone: true);
      expect(completed.id, 't-1');
      expect(completed.title, 'Deep Work');
      expect(completed.isDone, isTrue);
      expect(completed.createdAt, task.createdAt);
    });
  });

  group('ReceiptRunnerController', () {
    test('TaskRunner restricts max 5 items and handles stamp & tear', () {
      final controller = ReceiptRunnerController();
      for (int i = 1; i <= 5; i++) {
        controller.addTask('Task $i');
      }
      expect(controller.state.tasks.length, 5);
      expect(controller.canAddTask, isFalse);

      // Stamp done
      final taskId = controller.state.tasks.first.id;
      controller.stampDone(taskId);
      expect(controller.state.tasks.first.isDone, isTrue);

      // Tear paper
      controller.tearTask(taskId);
      expect(controller.state.tasks.length, 4);
      expect(controller.canAddTask, isTrue);
    });

    test('ignores blank or whitespace-only task titles', () {
      final controller = ReceiptRunnerController();
      controller.addTask('');
      controller.addTask('   ');
      expect(controller.state.tasks, isEmpty);
      expect(controller.canAddTask, isTrue);
    });

    test('does not add beyond 5 tasks', () {
      final controller = ReceiptRunnerController();
      for (int i = 1; i <= 5; i++) {
        controller.addTask('Task $i');
      }
      expect(controller.state.tasks.length, 5);
      expect(controller.canAddTask, isFalse);

      controller.addTask('Task 6');
      expect(controller.state.tasks.length, 5);
      expect(controller.state.tasks.last.title, 'Task 5');
    });

    test('stampDone toggles completed status back and forth', () {
      final controller = ReceiptRunnerController();
      controller.addTask('Review Spec');
      final id = controller.state.tasks.first.id;

      controller.stampDone(id);
      expect(controller.state.tasks.first.isDone, isTrue);

      controller.stampDone(id);
      expect(controller.state.tasks.first.isDone, isFalse);
    });

    test('updateTearProgress clamps between 0.0 and 1.0', () {
      final controller = ReceiptRunnerController();
      controller.updateTearProgress(0.5);
      expect(controller.state.tearDragProgress, 0.5);

      controller.updateTearProgress(-0.2);
      expect(controller.state.tearDragProgress, 0.0);

      controller.updateTearProgress(1.4);
      expect(controller.state.tearDragProgress, 1.0);
    });

    test('plays stepperPrint, inkStamp, and paperTear foley via AudioService', () {
      final mockAudio = MockAudioService();
      final controller = ReceiptRunnerController(mockAudio);

      controller.addTask('Foley Task');
      expect(mockAudio.playedEffects, contains(SoundEffect.stepperPrint));

      final id = controller.state.tasks.first.id;
      controller.stampDone(id);
      expect(mockAudio.playedEffects, contains(SoundEffect.inkStamp));

      controller.tearTask(id);
      expect(mockAudio.playedEffects, contains(SoundEffect.paperTear));
      expect(controller.state.tearDragProgress, 0.0);
    });

    test('synchronizes addTask, stampDone, and tearTask with AppDatabase', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final controller = ReceiptRunnerController(null, db);
      addTearDown(controller.dispose);

      await controller.addTask('Database Task');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.state.tasks.length, 1);
      final taskId = controller.state.tasks.first.id;
      expect(controller.state.tasks.first.title, 'Database Task');

      controller.stampDone(taskId);
      await Future.delayed(const Duration(milliseconds: 50));
      final dbTasks = await db.watchActiveTasks().first;
      expect(dbTasks.first.isCompleted, isTrue);

      controller.tearTask(taskId);
      await Future.delayed(const Duration(milliseconds: 50));
      final dbTasksAfterTear = await db.watchActiveTasks().first;
      expect(dbTasksAfterTear, isEmpty);
      expect(controller.state.tasks, isEmpty);
    });
  });
}
