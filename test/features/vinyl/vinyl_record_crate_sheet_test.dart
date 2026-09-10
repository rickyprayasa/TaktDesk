import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';
import 'package:takt_desk/features/vinyl/domain/vinyl_track.dart';
import 'package:takt_desk/features/vinyl/presentation/vinyl_controller.dart';
import 'package:takt_desk/features/vinyl/presentation/widgets/vinyl_record_crate_sheet.dart';

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
    void Function(ProviderContainer)? onContainerReady,
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
          return controller;
        }),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                key: const ValueKey('open_crate_button'),
                onPressed: () => VinylRecordCrateSheet.show(context),
                child: const Text('OPEN CRATE'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('VinylRecordCrateSheet', () {
    testWidgets('Opening VinylRecordCrateSheet displays header and counter [ 01 / 08 ]',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.byKey(const ValueKey('open_crate_button')));
      await tester.pumpAndSettle();

      expect(find.byType(VinylRecordCrateSheet), findsOneWidget);
      expect(find.textContaining('ANALOG RECORD CRATE'), findsOneWidget);
      expect(find.text('[ 01 / 08 ]'), findsOneWidget);
      expect(find.byKey(const ValueKey('crate_close_button')), findsOneWidget);
    });

    testWidgets('Displays 8 record sleeve cards with keys record_sleeve_0 through record_sleeve_7',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.byKey(const ValueKey('open_crate_button')));
      await tester.pumpAndSettle();

      // First card should be visible immediately
      expect(find.byKey(const ValueKey('record_sleeve_0')), findsOneWidget);
      expect(find.text('TK-01'), findsOneWidget);
      expect(find.text('LO-FI RAIN'), findsOneWidget);

      // Verify all 8 sleeve cards exist by swiping across the PageView
      for (int i = 1; i < 8; i++) {
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('record_sleeve_$i')), findsOneWidget);
        expect(find.text(VinylTrack.presets[i].catalogId), findsOneWidget);
      }
    });

    testWidgets('Track 0 shows [ ON PLATTER ] when selected', (tester) async {
      await tester.pumpWidget(buildTestApp(initialTrackIndex: 0));
      await tester.tap(find.byKey(const ValueKey('open_crate_button')));
      await tester.pumpAndSettle();

      final sleeve0 = find.byKey(const ValueKey('record_sleeve_0'));
      expect(
        find.descendant(of: sleeve0, matching: find.text('[ ON PLATTER ]')),
        findsOneWidget,
      );
    });

    testWidgets('Tapping record_sleeve_1 calls controller.selectTrack(1) and pops the sheet',
        (tester) async {
      await tester.pumpWidget(buildTestApp(initialTrackIndex: 0));
      await tester.tap(find.byKey(const ValueKey('open_crate_button')));
      await tester.pumpAndSettle();

      // Swipe to track 1
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Tap load track 1 button or sleeve card
      final loadButton1 = find.byKey(const ValueKey('load_track_button_1'));
      expect(loadButton1, findsOneWidget);
      await tester.tap(loadButton1);
      await tester.pumpAndSettle();

      // Sheet should be popped
      expect(find.byType(VinylRecordCrateSheet), findsNothing);

      // Reopen sheet and verify track 1 is now on platter
      await tester.tap(find.byKey(const ValueKey('open_crate_button')));
      await tester.pumpAndSettle();

      final sleeve1 = find.byKey(const ValueKey('record_sleeve_1'));
      expect(
        find.descendant(of: sleeve1, matching: find.text('[ ON PLATTER ]')),
        findsOneWidget,
      );
    });

    testWidgets('Track 4 (Campfire) displays STUDIO PRO badge when isProSimulated == false',
        (tester) async {
      await tester.pumpWidget(buildTestApp(isProSimulated: false));
      await tester.tap(find.byKey(const ValueKey('open_crate_button')));
      await tester.pumpAndSettle();

      // Swipe to track 4
      for (int i = 0; i < 4; i++) {
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();
      }

      final sleeve4 = find.byKey(const ValueKey('record_sleeve_4'));
      expect(sleeve4, findsOneWidget);
      expect(find.byKey(const ValueKey('locked_track_button_4')), findsOneWidget);
      expect(
        find.descendant(of: sleeve4, matching: find.textContaining('STUDIO PRO')),
        findsWidgets,
      );
    });

    testWidgets('Tapping locked track opens Studio Pro dialog and unlocks track on confirmation',
        (tester) async {
      await tester.pumpWidget(buildTestApp(isProSimulated: false));
      await tester.tap(find.byKey(const ValueKey('open_crate_button')));
      await tester.pumpAndSettle();

      // Swipe to track 4
      for (int i = 0; i < 4; i++) {
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();
      }

      // Tap locked track button
      await tester.tap(find.byKey(const ValueKey('locked_track_button_4')));
      await tester.pumpAndSettle();

      // Studio Pro dialog appears
      expect(find.text('TAKT DESK STUDIO PRO'), findsOneWidget);
      expect(find.textContaining('CAMPFIRE EMBERS'), findsWidgets);

      final unlockButton = find.byKey(const ValueKey('pro_dialog_unlock_button'));
      expect(unlockButton, findsOneWidget);

      await tester.tap(unlockButton);
      await tester.pumpAndSettle();

      // Dialog dismissed
      expect(find.text('TAKT DESK STUDIO PRO'), findsNothing);

      // Now track 4 is equipped and shows [ ON PLATTER ]
      final sleeve4 = find.byKey(const ValueKey('record_sleeve_4'));
      expect(
        find.descendant(of: sleeve4, matching: find.text('[ ON PLATTER ]')),
        findsOneWidget,
      );
    });

    testWidgets('When isProSimulated == true, Track 4 displays [ LOAD ON PLATTER ] and equips track',
        (tester) async {
      await tester.pumpWidget(buildTestApp(isProSimulated: true, initialTrackIndex: 0));
      await tester.tap(find.byKey(const ValueKey('open_crate_button')));
      await tester.pumpAndSettle();

      // Swipe to track 4
      for (int i = 0; i < 4; i++) {
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();
      }

      final loadButton4 = find.byKey(const ValueKey('load_track_button_4'));
      expect(loadButton4, findsOneWidget);

      await tester.tap(loadButton4);
      await tester.pumpAndSettle();

      // Sheet popped
      expect(find.byType(VinylRecordCrateSheet), findsNothing);

      // Reopen to verify track 4 is on platter (sheet opens on active track 4)
      await tester.tap(find.byKey(const ValueKey('open_crate_button')));
      await tester.pumpAndSettle();

      final sleeve4 = find.byKey(const ValueKey('record_sleeve_4'));
      expect(
        find.descendant(of: sleeve4, matching: find.text('[ ON PLATTER ]')),
        findsOneWidget,
      );
    });

    testWidgets('Close button dismisses the sheet', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.byKey(const ValueKey('open_crate_button')));
      await tester.pumpAndSettle();

      expect(find.byType(VinylRecordCrateSheet), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('crate_close_button')));
      await tester.pumpAndSettle();

      expect(find.byType(VinylRecordCrateSheet), findsNothing);
    });

    testWidgets('Swiping page updates counter', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.byKey(const ValueKey('open_crate_button')));
      await tester.pumpAndSettle();

      expect(find.text('[ 01 / 08 ]'), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(find.text('[ 02 / 08 ]'), findsOneWidget);
    });
  });
}
