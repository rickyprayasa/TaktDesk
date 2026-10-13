import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../app/theme/takt_colors.dart';
import '../../../app/theme/takt_typography.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_effect.dart';
import '../../../core/billing/pro_purchase_controller.dart';
import '../../../core/focus/focus_lock_controller.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/sensors/parallax_controller.dart';
import '../../../core/services/app_widget_service.dart';
import '../../../core/services/widget_theme_sync.dart';
import '../../analytics/presentation/widgets/focus_analytics_dialog.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../settings/presentation/widgets/studio_pro_dialog.dart';
import '../../tasks/presentation/receipt_runner_widget.dart';
import '../../timer/presentation/chrono_dial_controller.dart';
import '../../timer/presentation/chrono_dial_widget.dart';
import '../../timer/presentation/paused_timer_notification.dart';
import '../../vinyl/presentation/vinyl_player_widget.dart';
import 'ambient_lighting_layer.dart';
import 'isometric_desk_layout.dart';
import 'widgets/chassis_theme_switch.dart';
import 'widgets/desk_spec_plate_widget.dart';
import 'widgets/emergency_unlatch_widget.dart';
import 'widgets/master_console_landscape_layout.dart';
import 'widgets/settings_rivet_button.dart';
import 'widgets/timer_status_led.dart';

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
  double _lastSlideDirection = 1.0;
  double _dragDistance = 0.0;
  bool _sensorsPaused = false;
  bool _isLandscape = false;
  AppLifecycleListener? _lifecycleListener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncSensors();
  }

  /// Parallax tilt runs only if the user enabled it AND the system does not
  /// ask to remove animations (also saves the sensor battery cost).
  bool _reduceMotion = false;

  void _syncSensors() {
    final enabled = ref.read(deskPreferencesControllerProvider).parallaxEnabled;
    _setSensorsActive(enabled && !_reduceMotion);
  }

  @override
  void initState() {
    super.initState();
    _initSensors();
    _initWidgetActions();
    // Starts the Google Play ownership check (no-op in simulation builds).
    ref.read(proPurchaseProvider);
    ref.read(chronoDialProvider.notifier).importPendingNativeSessions();
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        final chrono = ref.read(chronoDialProvider.notifier);
        chrono.importPendingNativeSessions();
        chrono.resyncWithNative();
      },
      // No tilt while nobody can see the desk: the foreground timer service keeps the process alive, and
      // the gyro + accelerometer used to keep streaming ~30 events/s in the background.
      onHide: () {
        _setSensorsActive(false);
        ref.read(chronoDialProvider.notifier).setAppHidden(true);
      },
      onShow: () {
        ref.read(chronoDialProvider.notifier).setAppHidden(false);
        _syncSensors();
      },
    );
  }

  /// Real device sensors (no injected test streams).
  bool get _usesDeviceSensors => widget.gyroscopeStream == null && widget.accelerometerStream == null;

  void _setSensorsActive(bool active) {
    if (active) {
      if (_sensorsPaused) {
        if (_usesDeviceSensors) {
          _listenDeviceSensors();
        } else {
          _gyroscopeSubscription?.resume();
          _accelerometerSubscription?.resume();
        }
        _sensorsPaused = false;
      }
    } else {
      if (!_sensorsPaused) {
        if (_usesDeviceSensors) {
          // Cancel, don't pause: pausing a sensors_plus broadcast stream only drops events while the
          // Android sensor listener stays registered and keeps drawing power.
          _gyroscopeSubscription?.cancel();
          _accelerometerSubscription?.cancel();
          _gyroscopeSubscription = null;
          _accelerometerSubscription = null;
        } else {
          _gyroscopeSubscription?.pause();
          _accelerometerSubscription?.pause();
        }
        _sensorsPaused = true;
        // Deferred: may be called from didChangeDependencies (build phase),
        // where Riverpod forbids provider writes.
        Future.microtask(() {
          if (mounted) ref.read(parallaxProvider.notifier).reset();
        });
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

    if (_usesDeviceSensors) _listenDeviceSensors();

    _syncSensors();
  }

  void _listenDeviceSensors() {
    if (_gyroscopeSubscription == null) {
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
    }
    if (_accelerometerSubscription == null) {
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
  }

  void _initWidgetActions() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final widgetService = ref.read(appWidgetServiceProvider);
      final initialAction = await widgetService.getInitialAction();
      if (!mounted) return;
      if (initialAction == 'studio_pro') {
        showStudioProDialog(context, ref);
      } else if (initialAction == 'tasks') {
        _selectInstrument(1);
      } else if (initialAction == 'dial') {
        _selectInstrument(0);
      } else if (initialAction == 'analytics') {
        FocusAnalyticsDialog.show(context);
      } else if (initialAction == AppWidgetService.startFocusAction) {
        // Launcher shortcut "Start focus" on a cold start (a warm start arrives on the action stream).
        _selectInstrument(0);
        ref.read(chronoDialControllerProvider.notifier).startFocus();
      }
      _widgetActionSubscription = widgetService.onWidgetAction.listen((action) {
        if (!mounted) return;
        if (action == 'studio_pro') {
          showStudioProDialog(context, ref);
        } else if (action == 'tasks') {
          _selectInstrument(1);
        } else if (action == 'dial' || action == AppWidgetService.startFocusAction) {
          _selectInstrument(0);
        } else if (action == 'analytics') {
          FocusAnalyticsDialog.show(context);
        }
      });
    });
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    _widgetActionSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  void _selectInstrument(int index) {
    if (_selectedInstrumentIndex == index) return;
    ref.read(audioServiceProvider).play(SoundEffect.dialClick);
    HapticService.selectionClick();
    setState(() {
      _lastSlideDirection = (index > _selectedInstrumentIndex) ? 1.0 : -1.0;
      _selectedInstrumentIndex = index;
    });
  }

  Widget _buildActiveInstrument(int index) {
    switch (index) {
      case 0:
        return const Center(key: ValueKey('instrument_dial'), child: ChronoDialWidget());
      case 1:
        return const Center(key: ValueKey('instrument_tasks'), child: ReceiptRunnerWidget());
      case 2:
        return const Center(key: ValueKey('instrument_vinyl'), child: VinylPlayerWidget());
      default:
        return const Center(key: ValueKey('instrument_dial'), child: ChronoDialWidget());
    }
  }

  Widget _buildInstrumentSelector(ChassisThemeState theme) {
    const labels = ['DIAL', 'TASKS', 'VINYL'];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? TaktColors.basaltSlate : const Color(0xFFD8D5CC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.isDarkMode ? TaktColors.slateBorder : const Color(0xFFB5B0A4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (index) {
          final isSelected = _selectedInstrumentIndex == index;
          // Exposed as a selected tab to screen readers (the look alone said which one was active).
          return Semantics(
            selected: isSelected,
            button: true,
            child: InkWell(
            onTap: () => _selectInstrument(index),
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
                      : (theme.isDarkMode ? Colors.white54 : const Color(0xFF374151)),
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          );
        }),
      ),
    );
  }

  /// Wraps non-hardware empty areas (header & dock) with horizontal swipe gesture
  /// to switch between instruments without intercepting rotary dials or receipt gestures.
  Widget _buildSwipeZone({Key? key, required Widget child}) {
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) {
        _dragDistance = 0.0;
      },
      onHorizontalDragUpdate: (details) {
        _dragDistance += details.delta.dx;
      },
      onHorizontalDragEnd: (details) {
        final vx = details.primaryVelocity ?? 0.0;
        if (vx < -220 || _dragDistance < -45) {
          // Swipe Left -> Next Instrument
          if (_selectedInstrumentIndex < 2) {
            _selectInstrument(_selectedInstrumentIndex + 1);
          }
        } else if (vx > 220 || _dragDistance > 45) {
          // Swipe Right -> Previous Instrument
          if (_selectedInstrumentIndex > 0) {
            _selectInstrument(_selectedInstrumentIndex - 1);
          }
        }
        _dragDistance = 0.0;
      },
      onHorizontalDragCancel: () {
        _dragDistance = 0.0;
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(chassisThemeProvider);
    final focusState = ref.watch(focusLockProvider);
    ref.watch(appWidgetSyncProvider);
    ref.watch(pausedTimerNotificationSyncProvider);
    ref.watch(widgetThemeSyncProvider);

    ref.listen<bool>(
      deskPreferencesControllerProvider.select((p) => p.parallaxEnabled),
      (prev, enabled) {
        _setSensorsActive(enabled && !_reduceMotion);
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
            // Touch tilt follows the same opt-out as the sensors (parallax off, reduce motion, hidden).
            if (_sensorsPaused) return;
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
            if (_sensorsPaused) return;
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
                                      // Top Section: Header + Segmented Instrument Navigation (Swipe Enabled on Empty Header/Tabs)
                                      _buildSwipeZone(
                                        key: const ValueKey('desk_header_swipe_zone'),
                                        child: Column(
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
                                                      const TimerStatusLed(),
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
                                      ),
                                      // Middle Section: Active Instrument Console (Direct Hardware UI - NO Swipe Interception)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                                        child: AnimatedSwitcher(
                                          duration: _reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
                                          switchInCurve: Curves.easeOutCubic,
                                          switchOutCurve: Curves.easeInCubic,
                                          transitionBuilder: (child, animation) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: SlideTransition(
                                                position: Tween<Offset>(
                                                  begin: Offset(_lastSlideDirection * 0.08, 0.0),
                                                  end: Offset.zero,
                                                ).animate(animation),
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: _buildActiveInstrument(_selectedInstrumentIndex),
                                        ),
                                      ),
                                      // Bottom Dock: Emergency Unlatch (pinned at bottom when locked) + Desk Spec Plate (Swipe Enabled)
                                      _buildSwipeZone(
                                        key: const ValueKey('desk_dock_swipe_zone'),
                                        child: const Column(
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
