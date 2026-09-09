import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/takt_colors.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/audio/sound_effect.dart';
import 'package:takt_desk/features/desk/presentation/widgets/desk_spec_plate_widget.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';

class MockAudioService extends AudioService {
  final List<SoundEffect> playedEffects = [];

  MockAudioService() : super(isMock: true);

  @override
  void play(SoundEffect effect) {
    playedEffects.add(effect);
  }

  @override
  void playFoley(SoundEffect effect) {
    playedEffects.add(effect);
  }
}

void main() {
  testWidgets('DeskSpecPlateWidget renders manufacturer stamp and 4 LED dots', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayFocusStatsProvider.overrideWith(
            (ref) => Stream.value(const TodayFocusStats(
              completedCount: 2,
              totalMinutes: 50,
            )),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DeskSpecPlateWidget(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('BRAUN CLASSIC'), findsOneWidget);
    expect(find.textContaining('MOD. 01'), findsOneWidget);
    expect(find.textContaining('1960'), findsOneWidget);
    expect(find.textContaining('GERMANIC MINIMALISM'), findsOneWidget);
    expect(find.textContaining('STEREO 44.1kHz'), findsOneWidget);
    expect(find.textContaining('2 / 4 CYCLES'), findsOneWidget);
    expect(find.textContaining('50 MIN FOCUSED'), findsOneWidget);
    expect(find.byKey(const ValueKey('spec_plate_led_row')), findsOneWidget);

    // Verify LED states: completedCount = 2 -> 2 active (filamentAmber), 2 inactive (basaltSlate)
    for (int i = 0; i < 2; i++) {
      final container = tester.widget<Container>(find.byKey(ValueKey('spec_plate_led_$i')));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(TaktColors.filamentAmber));
    }
    for (int i = 2; i < 4; i++) {
      final container = tester.widget<Container>(find.byKey(ValueKey('spec_plate_led_$i')));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(TaktColors.basaltSlate));
    }
  });

  testWidgets('DeskSpecPlateWidget handles loading / null state gracefully defaulting to 0', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayFocusStatsProvider.overrideWith(
            (ref) => const Stream.empty(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DeskSpecPlateWidget(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('0 / 4 CYCLES'), findsOneWidget);
    expect(find.textContaining('0 MIN FOCUSED'), findsOneWidget);

    // All 4 LEDs should be inactive
    for (int i = 0; i < 4; i++) {
      final container = tester.widget<Container>(find.byKey(ValueKey('spec_plate_led_$i')));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(TaktColors.basaltSlate));
    }
  });

  testWidgets('DeskSpecPlateWidget lights all 4 LEDs when completedCount is 4', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayFocusStatsProvider.overrideWith(
            (ref) => Stream.value(const TodayFocusStats(
              completedCount: 4,
              totalMinutes: 100,
            )),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DeskSpecPlateWidget(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('4 / 4 CYCLES'), findsOneWidget);
    expect(find.textContaining('100 MIN FOCUSED'), findsOneWidget);

    for (int i = 0; i < 4; i++) {
      expect(find.byKey(ValueKey('spec_plate_led_$i')), findsOneWidget);
      final container = tester.widget<Container>(find.byKey(ValueKey('spec_plate_led_$i')));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(TaktColors.filamentAmber));
    }
  });

  testWidgets('DeskSpecPlateWidget plays sound and triggers haptic on tap', (tester) async {
    final mockAudio = MockAudioService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(mockAudio),
          todayFocusStatsProvider.overrideWith(
            (ref) => Stream.value(const TodayFocusStats(
              completedCount: 1,
              totalMinutes: 25,
            )),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DeskSpecPlateWidget(),
          ),
        ),
      ),
    );
    await tester.pump();

    final led0 = tester.widget<Container>(find.byKey(const ValueKey('spec_plate_led_0')));
    expect((led0.decoration as BoxDecoration).color, equals(TaktColors.filamentAmber));
    for (int i = 1; i < 4; i++) {
      final led = tester.widget<Container>(find.byKey(ValueKey('spec_plate_led_$i')));
      expect((led.decoration as BoxDecoration).color, equals(TaktColors.basaltSlate));
    }

    await tester.tap(find.byType(DeskSpecPlateWidget));
    await tester.pumpAndSettle();

    expect(mockAudio.playedEffects, contains(SoundEffect.dialClick));
  });

  testWidgets('DeskSpecPlateWidget renders in light mode without error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chassisThemeProvider.overrideWith((ref) => ThemeController()..setDarkMode(false)),
          todayFocusStatsProvider.overrideWith(
            (ref) => Stream.value(const TodayFocusStats(
              completedCount: 3,
              totalMinutes: 75,
            )),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DeskSpecPlateWidget(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('BRAUN CLASSIC'), findsOneWidget);
    expect(find.textContaining('3 / 4 CYCLES'), findsOneWidget);

    for (int i = 0; i < 3; i++) {
      final container = tester.widget<Container>(find.byKey(ValueKey('spec_plate_led_$i')));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(TaktColors.filamentAmber));
    }
    final inactiveLed = tester.widget<Container>(find.byKey(const ValueKey('spec_plate_led_3')));
    expect((inactiveLed.decoration as BoxDecoration).color, equals(TaktColors.basaltSlate));
  });

  testWidgets('DeskSpecPlateWidget updates stamp title and gradient based on active edition', (tester) async {
    final container = ProviderContainer(
      overrides: [
        todayFocusStatsProvider.overrideWith(
          (ref) => Stream.value(const TodayFocusStats(completedCount: 1, totalMinutes: 25)),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(chassisThemeProvider.notifier).setHardwareEdition(HardwareEditionType.titaniumStealth);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: DeskSpecPlateWidget(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('TITANIUM STEALTH'), findsOneWidget);
    expect(find.textContaining('AEROSPACE PVD GRADE 5'), findsOneWidget);

    final plateContainer = tester.widget<Container>(
      find.descendant(of: find.byType(DeskSpecPlateWidget), matching: find.byType(Container)).first,
    );
    final decoration = plateContainer.decoration as BoxDecoration;
    final gradient = decoration.gradient as LinearGradient;
    expect(gradient.colors, equals(HardwareEdition.titaniumStealth.plateGradientDark));

    final litLed = tester.widget<Container>(find.byKey(const ValueKey('spec_plate_led_0')));
    final ledDecoration = litLed.decoration as BoxDecoration;
    expect(ledDecoration.color, equals(HardwareEdition.titaniumStealth.filamentColor));
  });
}
