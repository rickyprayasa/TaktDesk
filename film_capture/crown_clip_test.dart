// Clip "crown": custom Pomodoro set entirely by the crown and the dial.
//   standby (PULL CROWN // SET) -> pull crown -> wind dial to 40 (focus)
//   -> tap -> 8 (short break) -> tap -> 20 (long break) -> tap (seated)
//   -> press crown -> countdown runs.
//
//   flutter test film_capture/crown_clip_test.dart --dart-define=FILM_OUT=/path/to/frames/crown
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:takt_desk/app/theme/takt_theme.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/features/desk/presentation/desk_canvas_screen.dart';
import 'package:takt_desk/features/timer/domain/timer_state.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';
import 'package:takt_desk/features/timer/presentation/widgets/crown_push_button.dart';

import 'capture_kit.dart';

const _out = String.fromEnvironment('FILM_OUT', defaultValue: '/tmp/zykl_film/crown');
const _dark = bool.fromEnvironment('FILM_DARK', defaultValue: false);

void main() {
  testWidgets('capture crown clip', (tester) async {
    await loadFilmFonts();
    usePhoneView(tester);

    var now = DateTime(2026, 10, 2, 9, 0);
    await withClock(Clock(() => now), () async {
      final boundary = GlobalKey();
      final container = ProviderContainer(overrides: [
        chassisThemeProvider.overrideWith((ref) => ThemeController(initial: const ChassisThemeState(isDarkMode: _dark))),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _dark ? TaktTheme.darkThemeData : TaktTheme.lightThemeData,
          home: RepaintBoundary(
            key: boundary,
            child: const DeskCanvasScreen(
              gyroscopeStream: Stream<GyroscopeEvent>.empty(),
              accelerometerStream: Stream<AccelerometerEvent>.empty(),
            ),
          ),
        ),
      ));
      final chrono = container.read(chronoDialProvider.notifier);
      chrono.setProfile(container.read(chronoDialProvider).customProfile);
      await tester.pump(const Duration(milliseconds: 500));

      final finger = FilmFinger(tester);
      final rec = FilmRecorder(tester, boundary, _out, finger);

      // Geometry from the live layout: crown box top is 6 px below the dial
      // stack top, dial canvas (264x264) starts 24 px below it.
      final crownRect = tester.getRect(find.byType(CrownPushButton));
      final crown = crownRect.center;
      final dialCenter = Offset(crown.dx, crownRect.top - 6 + 24 + 132);
      Offset onDial(double minutes, [double r = 92]) {
        final a = minutes / 60 * 2 * math.pi;
        return dialCenter + Offset(math.sin(a) * r, -math.cos(a) * r);
      }

      Future<void> frame() async {
        now = now.add(kFrame);
        await tester.pump(kFrame);
        await rec.capture();
      }

      Future<void> hold(double seconds) async {
        for (var i = 0; i < (seconds * kFps).round(); i++) {
          await frame();
        }
      }

      Future<void> tap(Offset p) async {
        await finger.down(p);
        await frame();
        await frame();
        await finger.up();
        await frame();
      }

      // Wind the dial from `from` to `to` minutes along the rim, eased.
      Future<void> wind(double from, double to, double seconds) async {
        await finger.down(onDial(from));
        await frame();
        final n = (seconds * kFps).round();
        for (var i = 1; i <= n; i++) {
          final t = i / n;
          final e = t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2; // easeInOutCubic
          await finger.moveTo(onDial(from + (to - from) * e));
          await frame();
        }
        await hold(0.15);
        await finger.up();
        await frame();
      }

      // 1. Standby on the CUSTOM preset: "PULL CROWN // SET"
      await hold(1.0);

      // 2. Pull the crown up
      await finger.down(crown);
      await frame();
      // > 18 px touch slop + 8 px pull threshold, like a real thumb flick
      for (var i = 1; i <= 12; i++) {
        await finger.moveTo(crown + Offset(0, -4.0 * i));
        await frame();
      }
      await finger.up();
      await frame();
      finger.hide();
      expect(container.read(chronoDialProvider).setupStage, ChronoSetupStage.focus, reason: 'crown pull');
      await hold(0.6);

      final focusStart = container.read(chronoDialProvider).targetMinutes.toDouble();

      // 3. Focus: wind to 40 min, confirm
      await wind(focusStart, 40, 1.6);
      expect(container.read(chronoDialProvider).targetMinutes, 40, reason: 'focus wind');
      finger.hide();
      await hold(0.5);
      await tap(dialCenter + const Offset(0, 40));
      finger.hide();
      await hold(0.5);

      expect(container.read(chronoDialProvider).setupStage, ChronoSetupStage.shortBreak, reason: 'to short break');

      // 4. Short break: wind to 8 min, confirm
      final shortStart = container.read(chronoDialProvider).targetMinutes.toDouble();
      await wind(shortStart, 8, 1.0);
      finger.hide();
      await hold(0.4);
      await tap(dialCenter + const Offset(0, 40));
      finger.hide();
      await hold(0.5);

      expect(container.read(chronoDialProvider).customProfile.shortBreakMinutes, 8, reason: 'short wind');
      expect(container.read(chronoDialProvider).setupStage, ChronoSetupStage.longBreak, reason: 'to long break');

      // 5. Long break: wind to 20 min, confirm (crown seats back in)
      final longStart = container.read(chronoDialProvider).targetMinutes.toDouble();
      await wind(longStart, 20, 1.0);
      finger.hide();
      await hold(0.4);
      await tap(dialCenter + const Offset(0, 40));
      finger.hide();
      await hold(0.9);

      expect(container.read(chronoDialProvider).setupStage, ChronoSetupStage.none, reason: 'calibration done');
      expect(container.read(chronoDialProvider).profile.focusMinutes, 40, reason: 'custom saved');

      // 6. Press the crown: the 40 min focus starts
      await tap(crown);
      finger.hide();
      expect(container.read(chronoDialProvider).isRunning, isTrue, reason: 'started');
      await hold(2.0);

      rec.finish();
      chrono.pause();
      await tester.pump(const Duration(seconds: 1));
      // ignore: avoid_print
      print('FILM: ${rec.frame} frames -> $_out');
    });
  });
}
