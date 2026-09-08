import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../app/theme/takt_colors.dart';
import '../../../app/theme/takt_typography.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/sensors/parallax_controller.dart';
import '../../tasks/presentation/receipt_runner_widget.dart';
import '../../timer/presentation/chrono_dial_widget.dart';
import '../../vinyl/presentation/vinyl_player_widget.dart';
import '../../vumeter/presentation/analog_vu_meter_widget.dart';
import 'ambient_lighting_layer.dart';
import 'isometric_desk_layout.dart';
import 'widgets/chassis_theme_switch.dart';
import 'widgets/modular_rack_bracket.dart';

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
    final theme = ref.watch(chassisThemeProvider);

    return Scaffold(
      backgroundColor: theme.canvasColor,
      body: MouseRegion(
        onHover: (event) {
          final size = MediaQuery.of(context).size;
          if (size.width > 0 && size.height > 0) {
            final normX = ((event.position.dx / size.width) - 0.5) * 2;
            final normY = ((event.position.dy / size.height) - 0.5) * 2;
            ref.read(parallaxProvider.notifier).updateSensorInput(
                  rawX: normX * 3.0,
                  rawY: -normY * 3.0,
                );
          }
        },
        child: AmbientLightingLayer(
          child: SafeArea(
            child: IsometricDeskLayout(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 640;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWide ? 620 : 320,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Desk Spatial Header Bar with Theme Switch
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isWide ? 'TAKT DESK // SPATIAL WORKBENCH' : 'TAKT DESK',
                                    style: TaktTypography.controlLabel.copyWith(
                                      color: theme.isDarkMode
                                          ? TaktColors.warmBone.withValues(alpha: 0.6)
                                          : const Color(0xFF2C3038),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const ChassisThemeSwitch(),
                                ],
                              ),
                            ),
                            // Instruments Layout: 2x2 on Desktop Wide, Column on Mobile
                            if (isWide) ...[
                              // Row 1: Chrono Dial (Timer) + Analog Dual VU Meter
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(child: Center(child: ChronoDialWidget())),
                                  ModularRackBracket(isVertical: false),
                                  Expanded(child: Center(child: AnalogVuMeterWidget())),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Center(child: ModularRackBracket(isVertical: true)),
                              const SizedBox(height: 8),
                              // Row 2: Thermal Task Runner + Analog Vinyl Deck
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: Center(child: ReceiptRunnerWidget())),
                                  ModularRackBracket(isVertical: false),
                                  Expanded(child: Center(child: VinylPlayerWidget())),
                                ],
                              ),
                            ] else ...[
                              // Single-Column Mobile Layout with Modular Brackets
                              const Center(child: ChronoDialWidget()),
                              const SizedBox(height: 4),
                              const Center(child: ModularRackBracket(isVertical: true)),
                              const SizedBox(height: 4),
                              const Center(child: AnalogVuMeterWidget()),
                              const SizedBox(height: 4),
                              const Center(child: ModularRackBracket(isVertical: true)),
                              const SizedBox(height: 4),
                              const Center(child: ReceiptRunnerWidget()),
                              const SizedBox(height: 4),
                              const Center(child: ModularRackBracket(isVertical: true)),
                              const SizedBox(height: 4),
                              const Center(child: VinylPlayerWidget()),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
