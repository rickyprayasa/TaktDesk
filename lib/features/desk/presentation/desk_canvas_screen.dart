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
import '../../../core/services/app_widget_service.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../settings/presentation/widgets/studio_pro_dialog.dart';
import '../../tasks/presentation/receipt_runner_widget.dart';
import '../../timer/presentation/chrono_dial_widget.dart';
import '../../vinyl/presentation/vinyl_player_widget.dart';
import 'ambient_lighting_layer.dart';
import 'isometric_desk_layout.dart';
import 'widgets/chassis_theme_switch.dart';
import 'widgets/desk_spec_plate_widget.dart';
import 'widgets/emergency_unlatch_widget.dart';
import 'widgets/master_console_landscape_layout.dart';
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
  StreamSubscription<String>? _widgetActionSubscription;
  int _selectedInstrumentIndex = 0; // 0: Dial, 1: Tasks, 2: Vinyl
  bool _sensorsPaused = false;
  bool _isLandscape = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
  }

  @override
  void initState() {
    super.initState();
    _initSensors();
    _initWidgetActions();
  }

  void _setSensorsActive(bool active) {
    if (active) {
      if (_sensorsPaused) {
        _gyroscopeSubscription?.resume();
        _accelerometerSubscription?.resume();
        _sensorsPaused = false;
      }
    } else {
      if (!_sensorsPaused) {
        _gyroscopeSubscription?.pause();
        _accelerometerSubscription?.pause();
        _sensorsPaused = true;
        ref.read(parallaxProvider.notifier).reset();
      }
    }
  }

  void _initSensors() {
    if (widget.gyroscopeStream != null) {
      try {
        _gyroscopeSubscription = widget.gyroscopeStream!.listen(
          (event) {
            if (!mounted || _sensorsPaused) return;
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
            if (!mounted || _sensorsPaused) return;
            ref.read(parallaxProvider.notifier).updateTiltFromAccelerometer(
                  x: event.x,
                  y: event.y,
                  z: event.z,
                  isLandscape: _isLandscape,
                );
          },
          onError: (Object error) {},
          cancelOnError: false,
        );
      } catch (_) {}
    }

    if (widget.gyroscopeStream == null && widget.accelerometerStream == null) {
      try {
        _gyroscopeSubscription = gyroscopeEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
          (event) {
            if (!mounted || _sensorsPaused) return;
            ref.read(parallaxProvider.notifier).updateFromGyroscope(
                  x: event.x,
                  y: event.y,
                );
          },
          onError: (Object error) {},
          cancelOnError: false,
        );
      } catch (_) {}

      try {
        _accelerometerSubscription = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
          (event) {
            if (!mounted || _sensorsPaused) return;
            ref.read(parallaxProvider.notifier).updateTiltFromAccelerometer(
                  x: event.x,
                  y: event.y,
                  z: event.z,
                  isLandscape: _isLandscape,
                );
          },
          onError: (Object error) {},
          cancelOnError: false,
        );
      } catch (_) {}
    }

    final initialEnabled = ref.read(deskPreferencesControllerProvider).parallaxEnabled;
    if (!initialEnabled) {
      _setSensorsActive(false);
    }
  }

  void _initWidgetActions() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final widgetService = ref.read(appWidgetServiceProvider);
      final initialAction = await widgetService.getInitialAction();
      if (!mounted) return;
      if (initialAction == 'studio_pro') {
        showStudioProDialog(context, ref);
      }
      _widgetActionSubscription = widgetService.onWidgetAction.listen((action) {
        if (!mounted) return;
        if (action == 'studio_pro') {
          showStudioProDialog(context, ref);
        }
      });
    });
  }

  @override
  void dispose() {
    _widgetActionSubscription?.cancel();
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
    ref.watch(appWidgetSyncProvider);

    ref.listen<bool>(
      deskPreferencesControllerProvider.select((p) => p.parallaxEnabled),
      (prev, enabled) {
        _setSensorsActive(enabled);
      },
    );

    return PopScope(
      canPop: !focusState.isLocked,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          HapticService.lightClick();
        }
      },
      child: Scaffold(
        backgroundColor: theme.canvasColor,
        body: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerMove: (event) {
            final size = MediaQuery.of(context).size;
            if (size.width > 0 && size.height > 0) {
              final normX = ((event.position.dx / size.width) - 0.5) * 2;
              final normY = ((event.position.dy / size.height) - 0.5) * 2;
              ref.read(parallaxProvider.notifier).updateSensorInput(
                    rawX: normX * 8.0,
                    rawY: -normY * 8.0,
                  );
            }
          },
          onPointerHover: (event) {
            final size = MediaQuery.of(context).size;
            if (size.width > 0 && size.height > 0) {
              final normX = ((event.position.dx / size.width) - 0.5) * 2;
              final normY = ((event.position.dy / size.height) - 0.5) * 2;
              ref.read(parallaxProvider.notifier).updateSensorInput(
                    rawX: normX * 8.0,
                    rawY: -normY * 8.0,
                  );
            }
          },
          child: AmbientLightingLayer(
            child: SafeArea(
              child: IsometricDeskLayout(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape ||
                        constraints.maxWidth >= 720;
                    if (isLandscape) {
                      return const MasterConsoleLandscapeLayout();
                    }
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: LayoutBuilder(
                          builder: (context, viewportConstraints) {
                            return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: viewportConstraints.maxHeight,
                              minWidth: viewportConstraints.maxWidth,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Top Section: Header + Segmented Instrument Navigation
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Row 1: Header - Branding and Chassis Hardware Controls (Monastic + Theme Switch)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 14.0),
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
                                                  'ZYKL',
                                                  style: TaktTypography.controlLabel.copyWith(
                                                    color: theme.hasDarkChassis
                                                        ? TaktColors.warmBone.withValues(alpha: 0.85)
                                                        : const Color(0xFF2C3038),
                                                    letterSpacing: 2.0,
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w800,
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
                                      Center(
                                        child: _buildInstrumentSelector(theme),
                                      ),
                                    ],
                                  ),
                                  // Middle Section: Active Instrument Console (Vertically Centered in viewport)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                                    child: _selectedInstrumentIndex == 0
                                        ? const Center(child: ChronoDialWidget())
                                        : _selectedInstrumentIndex == 1
                                            ? const Center(child: ReceiptRunnerWidget())
                                            : const Center(child: VinylPlayerWidget()),
                                  ),
                                  // Bottom Dock: Emergency Unlatch (pinned at bottom when locked) + Desk Spec Plate
                                  const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      EmergencyUnlatchWidget(),
                                      Padding(
                                        padding: EdgeInsets.only(top: 8.0),
                                        child: DeskSpecPlateWidget(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  ),
);
  }
}
