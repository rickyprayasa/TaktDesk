// Shared stage for the promo clips: the real DeskCanvasScreen (or opening
// screen) under a fake clock, a recorder and a finger. Clip scripts only
// describe *what happens*; this file owns timing and capture.
import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/takt_theme.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/core/focus/focus_lock_service.dart';
import 'package:takt_desk/features/desk/presentation/desk_canvas_screen.dart';
import 'package:takt_desk/features/timer/presentation/widgets/crown_push_button.dart';

import 'capture_kit.dart';

/// Android DND / app pinning are not available off-device; the lock UI still runs.
class FilmFocusLockService extends FocusLockService {
  @override
  Future<bool> enableFocusLock() async => true;
  @override
  Future<bool> disableFocusLock() async => true;
}

class FilmScene {
  final WidgetTester tester;
  final ProviderContainer container;
  final AppDatabase db;
  final GlobalKey boundary = GlobalKey();
  late final FilmFinger finger = FilmFinger(tester);
  late final FilmRecorder rec;
  DateTime now;

  FilmScene._(this.tester, this.container, this.db, this.now);

  /// Builds the scene inside a fake clock zone and runs [script].
  static Future<void> run(
    WidgetTester tester, {
    required String out,
    bool dark = false,
    HardwareEditionType edition = HardwareEditionType.braunClassic,
    Widget Function()? home,
    Future<void> Function(AppDatabase db, DateTime now)? seed,
    required Future<void> Function(FilmScene s) script,
  }) async {
    await loadFilmFonts();
    usePhoneView(tester);
    // Sensors are not available off-device: give the desk silent streams
    // (the opening screen builds DeskCanvasScreen without injected streams).
    for (final name in const [
      'dev.fluttercommunity.plus/sensors/gyroscope',
      'dev.fluttercommunity.plus/sensors/accelerometer',
      'dev.fluttercommunity.plus/sensors/user_accel',
      'dev.fluttercommunity.plus/sensors/magnetometer',
      'dev.fluttercommunity.plus/sensors/barometer',
    ]) {
      tester.binding.defaultBinaryMessenger
          .setMockStreamHandler(EventChannel(name), MockStreamHandler.inline(onListen: (_, __) {}));
    }
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/sensors/method'), (_) async => null);
    var clockNow = DateTime(2026, 10, 2, 9, 0);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await withClock(Clock(() => clockNow), () async {
      if (seed != null) await tester.runAsync(() => seed(db, clockNow));
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        focusLockServiceProvider.overrideWithValue(FilmFocusLockService()),
        chassisThemeProvider.overrideWith((ref) => ThemeController(
              initial: ChassisThemeState(
                isDarkMode: dark,
                edition: HardwareEdition.fromType(edition),
                isProUnlocked: true,
              ),
            )),
      ]);
      final s = FilmScene._(tester, container, db, clockNow);
      s.rec = FilmRecorder(tester, s.boundary, out, s.finger);
      s._advance = (d) => clockNow = clockNow.add(d);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: dark ? TaktTheme.darkThemeData : TaktTheme.lightThemeData,
          builder: (context, child) => RepaintBoundary(key: s.boundary, child: child),
          home: home?.call() ??
              const DeskCanvasScreen(
                gyroscopeStream: Stream<GyroscopeEvent>.empty(),
                accelerometerStream: Stream<AccelerometerEvent>.empty(),
              ),
        ),
      ));
      // Let saved preferences / DB streams settle (not recorded)
      for (var i = 0; i < 15; i++) {
        s._advance(kFrame);
        await tester.pump(kFrame);
      }
      await script(s);
      s.rec.finish();
      // ignore: avoid_print
      print('FILM: ${s.rec.frame} frames -> $out');
      // Tear down: drop the tree, then the providers (cancels the countdown's
      // periodic timer), then flush one-shot timers (debounces, animations).
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    });
    // db is in-memory and dies with the test process; closing it from the fake-clock
    // zone can hang.
  }

  late void Function(Duration) _advance;

  T read<T>(ProviderListenable<T> p) => container.read(p);

  /// One recorded frame (1/30 s of app time).
  Future<void> frame() async {
    _advance(kFrame);
    await tester.pump(kFrame);
    await rec.capture();
  }

  Future<void> hold(double seconds) async {
    for (var i = 0; i < (seconds * kFps).round(); i++) {
      await frame();
    }
  }

  /// Runs an action between frames (no extra frame).
  Future<void> act(FutureOr<void> Function() f) async => await f();

  Future<void> tap(Offset p) async {
    await finger.down(p);
    await frame();
    await frame();
    await finger.up();
    finger.hide();
    await frame();
  }

  Future<void> tapFinder(Finder f) => tap(tester.getCenter(f.first));

  /// Press and keep the finger down for [seconds] (e.g. emergency unlatch).
  Future<void> pressHold(Offset p, double seconds) async {
    await finger.down(p);
    await hold(seconds);
    await finger.up();
    finger.hide();
    await frame();
  }

  Future<void> drag(Offset from, Offset to, double seconds) async {
    await finger.down(from);
    await frame();
    final n = math.max(1, (seconds * kFps).round());
    for (var i = 1; i <= n; i++) {
      final t = i / n;
      final e = t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;
      await finger.moveTo(Offset.lerp(from, to, e.toDouble())!);
      await frame();
    }
    await finger.up();
    finger.hide();
    await frame();
  }

  // ---- dial geometry (live layout) ----
  Rect get crownRect => tester.getRect(find.byType(CrownPushButton));
  Offset get crown => crownRect.center;
  Offset get dialCenter => Offset(crown.dx, crownRect.top - 6 + 24 + 132);
  Offset onDial(double minutes, [double r = 92]) {
    final a = minutes / 60 * 2 * math.pi;
    return dialCenter + Offset(math.sin(a) * r, -math.cos(a) * r);
  }

  Future<void> wind(double from, double to, double seconds) async {
    await finger.down(onDial(from));
    await frame();
    final n = (seconds * kFps).round();
    for (var i = 1; i <= n; i++) {
      final t = i / n;
      final e = t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;
      await finger.moveTo(onDial(from + (to - from) * e));
      await frame();
    }
    await hold(0.15);
    await finger.up();
    finger.hide();
    await frame();
  }

  Future<void> pullCrown() async {
    final c = crown;
    await finger.down(c);
    await frame();
    for (var i = 1; i <= 12; i++) {
      await finger.moveTo(c + Offset(0, -4.0 * i));
      await frame();
    }
    await finger.up();
    finger.hide();
    await frame();
  }

  Future<void> tab(String label) => tapFinder(find.text(label));
}
