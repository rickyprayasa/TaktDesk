// Use-case demo clips for the social content pack (promo/Konten/Konten 1):
// a "screen recording" of the real app per post, driven like a person would.
// Run ONE at a time, memory-capped (see run_content.sh):
//
//   flutter test film_capture/content_clips_test.dart --plain-name 'content coding' \
//     --dart-define=FILM_DIR=$HOME/.cache/zykl-film/content
//
// Each frame logs a camera target (`cam`) and the app's sound events (`sfx`)
// in touches.json; promo/Konten/demo/compose.py turns them into the video.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/core/focus/focus_lock_controller.dart';
import 'package:takt_desk/features/analytics/presentation/widgets/focus_analytics_dialog.dart';
import 'package:takt_desk/features/desk/presentation/widgets/emergency_unlatch_widget.dart';
import 'package:takt_desk/features/desk/presentation/widgets/monastic_switch_widget.dart';
import 'package:takt_desk/features/desk/presentation/widgets/settings_rivet_button.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';
import 'package:takt_desk/features/tasks/presentation/receipt_runner_controller.dart';
import 'package:takt_desk/features/tasks/presentation/widgets/animated_receipt_strip.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_profile.dart';
import 'package:takt_desk/features/timer/domain/timer_state.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';
import 'package:takt_desk/features/vinyl/domain/vinyl_track.dart';
import 'package:takt_desk/features/vinyl/presentation/vinyl_controller.dart';

import 'film_scene.dart';

const _dir = String.fromEnvironment('FILM_DIR', defaultValue: '/tmp/zykl_film');

VinylTrack _track(String name) => VinylTrack.presets.firstWhere((t) => t.name == name);

/// Taps a preset segment on the dial ('50/10 MON', '25/5 CLS', '15/3 SPR').
Future<void> _preset(FilmScene s, String label, PomodoroProfileType type) async {
  s.camOn(find.text(label), 1.75);
  await s.hold(0.45);
  await s.tapFinder(find.text(label));
  expect(s.read(chronoDialProvider).profile.type, type, reason: 'preset $label');
  await s.hold(0.7);
}

bool _drawerOpen = false;

/// Vinyl tab: open the record drawer, page to [track], load it.
Future<void> _loadRecord(FilmScene s, VinylTrack track) async {
  final drawer = find.byKey(const ValueKey('vinyl_disc_drawer_container'));
  if (!_drawerOpen) {
    await s.tapFinder(find.byKey(const ValueKey('vinyl_drawer_1_handle')));
    _drawerOpen = true;
    await s.hold(0.7);
    s.camOn(drawer, 1.3);
    await s.hold(0.4);
  }
  final second = VinylTrack.drawer2Presets.contains(track);
  if (second && find.text('02 · HARMONICS').evaluate().isNotEmpty &&
      s.read(vinylProvider).selectedTrackIndex < 10) {
    await s.tapFinder(find.text('02 · HARMONICS'));
    await s.hold(0.7);
  }
  if (s.read(vinylProvider).selectedTrackIndex == track.index) {
    // Already on the platter (the default disc): nothing to load.
    s.camOn(find.byKey(ValueKey('record_sleeve_${track.index}')), 1.5);
    await s.hold(1.0);
    return;
  }
  final button = find.byKey(ValueKey('load_track_button_${track.index}'));
  final nextKey = ValueKey('drawer_${second ? 2 : 1}_next_disc');
  for (var i = 0; i < 10; i++) {
    final centerX = s.tester.getCenter(drawer).dx;
    if (button.hitTestable().evaluate().isNotEmpty && (s.tester.getCenter(button).dx - centerX).abs() < 40) break;
    await s.tapFinder(find.byKey(nextKey));
    await s.hold(0.45);
  }
  s.camOn(button, 1.6);
  await s.hold(0.45);
  await s.tapFinder(button);
  expect(s.read(vinylProvider).selectedTrackIndex, track.index, reason: '${track.name} loaded');
  await s.hold(0.8);
}

