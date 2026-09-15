import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';
import 'package:takt_desk/features/settings/presentation/takt_settings_sheet.dart';

class MockAudioService extends AudioService {
  final List<String> playedChimes = [];
  MockAudioService() : super(isMock: true);

  @override
  void playAlarmChime(String chimeId) {
    playedChimes.add(chimeId);
  }
}

void main() {
  group('Alarm Acoustics Settings in TaktSettingsSheet', () {
    late MockAudioService mockAudioService;

    setUp(() {
      mockAudioService = MockAudioService();
    });

    Widget buildSheet({bool isPro = true, String selectedChime = 'braunBell'}) {
      return ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(mockAudioService),
          deskPreferencesControllerProvider.overrideWith(
            (ref) {
              final controller = DeskPreferencesController(
                null,
                mockAudioService,
                ref.watch(chassisThemeProvider.notifier),
              );
              controller.state = controller.state.copyWith(
                isProSimulated: isPro,
                alarmChimeId: selectedChime,
              );
              return controller;
            },
          ),
          lifetimeFocusStatsProvider.overrideWith(
            (ref) => Stream.value(const LifetimeFocusStats()),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TaktSettingsSheet(),
          ),
        ),
      );
    }

    testWidgets('renders Alarm Acoustics section with 5 free chimes', (tester) async {
      await tester.pumpWidget(buildSheet(isPro: false));
      await tester.pumpAndSettle();

      expect(find.textContaining('ALARM ACOUSTICS'), findsOneWidget);
      expect(find.text('BRAUN DUAL-HAMMER'), findsOneWidget);
      expect(find.text('BRASS DESK BELL'), findsOneWidget);
      expect(find.text('TIBETAN SINGING BOWL'), findsOneWidget);
      expect(find.text('ZEN TEMPLE GONG'), findsOneWidget);
      expect(find.text('TUBULAR CHIME'), findsOneWidget);
    });

    testWidgets('audition play button triggers playAlarmChime on AudioService', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      final previewButton = find.byKey(const ValueKey('preview_chime_deskBell'));
      expect(previewButton, findsOneWidget);

      await tester.ensureVisible(previewButton);
      await tester.pumpAndSettle();
      await tester.tap(previewButton);
      await tester.pump();

      expect(mockAudioService.playedChimes, contains('deskBell'));
    });

    testWidgets('tapping a chime equips it directly', (tester) async {
      await tester.pumpWidget(buildSheet(selectedChime: 'braunBell'));
      await tester.pumpAndSettle();

      final tile = find.byKey(const ValueKey('alarm_chime_tile_deskBell'));
      expect(tile, findsOneWidget);

      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(mockAudioService.playedChimes, contains('deskBell'));
    });

    testWidgets('tapping meditative/organic chimes equips directly without PRO block', (tester) async {
      await tester.pumpWidget(buildSheet(isPro: false, selectedChime: 'braunBell'));
      await tester.pumpAndSettle();

      final proTile = find.byKey(const ValueKey('alarm_chime_tile_tibetanBowl'));
      expect(proTile, findsOneWidget);

      await tester.ensureVisible(proTile);
      await tester.pumpAndSettle();
      await tester.tap(proTile);
      await tester.pumpAndSettle();

      expect(mockAudioService.playedChimes, contains('tibetanBowl'));
    });
  });
}
