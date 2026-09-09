import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/takt_colors.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/features/desk/presentation/ambient_lighting_layer.dart';

void main() {
  group('AmbientLightingLayer Widget Tests', () {
    testWidgets('renders child widget and IgnorePointer overlay', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AmbientLightingLayer(
              child: Text('Desk Canvas Content'),
            ),
          ),
        ),
      );

      expect(find.text('Desk Canvas Content'), findsOneWidget);

      final ignorePointerFinder = find.descendant(
        of: find.byType(AmbientLightingLayer),
        matching: find.byType(IgnorePointer),
      );
      expect(ignorePointerFinder, findsOneWidget);

      final ignorePointer = tester.widget<IgnorePointer>(ignorePointerFinder);
      expect(ignorePointer.ignoring, isTrue);
    });

    testWidgets('applies morning daylight (6 <= hour < 11) with topLeft origin', (tester) async {
      // 08:30 AM
      final morningTime = DateTime(2026, 9, 8, 8, 30);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AmbientLightingLayer(
              currentTime: morningTime,
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AmbientLightingLayer),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      final gradient = decoration.gradient as RadialGradient;

      expect(gradient.center, Alignment.topLeft);
      expect(gradient.radius, 1.5);
      expect(gradient.colors[0], HardwareEdition.braunClassic.accentColor.withValues(alpha: 0.06));
      expect(gradient.colors[1], Colors.transparent);
    });

    testWidgets('applies afternoon sunlight (11 <= hour < 17) with topCenter origin', (tester) async {
      // 14:15 PM
      final afternoonTime = DateTime(2026, 9, 8, 14, 15);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AmbientLightingLayer(
              currentTime: afternoonTime,
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AmbientLightingLayer),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      final gradient = decoration.gradient as RadialGradient;

      expect(gradient.center, Alignment.topCenter);
      expect(gradient.radius, 1.5);
      expect(gradient.colors[0], const Color(0x15FFD6A5));
      expect(gradient.colors[1], Colors.transparent);
    });

    testWidgets('applies filament amber night lighting (hour >= 17 or hour < 6) with topRight origin', (tester) async {
      // 21:00 PM (night)
      final nightTime = DateTime(2026, 9, 8, 21, 0);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AmbientLightingLayer(
              currentTime: nightTime,
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AmbientLightingLayer),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      final gradient = decoration.gradient as RadialGradient;

      expect(gradient.center, Alignment.topRight);
      expect(gradient.radius, 1.5);
      // Filament night lamp tint with 0.08 opacity
      expect(gradient.colors[0], TaktColors.filamentAmber.withValues(alpha: 0.08));
      expect(gradient.colors[1], Colors.transparent);

      // Also test early morning pre-dawn hours (03:30 AM)
      final earlyHours = DateTime(2026, 9, 8, 3, 30);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AmbientLightingLayer(
              currentTime: earlyHours,
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      final earlyContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(AmbientLightingLayer),
          matching: find.byType(Container),
        ),
      );
      final earlyGradient = (earlyContainer.decoration as BoxDecoration).gradient as RadialGradient;
      expect(earlyGradient.center, Alignment.topRight);
      expect(earlyGradient.colors[0], TaktColors.filamentAmber.withValues(alpha: 0.08));
    });

    testWidgets('allows gesture/tap events to pass through IgnorePointer to child', (tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AmbientLightingLayer(
              child: GestureDetector(
                onTap: () => tapCount++,
                child: const Text('Interactive Button'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Interactive Button'));
      await tester.pump();

      expect(tapCount, 1);
    });

    testWidgets('defaults to DateTime.now() when currentTime is null', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AmbientLightingLayer(
              child: Text('Ambient Layer with Default Time'),
            ),
          ),
        ),
      );

      expect(find.text('Ambient Layer with Default Time'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AmbientLightingLayer),
          matching: find.byType(Container),
        ),
        findsOneWidget,
      );
    });

    testWidgets('applies active edition accent and filament colors dynamically', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(chassisThemeProvider.notifier).setHardwareEdition(HardwareEditionType.titaniumStealth);

      // Morning test (8:30 AM)
      final morningTime = DateTime(2026, 9, 8, 8, 30);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AmbientLightingLayer(
              currentTime: morningTime,
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      var box = tester.widget<Container>(
        find.descendant(
          of: find.byType(AmbientLightingLayer),
          matching: find.byType(Container),
        ),
      );
      var gradient = (box.decoration as BoxDecoration).gradient as RadialGradient;
      expect(gradient.colors[0], HardwareEdition.titaniumStealth.accentColor.withValues(alpha: 0.06));

      // Night test (21:00 PM)
      final nightTime = DateTime(2026, 9, 8, 21, 0);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AmbientLightingLayer(
              currentTime: nightTime,
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      box = tester.widget<Container>(
        find.descendant(
          of: find.byType(AmbientLightingLayer),
          matching: find.byType(Container),
        ),
      );
      gradient = (box.decoration as BoxDecoration).gradient as RadialGradient;
      expect(gradient.colors[0], HardwareEdition.titaniumStealth.filamentColor.withValues(alpha: 0.08));
    });
  });
}
