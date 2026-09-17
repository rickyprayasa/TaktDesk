import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/takt_colors.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/audio/sound_effect.dart';
import 'package:takt_desk/features/desk/presentation/widgets/desk_spec_plate_widget.dart';
import 'package:takt_desk/features/desk/presentation/widgets/desk_telemetry_slip_widget.dart';
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
          todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value([])),
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

    final plateSurface = find.byKey(const ValueKey('desk_spec_plate_surface'));
    expect(find.descendant(of: plateSurface, matching: find.text('BRAUN CLASSIC')), findsOneWidget);
    expect(find.descendant(of: plateSurface, matching: find.textContaining('MOD. 01')), findsOneWidget);
    expect(find.descendant(of: plateSurface, matching: find.textContaining('1960')), findsOneWidget);
    expect(find.descendant(of: plateSurface, matching: find.textContaining('GERMANIC MINIMALISM')), findsOneWidget);
    expect(find.descendant(of: plateSurface, matching: find.textContaining('STEREO 44.1kHz')), findsOneWidget);
    expect(find.descendant(of: plateSurface, matching: find.textContaining('2 / 4 CYCLES')), findsOneWidget);
    expect(find.descendant(of: plateSurface, matching: find.textContaining('50 MIN FOCUSED')), findsOneWidget);
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
          todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value([])),
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

    final plateSurface = find.byKey(const ValueKey('desk_spec_plate_surface'));
    expect(find.descendant(of: plateSurface, matching: find.textContaining('0 / 4 CYCLES')), findsOneWidget);
    expect(find.descendant(of: plateSurface, matching: find.textContaining('0 MIN FOCUSED')), findsOneWidget);

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
          todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value([])),
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

    final plateSurface = find.byKey(const ValueKey('desk_spec_plate_surface'));
    expect(find.descendant(of: plateSurface, matching: find.textContaining('4 / 4 CYCLES')), findsOneWidget);
    expect(find.descendant(of: plateSurface, matching: find.textContaining('100 MIN FOCUSED')), findsOneWidget);

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
          todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value([])),
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

    await tester.tap(find.byKey(const ValueKey('desk_spec_plate_surface')));
    await tester.pumpAndSettle();

    expect(mockAudio.playedEffects, contains(SoundEffect.dialClick));
  });

  testWidgets('DeskSpecPlateWidget renders in light mode without error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value([])),
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

    final plateSurface = find.byKey(const ValueKey('desk_spec_plate_surface'));
    expect(find.descendant(of: plateSurface, matching: find.text('BRAUN CLASSIC')), findsOneWidget);
    expect(find.descendant(of: plateSurface, matching: find.textContaining('3 / 4 CYCLES')), findsOneWidget);

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
        todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value([])),
        todayFocusStatsProvider.overrideWith(
          (ref) => Stream.value(const TodayFocusStats(completedCount: 1, totalMinutes: 25)),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(chassisThemeProvider.notifier).setDarkMode(true);
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

    final plateSurface = find.byKey(const ValueKey('desk_spec_plate_surface'));
    expect(find.descendant(of: plateSurface, matching: find.text('TITANIUM STEALTH')), findsOneWidget);
    expect(find.descendant(of: plateSurface, matching: find.textContaining('AEROSPACE PVD GRADE 5')), findsOneWidget);

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

  testWidgets('DeskSpecPlateWidget has maxWidth 280 and fits all text without truncation on narrow screens', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value([])),
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

    // Verify plate container width does not exceed 340 (matching modular instrument chassis)
    final plateContainerFinder = find.descendant(
      of: find.byType(DeskSpecPlateWidget),
      matching: find.byType(Container),
    ).first;
    final innerContainerBox = tester.renderObject(plateContainerFinder) as RenderBox;
    expect(innerContainerBox.size.width, lessThanOrEqualTo(340.0));

    final plateSurface = find.byKey(const ValueKey('desk_spec_plate_surface'));
    // Verify all text elements are present
    expect(find.descendant(of: plateSurface, matching: find.text('BRAUN CLASSIC')), findsOneWidget);
    expect(find.descendant(of: plateSurface, matching: find.textContaining('MOD. 01')), findsOneWidget);
    expect(find.descendant(of: plateSurface, matching: find.textContaining('1960')), findsOneWidget);
    expect(find.descendant(of: plateSurface, matching: find.textContaining('GERMANIC MINIMALISM')), findsOneWidget);
    expect(find.descendant(of: plateSurface, matching: find.textContaining('STEREO 44.1kHz')), findsOneWidget);
    expect(find.descendant(of: plateSurface, matching: find.textContaining('2 / 4 CYCLES')), findsOneWidget);
    expect(find.descendant(of: plateSurface, matching: find.textContaining('50 MIN FOCUSED')), findsOneWidget);

    // Verify that NO Text widget in the plate has overflow: TextOverflow.ellipsis
    // (labels are structured to fit naturally and scale with FittedBox rather than clipping with ellipsis)
    final textWidgets = tester.widgetList<Text>(find.descendant(
      of: plateSurface,
      matching: find.byType(Text),
    ));
    for (final text in textWidgets) {
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    }
  });

  testWidgets('DeskSpecPlateWidget renders dark obsidian text on light plates in light mode for Mid-Century Walnut', (tester) async {
    final themeNotifier = ThemeController(
      initial: const ChassisThemeState(
        isDarkMode: false,
        edition: HardwareEdition.midCenturyWalnut,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chassisThemeProvider.overrideWith((ref) => themeNotifier),
          todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value([])),
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

    final plateSurface = find.byKey(const ValueKey('desk_spec_plate_surface'));
    final titleText = tester.widget<Text>(find.descendant(of: plateSurface, matching: find.text('MID-CENTURY WALNUT')));
    expect(titleText.style?.color, equals(TaktColors.chassisObsidian));
  });

  testWidgets('DeskSpecPlateWidget opens DeskTelemetryDialog modal on plate tap and dismisses cleanly', (tester) async {
    final mockAudio = MockAudioService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(mockAudio),
          todayFocusStatsProvider.overrideWith(
            (ref) => Stream.value(const TodayFocusStats(completedCount: 1, totalMinutes: 25)),
          ),
          todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DeskSpecPlateWidget(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The plate itself is compact and does not embed DeskTelemetrySlipWidget directly in tree
    expect(find.byType(DeskTelemetryDialog), findsNothing);
    expect(find.byType(DeskTelemetrySlipWidget), findsNothing);

    // Tap plate to open modal dialog
    await tester.tap(find.byKey(const ValueKey('desk_spec_plate_surface')));
    await tester.pumpAndSettle();

    // Dialog is now displayed centered on screen
    expect(find.byType(DeskTelemetryDialog), findsOneWidget);
    expect(find.byType(DeskTelemetrySlipWidget), findsOneWidget);
    expect(find.textContaining('ZYKL // SESSION TELEMETRY'), findsOneWidget);
    expect(find.byKey(const ValueKey('telemetry_copy_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('telemetry_close_button')), findsOneWidget);
    expect(mockAudio.playedEffects, contains(SoundEffect.dialClick));

    // Tap close button on dialog
    await tester.tap(find.byKey(const ValueKey('telemetry_close_button')));
    await tester.pumpAndSettle();

    // Dialog dismissed; main plate remains intact
    expect(find.byType(DeskTelemetryDialog), findsNothing);
    expect(find.byType(DeskTelemetrySlipWidget), findsNothing);
    expect(find.byKey(const ValueKey('desk_spec_plate_surface')), findsOneWidget);

    // Tap plate again to open and dismiss via barrier tap
    await tester.tap(find.byKey(const ValueKey('desk_spec_plate_surface')));
    await tester.pumpAndSettle();
    expect(find.byType(DeskTelemetryDialog), findsOneWidget);

    // Tap top-left edge outside the 280px dialog to trigger barrier dismissal
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(DeskTelemetryDialog), findsNothing);
  });
}

