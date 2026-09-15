import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../../features/settings/presentation/settings_controller.dart';
import '../../features/timer/presentation/chrono_dial_controller.dart';

final appWidgetServiceProvider = Provider<AppWidgetService>((ref) {
  return const AppWidgetService();
});

final activeTasksStreamProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchActiveTasks();
});

final appWidgetSyncProvider = Provider.autoDispose<void>((ref) {
  final widgetService = ref.watch(appWidgetServiceProvider);

  void sync() {
    final statsAsync = ref.read(todayFocusStatsProvider);
    final state = ref.read(chronoDialControllerProvider);
    final tasksAsync = ref.read(activeTasksStreamProvider);
    final status = state.isRunning ? (state.isBreak ? 'BREAK' : 'FOCUS') : 'STANDBY';

    statsAsync.whenData((stats) {
      final completedCount = stats.completedCount;
      final cycles = (completedCount > 0 && completedCount % 4 == 0)
          ? 4
          : (completedCount % 4);

      final activeTasks = tasksAsync.valueOrNull ?? const <Task>[];
      final tasks = activeTasks
          .take(5)
          .map((t) => {
                'id': t.id,
                'title': t.title,
                'is_completed': t.isCompleted,
              })
          .toList();

      widgetService.updateAllWidgetData(
        cyclesCompleted: cycles,
        cyclesTarget: 4,
        minutesFocused: stats.totalMinutes,
        status: status,
        remainingSeconds: state.remainingSeconds.round(),
        targetMinutes: state.targetMinutes,
        tasks: tasks,
      );
    });
  }

  ref.listen(todayFocusStatsProvider, (_, __) => sync(), fireImmediately: true);
  ref.listen(activeTasksStreamProvider, (_, __) => sync());
  ref.listen(chronoDialControllerProvider.select((state) {
    if (state.isRunning) return state.isBreak ? 'BREAK' : 'FOCUS';
    return 'STANDBY';
  }), (_, __) => sync());
});

class AppWidgetService {
  static const MethodChannel channel = MethodChannel('com.takt.desk/app_widget');

  const AppWidgetService();

  Future<bool> updateWidgetData({
    required int cyclesCompleted,
    required int cyclesTarget,
    required int minutesFocused,
    required String status,
  }) async {
    try {
      final res = await channel.invokeMethod<bool>('updateWidgetData', {
        'cyclesCompleted': cyclesCompleted,
        'cyclesTarget': cyclesTarget,
        'minutesFocused': minutesFocused,
        'status': status,
      });
      return res ?? false;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateAllWidgetData({
    required int cyclesCompleted,
    required int cyclesTarget,
    required int minutesFocused,
    required String status,
    required int remainingSeconds,
    required int targetMinutes,
    required List<Map<String, dynamic>> tasks,
  }) async {
    try {
      final res = await channel.invokeMethod<bool>('updateAllWidgetData', {
        'cyclesCompleted': cyclesCompleted,
        'cyclesTarget': cyclesTarget,
        'minutesFocused': minutesFocused,
        'status': status,
        'remainingSeconds': remainingSeconds,
        'targetMinutes': targetMinutes,
        'tasks': tasks,
      });
      return res ?? false;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
