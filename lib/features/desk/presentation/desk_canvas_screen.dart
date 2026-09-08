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

  const DeskCanvasScreen({super.key, this.gyroscopeStream});

  @override
  ConsumerState<DeskCanvasScreen> createState() => _DeskCanvasScreenState();
}

class _DeskCanvasScreenState extends ConsumerState<DeskCanvasScreen> {
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  @override
  void initState() {
    super.initState();
    _initGyroscope();
  }

  void _initGyroscope() {
    try {
      final stream = widget.gyroscopeStream ?? gyroscopeEventStream();
      _gyroscopeSubscription = stream.listen(
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
    } catch (_) {
      // Platform does not support gyroscope or sensor initialization failed
    }
  }

  @override
  void dispose() {
    _gyroscopeSubscription?.cancel();
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
