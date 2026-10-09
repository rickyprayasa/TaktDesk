// High-resolution stills of the real ZYKL hardware for social images.
// One testWidgets per still; run ONE at a time (see run_stills.sh):
//
//   flutter test film_capture/stills_test.dart --plain-name 'still dial classic dark' \
//     --dart-define=FILM_DIR=$HOME/.cache/zykl-film/stills --dart-define=FILM_PR=4
//
// Output: $FILM_DIR/<name>.png (whole 384x800 phone at FILM_PR) plus
// <name>.json with the logical rect of each component on screen, so the
// image script can cut the dial, dispenser, vinyl or lockdown out exactly.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/core/focus/focus_lock_controller.dart';
import 'package:takt_desk/features/desk/presentation/widgets/emergency_unlatch_widget.dart';
import 'package:takt_desk/features/desk/presentation/widgets/monastic_switch_widget.dart';
import 'package:takt_desk/features/tasks/presentation/receipt_runner_controller.dart';
import 'package:takt_desk/features/tasks/presentation/receipt_runner_widget.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_widget.dart';
import 'package:takt_desk/features/timer/presentation/widgets/crown_push_button.dart';
import 'package:takt_desk/features/vinyl/domain/vinyl_track.dart';
import 'package:takt_desk/features/vinyl/presentation/vinyl_controller.dart';
import 'package:takt_desk/features/vinyl/presentation/vinyl_player_widget.dart';
import 'package:takt_desk/features/vumeter/presentation/analog_vu_meter_widget.dart';

import 'film_scene.dart';

const _dir = String.fromEnvironment('FILM_DIR', defaultValue: '/tmp/zykl_stills');

const _editions = {
  'classic': HardwareEditionType.braunClassic,
  'cream': HardwareEditionType.braunAtelierCream,
  'bauhaus': HardwareEditionType.bauhausHeritage,
  'steel': HardwareEditionType.industrialMonoSteel,
  'titanium': HardwareEditionType.titaniumStealth,
  'brass': HardwareEditionType.rawBrassPatina,
  'walnut': HardwareEditionType.midCenturyWalnut,
  'carbon': HardwareEditionType.forgedCarbon,
  'obsidian': HardwareEditionType.obsidianCeramic,
  'copper': HardwareEditionType.copperHearthAsh,
  'racing': HardwareEditionType.britishRacingGreen,
  'indigo': HardwareEditionType.indigoAstronomical,
};

/// Saves the still and the on-screen rect of every component found.
Future<void> _shoot(FilmScene s, String name) async {
  await s.still('$_dir/$name.png');
  final parts = <String, Finder>{
    'dial': find.byType(ChronoDialWidget),
    'crown': find.byType(CrownPushButton),
    'dispenser': find.byType(ReceiptRunnerWidget),
    'vinyl': find.byType(VinylPlayerWidget),
    'vu': find.byType(AnalogVuMeterWidget),
    'lock_switch': find.byType(MonasticSwitchWidget),
    'unlatch': find.byType(EmergencyUnlatchWidget),
  };
  final rects = <String, List<double>>{};
  parts.forEach((k, f) {
    if (f.evaluate().isNotEmpty) {
      final r = s.tester.getRect(f.first);
      rects[k] = [r.left, r.top, r.width, r.height];
    }
  });
  File('$_dir/$name.json').writeAsStringSync(const JsonEncoder.withIndent(' ').convert(rects));
  // ignore: avoid_print
  print('STILL: $_dir/$name.png ${rects.keys.join(',')}');
}

Future<void> _tapTab(FilmScene s, String label) async {
  await s.tester.tap(find.text(label).first);
  await s.settle(1.2);
}

void _still(String name, HardwareEditionType edition, bool dark, Future<void> Function(FilmScene s) pose) {
  testWidgets('still $name', (t) => FilmScene.run(t, out: '$_dir/_frames/$name', dark: dark, edition: edition,
      script: (s) async {
    await pose(s);
    await _shoot(s, name);
  }));
}

/// Dial running, about 7 minutes in.
Future<void> _dial(FilmScene s) async {
  await s.act(() => s.read(chronoDialProvider.notifier).start());
  await s.settle(7 * 60 + 10, step: const Duration(seconds: 1));
  await s.settle(2.0);
  expect(s.read(chronoDialProvider).isRunning, isTrue);
}

/// Three tasks printed, the first stamped DONE.
Future<void> _tasks(FilmScene s) async {
  await _tapTab(s, 'TASKS');
  final runner = s.read(receiptRunnerProvider.notifier);
  for (final title in ['Finish the UI design', 'Reply to the studio', 'Read 20 pages']) {
    await s.act(() => s.tester.runAsync(() => runner.addTask(title)));
    await s.settle(1.2);
  }
  expect(s.read(receiptRunnerProvider).tasks, hasLength(3));
  await s.act(() => runner.stampDone(s.read(receiptRunnerProvider).tasks.first.id));
  await s.settle(1.6);
}

/// Record loaded (first piano record), needle down, platter spinning.
Future<void> _vinyl(FilmScene s, {int? track}) async {
  await _tapTab(s, 'VINYL');
  final vinyl = s.read(vinylProvider.notifier);
  final t = track ?? VinylTrack.drawer2Presets.first.index;
  await s.act(() => vinyl.selectTrack(t, isPro: true));
  await s.settle(0.8);
  await s.act(vinyl.dropNeedle);
  await s.settle(2.4);
  expect(s.read(vinylProvider).needleOnRecord, isTrue);
}

/// Focusing with Lockdown engaged.
Future<void> _lock(FilmScene s) async {
  await s.act(() => s.read(chronoDialProvider.notifier).start());
  await s.settle(1.0);
  await s.tester.tap(find.byType(MonasticSwitchWidget).first);
  await s.settle(1.6);
  expect(s.read(focusLockProvider).isLocked, isTrue);
}

void main() {
  // Every edition: dial running (dark and light classic, the rest in their own light).
  _editions.forEach((key, e) {
    final darkFirst = !(key == 'cream' || key == 'bauhaus');
    _still('dial $key ${darkFirst ? 'dark' : 'light'}', e, darkFirst, _dial);
  });
  _still('dial classic light', HardwareEditionType.braunClassic, false, _dial);

  for (final dark in [true, false]) {
    final th = dark ? 'dark' : 'light';
    _still('tasks classic $th', HardwareEditionType.braunClassic, dark, _tasks);
    _still('vinyl classic $th', HardwareEditionType.braunClassic, dark, _vinyl);
    _still('lock classic $th', HardwareEditionType.braunClassic, dark, _lock);
  }
  _still('tasks walnut dark', HardwareEditionType.midCenturyWalnut, true, _tasks);
  _still('vinyl walnut dark', HardwareEditionType.midCenturyWalnut, true, _vinyl);
  _still('vinyl bauhaus light', HardwareEditionType.bauhausHeritage, false, _vinyl);
}
