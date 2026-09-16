import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/timer/domain/pomodoro_phase.dart';

final timerBackgroundServiceProvider = Provider<TimerBackgroundService>((ref) {
  return const TimerBackgroundService();
});

class TimerBackgroundService {
  static const MethodChannel channel =
      MethodChannel('com.takt.desk/timer_service');

  const TimerBackgroundService();

  Future<bool> start({
    required double remainingSeconds,
    required int targetMinutes,
    required PomodoroPhase phase,
    required int cycleCount,
    required String profileName,
    String alarmChimeId = 'braunBell',
  }) async {
    try {
      final res = await channel.invokeMethod<bool>('startService', {
        'remainingSeconds': remainingSeconds,
        'targetMinutes': targetMinutes,
        'phase': phase.name,
        'cycleCount': cycleCount,
        'profileName': profileName,
        'alarmChimeId': alarmChimeId,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> stop() async {
    try {
      final res = await channel.invokeMethod<bool>('stopService');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
