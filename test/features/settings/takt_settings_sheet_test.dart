import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';
import 'package:takt_desk/features/settings/presentation/takt_settings_sheet.dart';

void main() {
  group('TaktSettingsSheet', () {
    testWidgets('TaktSettingsSheet renders acoustics, clearance, telemetry, and creed sections', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TaktSettingsSheet(),
            ),
          ),
        ),
      );

      expect(find.textContaining('SERVICE HATCH'), findsOneWidget);
      expect(find.textContaining('HARDWARE ACOUSTICS'), findsOneWidget);
      expect(find.textContaining('SYSTEM CLEARANCE'), findsOneWidget);
      expect(find.textContaining('TELEMETRY & LOGS'), findsOneWidget);
      expect(find.textContaining('Weniger, aber besser'), findsOneWidget);
      expect(find.text('OPEN SOURCE LICENSES'), findsOneWidget);
    });

    testWidgets('Grip handle and section headers are rendered with Braun styling', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TaktSettingsSheet(),
            ),
          ),
        ),
      );

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
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TaktSettingsSheet(),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('master_volume_slider')), findsOneWidget);
      expect(find.byKey(const ValueKey('foley_clicks_switch')), findsOneWidget);
      expect(find.byKey(const ValueKey('tactile_haptics_switch')), findsOneWidget);

      expect(find.textContaining('80%'), findsOneWidget); // Default sound volume is 0.8
    });

    testWidgets('Master volume slider updates preferences controller', (tester) async {
      final container = ProviderContainer();
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

      final sliderFinder = find.byKey(const ValueKey('master_volume_slider'));
      expect(sliderFinder, findsOneWidget);

      // Drag slider
      await tester.drag(sliderFinder, const Offset(-50, 0));
      await tester.pumpAndSettle();

      final currentVolume = container.read(deskPreferencesControllerProvider).soundVolume;
      expect(currentVolume, isNot(0.8));
    });

    testWidgets('Foley and Haptics switches toggle preferences', (tester) async {
      final container = ProviderContainer();
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

      final foleyFinder = find.byKey(const ValueKey('foley_clicks_switch'));
      final hapticsFinder = find.byKey(const ValueKey('tactile_haptics_switch'));

      expect(container.read(deskPreferencesControllerProvider).foleyEnabled, isTrue);
      await tester.tap(foleyFinder);
      await tester.pumpAndSettle();
      expect(container.read(deskPreferencesControllerProvider).foleyEnabled, isFalse);

      expect(container.read(deskPreferencesControllerProvider).hapticsEnabled, isTrue);
      await tester.tap(hapticsFinder);
      await tester.pumpAndSettle();
      expect(container.read(deskPreferencesControllerProvider).hapticsEnabled, isFalse);
    });

    testWidgets('System clearance section shows status badge and emergency unlatch instructions', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TaktSettingsSheet(),
            ),
          ),
        ),
      );

      expect(find.textContaining('STATUS: VERIFIED (ANDROID DND / APP PINNING)'), findsOneWidget);
      expect(
        find.textContaining('In Monastic Lockdown, press and hold the bottom unlatch lever for 5 continuous seconds to release the system.'),
        findsOneWidget,
      );
    });

    testWidgets('Telemetry section displays lifetime focus stats', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lifetimeFocusStatsProvider.overrideWith(
              (ref) => Stream.value(const LifetimeFocusStats(
                totalSessions: 42,
                totalHours: 17.5,
              )),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TaktSettingsSheet(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('42'), findsWidgets);
      expect(find.textContaining('17.5'), findsWidgets);
    });

    testWidgets('Purge session logs shows confirmation dialog and cancels without purge', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TaktSettingsSheet(),
            ),
          ),
        ),
      );

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
      final container = ProviderContainer();
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
    });

    testWidgets('Braun creed section displays quote, metadata, and privacy declaration', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TaktSettingsSheet(),
            ),
          ),
        ),
      );

      expect(find.textContaining('Weniger, aber besser — Less, but better.'), findsOneWidget);
      expect(find.textContaining('Dieter Rams'), findsOneWidget);
      expect(find.textContaining('Takt Desk v1.0.0 (Build 2026.09) · Pure Handheld Mobile Edition'), findsOneWidget);
      expect(
        find.textContaining('100% Offline. Zero analytics. Zero telemetry. All session data remains exclusively on this device.'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping OPEN SOURCE LICENSES opens license page', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TaktSettingsSheet(),
            ),
          ),
        ),
      );

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
        ProviderScope(
          overrides: [
            chassisThemeProvider.overrideWith((ref) => ThemeController()..setDarkMode(false)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TaktSettingsSheet(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('SERVICE HATCH'), findsOneWidget);
      expect(find.textContaining('HARDWARE ACOUSTICS'), findsOneWidget);
    });
  });
}
