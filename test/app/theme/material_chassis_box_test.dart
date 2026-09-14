import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/app/theme/widgets/material_chassis_box.dart';
import 'package:takt_desk/app/theme/widgets/material_texture_painter.dart';

void main() {
  group('MaterialTexturePainter Unit Tests', () {
    test('shouldRepaint returns false when properties are identical', () {
      const painter1 = MaterialTexturePainter(
        textureType: HardwareTextureType.matteAbsGrain,
        isDark: true,
        chassisColor: Color(0xFF24272C),
      );
      const painter2 = MaterialTexturePainter(
        textureType: HardwareTextureType.matteAbsGrain,
        isDark: true,
        chassisColor: Color(0xFF24272C),
      );
      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('shouldRepaint returns true when textureType changes', () {
      const painter1 = MaterialTexturePainter(
        textureType: HardwareTextureType.matteAbsGrain,
        isDark: true,
        chassisColor: Color(0xFF24272C),
      );
      const painter2 = MaterialTexturePainter(
        textureType: HardwareTextureType.brushedTitanium,
        isDark: true,
        chassisColor: Color(0xFF24272C),
      );
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns true when isDark changes', () {
      const painter1 = MaterialTexturePainter(
        textureType: HardwareTextureType.brushedTitanium,
        isDark: true,
        chassisColor: Color(0xFF1B1E24),
      );
      const painter2 = MaterialTexturePainter(
        textureType: HardwareTextureType.brushedTitanium,
        isDark: false,
        chassisColor: Color(0xFF1B1E24),
      );
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns true when chassisColor changes', () {
      const painter1 = MaterialTexturePainter(
        textureType: HardwareTextureType.burnishedBrass,
        isDark: true,
        chassisColor: Color(0xFF202520),
      );
      const painter2 = MaterialTexturePainter(
        textureType: HardwareTextureType.burnishedBrass,
        isDark: true,
        chassisColor: Color(0xFFCCC7B3),
      );
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('paint succeeds across all HardwareTextureTypes and dark/light modes', () {
      for (final type in HardwareTextureType.values) {
        for (final isDark in [true, false]) {
          final painter = MaterialTexturePainter(
            textureType: type,
            isDark: isDark,
            chassisColor: isDark ? const Color(0xFF202020) : const Color(0xFFE0E0E0),
          );
          final recorder = PictureRecorder();
          final canvas = Canvas(recorder);
          expect(
            () => painter.paint(canvas, const Size(200, 200)),
            returnsNormally,
            reason: 'Painting texture $type with isDark=$isDark should not throw',
          );
          recorder.endRecording();
        }
      }
    });
  });

  group('ChassisChamferPainter Unit Tests', () {
    test('shouldRepaint returns false when properties are identical', () {
      const painter1 = ChassisChamferPainter(
        highlightColor: Color(0x20FFFFFF),
        borderRadius: BorderRadius.all(Radius.circular(8)),
        strokeWidth: 1.0,
      );
      const painter2 = ChassisChamferPainter(
        highlightColor: Color(0x20FFFFFF),
        borderRadius: BorderRadius.all(Radius.circular(8)),
        strokeWidth: 1.0,
      );
      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('shouldRepaint returns true when highlightColor, borderRadius, or strokeWidth changes', () {
      const base = ChassisChamferPainter(
        highlightColor: Color(0x20FFFFFF),
        borderRadius: BorderRadius.all(Radius.circular(8)),
        strokeWidth: 1.0,
      );
      const diffColor = ChassisChamferPainter(
        highlightColor: Color(0x40FFFFFF),
        borderRadius: BorderRadius.all(Radius.circular(8)),
        strokeWidth: 1.0,
      );
      const diffRadius = ChassisChamferPainter(
        highlightColor: Color(0x20FFFFFF),
        borderRadius: BorderRadius.all(Radius.circular(12)),
        strokeWidth: 1.0,
      );
      const diffWidth = ChassisChamferPainter(
        highlightColor: Color(0x20FFFFFF),
        borderRadius: BorderRadius.all(Radius.circular(8)),
        strokeWidth: 2.0,
      );

      expect(base.shouldRepaint(diffColor), isTrue);
      expect(base.shouldRepaint(diffRadius), isTrue);
      expect(base.shouldRepaint(diffWidth), isTrue);
    });

    test('paint draws top and left chamfer specular path without throwing', () {
      const painter = ChassisChamferPainter(
        highlightColor: Color(0x20FFFFFF),
        borderRadius: BorderRadius.all(Radius.circular(8)),
        strokeWidth: 1.0,
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, const Size(200, 200)), returnsNormally);
      final picture = recorder.endRecording();
      picture.dispose();
    });
  });

  group('MaterialChassisBox Widget Tests', () {
    testWidgets('renders multi-layer elevation depth shadows and chamfer highlight in dark and light modes', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(chassisThemeProvider.notifier).setDarkMode(true);

      // 1. Dark Mode
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: MaterialChassisBox(
                child: Text('Chamfer Depth'),
              ),
            ),
          ),
        ),
      );

      // Verify multi-layer shadows
      final boxContainer = tester.widget<Container>(find.byType(Container).first);
      final darkDeco = boxContainer.decoration as BoxDecoration;
      expect(darkDeco.boxShadow, isNotNull);
      expect(darkDeco.boxShadow!.length, greaterThanOrEqualTo(2));

      // Deep directional cast shadow
      final darkCastShadow = darkDeco.boxShadow![0];
      expect(darkCastShadow.blurRadius, equals(14));
      expect(darkCastShadow.offset, equals(const Offset(0, 6)));
      expect(darkCastShadow.color, equals(Colors.black.withValues(alpha: 0.45)));

      // Tighter ambient contact shadow
      final darkContactShadow = darkDeco.boxShadow![1];
      expect(darkContactShadow.blurRadius, equals(4));
      expect(darkContactShadow.offset, equals(const Offset(0, 1)));
      expect(darkContactShadow.color, equals(Colors.black.withValues(alpha: 0.25)));

      // Verify chamfer highlight painter is attached as foregroundPainter inside ClipRRect
      final customPaintFinder = find.descendant(
        of: find.byType(ClipRRect),
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsOneWidget);
      var customPaint = tester.widget<CustomPaint>(customPaintFinder);
      expect(customPaint.foregroundPainter, isA<ChassisChamferPainter>());
      var chamferPainter = customPaint.foregroundPainter as ChassisChamferPainter;
      expect(chamferPainter.highlightColor, equals(Colors.white.withValues(alpha: 0.12)));

      // 2. Switch to Light Mode
      container.read(chassisThemeProvider.notifier).setDarkMode(false);
      await tester.pumpAndSettle();

      final lightBoxContainer = tester.widget<Container>(find.byType(Container).first);
      final lightDeco = lightBoxContainer.decoration as BoxDecoration;
      expect(lightDeco.boxShadow![0].color, equals(const Color(0x1F000000)));
      expect(lightDeco.boxShadow![1].color, equals(const Color(0x0F000000)));

      customPaint = tester.widget<CustomPaint>(customPaintFinder);
      expect(customPaint.foregroundPainter, isA<ChassisChamferPainter>());
      chamferPainter = customPaint.foregroundPainter as ChassisChamferPainter;
      expect(chamferPainter.highlightColor, equals(Colors.white.withValues(alpha: 0.28)));
    });
    testWidgets('renders child widget inside container with custom padding and margin', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MaterialChassisBox(
                width: 250,
                height: 150,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.all(8),
                child: Text('Console Display Unit'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Console Display Unit'), findsOneWidget);

      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      expect(container.constraints?.maxWidth, 250);
      expect(container.constraints?.maxHeight, 150);
      expect(container.margin, const EdgeInsets.all(8));

      // Locate the innermost padding wrapping the child directly
      final childPaddingFinder = find.ancestor(
        of: find.text('Console Display Unit'),
        matching: find.byType(Padding),
      );
      final padding = tester.widget<Padding>(childPaddingFinder.first);
      expect(padding.padding, const EdgeInsets.all(12));
    });

    testWidgets('embeds 4 corner rivets with rivetKeyPrefix and theme rivetColor', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MaterialChassisBox(
                rivetKeyPrefix: 'test_rivet',
                child: Text('Rivet Inspection'),
              ),
            ),
          ),
        ),
      );

      for (int i = 0; i < 4; i++) {
        final rivetFinder = find.byKey(ValueKey('test_rivet_$i'));
        expect(rivetFinder, findsOneWidget);

        final rivetContainer = tester.widget<Container>(rivetFinder);
        final decoration = rivetContainer.decoration as BoxDecoration;
        expect(decoration.shape, BoxShape.circle);
        expect(decoration.color, equals(HardwareEdition.braunClassic.rivetDark));

        final ignorePointer = find.ancestor(
          of: rivetFinder,
          matching: find.byWidgetPredicate((w) => w is IgnorePointer && w.ignoring == true),
        );
        expect(ignorePointer, findsOneWidget);
      }
    });

    testWidgets('does not render rivets when showRivets is false', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MaterialChassisBox(
                showRivets: false,
                rivetKeyPrefix: 'hidden_rivet',
                child: Text('No Rivets'),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('hidden_rivet_0')), findsNothing);
      expect(find.byKey(const ValueKey('hidden_rivet_1')), findsNothing);
      expect(find.byKey(const ValueKey('hidden_rivet_2')), findsNothing);
      expect(find.byKey(const ValueKey('hidden_rivet_3')), findsNothing);
    });

    testWidgets('renders MaterialTexturePainter inside ClipRRect when showTexture is true', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MaterialChassisBox(
                showTexture: true,
                child: Text('Textured Box'),
              ),
            ),
          ),
        ),
      );

      final clipRRectFinder = find.descendant(
        of: find.byType(MaterialChassisBox),
        matching: find.byType(ClipRRect),
      );
      expect(clipRRectFinder, findsOneWidget);

      final repaintBoundaryFinder = find.descendant(
        of: clipRRectFinder,
        matching: find.byType(RepaintBoundary),
      );
      expect(repaintBoundaryFinder, findsOneWidget);

      final customPaintFinder = find.descendant(
        of: repaintBoundaryFinder,
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsOneWidget);

      final customPaint = tester.widget<CustomPaint>(customPaintFinder);
      expect(customPaint.isComplex, isTrue);
      expect(customPaint.willChange, isFalse);
      expect(customPaint.painter, isA<MaterialTexturePainter>());

      final painter = customPaint.painter as MaterialTexturePainter;
      expect(painter.textureType, HardwareTextureType.matteAbsGrain);
      expect(painter.isDark, isTrue);
      expect(painter.chassisColor, HardwareEdition.braunClassic.darkModuleBg);
    });

    testWidgets('omits texture and chamfer painters when both showTexture and showChamfer are false', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MaterialChassisBox(
                showTexture: false,
                showChamfer: false,
                child: Text('Smooth Box'),
              ),
            ),
          ),
        ),
      );

      final clipRRectFinder = find.descendant(
        of: find.byType(MaterialChassisBox),
        matching: find.byType(ClipRRect),
      );
      expect(clipRRectFinder, findsNothing);

      final customPaintFinder = find.descendant(
        of: find.byType(MaterialChassisBox),
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsNothing);
    });

    testWidgets('renders ChassisChamferPainter when showTexture is false and showChamfer is true', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MaterialChassisBox(
                showTexture: false,
                showChamfer: true,
                child: Text('Chamfer Highlight Box'),
              ),
            ),
          ),
        ),
      );

      final clipRRectFinder = find.descendant(
        of: find.byType(MaterialChassisBox),
        matching: find.byType(ClipRRect),
      );
      expect(clipRRectFinder, findsOneWidget);

      final customPaintFinder = find.descendant(
        of: clipRRectFinder,
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsOneWidget);

      final customPaint = tester.widget<CustomPaint>(customPaintFinder);
      expect(customPaint.painter, isNull);
      expect(customPaint.foregroundPainter, isA<ChassisChamferPainter>());
    });

    testWidgets('reacts dynamically when theme changes from braunClassic to titaniumStealth', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(chassisThemeProvider.notifier).setDarkMode(true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: MaterialChassisBox(
                rivetKeyPrefix: 'chassis_rivet',
                child: Text('Dynamic Chassis Box'),
              ),
            ),
          ),
        ),
      );

      final texturePaintFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is MaterialTexturePainter,
      );

      // Verify braunClassic state
      var customPaint = tester.widget<CustomPaint>(texturePaintFinder);
      var painter = customPaint.painter as MaterialTexturePainter;
      expect(painter.textureType, HardwareTextureType.matteAbsGrain);
      expect(painter.chassisColor, HardwareEdition.braunClassic.darkModuleBg);

      var rivet = tester.widget<Container>(find.byKey(const ValueKey('chassis_rivet_0')));
      var rivetDeco = rivet.decoration as BoxDecoration;
      expect(rivetDeco.color, HardwareEdition.braunClassic.rivetDark);

      // Switch to titaniumStealth
      container.read(chassisThemeProvider.notifier).setHardwareEdition(HardwareEditionType.titaniumStealth);
      await tester.pumpAndSettle();

      // Verify titaniumStealth state
      customPaint = tester.widget<CustomPaint>(texturePaintFinder);
      painter = customPaint.painter as MaterialTexturePainter;
      expect(painter.textureType, HardwareTextureType.brushedTitanium);
      expect(painter.chassisColor, HardwareEdition.titaniumStealth.darkModuleBg);

      rivet = tester.widget<Container>(find.byKey(const ValueKey('chassis_rivet_0')));
      rivetDeco = rivet.decoration as BoxDecoration;
      expect(rivetDeco.color, HardwareEdition.titaniumStealth.rivetDark);

      // Switch to Light Mode
      container.read(chassisThemeProvider.notifier).setDarkMode(false);
      await tester.pumpAndSettle();

      customPaint = tester.widget<CustomPaint>(texturePaintFinder);
      painter = customPaint.painter as MaterialTexturePainter;
      expect(painter.isDark, isFalse);
      expect(painter.chassisColor, HardwareEdition.titaniumStealth.lightModuleBg);

      rivet = tester.widget<Container>(find.byKey(const ValueKey('chassis_rivet_0')));
      rivetDeco = rivet.decoration as BoxDecoration;
      expect(rivetDeco.color, HardwareEdition.titaniumStealth.rivetLight);
    });
  });
}
