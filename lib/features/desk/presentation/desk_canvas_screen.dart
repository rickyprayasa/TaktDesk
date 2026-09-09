import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../app/theme/takt_colors.dart';
import '../../../app/theme/takt_typography.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/focus/focus_lock_controller.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/sensors/parallax_controller.dart';
import '../../tasks/presentation/receipt_runner_widget.dart';
import '../../timer/presentation/chrono_dial_widget.dart';
import '../../vinyl/presentation/vinyl_player_widget.dart';
import 'ambient_lighting_layer.dart';
import 'isometric_desk_layout.dart';
import 'widgets/chassis_theme_switch.dart';
import 'widgets/desk_spec_plate_widget.dart';
import 'widgets/emergency_unlatch_widget.dart';
import 'widgets/settings_rivet_button.dart';

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
  int _selectedInstrumentIndex = 0; // 0: Dial, 1: Tasks, 2: Vinyl

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
          onError: (Object error) {},
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
          onError: (Object error) {},
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
          onError: (Object error) {},
          cancelOnError: false,
        );
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  Widget _buildInstrumentSelector(ChassisThemeState theme) {
    const labels = ['DIAL', 'TASKS', 'VINYL'];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? TaktColors.basaltSlate : const Color(0xFFD2D6DC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.isDarkMode ? TaktColors.slateBorder : const Color(0xFFB0B5BC),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (index) {
          final isSelected = _selectedInstrumentIndex == index;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedInstrumentIndex = index;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? (theme.isDarkMode ? TaktColors.chassisObsidian : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color(0x33000000),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                labels[index],
                style: TaktTypography.controlLabel.copyWith(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? (theme.isDarkMode ? TaktColors.filamentAmber : const Color(0xFF141517))
                      : (theme.isDarkMode ? Colors.white54 : Colors.black45),
                  letterSpacing: 1.0,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(chassisThemeProvider);
    final focusState = ref.watch(focusLockProvider);

    return PopScope(
      canPop: !focusState.isLocked,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          HapticService.lightClick();
        }
      },
      child: Scaffold(
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
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Row 1: Header - Branding and Chassis Hardware Controls (Monastic + Theme Switch)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: focusState.isLocked
                                            ? TaktColors.filamentAmber
                                            : TaktColors.patinaOlive,
                                        boxShadow: [
                                          BoxShadow(
                                            color: (focusState.isLocked
                                                    ? TaktColors.filamentAmber
                                                    : TaktColors.patinaOlive)
                                                .withValues(alpha: 0.6),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'TAKT DESK',
                                      style: TaktTypography.controlLabel.copyWith(
                                        color: theme.isDarkMode
                                            ? TaktColors.warmBone.withValues(alpha: 0.75)
                                            : const Color(0xFF2C3038),
                                        letterSpacing: 1.5,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SettingsRivetButton(),
                                    SizedBox(width: 8),
                                    ChassisThemeSwitch(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Row 2: Dedicated Segmented Instrument Navigation
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Center(
                              child: _buildInstrumentSelector(theme),
                            ),
                          ),
                          // Row 3: Active Instrument Console
                          if (_selectedInstrumentIndex == 0)
                            const Center(child: ChronoDialWidget())
                          else if (_selectedInstrumentIndex == 1)
                            const Center(child: ReceiptRunnerWidget())
                          else
                            const Center(child: VinylPlayerWidget()),
                          const SizedBox(height: 12),
                          // Emergency Unlatch Latch (renders when focus lock engaged)
                          const EmergencyUnlatchWidget(),
                          const SizedBox(height: 16),
                          const DeskSpecPlateWidget(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
