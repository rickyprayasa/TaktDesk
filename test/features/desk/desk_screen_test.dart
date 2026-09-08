import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:takt_desk/core/sensors/parallax_controller.dart';
import 'package:takt_desk/features/desk/presentation/ambient_lighting_layer.dart';
import 'package:takt_desk/features/desk/presentation/desk_canvas_screen.dart';
import 'package:takt_desk/features/desk/presentation/isometric_desk_layout.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_widget.dart';
import 'package:takt_desk/features/tasks/presentation/receipt_runner_widget.dart';
import 'package:takt_desk/features/vinyl/presentation/vinyl_player_widget.dart';

void main() {
  group('DeskCanvasScreen & IsometricDeskLayout', () {
    testWidgets('DeskCanvasScreen renders all 3 analog instruments', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DeskCanvasScreen(),
          ),
        ),
      );

      expect(find.byType(AmbientLightingLayer), findsOneWidget);
      expect(find.byType(IsometricDeskLayout), findsOneWidget);
      expect(find.byType(ChronoDialWidget), findsOneWidget);
      expect(find.byType(ReceiptRunnerWidget), findsOneWidget);
      expect(find.byType(VinylPlayerWidget), findsOneWidget);
    });

    testWidgets('IsometricDeskLayout applies 3D perspective and parallax transform', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set non-zero tilt on parallaxProvider
      container.read(parallaxProvider.notifier).updateSensorInput(rawX: 4.0, rawY: -3.0);
      final parallaxState = container.read(parallaxProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: IsometricDeskLayout(
                child: Text('Desk Surface'),
              ),
            ),
          ),
        ),
      );

      final transformFinder = find.descendant(
        of: find.byType(IsometricDeskLayout),
        matching: find.byType(Transform),
      );
      expect(transformFinder, findsOneWidget);

      final transformWidget = tester.widget<Transform>(transformFinder);
      final matrix = transformWidget.transform;

      // Perspective entry (3,2) should be 0.001
      expect(matrix.entry(3, 2), closeTo(0.001, 1e-5));
      expect(transformWidget.alignment, Alignment.center);
      expect(parallaxState.tiltX, isNonZero);
      expect(parallaxState.tiltY, isNonZero);
    });

    testWidgets('DeskCanvasScreen updates parallaxProvider from gyroscope stream', (tester) async {
      final streamController = StreamController<GyroscopeEvent>.broadcast();
      addTearDown(streamController.close);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: DeskCanvasScreen(gyroscopeStream: streamController.stream),
          ),
        ),
      );

      expect(container.read(parallaxProvider).tiltX, 0.0);
      expect(container.read(parallaxProvider).tiltY, 0.0);

      // Emit a gyroscope event
      streamController.add(GyroscopeEvent(2.5, 1.5, 0.0));
      await tester.pump();

      expect(container.read(parallaxProvider).tiltX, isNonZero);
      expect(container.read(parallaxProvider).tiltY, isNonZero);
    });

    testWidgets('DeskCanvasScreen handles gyroscope stream error gracefully without crashing', (tester) async {
      final streamController = StreamController<GyroscopeEvent>.broadcast();
      addTearDown(streamController.close);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: DeskCanvasScreen(gyroscopeStream: streamController.stream),
          ),
        ),
      );

      // Emit an error (e.g. sensor unavailable)
      streamController.addError(Exception('Sensor not available on device'));
      await tester.pump();

      // Screen should still be rendered without throwing
      expect(find.byType(DeskCanvasScreen), findsOneWidget);
    });

    testWidgets('DeskCanvasScreen updates parallaxProvider from accelerometer stream', (tester) async {
      final streamController = StreamController<AccelerometerEvent>.broadcast();
      addTearDown(streamController.close);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: DeskCanvasScreen(accelerometerStream: streamController.stream),
          ),
        ),
      );

      expect(container.read(parallaxProvider).tiltX, 0.0);
      expect(container.read(parallaxProvider).tiltY, 0.0);

      // Emit an accelerometer event (phone tilted)
      streamController.add(AccelerometerEvent(0.4, 0.3, 9.8));
      await tester.pump();

      expect(container.read(parallaxProvider).tiltX, isNonZero);
      expect(container.read(parallaxProvider).tiltY, isNonZero);
    });

    testWidgets('DeskCanvasScreen handles accelerometer stream error gracefully without crashing', (tester) async {
      final streamController = StreamController<AccelerometerEvent>.broadcast();
      addTearDown(streamController.close);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: DeskCanvasScreen(accelerometerStream: streamController.stream),
          ),
        ),
      );

      streamController.addError(Exception('Accelerometer not available'));
      await tester.pump();

      expect(find.byType(DeskCanvasScreen), findsOneWidget);
    });
  });
}
