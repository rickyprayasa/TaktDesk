import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/features/vinyl/presentation/soundscape_mixer_controller.dart';
import 'package:takt_desk/features/vinyl/presentation/widgets/turntable_mixer_strip.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('TurntableMixerStrip renders 3 faders (REC, DUST, FLOW) and mute toggles', (tester) async {
    final mockAudio = AudioService(isMock: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(mockAudio),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: TurntableMixerStrip(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify channel labels
    expect(find.text('REC'), findsOneWidget);
    expect(find.text('DUST'), findsOneWidget);
    expect(find.text('FLOW'), findsOneWidget);

    // Verify dB scale markings
    expect(find.text('0dB'), findsNWidgets(3));
    expect(find.text('-∞'), findsNWidgets(3));

    // Verify 3 mute buttons
    expect(find.byKey(const ValueKey('mute_rec_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('mute_dust_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('mute_flow_button')), findsOneWidget);
  });

  testWidgets('Tapping mute button toggles channel mute in controller', (tester) async {
    final mockAudio = AudioService(isMock: true);
    final container = ProviderContainer(
      overrides: [
        audioServiceProvider.overrideWithValue(mockAudio),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: TurntableMixerStrip(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Initial state: DUST unmuted
    expect(container.read(soundscapeMixerProvider).isCrackleMuted, isFalse);

    // Tap mute DUST
    await tester.tap(find.byKey(const ValueKey('mute_dust_button')));
    await tester.pump();

    expect(container.read(soundscapeMixerProvider).isCrackleMuted, isTrue);

    // Tap mute DUST again to unmute
    await tester.tap(find.byKey(const ValueKey('mute_dust_button')));
    await tester.pump();

    expect(container.read(soundscapeMixerProvider).isCrackleMuted, isFalse);
  });

  testWidgets('Dragging fader thumb updates channel volume', (tester) async {
    final mockAudio = AudioService(isMock: true);
    final container = ProviderContainer(
      overrides: [
        audioServiceProvider.overrideWithValue(mockAudio),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: TurntableMixerStrip(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final recFader = find.byKey(const ValueKey('fader_rec_track'));
    expect(recFader, findsOneWidget);

    // Drag fader down by 20 pixels
    await tester.drag(recFader, const Offset(0, 20));
    await tester.pump();

    expect(container.read(soundscapeMixerProvider).primaryVolume, lessThan(0.80));
  });
}
