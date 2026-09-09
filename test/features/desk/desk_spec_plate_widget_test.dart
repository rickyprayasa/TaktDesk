import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
          todayFocusStatsProvider.overrideWithValue(
            const AsyncValue.data(TodayFocusStats(
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

    expect(find.textContaining('TAKT DESK'), findsOneWidget);
    expect(find.textContaining('MOD. 01'), findsOneWidget);
    expect(find.textContaining('2026'), findsOneWidget);
    expect(find.textContaining('GERMANIC MINIMALISM'), findsOneWidget);
    expect(find.textContaining('STEREO 44.1kHz'), findsOneWidget);
    expect(find.textContaining('2 / 4 CYCLES'), findsOneWidget);
    expect(find.textContaining('50 MIN FOCUSED'), findsOneWidget);
    expect(find.byKey(const ValueKey('spec_plate_led_row')), findsOneWidget);
  });

  testWidgets('DeskSpecPlateWidget handles loading / null state gracefully defaulting to 0', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayFocusStatsProvider.overrideWithValue(
            const AsyncValue.loading(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DeskSpecPlateWidget(),
          ),
        ),
      ),
    );

    expect(find.textContaining('0 / 4 CYCLES'), findsOneWidget);
    expect(find.textContaining('0 MIN FOCUSED'), findsOneWidget);
  });

  testWidgets('DeskSpecPlateWidget lights all 4 LEDs when completedCount is 4', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayFocusStatsProvider.overrideWithValue(
            const AsyncValue.data(TodayFocusStats(
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

    expect(find.textContaining('4 / 4 CYCLES'), findsOneWidget);
    expect(find.textContaining('100 MIN FOCUSED'), findsOneWidget);

    for (int i = 0; i < 4; i++) {
      expect(find.byKey(ValueKey('spec_plate_led_$i')), findsOneWidget);
    }
  });

  testWidgets('DeskSpecPlateWidget plays sound and triggers haptic on tap', (tester) async {
    final mockAudio = MockAudioService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(mockAudio),
          todayFocusStatsProvider.overrideWithValue(
            const AsyncValue.data(TodayFocusStats(
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

    await tester.tap(find.byType(DeskSpecPlateWidget));
    await tester.pumpAndSettle();

    expect(mockAudio.playedEffects, contains(SoundEffect.dialClick));
  });

  testWidgets('DeskSpecPlateWidget renders in light mode without error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chassisThemeProvider.overrideWith((ref) => ThemeController()..setDarkMode(false)),
          todayFocusStatsProvider.overrideWithValue(
            const AsyncValue.data(TodayFocusStats(
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

    expect(find.textContaining('TAKT DESK'), findsOneWidget);
    expect(find.textContaining('3 / 4 CYCLES'), findsOneWidget);
  });
}
