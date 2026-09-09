import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';
import 'package:takt_desk/features/settings/presentation/takt_settings_sheet.dart';

void main() {
  group('TaktSettingsSheet', () {
    Widget buildSheet({List<Override> overrides = const []}) {
      return ProviderScope(
        overrides: [
          deskPreferencesControllerProvider.overrideWith(
            (ref) => DeskPreferencesController(
              null,
              AudioService(isMock: true),
              ref.watch(chassisThemeProvider.notifier),
            ),
          ),
          lifetimeFocusStatsProvider.overrideWith(
            (ref) => Stream.value(const LifetimeFocusStats(
              totalSessions: 10,
              totalHours: 2.5,
            )),
          ),
          ...overrides,
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TaktSettingsSheet(),
          ),
        ),
      );
    }

    testWidgets('TaktSettingsSheet renders acoustics, clearance, telemetry, and creed sections', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      expect(find.textContaining('SERVICE HATCH'), findsOneWidget);
      expect(find.textContaining('HARDWARE ACOUSTICS'), findsOneWidget);
      expect(find.textContaining('SYSTEM CLEARANCE'), findsOneWidget);
      expect(find.textContaining('TELEMETRY & LOGS'), findsOneWidget);
      expect(find.textContaining('Weniger, aber besser'), findsOneWidget);
      expect(find.text('OPEN SOURCE LICENSES'), findsOneWidget);
    });

    testWidgets('Grip handle and section headers are rendered with Braun styling', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      // Grip handle
      expect(find.byKey(const ValueKey('service_hatch_grip_handle')), findsOneWidget);

      // Section titles
      expect(find.text('SERVICE HATCH // CALIBRATION & TELEMETRY'), findsOneWidget);
      expect(find.text('HARDWARE ACOUSTICS & TACTILITY'), findsOneWidget);
      expect(find.text('SYSTEM CLEARANCE & LOCKDOWN'), findsOneWidget);
      expect(find.text('TELEMETRY & LOGS'), findsOneWidget);
      expect(find.text('THE BRAUN CREED & LEGAL'), findsOneWidget);
    });

    testWidgets('Acoustics section renders volume slider, foley switch, and haptics switch', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      expect(find.byKey(const ValueKey('master_volume_slider')), findsOneWidget);
      expect(find.byKey(const ValueKey('foley_clicks_switch')), findsOneWidget);
      expect(find.byKey(const ValueKey('tactile_haptics_switch')), findsOneWidget);

      expect(find.textContaining('80%'), findsOneWidget);
    });

    testWidgets('Master volume slider updates preferences controller', (tester) async {
      final controller = DeskPreferencesController(null, AudioService(isMock: true));
      final container = ProviderContainer(
        overrides: [
          deskPreferencesControllerProvider.overrideWith((ref) => controller),
          lifetimeFocusStatsProvider.overrideWith(
            (ref) => Stream.value(const LifetimeFocusStats()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: TaktSettingsSheet(),
            ),
          ),
        ),
      );
      await tester.pump();

      final sliderFinder = find.byKey(const ValueKey('master_volume_slider'));
      expect(sliderFinder, findsOneWidget);

      // Drag slider
      await tester.drag(sliderFinder, const Offset(-50, 0));
      await tester.pump();

      final currentVolume = container.read(deskPreferencesControllerProvider).soundVolume;
      expect(currentVolume, isNot(0.8));
    });

    testWidgets('Foley and Haptics switches toggle preferences', (tester) async {
      final controller = DeskPreferencesController(null, AudioService(isMock: true));
      final container = ProviderContainer(
        overrides: [
          deskPreferencesControllerProvider.overrideWith((ref) => controller),
          lifetimeFocusStatsProvider.overrideWith(
            (ref) => Stream.value(const LifetimeFocusStats()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: TaktSettingsSheet(),
            ),
          ),
        ),
      );
      await tester.pump();

      final foleyFinder = find.byKey(const ValueKey('foley_clicks_switch'));
      final hapticsFinder = find.byKey(const ValueKey('tactile_haptics_switch'));

      expect(container.read(deskPreferencesControllerProvider).foleyEnabled, isTrue);
      expect(container.read(deskPreferencesControllerProvider).hapticsEnabled, isTrue);

      await tester.tap(foleyFinder);
      await tester.pump();
      expect(container.read(deskPreferencesControllerProvider).foleyEnabled, isFalse);

      await tester.tap(hapticsFinder);
      await tester.pump();
      expect(container.read(deskPreferencesControllerProvider).hapticsEnabled, isFalse);
    });

    testWidgets('System clearance section displays active badge and unlatch instructions', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      expect(find.byKey(const ValueKey('clearance_status_badge')), findsOneWidget);
      expect(find.textContaining('STATUS: VERIFIED (ANDROID DND / APP PINNING)'), findsOneWidget);
      expect(
        find.textContaining('In Monastic Lockdown, press and hold the bottom unlatch lever for 5 continuous seconds'),
        findsOneWidget,
      );
    });

    testWidgets('Telemetry section renders lifetime stats and purge button', (tester) async {
      await tester.pumpWidget(
        buildSheet(
          overrides: [
            lifetimeFocusStatsProvider.overrideWith(
              (ref) => Stream.value(const LifetimeFocusStats(
                totalSessions: 42,
                totalHours: 17.5,
              )),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.textContaining('42'), findsWidgets);
      expect(find.textContaining('17.5'), findsWidgets);
    });

    testWidgets('Purge session logs shows confirmation dialog and cancels without purge', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      final purgeButton = find.text('PURGE SESSION LOGS');
      expect(purgeButton, findsOneWidget);
      await tester.ensureVisible(purgeButton);
      await tester.pumpAndSettle();

      await tester.tap(purgeButton);
      await tester.pumpAndSettle();

      expect(find.text('CONFIRM PURGE'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);

      // Tap CANCEL
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      expect(find.text('CONFIRM PURGE'), findsNothing);
    });

    testWidgets('Purge session logs executes purge on confirm', (tester) async {
      final testDb = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(testDb.close);

      // Seed a session before purge
      await testDb.recordTimerSession(
        targetMinutes: 25,
        elapsedSeconds: 1500,
        isFinished: true,
        startedAt: DateTime.now(),
      );

      final beforeSessions = await (testDb.select(testDb.timerSessions)).get();
      expect(beforeSessions, hasLength(1));

      final controller = DeskPreferencesController(testDb, AudioService(isMock: true));
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
          deskPreferencesControllerProvider.overrideWith((ref) => controller),
          lifetimeFocusStatsProvider.overrideWith(
            (ref) => Stream.value(const LifetimeFocusStats(totalSessions: 1, totalHours: 0.4)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: TaktSettingsSheet(),
            ),
          ),
        ),
      );
      await tester.pump();

      final purgeButton = find.text('PURGE SESSION LOGS');
      await tester.ensureVisible(purgeButton);
      await tester.pumpAndSettle();

      await tester.tap(purgeButton);
      await tester.pumpAndSettle();

      final confirmBtn = find.byKey(const ValueKey('confirm_purge_button'));
      expect(confirmBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(find.text('CONFIRM PURGE'), findsNothing);

      // Verify that database clearTimerSessions was indeed executed and session is gone
      final afterSessions = await (testDb.select(testDb.timerSessions)).get();
      expect(afterSessions, isEmpty);
    });

    testWidgets('Braun creed section displays quote, metadata, and privacy declaration', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      expect(find.textContaining('Weniger, aber besser — Less, but better.'), findsOneWidget);
      expect(find.textContaining('Dieter Rams'), findsOneWidget);
      expect(find.textContaining('Takt Desk v1.0.0 (Build 2026.09) · Pure Handheld Mobile Edition'), findsOneWidget);
      expect(
        find.textContaining('100% Offline. Zero analytics. Zero telemetry. All session data remains exclusively on this device.'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping OPEN SOURCE LICENSES opens license page', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      final licenseButton = find.text('OPEN SOURCE LICENSES');
      expect(licenseButton, findsOneWidget);
      await tester.ensureVisible(licenseButton);
      await tester.pumpAndSettle();

      await tester.tap(licenseButton);
      await tester.pumpAndSettle();

      expect(find.byType(LicensePage), findsOneWidget);
    });

    testWidgets('Renders properly in light mode', (tester) async {
      await tester.pumpWidget(
        buildSheet(
          overrides: [
            chassisThemeProvider.overrideWith((ref) => ThemeController()..setDarkMode(false)),
          ],
        ),
      );
      await tester.pump();

      expect(find.textContaining('SERVICE HATCH'), findsOneWidget);
      expect(find.textContaining('HARDWARE ACOUSTICS'), findsOneWidget);
    });

    testWidgets('Section headers do not overflow on narrow viewport or large font scale', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deskPreferencesControllerProvider.overrideWith(
              (ref) => DeskPreferencesController(null, AudioService(isMock: true)),
            ),
            lifetimeFocusStatsProvider.overrideWith(
              (ref) => Stream.value(const LifetimeFocusStats()),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
                child: TaktSettingsSheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('SERVICE HATCH'), findsOneWidget);
    });

    testWidgets('TaktSettingsSheet renders Hardware Editions section with 4 swatches', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      expect(find.text('HARDWARE EDITIONS // CHASSIS MATERIALITY'), findsOneWidget);
      expect(find.text('BRAUN CLASSIC'), findsOneWidget);
      expect(find.text('TITANIUM STEALTH'), findsOneWidget);
      expect(find.text('BAUHAUS HERITAGE'), findsOneWidget);
      expect(find.text('RAW BRASS & PATINA'), findsOneWidget);
      expect(find.textContaining('SIMULATE STUDIO PRO CLEARANCE'), findsOneWidget);
    });

    testWidgets('Tapping unlocked edition equips it and triggers haptic click', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      final titaniumFinder = find.byKey(const ValueKey('edition_card_titaniumStealth'));
      expect(titaniumFinder, findsOneWidget);

      await tester.tap(titaniumFinder);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: titaniumFinder,
          matching: find.text('EQUIPPED'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Toggling simulate_pro_switch updates simulated pro status', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      final switchFinder = find.byKey(const ValueKey('simulate_pro_switch'));
      expect(switchFinder, findsOneWidget);

      final switchWidgetBefore = tester.widget<Switch>(switchFinder);
      expect(switchWidgetBefore.value, isTrue);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final switchWidgetAfter = tester.widget<Switch>(switchFinder);
      expect(switchWidgetAfter.value, isFalse);
    });

    testWidgets('Tapping locked card when pro is disabled opens Studio Pro dialog, and tapping unlock activates pro and equips edition', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      // Disable simulated pro
      final switchFinder = find.byKey(const ValueKey('simulate_pro_switch'));
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(find.text('LOCKED // PRO'), findsWidgets);

      // Tap locked titanium card
      final titaniumFinder = find.byKey(const ValueKey('edition_card_titaniumStealth'));
      await tester.tap(titaniumFinder);
      await tester.pumpAndSettle();

      // Verify Studio Pro dialog appears
      expect(find.text('TAKT DESK STUDIO PRO'), findsOneWidget);
      expect(find.textContaining('TITANIUM STEALTH'), findsWidgets);

      final unlockButton = find.byKey(const ValueKey('pro_dialog_unlock_button'));
      expect(unlockButton, findsOneWidget);

      await tester.tap(unlockButton);
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('TAKT DESK STUDIO PRO'), findsNothing);

      // Pro is now unlocked and titaniumStealth is equipped
      final switchWidgetAfter = tester.widget<Switch>(switchFinder);
      expect(switchWidgetAfter.value, isTrue);
      expect(
        find.descendant(
          of: titaniumFinder,
          matching: find.text('EQUIPPED'),
        ),
        findsOneWidget,
      );
    });
  });
}
