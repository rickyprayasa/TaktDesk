import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/presentation/settings_controller.dart';

DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// The day a moment belongs to when days start at [startHour] (0..6): 01:30 with a 4 am start still counts for the
/// previous day. Calendar arithmetic, so DST days are fine.
DateTime logicalDay(DateTime t, int startHour) {
  if (startHour == 0) return dayOf(t);
  final shifted = DateTime(t.year, t.month, t.day, t.hour - startHour, t.minute, t.second);
  return dayOf(shifted);
}

/// The first moment of logical [day] (its start hour on that calendar date).
DateTime dayStartOf(DateTime day, int startHour) => DateTime(day.year, day.month, day.day, startHour);

/// Today's date (local midnight). Moves on at the next local midnight and whenever the app returns to the
/// foreground on a new day, so "today" stats, the telemetry slip and the widgets roll over even when the app stays
/// open overnight (desk clock mode). Watch it in anything that filters by "today".
final currentDayProvider = StateNotifierProvider<CurrentDayController, DateTime>((ref) {
  final startHour = ref.watch(deskPreferencesControllerProvider.select((p) => p.dayStartHour));
  return CurrentDayController(startHour: startHour);
});

class CurrentDayController extends StateNotifier<DateTime> {
  CurrentDayController({this.startHour = 0}) : super(logicalDay(clock.now(), startHour)) {
    _schedule();
    try {
      _lifecycle = AppLifecycleListener(onResume: refresh);
    } catch (_) {
      // No widgets binding (plain unit tests): midnight timer only.
    }
  }

  /// Hour the day changes at (Settings → DAY STARTS AT).
  final int startHour;
  Timer? _timer;
  AppLifecycleListener? _lifecycle;

  /// Re-reads the clock (a resume after midnight, or the midnight timer).
  void refresh() {
    if (!mounted) return;
    final today = logicalDay(clock.now(), startHour);
    if (today != state) state = today;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    final now = clock.now();
    final current = logicalDay(now, startHour);
    final next = dayStartOf(DateTime(current.year, current.month, current.day + 1), startHour);
    // A second past the change of day, so the new day is certain.
    _timer = Timer(next.difference(now) + const Duration(seconds: 1), refresh);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }
}
