import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/audio/sound_effect.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';
import 'package:takt_desk/features/vinyl/presentation/vinyl_controller.dart';
import 'package:takt_desk/features/vinyl/presentation/widgets/vinyl_disc_drawer_widget.dart';

class FakeDeskPreferencesController extends DeskPreferencesController {
  FakeDeskPreferencesController({bool isProSimulated = false})
      : super(null, AudioService(isMock: true), null) {
    state = state.copyWith(isProSimulated: isProSimulated);
  }

  @override
  Future<void> setProSimulated(bool value) async {
    state = state.copyWith(isProSimulated: value);
  }
}

class MockAudioService extends AudioService {
  final List<SoundEffect> playedEffects = [];

  MockAudioService() : super(isMock: true);

  @override
  void playFoley(SoundEffect effect) {
    playedEffects.add(effect);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp({
    bool isProSimulated = false,
    int initialTrackIndex = 0,
    AudioService? audioService,
  }) {
    final prefsController =
        FakeDeskPreferencesController(isProSimulated: isProSimulated);
    final mockAudio = audioService ?? MockAudioService();

    return ProviderScope(
      overrides: [
        deskPreferencesControllerProvider.overrideWith((ref) => prefsController),
        audioServiceProvider.overrideWithValue(mockAudio),
        vinylProvider.overrideWith((ref) {
          final controller = VinylController(mockAudio);
          if (initialTrackIndex != 0) {
            controller.selectTrack(initialTrackIndex, isPro: isProSimulated);
          }
          return controller;
        }),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 340,
              child: SingleChildScrollView(
                child: VinylDiscDrawerWidget(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('VinylDiscDrawerWidget - Dual Record Drawers', () {
    testWidgets('renders single unified record drawer in closed state on deck', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Verify single unified drawer handle plate is rendered
      expect(find.byKey(const ValueKey('vinyl_drawer_1_handle')), findsOneWidget);
      expect(find.text('[ RECORD DRAWER // 24 DISCS ▾ ]'), findsOneWidget);

      // Interior drawer tabs and carousel are closed initially
      expect(find.byKey(const ValueKey('vinyl_drawer_segment_1')), findsNothing);
      expect(find.byKey(const ValueKey('vinyl_drawer_segment_2')), findsNothing);
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('expanding drawer displays interior drawer tabs, 12 sleeves, and allows navigation', (tester) async {
      final mockAudio = MockAudioService();
      await tester.pumpWidget(buildTestApp(audioService: mockAudio));
      await tester.pumpAndSettle();

      // Tap drawer handle to open
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_1_handle')));
      await tester.pumpAndSettle();

      // Exterior handle shows open indicator
      expect(find.text('[ RECORD DRAWER // 24 DISCS ▲ ]'), findsOneWidget);
      expect(mockAudio.playedEffects, contains(SoundEffect.drawerSlide));

      // Interior drawer tabs are now visible
      expect(find.byKey(const ValueKey('vinyl_drawer_segment_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('vinyl_drawer_segment_2')), findsOneWidget);
      expect(find.text('01 · NATURE'), findsOneWidget);
      expect(find.text('02 · HARMONICS'), findsOneWidget);

      // PageView is visible with Drawer 1 items (0..11)
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('[ 01 / 12 ]'), findsOneWidget);
      expect(find.byKey(const ValueKey('record_sleeve_0')), findsOneWidget);
      expect(find.text('TK-01'), findsOneWidget);
      expect(find.text('LO-FI RAIN'), findsOneWidget);
      expect(find.text('[ ON PLATTER ]'), findsOneWidget);

      // Navigate to next disc in Drawer 1
      await tester.tap(find.byKey(const ValueKey('drawer_1_next_disc')));
      await tester.pumpAndSettle();

      expect(find.text('[ 02 / 12 ]'), findsOneWidget);
      expect(find.byKey(const ValueKey('record_sleeve_1')), findsOneWidget);
      expect(find.text('TK-02'), findsOneWidget);
      expect(find.text('DEEP BROWN NOISE'), findsOneWidget);
    });

    testWidgets('switching to Drawer 2 displays 12 sleeves (12..23) in the same compact bay', (tester) async {
      final mockAudio = MockAudioService();
      await tester.pumpWidget(buildTestApp(audioService: mockAudio));
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_1_handle')));
      await tester.pumpAndSettle();

      // Switch to Drawer 2 using interior segment tab
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_segment_2')));
      await tester.pumpAndSettle();

      expect(mockAudio.playedEffects, contains(SoundEffect.switchClick));

      // Drawer 2 items start with index 12 (Warm Tape & Felt Piano)
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('[ 01 / 12 ]'), findsOneWidget);
      expect(find.byKey(const ValueKey('record_sleeve_12')), findsOneWidget);
      expect(find.text('TK-13'), findsOneWidget);
      expect(find.text('WARM TAPE & FELT PIANO'), findsOneWidget);
    });

    testWidgets('tapping handle again closes drawer, returning to clean deck appearance', (tester) async {
      final mockAudio = MockAudioService();
      await tester.pumpWidget(buildTestApp(audioService: mockAudio));
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_1_handle')));
      await tester.pumpAndSettle();

      expect(find.text('[ RECORD DRAWER // 24 DISCS ▲ ]'), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);

      // Close drawer by tapping handle again
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_1_handle')));
      await tester.pumpAndSettle();

      // Shows closed indicator, no PageView, no interior tabs
      expect(find.text('[ RECORD DRAWER // 24 DISCS ▾ ]'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
      expect(find.byKey(const ValueKey('vinyl_drawer_segment_1')), findsNothing);
      expect(mockAudio.playedEffects, contains(SoundEffect.drawerLatch));
    });

    testWidgets('interior segment rocker switches between Drawer 01 and Drawer 02', (tester) async {
      final mockAudio = MockAudioService();
      await tester.pumpWidget(buildTestApp(audioService: mockAudio));
      await tester.pumpAndSettle();

      // Open Drawer
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_1_handle')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('record_sleeve_0')), findsOneWidget);

      // Switch to Drawer 2 using interior segment pill
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_segment_2')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('record_sleeve_12')), findsOneWidget);
      expect(mockAudio.playedEffects, contains(SoundEffect.switchClick));

      // Switch back to Drawer 1 using interior segment pill
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_segment_1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('record_sleeve_0')), findsOneWidget);
    });

    testWidgets('loading track in Drawer 1 selects it onto the platter', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Open Drawer
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_1_handle')));
      await tester.pumpAndSettle();

      // Navigate to Track 1
      await tester.tap(find.byKey(const ValueKey('drawer_1_next_disc')));
      await tester.pumpAndSettle();

      final loadButton = find.byKey(const ValueKey('load_track_button_1'));
      expect(loadButton, findsOneWidget);
      await tester.tap(loadButton);
      await tester.pumpAndSettle();

      // Track 1 is now on platter
      expect(find.text('[ ON PLATTER ]'), findsOneWidget);
      expect(find.byKey(const ValueKey('load_track_button_1')), findsNothing);
    });

    testWidgets('Drawer 2 provides free tracks 12 and 13 (Harmonics), and premium track 16 triggers Studio Pro dialog', (tester) async {
      await tester.pumpWidget(buildTestApp(isProSimulated: false));
      await tester.pumpAndSettle();

      // Open Drawer
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_1_handle')));
      await tester.pumpAndSettle();

      // Switch to Drawer 2
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_segment_2')));
      await tester.pumpAndSettle();

      // Track 12 (Warm Tape & Felt Piano) is free
      final loadButton12 = find.byKey(const ValueKey('load_track_button_12'));
      expect(loadButton12, findsOneWidget);

      // Navigate to Track 13 (Monastic Rhodes & Velvet) which is also free (Harmonics)
      await tester.tap(find.byKey(const ValueKey('drawer_2_next_disc')));
      await tester.pumpAndSettle();

      final loadButton13 = find.byKey(const ValueKey('load_track_button_13'));
      expect(loadButton13, findsOneWidget);

      // Navigate to Track 14, 15, then Track 16 (Midnight Solitude Piano) which is premium locked
      await tester.tap(find.byKey(const ValueKey('drawer_2_next_disc')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('drawer_2_next_disc')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('drawer_2_next_disc')));
      await tester.pumpAndSettle();

      final lockedButton16 = find.byKey(const ValueKey('locked_track_button_16'));
      expect(lockedButton16, findsOneWidget);
      await tester.tap(lockedButton16);
      await tester.pumpAndSettle();

      // Studio Pro dialog is shown
      expect(find.text('ZYKL STUDIO PRO'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('MIDNIGHT SOLITUDE PIANO'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Drawer 2 premium tracks can be loaded when isProSimulated is true', (tester) async {
      await tester.pumpWidget(buildTestApp(isProSimulated: true));
      await tester.pumpAndSettle();

      // Open Drawer
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_1_handle')));
      await tester.pumpAndSettle();

      // Switch to Drawer 2
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_segment_2')));
      await tester.pumpAndSettle();

      // Navigate to Track 16
      await tester.tap(find.byKey(const ValueKey('drawer_2_next_disc')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('drawer_2_next_disc')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('drawer_2_next_disc')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('drawer_2_next_disc')));
      await tester.pumpAndSettle();

      // Track 16 should have load button when Pro
      final loadButton16 = find.byKey(const ValueKey('load_track_button_16'));
      expect(loadButton16, findsOneWidget);
      expect(find.byKey(const ValueKey('locked_track_button_16')), findsNothing);

      await tester.tap(loadButton16);
      await tester.pumpAndSettle();

      expect(find.text('[ ON PLATTER ]'), findsOneWidget);
    });
  });
}
