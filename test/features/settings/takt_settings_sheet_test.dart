import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';
import 'package:takt_desk/features/settings/presentation/takt_settings_sheet.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_profile.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';

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

      await tester.ensureVisible(foleyFinder);
      await tester.tap(foleyFinder);
      await tester.pump();
      expect(container.read(deskPreferencesControllerProvider).foleyEnabled, isFalse);

      await tester.ensureVisible(hapticsFinder);
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

    testWidgets('Focus Analytics button is present and opens FocusAnalyticsDialog', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      final analyticsButton = find.byKey(const ValueKey('open_focus_analytics_btn'));
      await tester.ensureVisible(analyticsButton);
      await tester.pumpAndSettle();

      expect(analyticsButton, findsOneWidget);
      expect(find.text('FOCUS ANALYTICS & CHARTS'), findsOneWidget);

      await tester.tap(analyticsButton);
      await tester.pumpAndSettle();

      expect(find.text('FOCUS ANALYTICS'), findsOneWidget);

      // Close dialog
      await tester.tap(find.byKey(const ValueKey('focus_analytics_close_btn')));
      await tester.pumpAndSettle();
      expect(find.text('FOCUS ANALYTICS'), findsNothing);

      // Unmount and flush drift query stream timer
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Braun creed section displays quote, metadata, and privacy declaration', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      expect(find.textContaining('Weniger, aber besser — Less, but better.'), findsOneWidget);
      expect(find.textContaining('Dieter Rams'), findsOneWidget);
      expect(find.textContaining('Takt Desk v1.0.0 (Build 2026.09) · Developed by RSQUARE'), findsOneWidget);
      expect(find.text('DEVELOPED BY RSQUARE'), findsWidgets);
      expect(
        find.textContaining('100% Offline. Zero analytics. Zero telemetry. All session data remains exclusively on this device.'),
        findsOneWidget,
      );
    });

    testWidgets('Braun creed section displays RSQUARE logo image asset', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      final logoFinder = find.byWidgetPredicate(
        (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/rsquare_logo.png',
      );
      expect(logoFinder, findsOneWidget);
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

    testWidgets('TaktSettingsSheet renders Hardware Editions section with 7 swatches', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      expect(find.text('HARDWARE EDITIONS // CHASSIS MATERIALITY'), findsOneWidget);
      expect(find.text('BRAUN CLASSIC'), findsOneWidget);
      expect(find.byKey(const ValueKey('edition_next_button')), findsOneWidget);

      // Advance through gallery carousel to inspect each edition
      await tester.tap(find.byKey(const ValueKey('edition_next_button')));
      await tester.pumpAndSettle();
      expect(find.text('BRAUN ATELIER CREAM'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('edition_next_button')));
      await tester.pumpAndSettle();
      expect(find.text('TITANIUM STEALTH'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('edition_next_button')));
      await tester.pumpAndSettle();
      expect(find.text('BAUHAUS HERITAGE'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('edition_next_button')));
      await tester.pumpAndSettle();
      expect(find.text('RAW BRASS & PATINA'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('edition_next_button')));
      await tester.pumpAndSettle();
      expect(find.text('MID-CENTURY WALNUT'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('edition_next_button')));
      await tester.pumpAndSettle();
      expect(find.text('FORGED CARBON'), findsOneWidget);

      expect(find.textContaining('SIMULATE STUDIO PRO CLEARANCE'), findsOneWidget);
    });

    testWidgets('Tapping unlocked edition equips it and triggers haptic click', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      // Navigate past Atelier Cream to titanium stealth card in carousel
      await tester.tap(find.byKey(const ValueKey('edition_next_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('edition_next_button')));
      await tester.pumpAndSettle();

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

      // Navigate past free Atelier Cream (page 1) to titanium stealth (page 2) in carousel
      await tester.tap(find.byKey(const ValueKey('edition_next_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('edition_next_button')));
      await tester.pumpAndSettle();

      expect(find.text('LOCKED // PREVIEW 👁'), findsWidgets);

      // Tap locked titanium card
      final titaniumFinder = find.byKey(const ValueKey('edition_card_titaniumStealth'));
      await tester.tap(titaniumFinder);
      await tester.pumpAndSettle();

      // Verify Studio Pro dialog appears
      expect(find.text('ZYKL STUDIO PRO'), findsOneWidget);
      expect(find.textContaining('TITANIUM STEALTH'), findsWidgets);

      final unlockButton = find.byKey(const ValueKey('pro_dialog_unlock_button'));
      expect(unlockButton, findsOneWidget);

      await tester.tap(unlockButton);
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('ZYKL STUDIO PRO'), findsNothing);

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

    testWidgets('Tapping free braunAtelierCream card equips it directly without StudioProDialog even when Pro is disabled', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      // Disable simulated pro
      final switchFinder = find.byKey(const ValueKey('simulate_pro_switch'));
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Navigate to Atelier Cream (page 1)
      await tester.tap(find.byKey(const ValueKey('edition_next_button')));
      await tester.pumpAndSettle();

      final atelierFinder = find.byKey(const ValueKey('edition_card_braunAtelierCream'));
      expect(atelierFinder, findsOneWidget);

      // Verify Free tier badge
      expect(
        find.descendant(
          of: atelierFinder,
          matching: find.text('FREE'),
        ),
        findsOneWidget,
      );

      // Tap Atelier Cream card directly
      await tester.tap(atelierFinder);
      await tester.pumpAndSettle();

      // Verify StudioProDialog did NOT open
      expect(find.text('ZYKL STUDIO PRO'), findsNothing);

      // Verify Atelier Cream is equipped
      expect(
        find.descendant(
          of: atelierFinder,
          matching: find.text('EQUIPPED'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Tapping locked midCenturyWalnut and forgedCarbon cards when Pro is disabled opens StudioProDialog', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      // Disable simulated pro
      final switchFinder = find.byKey(const ValueKey('simulate_pro_switch'));
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Navigate from index 0 to index 5 (Mid-Century Walnut)
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const ValueKey('edition_next_button')));
        await tester.pumpAndSettle();
      }

      final walnutFinder = find.byKey(const ValueKey('edition_card_midCenturyWalnut'));
      expect(walnutFinder, findsOneWidget);

      await tester.tap(walnutFinder);
      await tester.pumpAndSettle();

      // Verify Studio Pro dialog appears for Mid-Century Walnut
      expect(find.text('ZYKL STUDIO PRO'), findsOneWidget);
      expect(find.textContaining('MID-CENTURY WALNUT'), findsWidgets);

      // Dismiss dialog
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();
      expect(find.text('ZYKL STUDIO PRO'), findsNothing);

      // Advance to index 6 (Forged Carbon)
      await tester.tap(find.byKey(const ValueKey('edition_next_button')));
      await tester.pumpAndSettle();

      final carbonFinder = find.byKey(const ValueKey('edition_card_forgedCarbon'));
      expect(carbonFinder, findsOneWidget);

      await tester.tap(carbonFinder);
      await tester.pumpAndSettle();

      // Verify Studio Pro dialog appears for Forged Carbon
      expect(find.text('ZYKL STUDIO PRO'), findsOneWidget);
      expect(find.textContaining('FORGED CARBON'), findsWidgets);

      // Dismiss dialog
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();
      expect(find.text('ZYKL STUDIO PRO'), findsNothing);
    });

    testWidgets('TaktSettingsSheet displays gallery counter, arrows, and page dots', (tester) async {
      final container = ProviderContainer(
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
          todayFocusStatsProvider.overrideWith(
            (ref) => Stream.value(const TodayFocusStats(completedCount: 1, totalMinutes: 25)),
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
      await tester.pumpAndSettle();

      // Verify counter badge and arrow buttons exist
      expect(find.textContaining('01 / 07'), findsOneWidget);
      expect(find.byKey(const ValueKey('edition_prev_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('edition_next_button')), findsOneWidget);

      // Verify 7 indicator dots exist
      for (int i = 0; i < 7; i++) {
        expect(find.byKey(ValueKey('edition_dot_$i')), findsOneWidget);
      }

      // Tap next button to advance to page 2
      await tester.tap(find.byKey(const ValueKey('edition_next_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('02 / 07'), findsOneWidget);

      // Tap prev button to return to page 1
      await tester.tap(find.byKey(const ValueKey('edition_prev_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('01 / 07'), findsOneWidget);
    });

    testWidgets('Pomodoro Interval Engine steppers tune custom durations without mutating active session', (tester) async {
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
              body: SingleChildScrollView(
                child: TaktSettingsSheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to interval engine section
      await tester.ensureVisible(find.byKey(const ValueKey('custom_focus_plus')));
      await tester.pumpAndSettle();

      // Verify section header and active profile label
      expect(find.text('POMODORO INTERVAL ENGINE'), findsOneWidget);
      expect(find.text('CLASSIC 25/5'), findsOneWidget);

      // Verify default custom stepper values
      expect(find.byKey(const ValueKey('custom_focus_value')), findsOneWidget);
      expect(find.text('25 MIN'), findsWidgets);
      expect(find.text('5 MIN'), findsWidgets);
      expect(find.text('15 MIN'), findsWidgets);

      // Increment Focus duration: automatically switches to CUSTOM and updates duration
      await tester.tap(find.byKey(const ValueKey('custom_focus_plus')));
      await tester.pumpAndSettle();
      expect(find.text('26 MIN'), findsOneWidget);
      expect(container.read(chronoDialProvider).customProfile.focusMinutes, equals(26));
      expect(container.read(chronoDialProvider).profile.type, equals(PomodoroProfileType.custom));
      expect(container.read(chronoDialProvider).targetMinutes, equals(26));

      // Decrement Focus duration
      await tester.tap(find.byKey(const ValueKey('custom_focus_minus')));
      await tester.pumpAndSettle();
      expect(container.read(chronoDialProvider).customProfile.focusMinutes, equals(25));
      expect(container.read(chronoDialProvider).targetMinutes, equals(25));

      // Increment Short Break
      await tester.tap(find.byKey(const ValueKey('custom_short_break_plus')));
      await tester.pumpAndSettle();
      expect(find.text('6 MIN'), findsOneWidget);
      expect(container.read(chronoDialProvider).customProfile.shortBreakMinutes, equals(6));

      // Increment Long Break
      await tester.ensureVisible(find.byKey(const ValueKey('custom_long_break_plus')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('custom_long_break_plus')));
      await tester.pumpAndSettle();
      expect(find.text('16 MIN'), findsOneWidget);
      expect(container.read(chronoDialProvider).customProfile.longBreakMinutes, equals(16));

      // Increment Cycle Count
      await tester.ensureVisible(find.byKey(const ValueKey('custom_cycle_count_plus')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('custom_cycle_count_plus')));
      await tester.pumpAndSettle();
      expect(find.text('5 CYCLES'), findsOneWidget);
      expect(container.read(chronoDialProvider).customProfile.longBreakInterval, equals(5));

      // Switch to Monastic preset and verify durations update automatically
      await tester.ensureVisible(find.text('50/10 MON'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('50/10 MON'));
      await tester.pumpAndSettle();
      expect(container.read(chronoDialProvider).profile.type, equals(PomodoroProfileType.monastic));
      expect(find.text('50 MIN'), findsOneWidget);
      expect(find.text('10 MIN'), findsOneWidget);
      expect(find.text('30 MIN'), findsOneWidget);
      expect(find.text('4 CYCLES'), findsOneWidget);
    });

    testWidgets('Pomodoro Interval Engine steppers are disabled while timer is running', (tester) async {
      final testDb = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(testDb.close);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
        ],
      );
      addTearDown(container.dispose);

      // Start the timer
      container.read(chronoDialProvider.notifier).start();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TaktSettingsSheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to interval engine section
      await tester.ensureVisible(find.byKey(const ValueKey('custom_focus_plus')));
      await tester.pumpAndSettle();

      // Tap increment button while running
      await tester.tap(find.byKey(const ValueKey('custom_focus_plus')));
      await tester.pumpAndSettle();

      // Value remains unchanged at 25 MIN
      expect(container.read(chronoDialProvider).customProfile.focusMinutes, equals(25));
    });

    testWidgets('TaktSettingsSheet renders 4-tab bar in landscape and switches tabs seamlessly', (tester) async {
      await tester.pumpWidget(buildSheet(
        overrides: [],
      ));
      // Rebuild with isLandscape: true
      await tester.pumpWidget(
        ProviderScope(
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
                totalSessions: 12,
                totalHours: 5.0,
              )),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TaktSettingsSheet(isLandscape: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tab bar rendered
      expect(find.byKey(const ValueKey('settings_landscape_tab_bar')), findsOneWidget);
      expect(find.text('EDITIONS'), findsOneWidget);
      expect(find.text('ACOUSTICS'), findsOneWidget);
      expect(find.text('INTERVALS'), findsOneWidget);
      expect(find.text('TELEMETRY'), findsOneWidget);

      // Default tab: EDITIONS
      expect(find.textContaining('HARDWARE EDITIONS'), findsOneWidget);

      // Switch to ACOUSTICS
      await tester.tap(find.byKey(const ValueKey('settings_tab_ACOUSTICS')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('master_volume_slider')), findsOneWidget);
      expect(find.textContaining('ALARM ACOUSTICS'), findsOneWidget);

      // Switch to INTERVALS
      await tester.tap(find.byKey(const ValueKey('settings_tab_INTERVALS')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('clearance_status_badge')), findsOneWidget);

      // Switch to TELEMETRY
      await tester.tap(find.byKey(const ValueKey('settings_tab_TELEMETRY')));
      await tester.pumpAndSettle();
      expect(find.text('PURGE SESSION LOGS'), findsOneWidget);
      expect(find.textContaining('Weniger, aber besser'), findsOneWidget);
    });

    testWidgets('Interval steppers remain strictly horizontal on narrow viewport (width 320) and section headers do not truncate', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      // Ensure Pomodoro section is visible
      final sectionHeaderFinder = find.text('POMODORO INTERVAL ENGINE');
      await tester.ensureVisible(sectionHeaderFinder);
      await tester.pumpAndSettle();

      // 1. Section header must render without premature truncation
      final RenderParagraph headerParagraph = tester.renderObject(
        find.descendant(
          of: sectionHeaderFinder,
          matching: find.byType(RichText),
        ),
      );
      expect(headerParagraph.didExceedMaxLines, isFalse,
          reason: 'POMODORO INTERVAL ENGINE header should not be truncated');

      // 2. All 4 steppers must remain strictly horizontal (title column and stepper controls on the same horizontal band)
      final steppers = [
        (
          title: 'FOCUS DURATION',
          valueKey: const ValueKey('custom_focus_value'),
          minusKey: const ValueKey('custom_focus_minus'),
          plusKey: const ValueKey('custom_focus_plus'),
        ),
        (
          title: 'SHORT BREAK',
          valueKey: const ValueKey('custom_short_break_value'),
          minusKey: const ValueKey('custom_short_break_minus'),
          plusKey: const ValueKey('custom_short_break_plus'),
        ),
        (
          title: 'LONG BREAK',
          valueKey: const ValueKey('custom_long_break_value'),
          minusKey: const ValueKey('custom_long_break_minus'),
          plusKey: const ValueKey('custom_long_break_plus'),
        ),
        (
          title: 'CYCLE COUNT',
          valueKey: const ValueKey('custom_cycle_count_value'),
          minusKey: const ValueKey('custom_cycle_count_minus'),
          plusKey: const ValueKey('custom_cycle_count_plus'),
        ),
      ];

      for (final s in steppers) {
        final titleFinder = find.text(s.title);
        final minusFinder = find.byKey(s.minusKey);
        final valueFinder = find.byKey(s.valueKey);
        final plusFinder = find.byKey(s.plusKey);

        await tester.ensureVisible(titleFinder);
        await tester.pumpAndSettle();

        expect(titleFinder, findsOneWidget);
        expect(minusFinder, findsOneWidget);
        expect(valueFinder, findsOneWidget);
        expect(plusFinder, findsOneWidget);

        final titleRect = tester.getRect(titleFinder);
        final minusRect = tester.getRect(minusFinder);

        // Control widgets are to the right of title
        expect(minusRect.left, greaterThan(titleRect.left),
            reason: '${s.title} controls should be to the right of the title column');

        // Controls and title are vertically aligned in the same row
        final verticalOffset = (minusRect.center.dy - titleRect.center.dy).abs();
        expect(verticalOffset, lessThan(20.0),
            reason: '${s.title} controls must be horizontally aligned with the title column, not wrapped below');

        // Value text container width must be 70 and text must fit completely without line breaks
        final valueContainerFinder = find.ancestor(
          of: valueFinder,
          matching: find.byType(Container),
        ).first;
        final valueContainerSize = tester.getSize(valueContainerFinder);
        expect(valueContainerSize.width, equals(70.0),
            reason: '${s.title} value container width should be 70');

        final RenderParagraph valueParagraph = tester.renderObject(
          find.descendant(of: valueFinder, matching: find.byType(RichText)),
        );
        expect(valueParagraph.didExceedMaxLines, isFalse,
            reason: '${s.title} value text should fit completely');
      }

      // Also verify concise subtitles are present
      expect(find.text('Extended recovery (1 – 45 min)'), findsOneWidget);
      expect(find.text('Cycles to long recovery (2 – 8)'), findsOneWidget);
    });

    testWidgets('ZYKL.APP portal button is rendered and tapping it invokes openUrl on focus_lock channel', (tester) async {
      const MethodChannel channel = MethodChannel('com.takt.desk/focus_lock');
      final List<MethodCall> log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return true;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      await tester.pumpWidget(buildSheet());
      await tester.pump();

      final portalButton = find.byKey(const ValueKey('zykl_portal_button'));
      await tester.ensureVisible(portalButton);
      await tester.pumpAndSettle();

      expect(portalButton, findsOneWidget);
      expect(find.text('ZYKL.APP // PORTAL & PRIVACY'), findsOneWidget);

      await tester.tap(portalButton);
      await tester.pumpAndSettle();

      expect(
        log.any((call) => call.method == 'openUrl' && call.arguments['url'] == 'https://zykl.app'),
        isTrue,
      );
    });
  });
}

