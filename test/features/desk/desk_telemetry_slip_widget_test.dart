import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/desk/presentation/widgets/desk_telemetry_slip_widget.dart';

void main() {
  testWidgets('DeskTelemetrySlipWidget animates expansion and renders session log entries', (tester) async {
    final now = DateTime(2026, 9, 10, 14, 0);
    final mockSessions = [
      TimerSession(
        id: 1,
        targetMinutes: 25,
        elapsedSeconds: 1500,
        isFinished: true,
        startedAt: now,
        finishedAt: now.add(const Duration(minutes: 25)),
      ),
    ];

    bool retracted = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value(mockSessions)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DeskTelemetrySlipWidget(
              isExpanded: true,
              onRetract: () => retracted = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('TAKT DESK // SESSION TELEMETRY'), findsOneWidget);
    expect(find.textContaining('1 CYCLES · 25 MIN'), findsOneWidget);
    expect(find.textContaining('STATUS: COMPLETED ●'), findsOneWidget);
    expect(find.text('[ COPY TEXT LOG ]'), findsOneWidget);
    expect(find.text('[ RETRACT ▲ ]'), findsOneWidget);

    // Tap retract
    await tester.tap(find.text('[ RETRACT ▲ ]'));
    await tester.pumpAndSettle();
    expect(retracted, isTrue);
  });

  testWidgets('DeskTelemetrySlipWidget copies formatted telemetry text to clipboard', (tester) async {
    final now = DateTime(2026, 9, 10, 14, 0);
    final mockSessions = [
      TimerSession(
        id: 1,
        targetMinutes: 25,
        elapsedSeconds: 1500,
        isFinished: true,
        startedAt: now,
        finishedAt: now.add(const Duration(minutes: 25)),
      ),
    ];

    String? clipboardData;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboardData = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });

    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value(mockSessions)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DeskTelemetrySlipWidget(
              isExpanded: true,
              onRetract: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('[ COPY TEXT LOG ]'));
    await tester.pump();

    expect(clipboardData, isNotNull);
    expect(clipboardData, contains('TAKT DESK // SESSION TELEMETRY'));
    expect(clipboardData, contains('STATUS: COMPLETED ●'));
    expect(find.text('[ COPIED! ]'), findsOneWidget);
  });

  testWidgets('DeskTelemetrySlipWidget renders standby notice when sessions list is empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DeskTelemetrySlipWidget(
              isExpanded: true,
              onRetract: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('TAKT DESK // SESSION TELEMETRY'), findsOneWidget);
    expect(find.textContaining('[ NO SESSIONS RECORDED TODAY ]'), findsOneWidget);
    expect(find.textContaining('STANDBY // COMMENCE CHRONO DIAL'), findsOneWidget);
  });

  testWidgets('DeskTelemetrySlipWidget animates expansion and collapse when isExpanded changes', (tester) async {
    final now = DateTime(2026, 9, 10, 14, 0);
    final mockSessions = [
      TimerSession(
        id: 1,
        targetMinutes: 25,
        elapsedSeconds: 1500,
        isFinished: true,
        startedAt: now,
        finishedAt: now.add(const Duration(minutes: 25)),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value(mockSessions)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DeskTelemetrySlipWidget(
              isExpanded: false,
              onRetract: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // With isExpanded false, SizeTransition height factor should be 0.0
    final sizeTransitionFinder = find.byType(SizeTransition);
    expect(sizeTransitionFinder, findsOneWidget);
    final sizeTransition = tester.widget<SizeTransition>(sizeTransitionFinder);
    expect(sizeTransition.sizeFactor.value, equals(0.0));

    // Re-pump with isExpanded = true (Expansion)
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value(mockSessions)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DeskTelemetrySlipWidget(
              isExpanded: true,
              onRetract: () {},
            ),
          ),
        ),
      ),
    );
    // Mid animation
    await tester.pump(const Duration(milliseconds: 200));
    final midSizeTransition = tester.widget<SizeTransition>(sizeTransitionFinder);
    expect(midSizeTransition.sizeFactor.value, greaterThan(0.0));
    expect(midSizeTransition.sizeFactor.value, lessThan(1.0));

    // End animation
    await tester.pumpAndSettle();
    final endSizeTransition = tester.widget<SizeTransition>(sizeTransitionFinder);
    expect(endSizeTransition.sizeFactor.value, equals(1.0));

    // Re-pump with isExpanded = false (Collapse)
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value(mockSessions)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DeskTelemetrySlipWidget(
              isExpanded: false,
              onRetract: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    final collapsingTransition = tester.widget<SizeTransition>(sizeTransitionFinder);
    expect(collapsingTransition.sizeFactor.value, lessThan(1.0));
    expect(collapsingTransition.sizeFactor.value, greaterThan(0.0));

    await tester.pumpAndSettle();
    final collapsedTransition = tester.widget<SizeTransition>(sizeTransitionFinder);
    expect(collapsedTransition.sizeFactor.value, equals(0.0));
  });

  testWidgets('DeskTelemetrySlipWidget supports light mode aesthetics', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chassisThemeProvider.overrideWith((ref) => ThemeController()..setDarkMode(false)),
          todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DeskTelemetrySlipWidget(
              isExpanded: true,
              onRetract: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('TAKT DESK // SESSION TELEMETRY'), findsOneWidget);
  });
}
