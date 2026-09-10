import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/features/tasks/presentation/receipt_runner_controller.dart';
import 'package:takt_desk/features/tasks/presentation/receipt_runner_painter.dart';
import 'package:takt_desk/features/tasks/presentation/receipt_runner_widget.dart';
import 'package:takt_desk/features/tasks/presentation/task_input_sheet.dart';

void main() {
  Widget buildTestWidget({ReceiptRunnerController? controller}) {
    return ProviderScope(
      overrides: [
        if (controller != null)
          receiptRunnerProvider.overrideWith((ref) => controller),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ReceiptRunnerWidget(),
          ),
        ),
      ),
    );
  }

  group('ReceiptRunnerPainter', () {
    test('shouldRepaint returns true when tearProgress changes', () {
      final painter1 = ReceiptRunnerPainter(tearProgress: 0.0);
      final painter2 = ReceiptRunnerPainter(tearProgress: 0.5);
      final painter3 = ReceiptRunnerPainter(tearProgress: 0.0);

      expect(painter1.shouldRepaint(painter2), isTrue);
      expect(painter1.shouldRepaint(painter3), isFalse);
    });

    test('paints correctly with dynamic tear shear displacement and stress line', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final painter = ReceiptRunnerPainter(tearProgress: 0.5);

      expect(() => painter.paint(canvas, const Size(200, 60)), returnsNormally);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  group('ReceiptRunnerWidget', () {
    testWidgets('renders empty state queue and dispenser label', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('DISPENSER: 5 MAX'), findsOneWidget);
      expect(find.text('NO TASKS IN QUEUE'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('opens TaskInputSheet and adds a task upon feeding paper', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Tap the add icon
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Check TaskInputSheet is opened
      expect(find.byType(TaskInputSheet), findsOneWidget);
      expect(find.text('PRINT TASK RECEIPT'), findsOneWidget);

      // Enter task title
      await tester.enterText(find.byType(TextField), 'Calibrate Instruments');
      await tester.tap(find.text('FEED PAPER (PRINT)'));
      await tester.pumpAndSettle();

      // Bottom sheet closed and task item rendered
      expect(find.byType(TaskInputSheet), findsNothing);
      expect(find.text('NO TASKS IN QUEUE'), findsNothing);
      expect(find.text('Calibrate Instruments'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('double tap stamps task as done and toggles stamp', (tester) async {
      final controller = ReceiptRunnerController();
      controller.addTask('Log Telemetry');

      await tester.pumpWidget(buildTestWidget(controller: controller));

      expect(find.text('Log Telemetry'), findsOneWidget);
      expect(find.text('[DONE]'), findsNothing);

      // Double tap task to stamp done
      await tester.tap(find.text('Log Telemetry'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Log Telemetry'));
      await tester.pumpAndSettle();

      expect(find.text('[DONE]'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('Log Telemetry'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);

      // Double tap again to unstamp
      await tester.tap(find.text('Log Telemetry'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Log Telemetry'));
      await tester.pumpAndSettle();

      expect(find.text('[DONE]'), findsNothing);
      final textWidget2 = tester.widget<Text>(find.text('Log Telemetry'));
      expect(textWidget2.style?.decoration, isNull);
    });

    testWidgets('swiping dismisses/tears task from queue', (tester) async {
      final controller = ReceiptRunnerController();
      controller.addTask('Paper Tear Test');

      await tester.pumpWidget(buildTestWidget(controller: controller));
      expect(find.text('Paper Tear Test'), findsOneWidget);

      // Swipe horizontally to dismiss
      await tester.drag(find.text('Paper Tear Test'), const Offset(400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Paper Tear Test'), findsNothing);
      expect(find.text('NO TASKS IN QUEUE'), findsOneWidget);
    });

    testWidgets('disables add button when 5 tasks are queued', (tester) async {
      final controller = ReceiptRunnerController();
      for (int i = 1; i <= 5; i++) {
        controller.addTask('Batch $i');
      }

      await tester.pumpWidget(buildTestWidget(controller: controller));

      final iconButton = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add));
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('updates chassis color, border, and feeder slit border dynamically on edition switch', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: ReceiptRunnerWidget(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Initially braunClassic (dark mode)
      final chassisFinder = find.byKey(const ValueKey('receipt_dispenser_chassis'));
      final casingBefore = tester.widget<Container>(chassisFinder);
      final decorationBefore = casingBefore.decoration as BoxDecoration;
      expect(decorationBefore.color, equals(HardwareEdition.braunClassic.darkModuleBg));
      final borderBefore = decorationBefore.border as Border;
      expect(borderBefore.top.color, equals(HardwareEdition.braunClassic.darkBorder));

      // Verify feeder aperture slit border
      final slitFinder = find.byKey(const ValueKey('dispenser_aperture_slit'));
      final slitBefore = tester.widget<Container>(slitFinder);
      final slitDecorationBefore = slitBefore.decoration as BoxDecoration;
      final slitBorderBefore = slitDecorationBefore.border as Border;
      expect(slitBorderBefore.top.color, equals(HardwareEdition.braunClassic.darkBorder));

      // Switch edition to titaniumStealth
      container.read(chassisThemeProvider.notifier).setHardwareEdition(HardwareEditionType.titaniumStealth);
      await tester.pumpAndSettle();

      final casingAfter = tester.widget<Container>(chassisFinder);
      final decorationAfter = casingAfter.decoration as BoxDecoration;
      expect(decorationAfter.color, equals(HardwareEdition.titaniumStealth.darkModuleBg));
      final borderAfter = decorationAfter.border as Border;
      expect(borderAfter.top.color, equals(HardwareEdition.titaniumStealth.darkBorder));

      // Verify feeder aperture slit border updated
      final slitAfter = tester.widget<Container>(slitFinder);
      final slitDecorationAfter = slitAfter.decoration as BoxDecoration;
      final slitBorderAfter = slitDecorationAfter.border as Border;
      expect(slitBorderAfter.top.color, equals(HardwareEdition.titaniumStealth.darkBorder));
    });

    testWidgets('renders 4 corner rivets matching active edition rivetColor', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: ReceiptRunnerWidget(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      for (int i = 0; i < 4; i++) {
        final rivetFinder = find.byKey(ValueKey('dispenser_rivet_$i'));
        expect(rivetFinder, findsOneWidget);
        final rivet = tester.widget<Container>(rivetFinder);
        final decoration = rivet.decoration as BoxDecoration;
        expect(decoration.color, equals(HardwareEdition.braunClassic.rivetDark));
      }

      // Switch to rawBrassPatina
      container.read(chassisThemeProvider.notifier).setHardwareEdition(HardwareEditionType.rawBrassPatina);
      await tester.pumpAndSettle();

      for (int i = 0; i < 4; i++) {
        final rivetFinder = find.byKey(ValueKey('dispenser_rivet_$i'));
        expect(rivetFinder, findsOneWidget);
        final rivet = tester.widget<Container>(rivetFinder);
        final decoration = rivet.decoration as BoxDecoration;
        expect(decoration.color, equals(HardwareEdition.rawBrassPatina.rivetDark));
      }
    });

    testWidgets('updates ArchiveDrawerWidget plate gradient, rivets, and border dynamically', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: ReceiptRunnerWidget(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Drawer closed border
      final drawerContainerFinder = find.byKey(const ValueKey('archive_drawer_container'));
      expect(drawerContainerFinder, findsOneWidget);
      final drawerContainer = tester.widget<Container>(drawerContainerFinder);
      final drawerDecoration = drawerContainer.decoration as BoxDecoration;
      final drawerBorder = drawerDecoration.border as Border;
      expect(drawerBorder.top.color, equals(HardwareEdition.braunClassic.darkBorder));

      // Handle bar gradient
      final handleBarFinder = find.byKey(const ValueKey('archive_drawer_handle_bar'));
      expect(handleBarFinder, findsOneWidget);
      final handleBar = tester.widget<Container>(handleBarFinder);
      final handleDecoration = handleBar.decoration as BoxDecoration;
      final gradient = handleDecoration.gradient as LinearGradient;
      expect(gradient.colors, equals(HardwareEdition.braunClassic.plateGradientDark));

      // Handle rivets
      final leftRivet = tester.widget<Container>(find.byKey(const ValueKey('archive_drawer_rivet_left')));
      expect((leftRivet.decoration as BoxDecoration).color, equals(HardwareEdition.braunClassic.rivetDark));
      final rightRivet = tester.widget<Container>(find.byKey(const ValueKey('archive_drawer_rivet_right')));
      expect((rightRivet.decoration as BoxDecoration).color, equals(HardwareEdition.braunClassic.rivetDark));

      // Switch to titaniumStealth
      container.read(chassisThemeProvider.notifier).setHardwareEdition(HardwareEditionType.titaniumStealth);
      await tester.pumpAndSettle();

      final drawerAfter = tester.widget<Container>(drawerContainerFinder);
      final drawerBorderAfter = (drawerAfter.decoration as BoxDecoration).border as Border;
      expect(drawerBorderAfter.top.color, equals(HardwareEdition.titaniumStealth.darkBorder));

      final handleBarAfter = tester.widget<Container>(handleBarFinder);
      final gradientAfter = (handleBarAfter.decoration as BoxDecoration).gradient as LinearGradient;
      expect(gradientAfter.colors, equals(HardwareEdition.titaniumStealth.plateGradientDark));

      final leftRivetAfter = tester.widget<Container>(find.byKey(const ValueKey('archive_drawer_rivet_left')));
      expect((leftRivetAfter.decoration as BoxDecoration).color, equals(HardwareEdition.titaniumStealth.rivetDark));

      // Open drawer and check open border color uses filamentColor with alpha 0.6
      await tester.tap(find.byKey(const ValueKey('archive_drawer_handle_bar')));
      await tester.pumpAndSettle();

      final drawerOpen = tester.widget<Container>(drawerContainerFinder);
      final drawerOpenBorder = (drawerOpen.decoration as BoxDecoration).border as Border;
      expect(
        drawerOpenBorder.top.color,
        equals(HardwareEdition.titaniumStealth.filamentColor.withValues(alpha: 0.6)),
      );
    });
  });
}
