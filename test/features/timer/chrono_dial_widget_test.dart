import 'dart:ui';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/takt_colors.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_phase.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_painter.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_widget.dart';
import 'package:takt_desk/features/timer/presentation/widgets/crown_push_button.dart';
import 'package:takt_desk/features/timer/presentation/widgets/mechanical_flip_digit.dart';
import 'package:takt_desk/features/timer/presentation/widgets/split_flap_board_widget.dart';
import 'package:takt_desk/features/timer/presentation/widgets/split_flap_tile.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  final dialFinder = find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is ChronoDialPainter,
  );

  void expectDisplay(WidgetTester tester, int minutes, int seconds) {
    final display = tester.widget<MechanicalCounterDisplay>(
      find.byType(MechanicalCounterDisplay, skipOffstage: false),
    );
    expect(display.minutes, minutes);
    expect(display.seconds, seconds);
  }

  testWidgets('ChronoDialWidget renders initial state and custom painter', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoDialWidget(),
            ),
          ),
        ),
      ),
    );

    // Verify initial time display and target duration label (25 MIN)
    expect(find.byType(MechanicalCounterDisplay, skipOffstage: false), findsOneWidget);
    expectDisplay(tester, 25, 0);
    expect(find.text('25 MIN'), findsOneWidget);

    // Verify CustomPaint with ChronoDialPainter is rendered
    expect(dialFinder, findsOneWidget);

    // Verify adjust duration buttons exist
    expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ChronoDialWidget increments and decrements target minutes', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoDialWidget(),
            ),
          ),
        ),
      ),
    );

    // Tap '+' button
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();
    expect(find.text('30 MIN'), findsOneWidget);
    expectDisplay(tester, 30, 0);

    // Tap '-' button twice
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pump();
    expect(find.text('25 MIN'), findsOneWidget);
    expectDisplay(tester, 25, 0);

    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pump();
    expect(find.text('20 MIN'), findsOneWidget);
    expectDisplay(tester, 20, 0);

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ChronoDialWidget starts and pauses on dial tap', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoDialWidget(),
            ),
          ),
        ),
      ),
    );

    // Tap dial to start
    await tester.tap(dialFinder);
    await tester.pump();

    // Advance 1 second
    await tester.pump(const Duration(seconds: 1));
    expectDisplay(tester, 24, 59);

    // Tap dial to pause
    await tester.tap(dialFinder);
    await tester.pump();

    // Advance 2 seconds and verify counter stays paused
    await tester.pump(const Duration(seconds: 2));
    expectDisplay(tester, 24, 59);

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ChronoDialWidget disables duration buttons while running', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoDialWidget(),
            ),
          ),
        ),
      ),
    );

    // Initial state: buttons enabled
    final removeFinder = find.widgetWithIcon(IconButton, Icons.remove_circle_outline);
    final addFinder = find.widgetWithIcon(IconButton, Icons.add_circle_outline);

    IconButton removeButton = tester.widget(removeFinder);
    IconButton addButton = tester.widget(addFinder);
    expect(removeButton.onPressed, isNotNull);
    expect(addButton.onPressed, isNotNull);

    // Start timer
    await tester.tap(dialFinder);
    await tester.pump();

    // While running: buttons disabled
    removeButton = tester.widget(removeFinder);
    addButton = tester.widget(addFinder);
    expect(removeButton.onPressed, isNull);
    expect(addButton.onPressed, isNull);

    // Tapping disabled button should have no effect
    await tester.tap(addFinder);
    await tester.pump();
    expect(find.text('25 MIN'), findsOneWidget);

    // Pause timer
    await tester.tap(dialFinder);
    await tester.pump();

    // Paused: buttons enabled again
    removeButton = tester.widget(removeFinder);
    addButton = tester.widget(addFinder);
    expect(removeButton.onPressed, isNotNull);
    expect(addButton.onPressed, isNotNull);

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ChronoDialWidget restarts after expiration on dial tap', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoDialWidget(),
            ),
          ),
        ),
      ),
    );

    // Decrement to 5 MIN
    final removeFinder = find.widgetWithIcon(IconButton, Icons.remove_circle_outline);
    for (int i = 0; i < 4; i++) {
      await tester.tap(removeFinder);
      await tester.pump();
    }
    expect(find.text('5 MIN'), findsOneWidget);
    expectDisplay(tester, 5, 0);

    // Start timer
    await tester.tap(dialFinder);
    await tester.pump();

    // Advance 301 seconds to expire timer -> auto-advances to Short Break (5 mins) in Standby
    await tester.pump(const Duration(seconds: 301));
    expectDisplay(tester, 5, 0);

    // Tap dial to start the standby short break session
    await tester.tap(dialFinder);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expectDisplay(tester, 4, 59);

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ChronoDialWidget sets target minutes via rotary pan drag', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoDialWidget(),
            ),
          ),
        ),
      ),
    );

    // Initial state is 25 MIN
    expect(find.text('25 MIN'), findsOneWidget);

    // Drag from center rightwards (3 o'clock position = 15 MIN)
    final dialCenter = tester.getCenter(dialFinder);
    final gesture = await tester.startGesture(dialCenter + const Offset(50, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    // The dial target minutes should update to 15 MIN
    expect(find.text('15 MIN'), findsOneWidget);
    expectDisplay(tester, 15, 0);

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ChronoDialWidget passes themeState.needleColor and filamentColor to ChronoDialPainter and updates on live edition change', (tester) async {
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(testDb.close);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(testDb),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoDialWidget(),
            ),
          ),
        ),
      ),
    );

    // Initial default: Braun Classic
    var customPaint = tester.widget<CustomPaint>(dialFinder);
    var painter = customPaint.painter as ChronoDialPainter;
    expect(painter.needleColor, equals(const Color(0xFFC85A32))); // mutedOchre
    expect(painter.filamentColor, equals(const Color(0xFFD99B59))); // filamentAmber

    // Live update to Titanium Stealth
    container.read(chassisThemeProvider.notifier).setHardwareEdition(HardwareEditionType.titaniumStealth);
    await tester.pump();

    customPaint = tester.widget<CustomPaint>(dialFinder);
    painter = customPaint.painter as ChronoDialPainter;
    expect(painter.needleColor, equals(const Color(0xFF3A86FF))); // electric cobalt
    expect(painter.filamentColor, equals(const Color(0xFFFF9E00))); // vivid amber neon
  });

  testWidgets('ChronoDialWidget adapts dial bezel, crown, split flap, and pill timer to rawBrassPatina edition', (tester) async {
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(testDb.close);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(testDb),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoDialWidget(),
            ),
          ),
        ),
      ),
    );

    // Initial default: Braun Classic
    var customPaint = tester.widget<CustomPaint>(dialFinder);
    var painter = customPaint.painter as ChronoDialPainter;
    expect(painter.outerBezelGradient, equals(HardwareEdition.braunClassic.plateGradientDark));
    expect(painter.innerBezelColor, equals(HardwareEdition.braunClassic.darkBorder));

    // Initial crown push button
    var crownWidget = tester.widget<CrownPushButton>(find.byType(CrownPushButton));
    expect(crownWidget.gradientColors, equals(HardwareEdition.braunClassic.plateGradientDark));
    expect(crownWidget.borderColor, equals(HardwareEdition.braunClassic.darkBorder));
    expect(crownWidget.stemColor, equals(HardwareEdition.braunClassic.darkModuleBg));

    // Pill timer initial
    var pillContainer = tester.widget<Container>(
      find.ancestor(
        of: find.byIcon(Icons.remove_circle_outline),
        matching: find.byType(Container),
      ).first,
    );
    var pillDeco = pillContainer.decoration as BoxDecoration;
    expect((pillDeco.border as Border).top.color, equals(HardwareEdition.braunClassic.darkBorder));
    expect(pillDeco.color, equals(HardwareEdition.braunClassic.darkModuleBg));

    // Split flap board initial
    var splitFlapContainer = tester.widget<Container>(
      find.descendant(
        of: find.byType(SplitFlapBoardWidget),
        matching: find.byType(Container),
      ).first,
    );
    var splitFlapDeco = splitFlapContainer.decoration as BoxDecoration;
    expect((splitFlapDeco.border as Border).top.color, equals(HardwareEdition.braunClassic.darkBorder));
    expect(splitFlapDeco.color, equals(HardwareEdition.braunClassic.darkModuleBg));

    // Switch to Raw Brass & Patina edition
    container.read(chassisThemeProvider.notifier).setHardwareEdition(HardwareEditionType.rawBrassPatina);
    await tester.pump();

    // Verify ChronoDialPainter configured with brass plate gradient and border color
    customPaint = tester.widget<CustomPaint>(dialFinder);
    painter = customPaint.painter as ChronoDialPainter;
    expect(painter.outerBezelGradient, equals(HardwareEdition.rawBrassPatina.plateGradientDark));
    expect(painter.innerBezelColor, equals(HardwareEdition.rawBrassPatina.darkBorder));

    // Verify CrownPushButton adapts to rawBrassPatina
    crownWidget = tester.widget<CrownPushButton>(find.byType(CrownPushButton));
    expect(crownWidget.gradientColors, equals(HardwareEdition.rawBrassPatina.plateGradientDark));
    expect(crownWidget.borderColor, equals(HardwareEdition.rawBrassPatina.darkBorder));
    expect(crownWidget.stemColor, equals(HardwareEdition.rawBrassPatina.darkModuleBg));

    // Verify Pill timer container adapts to rawBrassPatina
    pillContainer = tester.widget<Container>(
      find.ancestor(
        of: find.byIcon(Icons.remove_circle_outline),
        matching: find.byType(Container),
      ).first,
    );
    pillDeco = pillContainer.decoration as BoxDecoration;
    expect((pillDeco.border as Border).top.color, equals(HardwareEdition.rawBrassPatina.darkBorder));
    expect(pillDeco.color, equals(HardwareEdition.rawBrassPatina.darkModuleBg));

    // Verify Split flap board container adapts to rawBrassPatina
    splitFlapContainer = tester.widget<Container>(
      find.descendant(
        of: find.byType(SplitFlapBoardWidget),
        matching: find.byType(Container),
      ).first,
    );
    splitFlapDeco = splitFlapContainer.decoration as BoxDecoration;
    expect((splitFlapDeco.border as Border).top.color, equals(HardwareEdition.rawBrassPatina.darkBorder));
    expect(splitFlapDeco.color, equals(HardwareEdition.rawBrassPatina.darkModuleBg));
  });

  testWidgets('ChronoDialWidget applies chassisTextColor in light mode and forwards textureType to painter', (tester) async {
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(testDb.close);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(testDb),
      ],
    );
    addTearDown(container.dispose);

    // Switch to Light Mode
    container.read(chassisThemeProvider.notifier).setDarkMode(false);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoDialWidget(),
            ),
          ),
        ),
      ),
    );

    final themeState = container.read(chassisThemeProvider);
    expect(themeState.isDarkMode, isFalse);
    expect(themeState.chassisTextColor, equals(const Color(0xFF1B1E23)));

    // Stopped state: Duration text '25 MIN' and icons use chassisTextColor
    final durationText = tester.widget<Text>(find.text('25 MIN'));
    expect(durationText.style?.color, equals(const Color(0xFF1B1E23)));

    final removeIcon = tester.widget<Icon>(find.byIcon(Icons.remove_circle_outline));
    expect(removeIcon.color, equals(const Color(0xFF1B1E23)));

    final addIcon = tester.widget<Icon>(find.byIcon(Icons.add_circle_outline));
    expect(addIcon.color, equals(const Color(0xFF1B1E23)));

    // ChronoDialPainter receives textureType matching active edition (braunClassic -> matteAbsGrain)
    var customPaint = tester.widget<CustomPaint>(dialFinder);
    var painter = customPaint.painter as ChronoDialPainter;
    expect(painter.textureType, equals(HardwareTextureType.matteAbsGrain));

    // When running: Duration text uses filamentColor, icons use borderColor
    await tester.tap(dialFinder);
    await tester.pump();

    final runningThemeState = container.read(chassisThemeProvider);
    final runningDurationText = tester.widget<Text>(find.text('25 MIN'));
    expect(runningDurationText.style?.color, equals(runningThemeState.filamentColor));

    final runningRemoveIcon = tester.widget<Icon>(find.byIcon(Icons.remove_circle_outline));
    expect(runningRemoveIcon.color, equals(runningThemeState.borderColor));

    final runningAddIcon = tester.widget<Icon>(find.byIcon(Icons.add_circle_outline));
    expect(runningAddIcon.color, equals(runningThemeState.borderColor));

    // Pause timer
    await tester.tap(dialFinder);
    await tester.pump();

    // Verify textureType forwards when changing edition
    container.read(chassisThemeProvider.notifier).setHardwareEdition(HardwareEditionType.rawBrassPatina);
    await tester.pump();

    customPaint = tester.widget<CustomPaint>(dialFinder);
    painter = customPaint.painter as ChronoDialPainter;
    expect(painter.textureType, equals(HardwareTextureType.burnishedBrass));
  });

  test('ChronoDialPainter shouldRepaint returns true when textureType changes', () {
    final painter1 = ChronoDialPainter(
      remainingSeconds: 1500,
      targetMinutes: 25,
      isRunning: false,
      textureType: HardwareTextureType.matteAbsGrain,
    );
    final painter2 = ChronoDialPainter(
      remainingSeconds: 1500,
      targetMinutes: 25,
      isRunning: false,
      textureType: HardwareTextureType.burnishedBrass,
    );
    expect(painter1.shouldRepaint(painter2), isTrue);
  });

  testWidgets('ChronoDialWidget passes isDark false and edition-specific light dial tone to ChronoDialPainter in Light Mode', (tester) async {
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(testDb.close);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(testDb),
      ],
    );
    addTearDown(container.dispose);

    // Switch to Light Mode
    container.read(chassisThemeProvider.notifier).setDarkMode(false);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoDialWidget(),
            ),
          ),
        ),
      ),
    );

    // Initial default: Braun Classic Light Mode
    var customPaint = tester.widget<CustomPaint>(dialFinder);
    var painter = customPaint.painter as ChronoDialPainter;
    expect(painter.isDark, isFalse);
    expect(painter.dialFaceColor, equals(const Color(0xFFEAE6DC)));

    // Switch to Titanium Stealth
    container.read(chassisThemeProvider.notifier).setHardwareEdition(HardwareEditionType.titaniumStealth);
    await tester.pump();
    customPaint = tester.widget<CustomPaint>(dialFinder);
    painter = customPaint.painter as ChronoDialPainter;
    expect(painter.dialFaceColor, equals(const Color(0xFFD3D8E0)));

    // Switch to Bauhaus Heritage
    container.read(chassisThemeProvider.notifier).setHardwareEdition(HardwareEditionType.bauhausHeritage);
    await tester.pump();
    customPaint = tester.widget<CustomPaint>(dialFinder);
    painter = customPaint.painter as ChronoDialPainter;
    expect(painter.dialFaceColor, equals(const Color(0xFFF0EDE4)));

    // Switch to Raw Brass & Patina
    container.read(chassisThemeProvider.notifier).setHardwareEdition(HardwareEditionType.rawBrassPatina);
    await tester.pump();
    customPaint = tester.widget<CustomPaint>(dialFinder);
    painter = customPaint.painter as ChronoDialPainter;
    expect(painter.dialFaceColor, equals(const Color(0xFFE2DCB8)));

    // Switch back to Dark Mode
    container.read(chassisThemeProvider.notifier).setDarkMode(true);
    await tester.pump();
    customPaint = tester.widget<CustomPaint>(dialFinder);
    painter = customPaint.painter as ChronoDialPainter;
    expect(painter.isDark, isTrue);
  });

  test('ChronoDialPainter configures authentic light-mode horological colors and dark ticks/numerals', () {
    final lightPainter = ChronoDialPainter(
      remainingSeconds: 1500,
      targetMinutes: 25,
      isRunning: false,
      isDark: false,
      dialFaceColor: const Color(0xFFEAE6DC),
      textureType: HardwareTextureType.matteAbsGrain,
    );

    expect(lightPainter.isDark, isFalse);
    expect(lightPainter.dialFaceColor, equals(const Color(0xFFEAE6DC)));
    expect(lightPainter.activeDialFaceColor, equals(const Color(0xFFEAE6DC)));
    expect(lightPainter.majorTickColor, equals(const Color(0xFF1B1E23).withValues(alpha: 0.88)));
    expect(lightPainter.minorTickColor, equals(const Color(0xFF1B1E23).withValues(alpha: 0.38)));
    expect(lightPainter.numeralColor, equals(const Color(0xFF1B1E23).withValues(alpha: 0.78)));
    expect(lightPainter.dishShadowColor, equals(Colors.black.withValues(alpha: 0.12)));
    expect(lightPainter.hubCapColor, equals(const Color(0xFF2B2E34)));
    expect(lightPainter.glassHighlightAlphas, equals(const [0.28, 0.06]));
    expect(lightPainter.knurlColor, equals(Colors.black.withValues(alpha: 0.08 * 0.75)));

    // Check numeral painter color
    final tpLight = ChronoDialPainter.getTextPainter('05', isDark: false);
    expect(tpLight.text?.style?.color, equals(const Color(0xFF1B1E23).withValues(alpha: 0.78)));

    final tpDark = ChronoDialPainter.getTextPainter('05', isDark: true);
    expect(tpDark.text?.style?.color, equals(TaktColors.warmBone.withValues(alpha: 0.65)));

    // Paint without errors on a canvas
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    expect(() => lightPainter.paint(canvas, const Size(240, 240)), returnsNormally);
  });

  test('ChronoDialPainter shouldRepaint returns true when isDark or dialFaceColor changes', () {
    final painter1 = ChronoDialPainter(
      remainingSeconds: 1500,
      targetMinutes: 25,
      isRunning: false,
      isDark: true,
    );
    final painter2 = ChronoDialPainter(
      remainingSeconds: 1500,
      targetMinutes: 25,
      isRunning: false,
      isDark: false,
    );
    final painter3 = ChronoDialPainter(
      remainingSeconds: 1500,
      targetMinutes: 25,
      isRunning: false,
      isDark: false,
      dialFaceColor: const Color(0xFFEAE6DC),
    );
    final painter4 = ChronoDialPainter(
      remainingSeconds: 1500,
      targetMinutes: 25,
      isRunning: false,
      isDark: false,
      dialFaceColor: const Color(0xFFD3D8E0),
    );

    expect(painter1.shouldRepaint(painter2), isTrue);
    expect(painter2.shouldRepaint(painter3), isTrue);
    expect(painter3.shouldRepaint(painter4), isTrue);
  });

  testWidgets('ChronoDialWidget renders Patina Olive colors and split flap labels during break', (tester) async {
    final container = ProviderContainer(
      overrides: [
        chronoDialProvider.overrideWith((ref) {
          final ctrl = ChronoDialController();
          ctrl.setPhase(PomodoroPhase.shortBreak);
          return ctrl;
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: ChronoDialWidget())),
      ),
    );
    await tester.pump();

    // Split-flap displays SHORT BRK
    final shortBrkChars = 'SHORT BRK'.split('');
    final tiles = tester.widgetList<SplitFlapTile>(find.byType(SplitFlapTile));
    final displayedPhase = tiles.take(shortBrkChars.length).map((t) => t.char).join();
    expect(displayedPhase, equals('SHORT BRK'));

    final dialPainter = tester.widget<CustomPaint>(dialFinder).painter as ChronoDialPainter;
    expect(dialPainter.needleColor, equals(TaktColors.patinaOlive));
    expect(dialPainter.filamentColor, equals(TaktColors.patinaOlive));
  });
}
