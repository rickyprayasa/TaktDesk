// All promo clips, one testWidgets per clip. Run ONE at a time, memory-capped:
//
//   systemd-run --user --scope -p MemoryMax=4000M -p MemorySwapMax=512M -p CPUQuota=200% \
//     nice -n 19 flutter test film_capture/clips_test.dart --plain-name 'clip pomo dark' \
//     --dart-define=FILM_DIR=$HOME/.cache/zykl-film/frames
//
// Output: $FILM_DIR/<clip>_<theme>/NNNN.png + touches.json. Use FILM_PR=1 for a fast smoke run.
// Every step asserts the app state, so a gesture that misses fails loudly
// instead of silently recording the wrong thing.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/core/focus/focus_lock_controller.dart';
import 'package:takt_desk/features/analytics/presentation/widgets/focus_analytics_dialog.dart';
import 'package:takt_desk/features/desk/presentation/desk_canvas_screen.dart';
import 'package:takt_desk/features/desk/presentation/widgets/emergency_unlatch_widget.dart';
import 'package:takt_desk/features/desk/presentation/widgets/monastic_switch_widget.dart';
import 'package:takt_desk/features/opening/presentation/takt_opening_screen.dart';
import 'package:takt_desk/features/tasks/presentation/receipt_runner_controller.dart';
import 'package:takt_desk/features/tasks/presentation/widgets/animated_receipt_strip.dart';
import 'package:takt_desk/features/timer/domain/timer_state.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';
import 'package:takt_desk/features/vinyl/domain/vinyl_track.dart';
import 'package:takt_desk/features/vinyl/presentation/vinyl_controller.dart';

import 'film_scene.dart';

const _dir = String.fromEnvironment('FILM_DIR', defaultValue: '/tmp/zykl_film');
String _out(String clip, bool dark) => '$_dir/${clip}_${dark ? 'dark' : 'light'}';

