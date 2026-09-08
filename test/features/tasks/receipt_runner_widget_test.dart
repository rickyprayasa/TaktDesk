import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
