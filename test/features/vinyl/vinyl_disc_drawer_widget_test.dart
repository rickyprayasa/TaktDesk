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
    testWidgets('renders dual record drawers (Drawer 01 & Drawer 02) in closed state', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Verify both drawer handle plates are rendered
      expect(find.byKey(const ValueKey('vinyl_drawer_1_handle')), findsOneWidget);
      expect(find.byKey(const ValueKey('vinyl_drawer_2_handle')), findsOneWidget);

      expect(find.text('[ LACI 01 · NATURE ▾ ]'), findsOneWidget);
      expect(find.text('[ LACI 02 · HARMONICS ▾ ]'), findsOneWidget);

      // Carousels are closed initially
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('expanding Drawer 1 displays 6 sleeves and allows navigation', (tester) async {
      final mockAudio = MockAudioService();
      await tester.pumpWidget(buildTestApp(audioService: mockAudio));
      await tester.pumpAndSettle();

      // Tap Drawer 1 handle
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_1_handle')));
      await tester.pumpAndSettle();

      // Drawer 1 is open, Drawer 2 remains closed
      expect(find.text('[ LACI 01 · NATURE ▲ ]'), findsOneWidget);
      expect(find.text('[ LACI 02 · HARMONICS ▾ ]'), findsOneWidget);
      expect(mockAudio.playedEffects, contains(SoundEffect.drawerSlide));

      // PageView is visible with Drawer 1 items (0..5)
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('[ 01 / 06 ]'), findsOneWidget);
      expect(find.byKey(const ValueKey('record_sleeve_0')), findsOneWidget);
      expect(find.text('TK-01'), findsOneWidget);
      expect(find.text('LO-FI RAIN'), findsOneWidget);
      expect(find.text('[ ON PLATTER ]'), findsOneWidget);

      // Navigate to next disc in Drawer 1
      await tester.tap(find.byKey(const ValueKey('drawer_1_next_disc')));
      await tester.pumpAndSettle();

      expect(find.text('[ 02 / 06 ]'), findsOneWidget);
      expect(find.byKey(const ValueKey('record_sleeve_1')), findsOneWidget);
      expect(find.text('TK-02'), findsOneWidget);
      expect(find.text('DEEP BROWN NOISE'), findsOneWidget);
    });

    testWidgets('expanding Drawer 2 displays 6 sleeves (6..11) independently', (tester) async {
      final mockAudio = MockAudioService();
      await tester.pumpWidget(buildTestApp(audioService: mockAudio));
      await tester.pumpAndSettle();

      // Tap Drawer 2 handle
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_2_handle')));
      await tester.pumpAndSettle();

      // Drawer 1 is closed, Drawer 2 is open
      expect(find.text('[ LACI 01 · NATURE ▾ ]'), findsOneWidget);
      expect(find.text('[ LACI 02 · HARMONICS ▲ ]'), findsOneWidget);
      expect(mockAudio.playedEffects, contains(SoundEffect.drawerSlide));

      // Drawer 2 items start with index 6
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('[ 01 / 06 ]'), findsOneWidget);
      expect(find.byKey(const ValueKey('record_sleeve_6')), findsOneWidget);
      expect(find.text('TK-07'), findsOneWidget);
      expect(find.text('ALPINE MOUNTAIN BROOK'), findsOneWidget);
    });

    testWidgets('opening Drawer 2 closes Drawer 1, maintaining mutually exclusive single compact bay', (tester) async {
      final mockAudio = MockAudioService();
      await tester.pumpWidget(buildTestApp(audioService: mockAudio));
      await tester.pumpAndSettle();

      // Open Drawer 1
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_1_handle')));
      await tester.pumpAndSettle();

      // Drawer 1 is open
      expect(find.text('[ LACI 01 · NATURE ▲ ]'), findsOneWidget);
      expect(find.text('[ LACI 02 · HARMONICS ▾ ]'), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
      expect(find.byKey(const ValueKey('record_sleeve_0')), findsOneWidget);

      // Open Drawer 2 -> Drawer 1 is automatically closed/swapped, Drawer 2 is open
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_2_handle')));
      await tester.pumpAndSettle();

      expect(find.text('[ LACI 01 · NATURE ▾ ]'), findsOneWidget);
      expect(find.text('[ LACI 02 · HARMONICS ▲ ]'), findsOneWidget);
      // Still exactly 1 PageView, never elongated
      expect(find.byType(PageView), findsOneWidget);
      expect(find.byKey(const ValueKey('record_sleeve_6')), findsOneWidget);
      expect(mockAudio.playedEffects, contains(SoundEffect.switchClick));

      // Close Drawer 2 by tapping its handle again
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_2_handle')));
      await tester.pumpAndSettle();

      // Both show closed indicator, no PageView
      expect(find.text('[ LACI 01 · NATURE ▾ ]'), findsOneWidget);
      expect(find.text('[ LACI 02 · HARMONICS ▾ ]'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
      expect(mockAudio.playedEffects, contains(SoundEffect.drawerLatch));
    });

    testWidgets('interior segment rocker switches between Drawer 01 and Drawer 02', (tester) async {
      final mockAudio = MockAudioService();
      await tester.pumpWidget(buildTestApp(audioService: mockAudio));
      await tester.pumpAndSettle();

      // Open Drawer 1
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_1_handle')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('record_sleeve_0')), findsOneWidget);

      // Switch to Drawer 2 using interior segment pill
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_segment_2')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('record_sleeve_6')), findsOneWidget);
      expect(mockAudio.playedEffects, contains(SoundEffect.switchClick));

      // Switch back to Drawer 1 using interior segment pill
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_segment_1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('record_sleeve_0')), findsOneWidget);
    });

    testWidgets('loading track in Drawer 1 selects it onto the platter', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Open Drawer 1
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

    testWidgets('Drawer 2 premium tracks trigger Studio Pro dialog when locked', (tester) async {
      await tester.pumpWidget(buildTestApp(isProSimulated: false));
      await tester.pumpAndSettle();

      // Open Drawer 2
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_2_handle')));
      await tester.pumpAndSettle();

      // Track 6 is premium (Alpine Mountain Brook)
      final lockedButton = find.byKey(const ValueKey('locked_track_button_6'));
      expect(lockedButton, findsOneWidget);
      await tester.tap(lockedButton);
      await tester.pumpAndSettle();

      // Studio Pro dialog is shown
      expect(find.text('ZYKL STUDIO PRO'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('ALPINE MOUNTAIN BROOK'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Drawer 2 premium tracks can be loaded when isProSimulated is true', (tester) async {
      await tester.pumpWidget(buildTestApp(isProSimulated: true));
      await tester.pumpAndSettle();

      // Open Drawer 2
      await tester.tap(find.byKey(const ValueKey('vinyl_drawer_2_handle')));
      await tester.pumpAndSettle();

      // Track 6 should have load button
      final loadButton = find.byKey(const ValueKey('load_track_button_6'));
      expect(loadButton, findsOneWidget);
      expect(find.byKey(const ValueKey('locked_track_button_6')), findsNothing);

      await tester.tap(loadButton);
      await tester.pumpAndSettle();

      expect(find.text('[ ON PLATTER ]'), findsOneWidget);
    });
  });
}