/// Taps the platter to drop the needle.
Future<void> _dropNeedle(FilmScene s) async {
  final platter = find.bySemanticsLabel('Drop needle');
  s.camOn(platter, 1.5);
  await s.hold(0.5);
  await s.tapFinder(platter);
  expect(s.read(vinylProvider).needleOnRecord, isTrue, reason: 'needle down');
  await s.hold(1.6);
}

/// Tasks tab "+" → type → FEED PAPER.
Future<void> _addTask(FilmScene s, String title, {double cps = 14, double settle = 0.9}) async {
  final add = find.byTooltip('Add task');
  s.camOn(add, 1.5);
  await s.hold(0.35);
  await s.tapFinder(add);
  await s.hold(0.55);
  final field = find.byType(TextField);
  s.camOn(field, 1.65);
  await s.hold(0.3);
  await s.typeText(field, title, cps: cps);
  await s.hold(0.25);
  final before = s.read(receiptRunnerProvider).tasks.length;
  await s.tapFinder(find.byType(ElevatedButton).last);
  // The DB insert runs on real async; let it land before the next frames.
  await s.act(() => s.tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120))));
  s.camOn(find.byKey(const ValueKey('receipt_dispenser_chassis')), 1.3);
  await s.hold(settle);
  expect(s.read(receiptRunnerProvider).tasks.length, before + 1, reason: 'task "$title" printed');
}

Future<void> _doubleTap(FilmScene s, Offset p) async {
  await s.finger.down(p);
  await s.frame();
  await s.finger.up();
  await s.frame();
  await s.frame();
  await s.finger.down(p);
  await s.frame();
  await s.finger.up();
  s.finger.hide();
  await s.frame();
}

/// Stamps the first task DONE (double tap on the slip).
Future<void> _stampFirst(FilmScene s) async {
  final strip = find.byType(AnimatedReceiptStrip).first;
  s.camOn(strip, 1.7);
  await s.hold(0.5);
  await _doubleTap(s, s.tester.getCenter(strip));
  expect(s.read(receiptRunnerProvider).tasks.first.isDone, isTrue, reason: 'stamped');
  await s.hold(1.3);
}

/// Dial tab, crown press, then the hand ticking for [seconds].
Future<void> _startAndHold(FilmScene s, double seconds) async {
  s.cam(null);
  await s.tab('DIAL');
  await s.hold(0.7);
  s.cam(s.crown, 1.7);
  await s.hold(0.45);
  await s.tap(s.crown);
  expect(s.read(chronoDialProvider).isRunning, isTrue, reason: 'running');
  s.cam(s.dialCenter, 1.3);
  await s.hold(seconds);
}

/// CUSTOM segment, pull the crown, wind focus / short break, confirm the long break.
Future<void> _crownTo(FilmScene s, int focus, int brk) async {
  s.camOn(find.text('CUSTOM'), 1.7);
  await s.hold(0.4);
  await s.tapFinder(find.text('CUSTOM'));
  await s.hold(0.5);
  s.cam(s.crown + const Offset(0, 90), 1.45);
  await s.hold(0.5);
  await s.pullCrown();
  expect(s.read(chronoDialProvider).setupStage, ChronoSetupStage.focus, reason: 'crown pulled');
  s.cam(s.dialCenter, 1.55);
  await s.hold(0.4);
  await s.wind(s.read(chronoDialProvider).targetMinutes.toDouble(), focus.toDouble(), 1.4);
  expect(s.read(chronoDialProvider).targetMinutes, focus);
  await s.hold(0.35);
  await s.tap(s.dialCenter + const Offset(0, 40));
  await s.hold(0.35);
  await s.wind(s.read(chronoDialProvider).targetMinutes.toDouble(), brk.toDouble(), 0.9);
  await s.hold(0.3);
  await s.tap(s.dialCenter + const Offset(0, 40));
  await s.hold(0.3);
  await s.tap(s.dialCenter + const Offset(0, 40));
  expect(s.read(chronoDialProvider).setupStage, ChronoSetupStage.none);
  expect(s.read(chronoDialProvider).profile.focusMinutes, focus);
  expect(s.read(chronoDialProvider).profile.shortBreakMinutes, brk);
  await s.hold(0.7);
}

