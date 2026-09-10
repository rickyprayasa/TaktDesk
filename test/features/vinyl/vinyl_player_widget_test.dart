import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/audio/sound_effect.dart';
import 'package:takt_desk/features/vinyl/presentation/vinyl_deck_painter.dart';
import 'package:takt_desk/features/vinyl/presentation/vinyl_player_widget.dart';

class MockAudioService extends AudioService {
  final List<SoundEffect> playedEffects = [];
  final List<int> ambientStarted = [];
  int ambientStoppedCount = 0;

  @override
  void playFoley(SoundEffect effect) {
    playedEffects.add(effect);
  }

  @override
  void startAmbient(int trackIndex) {
    ambientStarted.add(trackIndex);
  }

  @override
  void stopAmbient() {
    ambientStoppedCount++;
  }
}

void main() {
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

    // Verify DropdownButton is present
    expect(find.byType(DropdownButton<int>), findsOneWidget);

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

  testWidgets('VinylPlayerWidget changes track using dropdown', (tester) async {
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

    // Open dropdown
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();

    // Select 'Deep Brown Noise'
    await tester.tap(find.text('Deep Brown Noise').last);
    await tester.pumpAndSettle();

    expect(find.text('DEEP BROWN NOISE'), findsOneWidget);

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
  });

  group('VinylPlayerWidget Dynamic Metallurgy Theming', () {
    testWidgets('updates chassis color and border dynamically on edition switch', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

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
      final chassisFinder = find.byKey(const ValueKey('vinyl_player_deck_chassis'));
      expect(chassisFinder, findsOneWidget);
      final casingBefore = tester.widget<Container>(chassisFinder);
      final decorationBefore = casingBefore.decoration as BoxDecoration;
      expect(decorationBefore.color, equals(HardwareEdition.braunClassic.darkModuleBg));
      final borderBefore = decorationBefore.border as Border;
      expect(borderBefore.top.color, equals(HardwareEdition.braunClassic.darkBorder));

      // Switch edition to titaniumStealth
      container.read(chassisThemeProvider.notifier).setHardwareEdition(HardwareEditionType.titaniumStealth);
      await tester.pumpAndSettle();

      final casingAfter = tester.widget<Container>(chassisFinder);
      final decorationAfter = casingAfter.decoration as BoxDecoration;
      expect(decorationAfter.color, equals(HardwareEdition.titaniumStealth.darkModuleBg));
      final borderAfter = decorationAfter.border as Border;
      expect(borderAfter.top.color, equals(HardwareEdition.titaniumStealth.darkBorder));

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders 4 corner rivets matching active edition rivetColor', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

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

