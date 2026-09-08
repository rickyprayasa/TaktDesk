import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../app/theme/takt_colors.dart';
import '../../../core/sensors/parallax_controller.dart';
import '../../tasks/presentation/receipt_runner_widget.dart';
import '../../timer/presentation/chrono_dial_widget.dart';
import '../../vinyl/presentation/vinyl_player_widget.dart';
import 'ambient_lighting_layer.dart';
import 'isometric_desk_layout.dart';

class DeskCanvasScreen extends ConsumerStatefulWidget {
  final Stream<GyroscopeEvent>? gyroscopeStream;
  final Stream<AccelerometerEvent>? accelerometerStream;

  const DeskCanvasScreen({
    super.key,
    this.gyroscopeStream,
    this.accelerometerStream,
  });

  @override
  ConsumerState<DeskCanvasScreen> createState() => _DeskCanvasScreenState();
}

class _DeskCanvasScreenState extends ConsumerState<DeskCanvasScreen> {
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  void _initSensors() {
    if (widget.gyroscopeStream != null) {
      try {
        _gyroscopeSubscription = widget.gyroscopeStream!.listen(
          (event) {
            if (!mounted) return;
            ref.read(parallaxProvider.notifier).updateSensorInput(
                  rawX: event.x,
                  rawY: event.y,
                );
          },
          onError: (Object error) {
            // Handle platforms/environments without gyroscope gracefully without crashing
          },
          cancelOnError: false,
        );
      } catch (_) {}
    }

    if (widget.accelerometerStream != null) {
      try {
        _accelerometerSubscription = widget.accelerometerStream!.listen(
          (event) {
            if (!mounted) return;
            ref.read(parallaxProvider.notifier).updateTiltFromAccelerometer(
                  x: event.x,
                  y: event.y,
                  z: event.z,
                );
          },
          onError: (Object error) {
            // Handle platforms/environments without accelerometer gracefully without crashing
          },
          cancelOnError: false,
        );
      } catch (_) {}
    }

    if (widget.gyroscopeStream == null && widget.accelerometerStream == null) {
      try {
        _accelerometerSubscription = accelerometerEventStream().listen(
          (event) {
            if (!mounted) return;
            ref.read(parallaxProvider.notifier).updateTiltFromAccelerometer(
                  x: event.x,
                  y: event.y,
                  z: event.z,
                );
          },
          onError: (Object error) {
            // Handle platforms/environments without accelerometer gracefully without crashing
          },
          cancelOnError: false,
        );
      } catch (_) {
        // Platform does not support accelerometer or sensor initialization failed
      }
    }
  }

  @override
  void dispose() {
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: TaktColors.chassisObsidian,
      body: AmbientLightingLayer(
        child: SafeArea(
          child: IsometricDeskLayout(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ChronoDialWidget(),
                    SizedBox(height: 24),
                    ReceiptRunnerWidget(),
                    SizedBox(height: 24),
                    VinylPlayerWidget(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