void main() {
  for (final dark in [true, false]) {
    final th = dark ? 'dark' : 'light';

    // Opening: the cinematic 4.2 s boot and the hand-off to the desk.
    testWidgets('clip opening $th', (t) => FilmScene.run(t, out: _out('opening', dark), dark: dark,
        home: () => const TaktOpeningScreen(), script: (s) async {
      await s.hold(5.8);
      expect(find.byType(DeskCanvasScreen), findsOneWidget, reason: 'handed over to the desk');
    }));

    // Pomodoro: press the crown, the escapement ticks.
    testWidgets('clip pomo $th', (t) => FilmScene.run(t, out: _out('pomo', dark), dark: dark, script: (s) async {
      await s.hold(1.2);
      await s.tap(s.crown);
      expect(s.read(chronoDialProvider).isRunning, isTrue);
      await s.hold(6.0);
    }));

    // Crown: custom rhythm set with the crown and the dial alone.
    testWidgets('clip crown $th', (t) => FilmScene.run(t, out: _out('crown', dark), dark: dark, script: (s) async {
      final chrono = s.read(chronoDialProvider.notifier);
      chrono.setProfile(s.read(chronoDialProvider).customProfile);
      await s.hold(1.0);
      await s.pullCrown();
      expect(s.read(chronoDialProvider).setupStage, ChronoSetupStage.focus, reason: 'crown pull');
      await s.hold(0.6);
      await s.wind(s.read(chronoDialProvider).targetMinutes.toDouble(), 40, 1.6);
      expect(s.read(chronoDialProvider).targetMinutes, 40);
      await s.hold(0.5);
      await s.tap(s.dialCenter + const Offset(0, 40));
      expect(s.read(chronoDialProvider).setupStage, ChronoSetupStage.shortBreak);
      await s.hold(0.5);
      await s.wind(s.read(chronoDialProvider).targetMinutes.toDouble(), 8, 1.0);
      await s.hold(0.4);
      await s.tap(s.dialCenter + const Offset(0, 40));
      expect(s.read(chronoDialProvider).setupStage, ChronoSetupStage.longBreak);
      await s.hold(0.5);
      await s.wind(s.read(chronoDialProvider).targetMinutes.toDouble(), 20, 1.0);
      await s.hold(0.4);
      await s.tap(s.dialCenter + const Offset(0, 40));
      expect(s.read(chronoDialProvider).setupStage, ChronoSetupStage.none);
      expect(s.read(chronoDialProvider).profile.focusMinutes, 40);
      await s.hold(0.9);
      await s.tap(s.crown);
      expect(s.read(chronoDialProvider).isRunning, isTrue);
      await s.hold(2.0);
    }));

    // Lockdown: engage while focusing, then hold the unlatch for 5 s.
    testWidgets('clip lock $th', (t) => FilmScene.run(t, out: _out('lock', dark), dark: dark, script: (s) async {
      await s.act(() => s.read(chronoDialProvider.notifier).start());
      await s.hold(1.0);
      await s.tapFinder(find.byType(MonasticSwitchWidget));
      await s.hold(0.3);
      expect(s.read(focusLockProvider).isLocked, isTrue, reason: 'locked');
      await s.hold(1.6);
      await s.pressHold(s.tester.getCenter(find.byType(EmergencyUnlatchWidget)), 5.25);
      await s.hold(0.4);
      expect(s.read(focusLockProvider).isLocked, isFalse, reason: 'released');
      await s.hold(1.0);
    }));

    // Dispenser: three tasks print, the first is stamped DONE, then torn off.
    testWidgets('clip disp $th', (t) => FilmScene.run(t, out: _out('disp', dark), dark: dark, script: (s) async {
      await s.tab('TASKS');
      await s.hold(0.8);
      final runner = s.read(receiptRunnerProvider.notifier);
      for (final title in ['Finish the UI design', 'Reply to the studio', 'Read 20 pages']) {
        await s.act(() => s.tester.runAsync(() => runner.addTask(title)));
        await s.hold(1.1);
      }
      final first = s.read(receiptRunnerProvider).tasks.first;
      expect(s.read(receiptRunnerProvider).tasks, hasLength(3));
      await s.act(() => runner.stampDone(first.id));
      await s.hold(1.4);
      final strip = s.tester.getRect(find.byType(AnimatedReceiptStrip).first);
      await s.drag(strip.center, strip.center + Offset(strip.width * 0.9, 0), 0.45);
      await s.hold(1.4);
    }));

    // Vinyl: open the drawer, load a record, drop the needle.
    testWidgets('clip vinyl $th', (t) => FilmScene.run(t, out: _out('vinyl', dark), dark: dark, script: (s) async {
      await s.tab('VINYL');
      await s.hold(0.8);
      final vinyl = s.read(vinylProvider.notifier);
      // The record drawer keeps its open state locally: drive it like a user.
      await s.tapFinder(find.byKey(const ValueKey('vinyl_drawer_1_handle')));
      await s.hold(1.0);
      await s.tapFinder(find.byKey(const ValueKey('drawer_1_next_disc')));
      await s.hold(0.6);
      // Second drawer: the piano records
      await s.tapFinder(find.text('02 · HARMONICS'));
      await s.hold(0.9);
      final piano = VinylTrack.drawer2Presets.first;
      await s.tapFinder(find.byKey(ValueKey('load_track_button_${piano.index}')));
      expect(s.read(vinylProvider).selectedTrackIndex, piano.index, reason: 'piano loaded');
      await s.hold(0.9);
      await s.tapFinder(find.byKey(const ValueKey('vinyl_drawer_1_handle')));
      await s.hold(0.8);
      await s.act(vinyl.dropNeedle);
      expect(s.read(vinylProvider).needleOnRecord, isTrue);
      await s.hold(3.2);
    }));

    // Analytics: a week of real-looking history, goal met, 6-day streak.
    testWidgets('clip anal $th', (t) => FilmScene.run(t, out: _out('anal', dark), dark: dark,
        seed: _seedHistory, script: (s) async {
      await s.hold(0.6);
      // Not awaited: show() completes only when the dialog closes.
      unawaited(FocusAnalyticsDialog.show(s.tester.element(find.byType(DeskCanvasScreen))));
      await s.hold(2.6);
      await s.tapFinder(find.text('MONTH'));
      await s.hold(1.8);
      await s.tapFinder(find.text('WEEK'));
      await s.hold(1.2);
    }));
  }

  // Editions: each finish in its own light, the dial running.
  for (final e in [
    (HardwareEditionType.bauhausHeritage, false, 'bauhaus'),
    (HardwareEditionType.midCenturyWalnut, true, 'walnut'),
    (HardwareEditionType.rawBrassPatina, true, 'brass'),
    (HardwareEditionType.titaniumStealth, true, 'titanium'),
  ]) {
    testWidgets('clip edition ${e.$3}', (t) => FilmScene.run(t, out: '$_dir/edition_${e.$3}', dark: e.$2,
        edition: e.$1, script: (s) async {
      await s.act(() => s.read(chronoDialProvider.notifier).start());
      await s.hold(5.0);
    }));
  }
}

/// Six days in a row with completed cycles, today's goal met.
Future<void> _seedHistory(AppDatabase db, DateTime now) async {
  final cyclesPerDay = [3, 4, 2, 5, 4, 3, 4]; // oldest -> today
  for (var d = 0; d < cyclesPerDay.length; d++) {
    final day = DateTime(now.year, now.month, now.day - (cyclesPerDay.length - 1 - d));
    for (var c = 0; c < cyclesPerDay[d]; c++) {
      await db.recordTimerSession(
        targetMinutes: 25,
        elapsedSeconds: 25 * 60,
        isFinished: true,
        startedAt: day.add(Duration(hours: 8 + c, minutes: 10)),
      );
    }
  }
  // One abandoned session keeps the completion rate honest
  await db.recordTimerSession(
    targetMinutes: 25,
    elapsedSeconds: 9 * 60,
    isFinished: false,
    startedAt: DateTime(now.year, now.month, now.day - 2, 15),
  );
  // No preferences row: it would default the chassis to dark (goal default is 4).
}
