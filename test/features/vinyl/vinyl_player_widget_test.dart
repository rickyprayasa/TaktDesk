import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