/// Settings → Hardware Editions → equip [type], close the sheet.
Future<void> _equip(FilmScene s, HardwareEditionType type) async {
  final gear = find.byType(SettingsRivetButton);
  s.camOn(gear, 1.6);
  await s.hold(0.4);
  await s.tapFinder(gear);
  s.cam(null);
  await s.hold(0.9);
  final card = find.byKey(ValueKey('edition_card_${type.name}'));
  for (var i = 0; i < 12 && card.hitTestable().evaluate().isEmpty; i++) {
    await s.tapFinder(find.byKey(const ValueKey('edition_next_button')));
    await s.hold(0.4);
  }
  for (var i = 0; i < 12; i++) {
    final c = s.tester.getCenter(card);
    if ((c.dx - 192).abs() < 40) break;
    await s.tapFinder(find.byKey(const ValueKey('edition_next_button')));
    await s.hold(0.4);
  }
  s.camOn(card, 1.5);
  await s.hold(0.45);
  await s.tapFinder(find.descendant(of: card, matching: find.text('EQUIP')));
  expect(s.read(chassisThemeProvider).edition.type, type, reason: 'edition equipped');
  await s.hold(1.0);
  s.cam(null);
  await s.act(() => Navigator.of(s.tester.element(card)).pop());
  await s.hold(0.9);
}

/// Monastic Lockdown on, then hold the unlatch for 5 s.
Future<void> _lockdown(FilmScene s) async {
  final sw = find.byType(MonasticSwitchWidget);
  s.camOn(sw, 1.6);
  await s.hold(0.45);
  await s.tapFinder(sw);
  await s.hold(0.3);
  expect(s.read(focusLockProvider).isLocked, isTrue, reason: 'locked');
  s.cam(null);
  await s.hold(1.3);
  final un = find.byType(EmergencyUnlatchWidget);
  s.camOn(un, 1.45);
  await s.hold(0.5);
  await s.pressHold(s.tester.getCenter(un), 5.25);
  await s.hold(0.3);
  expect(s.read(focusLockProvider).isLocked, isFalse, reason: 'released');
}

/// Stamps every task, top to bottom.
Future<void> _stampAll(FilmScene s) async {
  final n = s.read(receiptRunnerProvider).tasks.length;
  for (var i = 0; i < n; i++) {
    final strip = find.byType(AnimatedReceiptStrip).at(i);
    s.camOn(strip, 1.6);
    await s.hold(0.4);
    await _doubleTap(s, s.tester.getCenter(strip));
    expect(s.read(receiptRunnerProvider).tasks[i].isDone, isTrue, reason: 'stamped $i');
    await s.hold(0.6);
  }
}

/// A week of real-looking history: goal met today, 7-day streak (same as clips_test 'clip anal').
/// Dated from the REAL today, not the film clock: the analytics queries use DateTime.now(), while
/// FilmScene freezes package:clock at 2 Oct 2026 (a film-clock seed showed an empty week on 9 Oct).
Future<void> _seedWeek(AppDatabase db, DateTime _) async {
  final now = DateTime.now();
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
  await db.recordTimerSession(
    targetMinutes: 25,
    elapsedSeconds: 9 * 60,
    isFinished: false,
    startedAt: DateTime(now.year, now.month, now.day - 2, 15),
  );
}

/// Taps an analytics period tab ('DAY' / 'WEEK' / 'MONTH') inside the dialog.
Future<void> _period(FilmScene s, String label) async {
  final tab = find.descendant(of: find.byType(FocusAnalyticsDialog), matching: find.text(label));
  s.camOn(tab, 1.4);
  await s.hold(0.4);
  await s.tapFinder(tab);
  s.cam(null);
  await s.hold(1.7);
}

Future<void> _toVinyl(FilmScene s) async {
  s.cam(null);
  await s.tab('VINYL');
  await s.hold(0.6);
}

