// Frame-exact capture of the real ZYKL widgets for the promo film, without a
// device or screen recording. Run a clip with:
//
//   flutter test film_capture/<clip>_clip_test.dart
//
// (kept out of test/ so the normal suite never runs it). Frames are written as
// PNG at 3x (1152x2400 for the 384x800 logical phone), plus touches.json with
// the finger position per frame so the film can auto-zoom on the action.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const Size kPhoneLogical = Size(384, 800); // 0.48 aspect = the film's phone screen (540x1125)
/// 3x for the film; pass --dart-define=FILM_PR=1 for a fast smoke run.
final double kPixelRatio = double.parse(const String.fromEnvironment('FILM_PR', defaultValue: '3'));
const int kFps = 30;
const Duration kFrame = Duration(microseconds: 1000000 ~/ kFps);

/// Real fonts instead of the test "Ahem" boxes. 'monospace' is the app's main
/// family; Noto Sans Mono is the Android system monospace family.
Future<void> loadFilmFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File(f).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/home/tuneeca/RSQUARE/flutter';
  final material = '$flutterRoot/bin/cache/artifacts/material_fonts';
  await load('monospace', [
    '/usr/share/fonts/truetype/noto/NotoSansMono-Regular.ttf',
    '/usr/share/fonts/truetype/noto/NotoSansMono-Bold.ttf',
  ]);
  for (final family in ['Roboto', 'sans-serif']) {
    await load(family, [
      '$material/Roboto-Regular.ttf',
      '$material/Roboto-Medium.ttf',
      '$material/Roboto-Bold.ttf',
    ]);
  }
  await load('MaterialIcons', ['$material/MaterialIcons-Regular.otf']);
}

/// Sets the test view to the phone size at [kPixelRatio].
void usePhoneView(WidgetTester tester) {
  tester.view.physicalSize = kPhoneLogical * kPixelRatio;
  tester.view.devicePixelRatio = kPixelRatio;
  addTearDown(tester.view.reset);
}

/// Scriptable finger: drives real pointer events and remembers its position
/// for touches.json. One call per frame keeps gestures frame-accurate.
class FilmFinger {
  final WidgetTester tester;
  TestGesture? _g;
  Offset? position;
  bool get isDown => _g != null;

  FilmFinger(this.tester);

  Future<void> down(Offset p) async {
    _g = await tester.startGesture(p);
    position = p;
  }

  Future<void> moveTo(Offset p) async {
    await _g?.moveTo(p);
    position = p;
  }

  Future<void> up() async {
    await _g?.up();
    _g = null;
  }

  void hide() => position = null;
}

/// Captures frames of the widget under [boundaryKey].
class FilmRecorder {
  final WidgetTester tester;
  final GlobalKey boundaryKey;
  final Directory dir;
  final FilmFinger finger;
  final List<Map<String, Object?>> _touches = [];
  int frame = 0;

  FilmRecorder(this.tester, this.boundaryKey, String outDir, this.finger)
      : dir = Directory(outDir)..createSync(recursive: true);

  Future<void> capture() async {
    frame++;
    final boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final ui.Image img = await boundary.toImage(pixelRatio: kPixelRatio);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      File('${dir.path}/${frame.toString().padLeft(4, '0')}.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
    final p = finger.position;
    _touches.add({
      'f': frame,
      if (p != null) 'x': (p.dx / kPhoneLogical.width).toStringAsFixed(4),
      if (p != null) 'y': (p.dy / kPhoneLogical.height).toStringAsFixed(4),
      'down': finger.isDown,
    });
  }

  void finish() {
    File('${dir.path}/touches.json').writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert({'fps': kFps, 'frames': frame, 'touches': _touches}),
    );
  }
}
