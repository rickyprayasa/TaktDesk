import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chrono_dial_controller.dart';
import 'chrono_dial_painter.dart';
import '../domain/timer_state.dart';
import 'widgets/crown_push_button.dart';
import 'widgets/chrono_profile_selector_widget.dart';
import 'widgets/mechanical_flip_digit.dart';
import '../../desk/presentation/widgets/monastic_switch_widget.dart';
import '../../../app/theme/hardware_edition.dart';
import '../../../app/theme/takt_colors.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/sensors/parallax_controller.dart';
import '../../../core/services/timer_background_service.dart';
import '../../settings/presentation/settings_controller.dart';

class ChronoDialWidget extends ConsumerStatefulWidget {
  const ChronoDialWidget({super.key});

  @override
  ConsumerState<ChronoDialWidget> createState() => _ChronoDialWidgetState();
}

class _ChronoDialWidgetState extends ConsumerState<ChronoDialWidget>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _remainingSecondsNotifier = ValueNotifier<double>(0.0);
  Duration? _lastElapsed;
  double _accumulatedDelta = 0.0;

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(chronoDialProvider);
    _remainingSecondsNotifier.value = initialState.remainingSeconds;

    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      if (_lastElapsed != null) {
        final delta = (elapsed - _lastElapsed!).inMicroseconds / 1000000.0;
        _remainingSecondsNotifier.value =
            (_remainingSecondsNotifier.value - delta).clamp(0.0, 90 * 60.0);

        _accumulatedDelta += delta;
        final currentState = ref.read(chronoDialProvider);
        final remaining = currentState.remainingSeconds - _accumulatedDelta;
        if (_accumulatedDelta >= 1.0 || remaining <= 0) {
          final toTick = _accumulatedDelta;
          _accumulatedDelta = 0.0;
          ref.read(chronoDialProvider.notifier).tick(toTick);
        }
      }
      _lastElapsed = elapsed;
    });

    if (initialState.isRunning) {
      _lastElapsed = null;
      _accumulatedDelta = 0.0;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _remainingSecondsNotifier.dispose();
    super.dispose();
  }

  void _handleToggle() {
    final state = ref.read(chronoDialProvider);
    if (state.setupStage.isActive) {
      ref.read(chronoDialProvider.notifier).advanceCalibrationStage();
      return;
    }
    if (state.isRunning) {
      if (_accumulatedDelta > 0) {
        ref.read(chronoDialProvider.notifier).tick(_accumulatedDelta);
        _accumulatedDelta = 0.0;
      }
      ref.read(chronoDialProvider.notifier).pause();
    } else {
      _accumulatedDelta = 0.0;
      ref.read(chronoDialProvider.notifier).start();
    }
  }

  void _handleRotaryPan(Offset localPos, Size dialSize) {
    final state = ref.read(chronoDialProvider);
    if (state.isRunning) return;

    final center = Offset(dialSize.width / 2, dialSize.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);

    // Allow rotary interaction across the dial face
    if (dist < 15 || dist > dialSize.width / 2 + 25) return;

    var angle = math.atan2(dy, dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;

    final fraction = angle / (2 * math.pi);

    if (state.setupStage.isActive) {
      var rawValue = (fraction * 60.0).round();
      if (rawValue == 0) rawValue = 60;

      final maxMins = state.setupStage == ChronoSetupStage.focus
          ? 90
          : (state.setupStage == ChronoSetupStage.shortBreak ? 30 : 45);
      final rawMinutes = rawValue.clamp(1, maxMins);
      _remainingSecondsNotifier.value = rawMinutes * 60.0;
      ref.read(chronoDialProvider.notifier).setTargetMinutes(rawMinutes);
      return;
    }

    var minutes = (fraction * 60).round();
    if (minutes == 0) minutes = 60;
    minutes = minutes.clamp(1, 90);

    _remainingSecondsNotifier.value = minutes * 60.0;
    if (minutes != state.targetMinutes) {
      ref.read(chronoDialProvider.notifier).setTargetMinutes(minutes);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(
      chronoDialProvider.select((s) => s.isRunning),
      (previous, isRunning) {
        final currentTimerState = ref.read(chronoDialProvider);
        final bgService = ref.read(timerBackgroundServiceProvider);

        if (isRunning) {
          _lastElapsed = null;
          _accumulatedDelta = 0.0;
          _remainingSecondsNotifier.value = currentTimerState.remainingSeconds;
          if (!_ticker.isActive) {
            _ticker.start();
          }
          final alarmChimeId = ref.read(deskPreferencesControllerProvider).alarmChimeId;
          bgService.start(
            remainingSeconds: currentTimerState.remainingSeconds,
            targetMinutes: currentTimerState.targetMinutes,
            phase: currentTimerState.phase,
            cycleCount: currentTimerState.cycleCount,
            profileName: currentTimerState.profile.label,
            alarmChimeId: alarmChimeId,
          );
        } else {
          if (_ticker.isActive) {
            _ticker.stop();
          }
          _lastElapsed = null;
          _accumulatedDelta = 0.0;
          _remainingSecondsNotifier.value = currentTimerState.remainingSeconds;
          bgService.stop();
        }
      },
    );

    ref.listen<double>(
      chronoDialProvider.select((s) => s.remainingSeconds),
      (previous, nextRemaining) {
        if (!ref.read(chronoDialProvider).isRunning) {
          _remainingSecondsNotifier.value = nextRemaining;
        }
      },
    );

    final state = ref.watch(chronoDialProvider);
    final themeState = ref.watch(chassisThemeProvider);
    final parallax = ref.watch(parallaxProvider);
    final remainingMinutes = (state.remainingSeconds / 60).floor();
    final remainingSeconds = (state.remainingSeconds % 60).floor();
    const dialDimensions = Size(264, 264);

    final Color lightDialColor;
    switch (themeState.edition.type) {
      case HardwareEditionType.braunClassic:
        lightDialColor = const Color(0xFFEAE6DC);
        break;
      case HardwareEditionType.titaniumStealth:
        lightDialColor = const Color(0xFFD3D8E0);
        break;
      case HardwareEditionType.bauhausHeritage:
        lightDialColor = const Color(0xFFF0EDE4);
        break;
      case HardwareEditionType.rawBrassPatina:
        lightDialColor = const Color(0xFFE2DCB8);
        break;
      case HardwareEditionType.braunAtelierCream:
        lightDialColor = const Color(0xFFDDD9CE);
        break;
      case HardwareEditionType.midCenturyWalnut:
        lightDialColor = const Color(0xFFEFEBE2);
        break;
      case HardwareEditionType.forgedCarbon:
        lightDialColor = const Color(0xFFE5E8EC);
        break;
    }

    final effectiveNeedleColor =
        state.isBreak ? TaktColors.patinaOlive : themeState.needleColor;
    final effectiveFilamentColor =
        state.isBreak ? TaktColors.patinaOlive : themeState.filamentColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Main Dial Canvas with 12 o'clock Crown Push-Button directly seated on bezel
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(-parallax.tiltY)
            ..rotateY(parallax.tiltX),
          child: SizedBox(
            width: dialDimensions.width,
            height: dialDimensions.height + 24,
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                // Main Dial Canvas with Unobstructed Analog Face
                Positioned(
                  top: 24,
                  child: Container(
                    width: dialDimensions.width,
                    height: dialDimensions.height,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: themeState.isDarkMode
                              ? Colors.black.withValues(alpha: 0.50)
                              : const Color(0x22000000),
                          blurRadius: 18,
                          offset: Offset(
                            (-parallax.tiltX * 160.0).clamp(-14.0, 14.0),
                            8.0 + (-parallax.tiltY * 160.0).clamp(-14.0, 14.0),
                          ),
                        ),
                        BoxShadow(
                          color: themeState.isDarkMode
                              ? Colors.black.withValues(alpha: 0.25)
                              : const Color(0x10000000),
                          blurRadius: 6,
                          offset: Offset(
                            (-parallax.tiltX * 50.0).clamp(-5.0, 5.0),
                            2.0 + (-parallax.tiltY * 50.0).clamp(-5.0, 5.0),
                          ),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: _handleToggle,
                      onPanStart: (details) => _handleRotaryPan(details.localPosition, dialDimensions),
                      onPanUpdate: (details) => _handleRotaryPan(details.localPosition, dialDimensions),
                      child: SizedBox(
                        width: dialDimensions.width,
                        height: dialDimensions.height,
                        child: ValueListenableBuilder<double>(
                          valueListenable: _remainingSecondsNotifier,
                          builder: (context, seconds, _) {
                            final m = (seconds / 60).floor();
                            final s = (seconds % 60).floor();
                            return CustomPaint(
                              size: dialDimensions,
                              painter: ChronoDialPainter(
                                remainingSeconds: seconds,
                                progressPercent: state.progressPercent,
                                targetMinutes: state.targetMinutes,
                                isRunning: state.isRunning,
                                needleColor: effectiveNeedleColor,
                                filamentColor: effectiveFilamentColor,
                                outerBezelGradient: themeState.plateGradient,
                                innerBezelColor: themeState.borderColor,
                                textureType: themeState.textureType,
                                isDark: themeState.isDarkMode,
                                dialFaceColor: lightDialColor,
                                drawHand: false,
                              ),
                              foregroundPainter: ChronoDialHandPainter(
                                remainingSeconds: seconds,
                                needleColor: effectiveNeedleColor,
                                hubCapColor: themeState.isDarkMode
                                    ? const Color(0xFF22252A)
                                    : const Color(0xFF2B2E34),
                              ),
                              child: Center(
                                child: Transform.translate(
                                  offset: const Offset(0, 40.0),
                                  child: IgnorePointer(
                                    child: MechanicalCounterDisplay(
                                      minutes: m,
                                      seconds: s,
                                      isDialInset: true,
                                    ),
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
                // Top Crown Push-Button seated directly into the 12 o'clock dial bezel socket
                Positioned(
                  top: 0,
                  child: CrownPushButton(
                    isPressed: state.isRunning,
                    isPulledOut: state.setupStage.isActive,
                    onTap: _handleToggle,
                    onPullOut: () {
                      if (state.isRunning || state.setupStage.isActive) return;
                      ref.read(chronoDialProvider.notifier).enterCustomCalibration();
                    },
                    onPushIn: () {
                      if (state.setupStage.isActive) {
                        ref.read(chronoDialProvider.notifier).cancelCalibration();
                      }
                    },
                    gradientColors: themeState.plateGradient,
                    borderColor: themeState.borderColor,
                    stemColor: themeState.moduleChassisColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        // 2. Consolidated Industrial Console (Telemetry + Timer MM:SS + Cassette Preset Selector)
        ChronoProfileSelectorWidget(

          remainingMinutes: remainingMinutes,
          seconds: remainingSeconds,
        ),
        const SizedBox(height: 16),
        // 3. Simple Monastic Focus Lockdown Toggle (below Preset Selector)
        const MonasticSwitchWidget(),
      ],
    );
  }
}
