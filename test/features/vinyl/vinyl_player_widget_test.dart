import 'dart:math' as math;
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/app/theme/widgets/material_chassis_box.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/audio/sound_effect.dart';
import 'package:takt_desk/features/vinyl/presentation/vinyl_deck_painter.dart';
import 'package:takt_desk/features/vinyl/presentation/vinyl_player_widget.dart';
import 'package:takt_desk/features/vinyl/presentation/widgets/vinyl_disc_drawer_widget.dart';

class MockAudioService extends AudioService {
  final List<SoundEffect> playedEffects = [];
  final List<int> ambientStarted = [];
  int ambientStoppedCount = 0;

  @override
  void playFoley(SoundEffect effect) {
    playedEffects.add(effect);
  }

  @override
  void startAmbient({
    required int trackIndex,
    String? assetPath,
    double? primaryVolume,
    double? crackleVolume,
    double? binauralVolume,
  }) {
    ambientStarted.add(trackIndex);
  }

  @override
  void stopAmbient() {
    ambientStoppedCount++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  testWidgets('VinylPlayerWidget renders initial state with VinylDeckPainter and track info', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: VinylPlayerWidget(),
            ),
          ),
        ),
      ),
    );

    // Verify track name is displayed in uppercase
    expect(find.text('LO-FI RAIN'), findsOneWidget);

    // Verify DropdownButton is no longer present
    expect(find.byType(DropdownButton<int>), findsNothing);

    // Verify VinylDiscDrawerWidget is present with single unified drawer handle
    expect(find.byType(VinylDiscDrawerWidget), findsOneWidget);
    expect(find.byKey(const ValueKey('vinyl_drawer_1_handle')), findsOneWidget);
    expect(find.text('[ RECORD DRAWER // 20 DISCS ▾ ]'), findsOneWidget);

    // Verify soundscape mixer is absent
    expect(find.byKey(const ValueKey('fader_rec_track')), findsNothing);
    expect(find.text('SOUNDSCAPE MIXER // 3-CH'), findsNothing);

    // Verify CustomPaint with VinylDeckPainter
    final painterFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is VinylDeckPainter,
    );
    expect(painterFinder, findsOneWidget);

    final customPaint = tester.widget<CustomPaint>(painterFinder);
    final painter = customPaint.painter as VinylDeckPainter;
    expect(painter.needleOnRecord, isFalse);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('VinylPlayerWidget drops and lifts needle on tap', (tester) async {
    final mockAudio = MockAudioService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(mockAudio),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: VinylPlayerWidget(),
            ),
          ),
        ),
      ),
    );

    // Initial state: needle lifted
    var painterFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is VinylDeckPainter,
    );
    var customPaint = tester.widget<CustomPaint>(painterFinder);
    expect((customPaint.painter as VinylDeckPainter).needleOnRecord, isFalse);

    // Tap deck to drop needle
    await tester.tap(painterFinder);
    await tester.pump();

    // Needle is now dropped
    painterFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is VinylDeckPainter,
    );
    customPaint = tester.widget<CustomPaint>(painterFinder);
    expect((customPaint.painter as VinylDeckPainter).needleOnRecord, isTrue);
    expect(mockAudio.playedEffects, contains(SoundEffect.stylusDrop));
    expect(mockAudio.ambientStarted, contains(0));

    // Tap deck to lift needle
    await tester.tap(painterFinder);
    await tester.pump();

    // Needle is now lifted
    painterFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is VinylDeckPainter,
    );
    customPaint = tester.widget<CustomPaint>(painterFinder);
    expect((customPaint.painter as VinylDeckPainter).needleOnRecord, isFalse);
    expect(mockAudio.playedEffects, contains(SoundEffect.stylusStop));
    expect(mockAudio.ambientStoppedCount, equals(1));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('VinylPlayerWidget drawer handle expands VinylDiscDrawerWidget and loads track', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: VinylPlayerWidget(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('LO-FI RAIN'), findsOneWidget);

    // Tap drawer 1 handle to expand
    final handleFinder = find.byKey(const ValueKey('vinyl_drawer_1_handle'));
    expect(handleFinder, findsOneWidget);
    await tester.tap(handleFinder);
    await tester.pumpAndSettle();

    // Verify drawer is expanded and carousel is displayed
    expect(find.text('[ RECORD DRAWER // 20 DISCS ▲ ]'), findsOneWidget);
    expect(find.text('01 · NATURE'), findsOneWidget);
    expect(find.text('02 · HARMONICS'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);

    // Navigate to Track 1 ("DEEP BROWN NOISE")
    await tester.tap(find.byKey(const ValueKey('drawer_1_next_disc')));
    await tester.pumpAndSettle();

    final loadButton = find.byKey(const ValueKey('load_track_button_1'));
    expect(loadButton, findsOneWidget);
    await tester.tap(loadButton);
    await tester.pumpAndSettle();

    // Verify track is loaded on the turntable deck (both deck title and drawer card display it)
    expect(find.text('DEEP BROWN NOISE'), findsNWidgets(2));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('VinylPlayerWidget rotates when needle is on record and stops when lifted', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: VinylPlayerWidget(),
            ),
          ),
        ),
      ),
    );

    final painterFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is VinylDeckPainter,
    );

    // Initial angle when needle is up
    var customPaint = tester.widget<CustomPaint>(painterFinder);
    final initialAngle = (customPaint.painter as VinylDeckPainter).rotationAngle;

    // Pump frames - idle should NOT rotate
    await tester.pump(const Duration(milliseconds: 100));
    customPaint = tester.widget<CustomPaint>(painterFinder);
    expect((customPaint.painter as VinylDeckPainter).rotationAngle, equals(initialAngle));

    // Tap to drop needle
    await tester.tap(painterFinder);
    await tester.pump();

    // Pump some frames while needle is on record
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    customPaint = tester.widget<CustomPaint>(painterFinder);
    final playingAngle = (customPaint.painter as VinylDeckPainter).rotationAngle;
    expect(playingAngle, isNot(equals(initialAngle)));

    // Tap to lift needle
    await tester.tap(painterFinder);
    await tester.pump();

    // Pump more frames while lifted - angle should stay constant (stopped)
    await tester.pump(const Duration(milliseconds: 100));
    customPaint = tester.widget<CustomPaint>(painterFinder);
    final stoppedAngle = (customPaint.painter as VinylDeckPainter).rotationAngle;
    expect(stoppedAngle, equals(playingAngle));

    await tester.pumpWidget(const SizedBox());
  });

  group('VinylDeckPainter theming & repainting', () {
    test('shouldRepaint returns true when tonearmGradient, armPivotBorderColor, or labelColor changes', () {
      final base = VinylDeckPainter(
        rotationAngle: 0.0,
        needleOnRecord: false,
        labelColor: Colors.amber,
        tonearmGradient: const [Colors.white, Colors.black],
        armPivotBorderColor: Colors.grey,
      );

      final same = VinylDeckPainter(
        rotationAngle: 0.0,
        needleOnRecord: false,
        labelColor: Colors.amber,
        tonearmGradient: const [Colors.white, Colors.black],
        armPivotBorderColor: Colors.grey,
      );

      final diffGradient = VinylDeckPainter(
        rotationAngle: 0.0,
        needleOnRecord: false,
        labelColor: Colors.amber,
        tonearmGradient: const [Colors.red, Colors.blue],
        armPivotBorderColor: Colors.grey,
      );

      final diffBorder = VinylDeckPainter(
        rotationAngle: 0.0,
        needleOnRecord: false,
        labelColor: Colors.amber,
        tonearmGradient: const [Colors.white, Colors.black],
        armPivotBorderColor: Colors.cyan,
      );

      final diffLabel = VinylDeckPainter(
        rotationAngle: 0.0,
        needleOnRecord: false,
        labelColor: Colors.green,
        tonearmGradient: const [Colors.white, Colors.black],
        armPivotBorderColor: Colors.grey,
      );

      expect(base.shouldRepaint(same), isFalse);
      expect(base.shouldRepaint(diffGradient), isTrue);
      expect(base.shouldRepaint(diffBorder), isTrue);
      expect(base.shouldRepaint(diffLabel), isTrue);
    });

    test('shouldRepaint returns true when rotationAngle, needleOnRecord, or armProgress changes', () {
      final base = VinylDeckPainter(
        rotationAngle: 0.0,
        needleOnRecord: false,
        armProgress: 0.0,
      );
      final diffAngle = VinylDeckPainter(
        rotationAngle: 1.5,
        needleOnRecord: false,
        armProgress: 0.0,
      );
      final diffNeedle = VinylDeckPainter(
        rotationAngle: 0.0,
        needleOnRecord: true,
        armProgress: 0.0,
      );
      final diffProgress = VinylDeckPainter(
        rotationAngle: 0.0,
        needleOnRecord: false,
        armProgress: 0.5,
      );

      expect(base.shouldRepaint(diffAngle), isTrue);
      expect(base.shouldRepaint(diffNeedle), isTrue);
      expect(base.shouldRepaint(diffProgress), isTrue);
    });

    test('VinylDeckPainter draws recessed well with inner shadow and lip before platter', () {
      final painter = VinylDeckPainter(
        rotationAngle: 0.0,
        needleOnRecord: false,
      );

      final recordingCanvas = _RecordingCanvas();
      const testSize = Size(300, 300);
      painter.paint(recordingCanvas, testSize);

      final radius = math.min(testSize.width, testSize.height) * 0.41;
      final platterRadius = radius + 5;
      final expectedWellRadius = platterRadius + 3.0;

      // Find the recessed well shadow circle (radial gradient)
      final wellShadowCircles = recordingCanvas.circles.where((c) =>
        (c.radius - expectedWellRadius).abs() < 0.001 &&
        c.paint.shader != null
      ).toList();
      expect(wellShadowCircles, isNotEmpty, reason: 'Must draw recessed well inner shadow circle with shader at wellRadius');

      // Find the subtle well lip circle (stroke)
      final wellLipCircles = recordingCanvas.circles.where((c) =>
        (c.radius - expectedWellRadius).abs() < 0.001 &&
        c.paint.style == PaintingStyle.stroke
      ).toList();
      expect(wellLipCircles, isNotEmpty, reason: 'Must draw subtle well lip stroke circle at wellRadius');

      // Check order: well shadow must be drawn before the platter main body
      final wellShadowIndex = recordingCanvas.circles.indexOf(wellShadowCircles.first);
      final platterBodyIndex = recordingCanvas.circles.indexWhere((c) =>
        (c.radius - platterRadius).abs() < 0.001 &&
        c.paint.shader != null
      );
      expect(wellShadowIndex, lessThan(platterBodyIndex), reason: 'Recessed well cavity must be painted before platter body');
    });
  });

  group('VinylPlayerWidget Dynamic Metallurgy Theming', () {
    testWidgets('updates chassis color and border dynamically on edition switch', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(chassisThemeProvider.notifier).setDarkMode(true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: VinylPlayerWidget(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Initially braunClassic
      expect(find.byType(MaterialChassisBox), findsOneWidget);
      final casingFinder = find.descendant(
        of: find.byType(MaterialChassisBox),
        matching: find.byType(Container),
      ).first;
      final casingBefore = tester.widget<Container>(casingFinder);
      final decorationBefore = casingBefore.decoration as BoxDecoration;
      expect(decorationBefore.color, equals(HardwareEdition.braunClassic.darkModuleBg));
      final borderBefore = decorationBefore.border as Border;
      expect(borderBefore.top.color, equals(HardwareEdition.braunClassic.darkBorder));

      // Switch edition to titaniumStealth
      container.read(chassisThemeProvider.notifier).setHardwareEdition(HardwareEditionType.titaniumStealth);
      await tester.pumpAndSettle();

      final casingAfter = tester.widget<Container>(casingFinder);
      final decorationAfter = casingAfter.decoration as BoxDecoration;
      expect(decorationAfter.color, equals(HardwareEdition.titaniumStealth.darkModuleBg));
      final borderAfter = decorationAfter.border as Border;
      expect(borderAfter.top.color, equals(HardwareEdition.titaniumStealth.darkBorder));

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders MaterialChassisBox and applies high-contrast typography in light and dark modes', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Start in light mode
      container.read(chassisThemeProvider.notifier).setDarkMode(false);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: VinylPlayerWidget(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // MaterialChassisBox is present
      expect(find.byType(MaterialChassisBox), findsOneWidget);

      final themeLight = container.read(chassisThemeProvider);

      // Verify title "BRAUN TP-1" text color in Light Mode
      final titleTextLight = tester.widget<Text>(find.text('BRAUN TP-1'));
      expect(titleTextLight.style?.color, equals(themeLight.chassisTextColor));

      // Verify "33 RPM" text color when needle is up
      final rpmTextLight = tester.widget<Text>(find.text('33 RPM'));
      expect(rpmTextLight.style?.color, equals(themeLight.chassisMutedTextColor));

      // Verify track name text color when needle is up
      final trackTextLight = tester.widget<Text>(find.text('LO-FI RAIN'));
      expect(trackTextLight.style?.color, equals(themeLight.chassisTextColor));

      // Switch to dark mode
      container.read(chassisThemeProvider.notifier).setDarkMode(true);
      await tester.pumpAndSettle();

      final themeDark = container.read(chassisThemeProvider);

      // Verify title "BRAUN TP-1" text color in Dark Mode
      final titleTextDark = tester.widget<Text>(find.text('BRAUN TP-1'));
      expect(titleTextDark.style?.color, equals(themeDark.chassisTextColor));

      // Verify "33 RPM" text color when needle is up in Dark Mode
      final rpmTextDark = tester.widget<Text>(find.text('33 RPM'));
      expect(rpmTextDark.style?.color, equals(themeDark.chassisMutedTextColor));

      // Verify track name in Dark Mode
      final trackTextDark = tester.widget<Text>(find.text('LO-FI RAIN'));
      expect(trackTextDark.style?.color, equals(themeDark.chassisTextColor));

      // Drop needle and verify colors change to filamentColor
      final painterFinder = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is VinylDeckPainter,
      );
      await tester.tap(painterFinder);
      await tester.pump();

      final rpmPlaying = tester.widget<Text>(find.text('33 RPM'));
      expect(rpmPlaying.style?.color, equals(themeDark.filamentColor));

      final trackPlaying = tester.widget<Text>(find.text('LO-FI RAIN'));
      expect(trackPlaying.style?.color, equals(themeDark.filamentColor));

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders 4 corner rivets matching active edition rivetColor', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(chassisThemeProvider.notifier).setDarkMode(true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: VinylPlayerWidget(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Check initial 4 rivets
      for (int i = 0; i < 4; i++) {
        final rivetFinder = find.byKey(ValueKey('vinyl_rivet_$i'));
        expect(rivetFinder, findsOneWidget);
        final rivet = tester.widget<Container>(rivetFinder);
        final decoration = rivet.decoration as BoxDecoration;
        expect(decoration.color, equals(HardwareEdition.braunClassic.rivetDark));
      }

      // Switch to rawBrassPatina
      container.read(chassisThemeProvider.notifier).setHardwareEdition(HardwareEditionType.rawBrassPatina);
      await tester.pumpAndSettle();

      for (int i = 0; i < 4; i++) {
        final rivetFinder = find.byKey(ValueKey('vinyl_rivet_$i'));
        expect(rivetFinder, findsOneWidget);
        final rivet = tester.widget<Container>(rivetFinder);
        final decoration = rivet.decoration as BoxDecoration;
        expect(decoration.color, equals(HardwareEdition.rawBrassPatina.rivetDark));
      }

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('passes dynamic accent labelColor, tonearm metallurgy gradient, and pivot border to VinylDeckPainter', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(chassisThemeProvider.notifier).setDarkMode(true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: VinylPlayerWidget(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final painterFinder = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is VinylDeckPainter,
      );
      expect(painterFinder, findsOneWidget);

      var customPaint = tester.widget<CustomPaint>(painterFinder);
      var painter = customPaint.painter as VinylDeckPainter;

      // Braun Classic defaults
      expect(painter.labelColor, equals(HardwareEdition.braunClassic.accentColor));
      expect(painter.tonearmGradient, equals(HardwareEdition.braunClassic.plateGradientDark));
      expect(painter.armPivotBorderColor, equals(HardwareEdition.braunClassic.darkBorder));

      // Switch to bauhausHeritage
      container.read(chassisThemeProvider.notifier).setHardwareEdition(HardwareEditionType.bauhausHeritage);
      await tester.pumpAndSettle();

      customPaint = tester.widget<CustomPaint>(painterFinder);
      painter = customPaint.painter as VinylDeckPainter;

      expect(painter.labelColor, equals(HardwareEdition.bauhausHeritage.accentColor));
      expect(painter.tonearmGradient, equals(HardwareEdition.bauhausHeritage.plateGradientDark));
      expect(painter.armPivotBorderColor, equals(HardwareEdition.bauhausHeritage.darkBorder));

      await tester.pumpWidget(const SizedBox());
    });
  });
}

class _RecordingCanvas implements Canvas {
  final List<({Offset center, double radius, Paint paint})> circles = [];

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    circles.add((center: c, radius: radius, paint: paint));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

