import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// Today's date (local midnight). Moves on at the next local midnight and whenever the app returns to the
/// foreground on a new day, so "today" stats, the telemetry slip and the widgets roll over even when the app stays
/// open overnight (desk clock mode). Watch it in anything that filters by "today".
final currentDayProvider = StateNotifierProvider<CurrentDayController, DateTime>((ref) {
  return CurrentDayController();
});

class CurrentDayController extends StateNotifier<DateTime> {
  CurrentDayController() : super(dayOf(clock.now())) {
    _schedule();
    try {
      _lifecycle = AppLifecycleListener(onResume: refresh);
    } catch (_) {
      // No widgets binding (plain unit tests): midnight timer only.
    }
  }

  Timer? _timer;
  AppLifecycleListener? _lifecycle;

  /// Re-reads the clock (a resume after midnight, or the midnight timer).
  void refresh() {
    if (!mounted) return;
    final today = dayOf(clock.now());
    if (today != state) state = today;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    final now = clock.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    // A second past midnight, so the new day is certain.
    _timer = Timer(next.difference(now) + const Duration(seconds: 1), refresh);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }
}
