import 'dart:ui';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/takt_colors.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/core/services/timer_background_service.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_phase.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_painter.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_widget.dart';
import 'package:takt_desk/features/timer/presentation/widgets/chrono_profile_selector_widget.dart';
import 'package:takt_desk/features/timer/presentation/widgets/crown_push_button.dart';
import 'package:takt_desk/features/timer/presentation/widgets/mechanical_flip_digit.dart';

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

    // Verify initial time display and cassette profile selector
    expect(find.byType(MechanicalCounterDisplay, skipOffstage: false), findsOneWidget);
    expectDisplay(tester, 25, 0);
    expect(find.byType(ChronoProfileSelectorWidget), findsOneWidget);
    expect(find.text('25/5 CLS'), findsOneWidget);
    expect(find.text('50/10 MON'), findsOneWidget);
    expect(find.text('15/3 SPR'), findsOneWidget);
    expect(find.text('CUSTOM'), findsOneWidget);

    // Verify CustomPaint with ChronoDialPainter is rendered
    expect(dialFinder, findsOneWidget);

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ChronoDialWidget switches profile via cassette selector segments', (tester) async {
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

    // Tap 50/10 MON segment
    await tester.tap(find.text('50/10 MON'));
    await tester.pump();
    expectDisplay(tester, 50, 0);

    // Tap 15/3 SPR segment
    await tester.tap(find.text('15/3 SPR'));
    await tester.pump();
    expectDisplay(tester, 15, 0);

    // Tap 25/5 CLS segment
    await tester.tap(find.text('25/5 CLS'));
    await tester.pump();
    expectDisplay(tester, 25, 0);

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

  testWidgets('ChronoDialWidget starts and pauses on CrownPushButton tap', (tester) async {
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

    // Tap CrownPushButton to start
    await tester.tap(find.byType(CrownPushButton));
    await tester.pump();

    // Advance 1 second
    await tester.pump(const Duration(seconds: 1));
    expectDisplay(tester, 24, 59);

    // Tap CrownPushButton to pause
    await tester.tap(find.byType(CrownPushButton));
    await tester.pump();

    // Advance 2 seconds and verify counter stays paused
    await tester.pump(const Duration(seconds: 2));
    expectDisplay(tester, 24, 59);

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ChronoDialWidget disables profile switching while running', (tester) async {
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

    // Initial state: 25/5 CLS
    expectDisplay(tester, 25, 0);

    // Start timer
    await tester.tap(dialFinder);
    await tester.pump();

    // While running: tapping another segment has no effect
    await tester.tap(find.text('50/10 MON'));
    await tester.pump();
    expectDisplay(tester, 25, 0);

    // Pause timer
    await tester.tap(dialFinder);
    await tester.pump();

    // Paused: tapping 50/10 MON switches profile
    await tester.tap(find.text('50/10 MON'));
    await tester.pump();
    expectDisplay(tester, 50, 0);

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

    // Select Sprint profile (15m focus / 3m break)
    await tester.tap(find.text('15/3 SPR'));
    await tester.pump();
    expectDisplay(tester, 15, 0);

    // Start timer
    await tester.tap(dialFinder);
    await tester.pump();

    // Advance 901 seconds to expire timer -> auto-advances to Short Break (3 mins) in Standby
    await tester.pump(const Duration(seconds: 901));
    expectDisplay(tester, 3, 0);

    // Tap dial to start the standby short break session
    await tester.tap(dialFinder);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expectDisplay(tester, 2, 59);

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
    expectDisplay(tester, 25, 0);

    // Drag from center rightwards (3 o'clock position = 15 MIN)
    final dialCenter = tester.getCenter(dialFinder);
    final gesture = await tester.startGesture(dialCenter + const Offset(50, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    // The dial target minutes should update to 15 MIN
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

  testWidgets('ChronoDialWidget adapts dial bezel, crown, and console to rawBrassPatina edition', (tester) async {
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(testDb.close);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(testDb),
      ],
    );
    addTearDown(container.dispose);
    container.read(chassisThemeProvider.notifier).setDarkMode(true);

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

    // Cassette profile selector initial
    var cassetteContainer = tester.widget<Container>(
      find.descendant(
        of: find.byType(ChronoProfileSelectorWidget),
        matching: find.byType(Container),
      ).first,
    );
    var cassetteDeco = cassetteContainer.decoration as BoxDecoration;
    expect((cassetteDeco.border as Border).top.color, equals(HardwareEdition.braunClassic.darkBorder));
    expect(cassetteDeco.color, equals(HardwareEdition.braunClassic.darkModuleBg));

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

    // Verify cassette profile selector container adapts to rawBrassPatina
    cassetteContainer = tester.widget<Container>(
      find.descendant(
        of: find.byType(ChronoProfileSelectorWidget),
        matching: find.byType(Container),
      ).first,
    );
    cassetteDeco = cassetteContainer.decoration as BoxDecoration;
    expect((cassetteDeco.border as Border).top.color, equals(HardwareEdition.rawBrassPatina.darkBorder));
    expect(cassetteDeco.color, equals(HardwareEdition.rawBrassPatina.darkModuleBg));
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

    // Stopped state: Inactive cassette segment text uses chassisTextColor with alpha, active uses filamentColor
    final inactiveSegmentText = tester.widget<Text>(find.text('50/10 MON'));
    expect(inactiveSegmentText.style?.color, equals(const Color(0xFF1B1E23).withValues(alpha: 0.70)));

    final activeSegmentText = tester.widget<Text>(find.text('25/5 CLS'));
    expect(activeSegmentText.style?.color, equals(themeState.filamentColor));

    // ChronoDialPainter receives textureType matching active edition (braunClassic -> matteAbsGrain)
    var customPaint = tester.widget<CustomPaint>(dialFinder);
    var painter = customPaint.painter as ChronoDialPainter;
    expect(painter.textureType, equals(HardwareTextureType.matteAbsGrain));

    // When running: Inactive cassette segment text dims to alpha 0.35
    await tester.tap(dialFinder);
    await tester.pump();

    final runningInactiveText = tester.widget<Text>(find.text('50/10 MON'));
    expect(runningInactiveText.style?.color, equals(themeState.chassisTextColor.withValues(alpha: 0.35)));

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

  testWidgets('ChronoDialWidget renders Patina Olive colors and console labels during break', (tester) async {
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

    // Console displays SHORT BRK and cycle progress
    expect(find.text('SHORT BRK'), findsOneWidget);
    expect(find.text('CYCLE 1/4'), findsOneWidget);

    final dialPainter = tester.widget<CustomPaint>(dialFinder).painter as ChronoDialPainter;
    expect(dialPainter.needleColor, equals(TaktColors.patinaOlive));
    expect(dialPainter.filamentColor, equals(TaktColors.patinaOlive));
  });

  testWidgets('ChronoDialWidget renders Patina Olive colors and LONG BRK console label during long break', (tester) async {
    final container = ProviderContainer(
      overrides: [
        chronoDialProvider.overrideWith((ref) {
          final ctrl = ChronoDialController();
          ctrl.setPhase(PomodoroPhase.longBreak);
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

    // Console displays LONG BRK
    expect(find.text('LONG BRK'), findsOneWidget);

    final dialPainter = tester.widget<CustomPaint>(dialFinder).painter as ChronoDialPainter;
    expect(dialPainter.needleColor, equals(TaktColors.patinaOlive));
    expect(dialPainter.filamentColor, equals(TaktColors.patinaOlive));
  });

  testWidgets('ChronoDialWidget starts and stops background timer service on state changes', (tester) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(TimerBackgroundService.channel, (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(TimerBackgroundService.channel, null);
    });

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

    // Tap dial to start -> triggers startService with full payload
    await tester.tap(dialFinder);
    await tester.pump();
    expect(calls.map((c) => c.method).toList(), contains('startService'));
    final startCall = calls.firstWhere((c) => c.method == 'startService');
    expect(startCall.arguments['remainingSeconds'], equals(25 * 60.0));
    expect(startCall.arguments['targetMinutes'], equals(25));
    expect(startCall.arguments['phase'], equals('focus'));
    expect(startCall.arguments['cycleCount'], equals(1));
    expect(startCall.arguments['profileName'], equals('CLASSIC 25/5'));

    // Tap dial to pause -> triggers stopService
    await tester.tap(dialFinder);
    await tester.pump();
    expect(calls.map((c) => c.method).toList(), contains('stopService'));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ChronoDialPainter uses high-contrast light ticks and numerals on dark dial face in light mode', (tester) async {
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
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChronoDialWidget(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final dialPainter = tester.widget<CustomPaint>(dialFinder).painter as ChronoDialPainter;
    expect(dialPainter.isDark, isFalse);
    expect(dialPainter.hasDarkDialFace, isTrue);
    expect(dialPainter.majorTickColor, equals(TaktColors.warmBone.withValues(alpha: 0.90)));
    expect(dialPainter.numeralColor, equals(TaktColors.warmBone.withValues(alpha: 0.65)));

    await tester.pumpWidget(const SizedBox());
  });
}