Future<void> _toTasks(FilmScene s) async {
  s.cam(null);
  await s.tab('TASKS');
  await s.hold(0.5);
}

void main() {
  setUp(() => _drawerOpen = false);

  // Post 1 — overview: presets 50/10 → 25/5 → 15/3, two soundscapes, dial ticking.
  testWidgets('content overview', (t) => FilmScene.run(t, out: '$_dir/overview', dark: true, script: (s) async {
    s.rec.chapter = '01|Pick a preset|50/10 · 25/5 · 15/3';
    await s.hold(0.9);
    await _preset(s, '50/10 MON', PomodoroProfileType.monastic);
    await _preset(s, '25/5 CLS', PomodoroProfileType.classic);
    await _preset(s, '15/3 SPR', PomodoroProfileType.sprint);
    s.rec.chapter = '02|Pick a sound|8 soundscapes are free';
    s.cam(null);
    await s.tab('VINYL');
    await s.hold(0.6);
    await _loadRecord(s, _track('Library Atmosphere'));
    await _dropNeedle(s);
    await _loadRecord(s, _track('Warm Tape & Felt Piano'));
    await s.hold(0.8);
    s.rec.chapter = '03|Write up to 5 tasks|Stamp them as you go';
    s.cam(null);
    await s.tab('TASKS');
    await s.hold(0.5);
    await _addTask(s, 'Read 20 pages', cps: 18, settle: 0.6);
    await _addTask(s, 'Fix login bug', cps: 18, settle: 0.6);
    await _stampFirst(s);
    s.rec.chapter = '04|Press the crown|and start';
    await _startAndHold(s, 2.6);
  }));

  // Post 4 — reading: 50/10, Library Atmosphere, "Read 20 pages".
  testWidgets('content reading', (t) => FilmScene.run(t, out: '$_dir/reading', dark: true, script: (s) async {
    s.rec.chapter = '01|Dial|50/10';
    await s.hold(0.9);
    await _preset(s, '50/10 MON', PomodoroProfileType.monastic);
    s.rec.chapter = '02|Sound|Library Atmosphere';
    s.cam(null);
    await s.tab('VINYL');
    await s.hold(0.6);
    await _loadRecord(s, _track('Library Atmosphere'));
    await _dropNeedle(s);
    s.rec.chapter = '03|Slip|Read 20 pages';
    s.cam(null);
    await s.tab('TASKS');
    await s.hold(0.6);
    await _addTask(s, 'Read 20 pages');
    s.rec.chapter = '04|Start|Get lost in a chapter';
    await _startAndHold(s, 2.6);
  }));

  // Post 2 — coding: 50/10, Deep Brown Noise, three tasks, one stamped.
  testWidgets('content coding', (t) => FilmScene.run(t, out: '$_dir/coding', dark: true, script: (s) async {
    s.rec.chapter = '01|Dial|50/10';
    await s.hold(0.9);
    await _preset(s, '50/10 MON', PomodoroProfileType.monastic);
    s.rec.chapter = '02|Sound|Deep Brown Noise';
    s.cam(null);
    await s.tab('VINYL');
    await s.hold(0.6);
    await _loadRecord(s, _track('Deep Brown Noise'));
    await _dropNeedle(s);
    s.rec.chapter = '03|Slip|Three tasks, one at a time';
    s.cam(null);
    await s.tab('TASKS');
    await s.hold(0.6);
    for (final title in ['Fix login bug', 'Write the test', 'Open the PR']) {
      await _addTask(s, title);
    }
    await _stampFirst(s);
    s.rec.chapter = '04|Start|Stay 50 minutes';
    await _startAndHold(s, 2.6);
  }));

  // Post 3 — studying: 25/5, Lo-Fi Rain, three tasks, Lockdown + 5 s hold.
  testWidgets('content studying', (t) => FilmScene.run(t, out: '$_dir/studying', dark: true, script: (s) async {
    s.rec.chapter = '01|Dial|25/5';
    await s.hold(0.6);
    await _preset(s, '50/10 MON', PomodoroProfileType.monastic);
    await _preset(s, '25/5 CLS', PomodoroProfileType.classic);
    s.rec.chapter = '02|Sound|Lo-Fi Rain';
    await _toVinyl(s);
    await _loadRecord(s, _track('Lo-fi Rain'));
    await _dropNeedle(s);
    s.rec.chapter = '03|Slip|3 tasks max';
    await _toTasks(s);
    for (final title in ['Outline', 'Draft section 1', 'Review notes']) {
      await _addTask(s, title, cps: 18, settle: 0.5);
    }
    s.rec.chapter = '04|Start|Then lock the phone';
    await _startAndHold(s, 0.9);
    s.rec.chapter = '05|Lockdown|Hold 5 seconds to leave';
    await _lockdown(s);
    s.cam(s.dialCenter, 1.3);
    await s.hold(1.6);
  }));

  // Post 5 — writing: crown to 40/8, Warm Tape & Felt Piano, "Write 300 words".
  testWidgets('content writing', (t) => FilmScene.run(t, out: '$_dir/writing', dark: true, script: (s) async {
    s.rec.chapter = '01|Crown|Pull it, wind to 40';
    await s.hold(0.6);
    await _crownTo(s, 40, 8);
    s.rec.chapter = '02|Sound|Warm Tape & Felt Piano';
    await _toVinyl(s);
    await _loadRecord(s, _track('Warm Tape & Felt Piano'));
    await _dropNeedle(s);
    s.rec.chapter = '03|Slip|One small goal';
    await _toTasks(s);
    await _addTask(s, 'Write 300 words');
    s.rec.chapter = '04|Start|Edit later, not now';
    await _startAndHold(s, 2.4);
  }));

  // Post 6 — creative: crown to 45/10, a lighter edition, Clair de Lune.
  testWidgets('content creative', (t) => FilmScene.run(t, out: '$_dir/creative', dark: true, script: (s) async {
    s.rec.chapter = '01|Crown|Wind to 45';
    await s.hold(0.6);
    await _crownTo(s, 45, 10);
    s.rec.chapter = '02|Edition|Atelier Cream';
    await _equip(s, HardwareEditionType.braunAtelierCream);
    final light = find.text('DARK');
    s.camOn(light, 1.7);
    await s.hold(0.4);
    await s.tapFinder(light);
    s.cam(null);
    await s.hold(1.3);
    s.rec.chapter = '03|Sound|Debussy, Clair de Lune';
    await _toVinyl(s);
    await _loadRecord(s, _track('Debussy Clair de Lune'));
    await _dropNeedle(s);
    s.rec.chapter = '04|Slip|Explore 3 layouts';
    await _toTasks(s);
    await _addTask(s, 'Explore 3 layouts', cps: 18);
    s.rec.chapter = '05|Start|Protect the flow';
    await _startAndHold(s, 2.4);
  }));

  // Post 7 — languages: 25/5, Kyoto Bamboo Stream, two tasks.
  testWidgets('content languages', (t) => FilmScene.run(t, out: '$_dir/languages', dark: true, script: (s) async {
    s.rec.chapter = '01|Dial|25/5';
    await s.hold(0.6);
    await _preset(s, '50/10 MON', PomodoroProfileType.monastic);
    await _preset(s, '25/5 CLS', PomodoroProfileType.classic);
    s.rec.chapter = '02|Sound|Kyoto Bamboo Stream';
    await _toVinyl(s);
    await _loadRecord(s, _track('Kyoto Bamboo Stream'));
    await _dropNeedle(s);
    s.rec.chapter = '03|Slip|Short and regular';
    await _toTasks(s);
    for (final title in ['10 new words', 'Say them out loud']) {
      await _addTask(s, title, cps: 16, settle: 0.6);
    }
    s.rec.chapter = '04|Start|25 calm minutes';
    await _startAndHold(s, 2.4);
  }));

  // Post 8 — admin: 15/3, Monastic Cello Solo, three tasks stamped one by one.
  testWidgets('content admin', (t) => FilmScene.run(t, out: '$_dir/admin', dark: true, script: (s) async {
    s.rec.chapter = '01|Dial|15/3';
    await s.hold(0.6);
    await _preset(s, '15/3 SPR', PomodoroProfileType.sprint);
    s.rec.chapter = '02|Sound|Monastic Cello Solo';
    await _toVinyl(s);
    await _loadRecord(s, _track('Monastic Cello Solo'));
    await _dropNeedle(s);
    s.rec.chapter = '03|Slip|The dull stuff';
    await _toTasks(s);
    for (final title in ['Reply to 5 emails', 'Pay bills', 'Tidy desk']) {
      await _addTask(s, title, cps: 18, settle: 0.5);
    }
    s.rec.chapter = '04|Stamp|One by one';
    await _stampAll(s);
    s.rec.chapter = '05|Start|When it rings, stop';
    await _startAndHold(s, 2.2);
  }));

  // ---- Feature clips: one feature per video (Threads "Feature video" slot) ----

  // Feature — Monastic Lockdown: start, lock, hold the lever 5 s, released.
  testWidgets('content feat_lockdown', (t) => FilmScene.run(t, out: '$_dir/feat_lockdown', dark: true, script: (s) async {
    s.rec.chapter = '01|Start a session|Press the crown';
    await s.hold(0.6);
    await _startAndHold(s, 1.0);
    s.rec.chapter = '02|Lock the phone|Apps and calls stay quiet';
    final sw = find.byType(MonasticSwitchWidget);
    s.camOn(sw, 1.6);
    await s.hold(0.45);
    await s.tapFinder(sw);
    await s.hold(0.3);
    expect(s.read(focusLockProvider).isLocked, isTrue, reason: 'locked');
    s.cam(null);
    await s.hold(1.6);
    s.rec.chapter = '03|Want out?|Hold the lever for 5 seconds';
    final un = find.byType(EmergencyUnlatchWidget);
    s.camOn(un, 1.45);
    await s.hold(0.5);
    await s.pressHold(s.tester.getCenter(un), 5.25);
    await s.hold(0.3);
    expect(s.read(focusLockProvider).isLocked, isFalse, reason: 'released');
    s.rec.chapter = '04|Released|Long enough to ask if you mean it';
    s.cam(s.dialCenter, 1.3);
    await s.hold(1.6);
  }));

  // Feature — Thermal Dispenser: print three slips, stamp one, tear it off.
  testWidgets('content feat_dispenser', (t) => FilmScene.run(t, out: '$_dir/feat_dispenser', dark: false, script: (s) async {
    await _toTasks(s);
    s.rec.chapter = '01|Print a task|Up to 5 per slip';
    for (final title in ['Finish the UI design', 'Reply to the studio', 'Read 20 pages']) {
      await _addTask(s, title, cps: 18, settle: 0.6);
    }
    s.rec.chapter = '02|Stamp it|Double tap. DONE, in red ink';
    await _stampFirst(s);
    s.rec.chapter = '03|Tear it off|Filed to the archive';
    final strip = s.tester.getRect(find.byType(AnimatedReceiptStrip).first);
    s.cam(strip.center, 1.5);
    await s.hold(0.4);
    await s.drag(strip.center, strip.center + Offset(strip.width * 0.9, 0), 0.45);
    await s.hold(1.0);
    s.rec.chapter = '04|Keep going|The next task moves up';
    s.camOn(find.byKey(const ValueKey('receipt_dispenser_chassis')), 1.3);
    await s.hold(1.4);
  }));

  // Feature — Chrono Dial: the three presets, a custom rhythm set with the crown, then start.
  testWidgets('content feat_dial', (t) => FilmScene.run(t, out: '$_dir/feat_dial', dark: true, script: (s) async {
    s.rec.chapter = '01|Pick a rhythm|Classic, Monastic or Sprint';
    await s.hold(0.6);
    await _preset(s, '50/10 MON', PomodoroProfileType.monastic);
    await _preset(s, '15/3 SPR', PomodoroProfileType.sprint);
    await _preset(s, '25/5 CLS', PomodoroProfileType.classic);
    s.rec.chapter = '02|Or set your own|Pull the crown, wind the dial';
    await _crownTo(s, 40, 8);
    s.rec.chapter = '03|Press the crown|The needle steps once a second';
    await _startAndHold(s, 2.4);
  }));

  // Feature — Hardware Editions: equip one finish from the gallery (how), then a showcase of the dial in five
  // more finishes while it runs (the look). The showcase swaps editions in code, as a montage under the dial shot.
  testWidgets('content feat_editions', (t) => FilmScene.run(t, out: '$_dir/feat_editions', dark: true, script: (s) async {
    s.rec.chapter = '01|12 material editions|Four free, eight with Studio PRO';
    await s.hold(0.4);
    await _startAndHold(s, 1.0);
    s.rec.chapter = '02|Bauhaus Heritage|1925 · tubular chrome, primary colours';
    await _equip(s, HardwareEditionType.bauhausHeritage);
    s.cam(s.dialCenter, 1.35);
    await s.hold(2.2);
    for (final (type, chapter) in [
      (HardwareEditionType.rawBrassPatina, '03|Raw Brass & Patina|1954 · a burnished marine chronometer'),
      (HardwareEditionType.midCenturyWalnut, '04|Mid-Century Walnut|1958 · natural timber, satin gold'),
      (HardwareEditionType.titaniumStealth, '05|Titanium Stealth|2026 · aerospace grade 5'),
      (HardwareEditionType.britishRacingGreen, '06|British Racing Green|1962 · vintage spruce and gold'),
      (HardwareEditionType.indigoAstronomical, '07|Indigo Astronomical|1974 · deep-sea navy and cyan'),
    ]) {
      s.rec.chapter = chapter;
      await s.act(() => s.read(deskPreferencesControllerProvider.notifier).setHardwareEdition(type));
      await s.hold(2.2);
      expect(s.read(chassisThemeProvider).edition.type, type, reason: chapter);
    }
    s.cam(null);
    await s.hold(1.2);
  }));

  // Feature — Focus Analytics: the desk plate, today's slip, then day / week / month on record.
  testWidgets('content feat_analytics', (t) => FilmScene.run(t, out: '$_dir/feat_analytics', dark: true, seed: _seedWeek,
      script: (s) async {
    s.rec.chapter = '01|Tap the plate|Today at a glance';
    await s.hold(0.6);
    final plate = find.byKey(const ValueKey('desk_spec_plate_surface'));
    s.camOn(plate, 1.5);
    await s.hold(0.5);
    await s.tapFinder(plate);
    s.cam(null);
    await s.hold(2.0);
    s.rec.chapter = '02|Focus analytics|Every session stays on your phone';
    await s.tapFinder(find.byKey(const ValueKey('telemetry_open_analytics_button')));
    await s.hold(1.6);
    expect(find.byType(FocusAnalyticsDialog), findsOneWidget, reason: 'analytics open');
    s.rec.chapter = '03|Day, week, month|Your daily goal and your streak';
    await _period(s, 'DAY');
    await _period(s, 'WEEK');
    await _period(s, 'MONTH');
  }));

  // Feature — Vinyl Soundscapes: an Atmosphere, then a Harmonic, platter spinning.
  testWidgets('content feat_vinyl', (t) => FilmScene.run(t, out: '$_dir/feat_vinyl', dark: true, script: (s) async {
    await _toVinyl(s);
    s.rec.chapter = '01|Atmospheres|Rain, brown noise, a library, a stream';
    await _loadRecord(s, _track('Kyoto Bamboo Stream'));
    await _dropNeedle(s);
    s.rec.chapter = '02|Harmonics|Piano, cello, guitar, Debussy';
    await _loadRecord(s, _track('Debussy Clair de Lune'));
    s.rec.chapter = '03|33⅓ RPM|It really spins';
    s.camOn(find.bySemanticsLabel('Lift tonearm'), 1.3);
    await s.hold(2.2);
  }));
}
