import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/presentation/settings_controller.dart';
import '../../features/timer/presentation/chrono_dial_controller.dart';

final appWidgetServiceProvider = Provider<AppWidgetService>((ref) {
  return const AppWidgetService();
});

final appWidgetSyncProvider = Provider.autoDispose<void>((ref) {
  final widgetService = ref.watch(appWidgetServiceProvider);

  void sync() {
    final statsAsync = ref.read(todayFocusStatsProvider);
    final state = ref.read(chronoDialControllerProvider);
    final status = state.isRunning ? (state.isBreak ? 'BREAK' : 'FOCUS') : 'STANDBY';

    statsAsync.whenData((stats) {
      final completedCount = stats.completedCount;
      final cycles = (completedCount > 0 && completedCount % 4 == 0)
          ? 4
          : (completedCount % 4);

      widgetService.updateWidgetData(
        cyclesCompleted: cycles,
        cyclesTarget: 4,
        minutesFocused: stats.totalMinutes,
        status: status,
      );
    });
  }

  ref.listen(todayFocusStatsProvider, (_, __) => sync(), fireImmediately: true);
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
}
