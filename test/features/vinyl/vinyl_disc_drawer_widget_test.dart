import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';
import 'package:takt_desk/features/vinyl/domain/vinyl_track.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp({
    bool isProSimulated = false,
    int initialTrackIndex = 0,
    bool initialDrawerOpen = false,
  }) {
    final prefsController =
        FakeDeskPreferencesController(isProSimulated: isProSimulated);

    return ProviderScope(
      overrides: [
        deskPreferencesControllerProvider.overrideWith((ref) => prefsController),
        vinylProvider.overrideWith((ref) {
          final controller = VinylController(AudioService(isMock: true));
          if (initialTrackIndex != 0) {
            controller.selectTrack(initialTrackIndex, isPro: isProSimulated);
          }
          if (initialDrawerOpen) {
            controller.setDrawerOpen(true);
          }
          return controller;
        }),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: VinylDiscDrawerWidget(),
            ),
          ),
        ),
      ),
    );
  }

  group('VinylDiscDrawerWidget', () {
    testWidgets('Initial closed state displays handle bar with [ RECORD DRAWER // 12 DISCS ▾ ]',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('[ RECORD DRAWER // 12 DISCS ▾ ]'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.label == 'Toggle record crate drawer'),
        findsOneWidget,
      );
      // Carousel interior bay should not be shown when closed
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('Tapping handle opens drawer and displays carousel with 12 cards',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap handle
      await tester.tap(find.text('[ RECORD DRAWER // 12 DISCS ▾ ]'));
      await tester.pumpAndSettle();

      // Drawer is open
      expect(find.text('[ RECORD DRAWER // 12 DISCS ▲ ]'), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('[ 01 / 12 ]'), findsOneWidget);
      expect(find.byKey(const ValueKey('drawer_prev_disc')), findsOneWidget);
      expect(find.byKey(const ValueKey('drawer_next_disc')), findsOneWidget);

      // First sleeve is visible
      expect(find.byKey(const ValueKey('record_sleeve_0')), findsOneWidget);
      expect(find.text('TK-01'), findsOneWidget);
      expect(find.text('LO-FI RAIN'), findsOneWidget);
      expect(find.text('[ ON PLATTER ]'), findsOneWidget);

      // Verify all 12 sleeves can be scrolled/navigated to
      for (int i = 1; i < 12; i++) {
        await tester.tap(find.byKey(const ValueKey('drawer_next_disc')));
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('record_sleeve_$i')), findsOneWidget);
        expect(find.text(VinylTrack.presets[i].catalogId), findsOneWidget);
      }
    });

    testWidgets('Tapping [ LOAD TO PLATTER ] calls controller.selectTrack(index)',
        (tester) async {
      await tester.pumpWidget(buildTestApp(initialDrawerOpen: true));
      await tester.pumpAndSettle();

      // Initially on track 0
      expect(find.text('[ ON PLATTER ]'), findsOneWidget);

      // Navigate to Track 1
      await tester.tap(find.byKey(const ValueKey('drawer_next_disc')));
      await tester.pumpAndSettle();

      expect(find.text('[ 02 / 12 ]'), findsOneWidget);
      expect(find.text('DEEP BROWN NOISE'), findsOneWidget);
      final loadButton = find.byKey(const ValueKey('load_track_button_1'));
      expect(loadButton, findsOneWidget);
      expect(
        find.descendant(of: loadButton, matching: find.text('[ LOAD TO PLATTER ]')),
        findsOneWidget,
      );

      // Tap load to platter
      await tester.tap(loadButton);
      await tester.pumpAndSettle();

      // Now Track 1 is active on platter
      expect(find.text('[ ON PLATTER ]'), findsOneWidget);
      expect(find.byKey(const ValueKey('load_track_button_1')), findsNothing);
    });

    testWidgets('Tapping locked track opens showStudioProDialog when isPro == false',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        initialDrawerOpen: true,
        isProSimulated: false,
      ));
      await tester.pumpAndSettle();

      // Navigate to Track 4 (Campfire Embers - premium)
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const ValueKey('drawer_next_disc')));
        await tester.pumpAndSettle();
      }

      expect(find.text('[ 05 / 12 ]'), findsOneWidget);
      expect(find.text('CAMPFIRE EMBERS'), findsOneWidget);
      final lockedButton = find.byKey(const ValueKey('locked_track_button_4'));
      expect(lockedButton, findsOneWidget);
      expect(
        find.descendant(of: lockedButton, matching: find.text('[ STUDIO PRO 🔒 ]')),
        findsOneWidget,
      );

      // Tap locked button
      await tester.tap(lockedButton);
      await tester.pumpAndSettle();

      // Studio Pro dialog should appear
      expect(find.text('ZYKL STUDIO PRO'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('CAMPFIRE EMBERS'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('When isPro == true, premium track displays [ LOAD TO PLATTER ]',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        initialDrawerOpen: true,
        isProSimulated: true,
      ));
      await tester.pumpAndSettle();

      // Navigate to Track 4
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const ValueKey('drawer_next_disc')));
        await tester.pumpAndSettle();
      }

      expect(find.text('CAMPFIRE EMBERS'), findsOneWidget);
      final loadButton = find.byKey(const ValueKey('load_track_button_4'));
      expect(loadButton, findsOneWidget);
      expect(find.byKey(const ValueKey('locked_track_button_4')), findsNothing);

      // Tap load button
      await tester.tap(loadButton);
      await tester.pumpAndSettle();

      expect(find.text('[ ON PLATTER ]'), findsOneWidget);
    });

    testWidgets('Tapping handle while open closes the drawer', (tester) async {
      await tester.pumpWidget(buildTestApp(initialDrawerOpen: true));
      await tester.pumpAndSettle();

      expect(find.text('[ RECORD DRAWER // 12 DISCS ▲ ]'), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);

      await tester.tap(find.text('[ RECORD DRAWER // 12 DISCS ▲ ]'));
      await tester.pumpAndSettle();

      expect(find.text('[ RECORD DRAWER // 12 DISCS ▾ ]'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
    });
  });
}
