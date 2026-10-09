import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../../features/settings/presentation/settings_controller.dart';
import '../../features/tasks/presentation/receipt_runner_controller.dart';
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
    final isPro = ref.read(deskPreferencesControllerProvider).isProSimulated;
    final status = state.isRunning ? (state.isBreak ? 'BREAK' : 'FOCUS') : 'STANDBY';

    statsAsync.whenData((stats) {
      final prefs = ref.read(deskPreferencesControllerProvider);

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
        // Today's cycles against the user's daily goal; the 4 widget LEDs show the share (TaktAppWidgetProvider.litLeds).
        cyclesCompleted: stats.completedCount,
        cyclesTarget: prefs.dailyGoalCycles,
        minutesFocused: stats.totalMinutes,
        status: status,
        remainingSeconds: state.remainingSeconds.round(),
        targetMinutes: state.targetMinutes,
        tasks: tasks,
        isPro: isPro,
        profileName: state.profile.label,
        alarmChimeId: prefs.alarmChimeId,
        cycleCount: state.cycleCount,
      );
    });
  }

  ref.listen(todayFocusStatsProvider, (_, __) => sync(), fireImmediately: true);
  ref.listen(activeTasksStreamProvider, (_, __) => sync());
  ref.listen(deskPreferencesControllerProvider.select((s) => s.isProSimulated), (_, __) => sync());
  ref.listen(chronoDialControllerProvider.select((s) => s.isRunning), (_, __) => sync());
  ref.listen(chronoDialControllerProvider.select((s) => s.targetMinutes), (_, __) => sync());
  ref.listen(chronoDialControllerProvider.select((s) => s.isBreak), (_, __) => sync());
  ref.listen(deskPreferencesControllerProvider.select((s) => (s.dailyGoalCycles, s.alarmChimeId)), (_, __) => sync());
  ref.listen(chronoDialControllerProvider.select((s) => (s.profile, s.cycleCount)), (_, __) => sync());

  // Listen for direct interactive widget actions from Android homescreen
  // and from the timer notification buttons (PAUSE / STOP while running, RESUME / STOP on the paused card).
  final actionSub = widgetService.onWidgetAction.listen((action) {
    final timer = ref.read(chronoDialControllerProvider.notifier);
    final running = ref.read(chronoDialControllerProvider).isRunning;
    switch (action) {
      case 'toggleTimer':
        running ? timer.pause() : timer.start();
      case 'pauseTimer':
        if (running) timer.pause();
      case 'resumeTimer':
        if (!running) timer.start();
      case 'stopTimer':
        timer.reset();
    }
  });
  ref.onDispose(actionSub.cancel);

  // A slip checked off on the Task Dispenser widget while the app is running.
  final taskSub = widgetService.onWidgetTaskToggle.listen((toggle) {
    ref.read(receiptRunnerProvider.notifier).applyExternalCompletion('${toggle.taskId}', toggle.isCompleted);
  });
  ref.onDispose(taskSub.cancel);
});

class AppWidgetService {
  static const MethodChannel channel = MethodChannel('com.takt.desk/app_widget');
  static final StreamController<String> _actionController =
      StreamController<String>.broadcast();
  static final StreamController<({int taskId, bool isCompleted})> _taskToggleController =
      StreamController<({int taskId, bool isCompleted})>.broadcast();
  static bool _handlerInitialized = false;

  const AppWidgetService();

  static void _ensureHandler() {
    if (_handlerInitialized) return;
    _handlerInitialized = true;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetAction') {
        final args = call.arguments;
        final action = args is Map ? args['action'] as String? : null;
        if (action != null && action.isNotEmpty) {
          _actionController.add(action);
        }
        if (action == 'toggleTask' && args is Map) {
          final taskId = args['taskId'];
          final isCompleted = args['isCompleted'];
          if (taskId is int && taskId >= 0 && isCompleted is bool) {
            _taskToggleController.add((taskId: taskId, isCompleted: isCompleted));
          }
        }
      }
    });
  }

  Stream<String> get onWidgetAction {
    _ensureHandler();
    return _actionController.stream;
  }

  /// Task check-offs made on the home-screen widget (the row is already written natively).
  Stream<({int taskId, bool isCompleted})> get onWidgetTaskToggle {
    _ensureHandler();
    return _taskToggleController.stream;
  }

  Future<String?> getInitialAction() async {
    try {
      final res = await channel.invokeMethod<String>('getInitialAction');
      return res;
    } on PlatformException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

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
    required bool isPro,
    String profileName = 'CLASSIC 25/5',
    String alarmChimeId = 'braunBell',
    int cycleCount = 1,
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
        'isPro': isPro,
        'profileName': profileName,
        'alarmChimeId': alarmChimeId,
        'cycleCount': cycleCount,
      });
      return res ?? false;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
