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
import 'package:takt_desk/core/sensors/parallax_controller.dart';
import 'package:takt_desk/core/services/timer_background_service.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_phase.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_profile.dart';
import 'package:takt_desk/features/timer/domain/timer_state.dart';
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

  // The needle has its own CustomPaint layer above the counter
  final handFinder = find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is ChronoDialHandPainter,
  );

  void expectDisplay(WidgetTester tester, int minutes, int seconds) {
    final display = tester.widget<MechanicalCounterDisplay>(
      find.byType(MechanicalCounterDisplay, skipOffstage: false),
    );
    expect(display.minutes, minutes);
    expect(display.seconds, seconds);
  }

  testWidgets('ChronoDialWidget exposes the countdown to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: Center(child: ChronoDialWidget())),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Focus timer, 25 minutes 0 seconds remaining, paused'),
      findsOneWidget,
    );
    handle.dispose();
  });

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

    // Light chassis: the filament darkened to a readable ink of the same hue.
    final activeSegmentText = tester.widget<Text>(find.text('25/5 CLS'));
    expect(activeSegmentText.style?.color, equals(TaktColors.readableAccent(themeState.filamentColor, onDark: false)));

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

  test('ChronoDialPainter uses high-contrast light ticks and numerals on dark dial face in light mode', () {
    final darkDialPainter = ChronoDialPainter(
      remainingSeconds: 1500,
      targetMinutes: 25,
      isRunning: false,
      isDark: false,
      dialFaceColor: const Color(0xFF16181B),
      textureType: HardwareTextureType.matteAbsGrain,
    );
    expect(darkDialPainter.isDark, isFalse);
    expect(darkDialPainter.hasDarkDialFace, isTrue);
    expect(darkDialPainter.majorTickColor, equals(TaktColors.warmBone.withValues(alpha: 0.90)));
    expect(darkDialPainter.numeralColor, equals(TaktColors.warmBone.withValues(alpha: 0.65)));
  });

  testWidgets('ChronoDialWidget mounts ChronoDialHandPainter on a layer over the embedded MechanicalCounterDisplay', (tester) async {
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
    await tester.pump();

    final customPaint = tester.widget<CustomPaint>(dialFinder);
    final painter = customPaint.painter as ChronoDialPainter;
    expect(painter.drawHand, isFalse);

    expect(handFinder, findsOneWidget);
    final handPainter = tester.widget<CustomPaint>(handFinder).painter as ChronoDialHandPainter;
    expect(handPainter.remainingSeconds, equals(25 * 60.0));

    final counter = tester.widget<MechanicalCounterDisplay>(find.byType(MechanicalCounterDisplay));
    expect(counter.isDialInset, isTrue);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ChronoProfileSelectorWidget renders 4-cycle pips gauge and theme-adaptive telemetry badge', (tester) async {
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
    await tester.pump();

    expect(find.text('CYCLE 1/4'), findsOneWidget);
    expect(find.text('STANDBY // READY'), findsOneWidget);

    // Start timer -> changes to RUNNING // SEC-ROLL
    await tester.tap(dialFinder);
    await tester.pump();

    expect(find.text('RUNNING // SEC-ROLL'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  test('ChronoDialHandPainter shouldRepaint returns true when needleColor, hubCapColor, or remainingSeconds changes', () {
    final painter1 = ChronoDialHandPainter(
      remainingSeconds: 1500,
      needleColor: Colors.amber,
      hubCapColor: Colors.black,
    );
    final painter2 = ChronoDialHandPainter(
      remainingSeconds: 1200,
      needleColor: Colors.amber,
      hubCapColor: Colors.black,
    );
    final painter3 = ChronoDialHandPainter(
      remainingSeconds: 1500,
      needleColor: Colors.red,
      hubCapColor: Colors.black,
    );
    final painter4 = ChronoDialHandPainter(
      remainingSeconds: 1500,
      needleColor: Colors.amber,
      hubCapColor: Colors.grey,
    );
    final painterIdentical = ChronoDialHandPainter(
      remainingSeconds: 1500,
      needleColor: Colors.amber,
      hubCapColor: Colors.black,
    );

    expect(painter1.shouldRepaint(painter2), isTrue);
    expect(painter1.shouldRepaint(painter3), isTrue);
    expect(painter1.shouldRepaint(painter4), isTrue);
    expect(painter1.shouldRepaint(painterIdentical), isFalse);
  });

  testWidgets('ChronoDialWidget mounts ChronoDialHandPainter with pure minimalist needle and applies 3D perspective', (tester) async {
    final container = ProviderContainer();
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
    await tester.pump();

    // Verify ChronoDialHandPainter is mounted
    expect(handFinder, findsOneWidget);
    var handPainter = tester.widget<CustomPaint>(handFinder).painter as ChronoDialHandPainter;
    expect(handPainter.remainingSeconds, equals(1500.0));

    // Verify 3D perspective transform exists around dial
    final transformFinder = find.ancestor(
      of: dialFinder,
      matching: find.byType(Transform),
    );
    expect(transformFinder, findsWidgets);

    // Update parallax state via sensor simulation
    container.read(parallaxProvider.notifier).updateTiltFromAccelerometer(
      x: 3.5,
      y: 8.0,
      z: 5.6,
    );
    await tester.pump();

    handPainter = tester.widget<CustomPaint>(handFinder).painter as ChronoDialHandPainter;
    expect(handPainter.remainingSeconds, equals(1500.0));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Crown push-button and dial face tap advance calibration stage when setupStage is active', (tester) async {
    final container = ProviderContainer();
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
    await tester.pump();

    // Enter calibration
    container.read(chronoDialProvider.notifier).enterCustomCalibration();
    await tester.pump();

    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.focus));
    expect(container.read(chronoDialProvider).isRunning, isFalse);

    // Tap CrownPushButton: advances to shortBreak, does NOT start timer
    await tester.tap(find.byType(CrownPushButton));
    await tester.pump();

    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.shortBreak));
    expect(container.read(chronoDialProvider).isRunning, isFalse);

    // Tap dial face: advances to longBreak
    await tester.tap(dialFinder);
    await tester.pump();

    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.longBreak));
    expect(container.read(chronoDialProvider).isRunning, isFalse);

    // Tap crown button: completes calibration, exits to none
    await tester.tap(find.byType(CrownPushButton));
    await tester.pump();

    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.none));
    expect(container.read(chronoDialProvider).isRunning, isFalse);

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Rotary pan drag calibrates duration according to active setup stage bounds', (tester) async {
    final container = ProviderContainer();
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
    await tester.pump();

    // Enter calibration: ChronoSetupStage.focus (max 90)
    container.read(chronoDialProvider.notifier).enterCustomCalibration();
    await tester.pump();

    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.focus));

    final dialCenter = tester.getCenter(dialFinder);

    // Drag to 3 o'clock position (15 min)
    var gesture = await tester.startGesture(dialCenter + const Offset(50, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(container.read(chronoDialProvider).customProfile.focusMinutes, equals(15));
    expectDisplay(tester, 15, 0);

    // Advance to shortBreak (max 30)
    container.read(chronoDialProvider.notifier).advanceCalibrationStage();
    await tester.pump();
    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.shortBreak));

    // Drag to 6 o'clock position (fraction 0.5 -> 30 min)
    gesture = await tester.startGesture(dialCenter + const Offset(0, 50));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 25));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(container.read(chronoDialProvider).customProfile.shortBreakMinutes, equals(30));
    expectDisplay(tester, 30, 0);

    // Advance to longBreak (max 45)
    container.read(chronoDialProvider.notifier).advanceCalibrationStage();
    await tester.pump();
    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.longBreak));

    // Drag to 6 o'clock position (fraction 0.5 -> 30 min, clamped to max 45)
    gesture = await tester.startGesture(dialCenter + const Offset(0, 50));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 25));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(container.read(chronoDialProvider).customProfile.longBreakMinutes, equals(30));
    expectDisplay(tester, 30, 0);

    // Advance past longBreak: completes calibration and returns to standby
    container.read(chronoDialProvider.notifier).advanceCalibrationStage();
    await tester.pump();
    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.none));
    expect(container.read(chronoDialProvider).profile.focusMinutes, equals(15));
    expect(container.read(chronoDialProvider).profile.shortBreakMinutes, equals(30));
    expect(container.read(chronoDialProvider).profile.longBreakMinutes, equals(30));

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Dragging up on CrownPushButton pulls crown and transitions setupStage to focus and profile to custom', (tester) async {
    final container = ProviderContainer();
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
    await tester.pump();

    // Verify initial idle state
    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.none));
    var crown = tester.widget<CrownPushButton>(find.byType(CrownPushButton));
    expect(crown.isPulledOut, isFalse);

    // Drag up on CrownPushButton
    await tester.drag(find.byType(CrownPushButton), const Offset(0, -30));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify calibration entered
    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.focus));
    expect(container.read(chronoDialProvider).profile.type, equals(PomodoroProfileType.custom));
    expect(find.text('SET 1/3 // FOCUS'), findsOneWidget);

    // Verify CrownPushButton reflects isPulledOut == true
    crown = tester.widget<CrownPushButton>(find.byType(CrownPushButton));
    expect(crown.isPulledOut, isTrue);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Dragging down on CrownPushButton while calibrating pushes crown in and cancels calibration', (tester) async {
    final container = ProviderContainer();
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
    await tester.pump();

    // Pull out crown to enter calibration
    await tester.drag(find.byType(CrownPushButton), const Offset(0, -30));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.focus));
    var crown = tester.widget<CrownPushButton>(find.byType(CrownPushButton));
    expect(crown.isPulledOut, isTrue);

    // Push crown back in by dragging down
    await tester.drag(find.byType(CrownPushButton), const Offset(0, 30));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Calibration should be cancelled and setupStage returned to none
    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.none));
    crown = tester.widget<CrownPushButton>(find.byType(CrownPushButton));
    expect(crown.isPulledOut, isFalse);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Dragging up on CrownPushButton while timer is running is ignored', (tester) async {
    final container = ProviderContainer();
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
    await tester.pump();

    // Start timer by tapping dial
    await tester.tap(dialFinder);
    await tester.pump();
    expect(container.read(chronoDialProvider).isRunning, isTrue);

    // Attempt to drag up on CrownPushButton
    await tester.drag(find.byType(CrownPushButton), const Offset(0, -30));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Setup stage must remain none and timer running
    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.none));
    expect(container.read(chronoDialProvider).isRunning, isTrue);

    // Pause timer before tearing down
    await tester.tap(dialFinder);
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Tapping CrownPushButton starts and pauses timer, and advances calibration stages when pulled out', (tester) async {
    final container = ProviderContainer();
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
    await tester.pump();

    // 1. Idle tap: starts timer
    await tester.tap(find.byType(CrownPushButton));
    await tester.pump();
    expect(container.read(chronoDialProvider).isRunning, isTrue);

    // 2. Running tap: pauses timer
    await tester.tap(find.byType(CrownPushButton));
    await tester.pump();
    expect(container.read(chronoDialProvider).isRunning, isFalse);

    // 3. Pull crown out: enters calibration stage 1 (focus)
    await tester.drag(find.byType(CrownPushButton), const Offset(0, -30));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.focus));

    // 4. Tap crown: advances to stage 2 (shortBreak)
    await tester.tap(find.byType(CrownPushButton));
    await tester.pump();
    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.shortBreak));

    // 5. Tap crown: advances to stage 3 (longBreak)
    await tester.tap(find.byType(CrownPushButton));
    await tester.pump();
    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.longBreak));

    // 6. Tap crown: completes calibration, exits to none
    await tester.tap(find.byType(CrownPushButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.none));
    expect(container.read(chronoDialProvider).isRunning, isFalse);

    final crown = tester.widget<CrownPushButton>(find.byType(CrownPushButton));
    expect(crown.isPulledOut, isFalse);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Dragging up on CrownPushButton while already calibrating is ignored', (tester) async {
    final container = ProviderContainer();
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
    await tester.pump();

    // Pull crown out: enters stage 1 (focus)
    await tester.drag(find.byType(CrownPushButton), const Offset(0, -30));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.focus));

    // Tap to advance to stage 2 (shortBreak)
    await tester.tap(find.byType(CrownPushButton));
    await tester.pump();
    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.shortBreak));

    // Drag up again: should remain in stage 2 (shortBreak) without resetting to focus
    await tester.drag(find.byType(CrownPushButton), const Offset(0, -30));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(container.read(chronoDialProvider).setupStage, equals(ChronoSetupStage.shortBreak));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ChronoDialWidget allocates 24px dial headroom with crown seated at top 6 and dial canvas at top 24', (tester) async {
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
    await tester.pump();

    // Crown at top 6: its 28 px box ends at 34, 2 px inside the bezel edge (24 + 8),
    // so the collar is seated instead of hovering
    final crownPositioned = tester.widget<Positioned>(
      find.ancestor(
        of: find.byType(CrownPushButton),
        matching: find.byType(Positioned),
      ).first,
    );
    expect(crownPositioned.top, equals(6.0));

    // Verify Dial Canvas Positioned has top == 24
    final dialPositioned = tester.widget<Positioned>(
      find.ancestor(
        of: dialFinder,
        matching: find.byType(Positioned),
      ).first,
    );
    expect(dialPositioned.top, equals(24.0));

    // Verify parent SizedBox height allocates 24px extra headroom
    final stackSizedBox = tester.widget<SizedBox>(
      find.ancestor(
        of: find.byType(CrownPushButton),
        matching: find.byType(SizedBox),
      ).first,
    );
    expect(stackSizedBox.height, equals(tester.getSize(dialFinder).height + 24.0));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('countdown keeps running while the dial is off screen', (tester) async {
    // Regression: the countdown used to live in the dial widget's Ticker, so
    // switching to the TASKS/VINYL tab (which disposes the dial) froze it.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    Widget host(bool showDial) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: Center(child: showDial ? const ChronoDialWidget() : const SizedBox())),
          ),
        );

    await tester.pumpWidget(host(true));
    await tester.tap(dialFinder);
    await tester.pump();

    // Dial leaves the tree while the session runs
    await tester.pumpWidget(host(false));
    await tester.pump(const Duration(seconds: 10));
    expect(container.read(chronoDialProvider).isRunning, isTrue);
    expect(container.read(chronoDialProvider).remainingSeconds, closeTo(25 * 60 - 10, 0.3));

    // And shows the right time when it comes back
    await tester.pumpWidget(host(true));
    await tester.pump();
    expectDisplay(tester, 24, 50);

    container.read(chronoDialProvider.notifier).pause();
  });

  test('dial face does not repaint for time alone; only the hand does', () {
    ChronoDialPainter face(double secs) => ChronoDialPainter(
          remainingSeconds: secs,
          targetMinutes: 25,
          isRunning: true,
          needleColor: Colors.orange,
          filamentColor: Colors.orange,
          outerBezelGradient: const [Colors.black, Colors.grey],
          innerBezelColor: Colors.black,
          textureType: HardwareTextureType.matteAbsGrain,
          isDark: true,
          dialFaceColor: Colors.white,
          drawHand: false,
        );
    expect(face(1499.5).shouldRepaint(face(1500.0)), isFalse);

    final remaining = ValueNotifier<double>(1500.0);
    addTearDown(remaining.dispose);
    final hand = ChronoDialHandPainter(remaining: remaining, needleColor: Colors.orange, hubCapColor: Colors.black);
    expect(hand.remainingSeconds, 1500.0);
    remaining.value = 1499.5;
    expect(hand.remainingSeconds, 1499.5);
  });
}
