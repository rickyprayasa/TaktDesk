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
    bool autoStartNext = false,
    int? sessionId,
  }) async {
    try {
      final res = await channel.invokeMethod<bool>('startService', {
        'remainingSeconds': remainingSeconds,
        'targetMinutes': targetMinutes,
        'phase': phase.name,
        'cycleCount': cycleCount,
        'profileName': profileName,
        'alarmChimeId': alarmChimeId,
        'autoStartNext': autoStartNext,
        if (sessionId != null) 'sessionId': sessionId,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Remaining time of the native session measured on Android's boot-time
  /// clock (immune to wall-clock changes, counts through deep sleep).
  /// Null when no native session ran in this process or on other platforms.
  /// Negative when the session already finished (native rang the alarm).
  Future<NativeTimerStatus?> status() async {
    try {
      final res = await channel.invokeMapMethod<String, Object?>('getRemainingMillis');
      if (res == null) return null;
      final millis = res['remainingMillis'];
      if (millis is! num) return null;
      final sessionId = res['sessionId'];
      return NativeTimerStatus(
        remainingSeconds: millis / 1000.0,
        running: res['running'] == true,
        sessionId: sessionId is int && sessionId != 0 ? sessionId : null,
      );
    } catch (_) {
      return null;
    }
  }

  /// Focus sessions the native service completed while Flutter was not
  /// running (app closed). Returned once, then cleared natively.
  Future<List<({DateTime startedAt, int targetMinutes})>> takePendingSessions() async {
    try {
      final raw = await channel.invokeListMethod<String>('takePendingSessions') ?? const [];
      final out = <({DateTime startedAt, int targetMinutes})>[];
      for (final entry in raw) {
        final parts = entry.split(',');
        if (parts.length != 2) continue;
        final start = int.tryParse(parts[0]);
        final target = int.tryParse(parts[1]);
        if (start == null || target == null || target <= 0) continue;
        out.add((startedAt: DateTime.fromMillisecondsSinceEpoch(start), targetMinutes: target));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// Shows a paused session as a notification (lock screen too) with RESUME / STOP buttons. Android only; the
  /// running countdown notification goes away with [stop], this one stays until [clearPaused] or RESUME.
  Future<void> showPaused({
    required double remainingSeconds,
    required int targetMinutes,
    required PomodoroPhase phase,
    required int cycleCount,
    required String profileName,
    String alarmChimeId = 'braunBell',
  }) async {
    try {
      await channel.invokeMethod<bool>('showPausedNotification', {
        'remainingSeconds': remainingSeconds,
        'targetMinutes': targetMinutes,
        'phase': phase.name,
        'cycleCount': cycleCount,
        'profileName': profileName,
        'alarmChimeId': alarmChimeId,
      });
    } catch (_) {}
  }

  Future<void> clearPaused() async {
    try {
      await channel.invokeMethod<bool>('clearPausedNotification');
    } catch (_) {}
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

class NativeTimerStatus {
  final double remainingSeconds;
  final bool running;

  /// The countdown this status describes (the id sent with start), null when unknown.
  final int? sessionId;

  const NativeTimerStatus({required this.remainingSeconds, required this.running, this.sessionId});
}
