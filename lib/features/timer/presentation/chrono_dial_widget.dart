import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chrono_dial_controller.dart';
import 'chrono_dial_painter.dart';
import '../domain/pomodoro_phase.dart';
import '../domain/timer_state.dart';
import 'widgets/crown_push_button.dart';
import 'widgets/chrono_profile_selector_widget.dart';
import 'widgets/mechanical_flip_digit.dart';
import '../../desk/presentation/widgets/monastic_switch_widget.dart';
import '../../../app/theme/hardware_edition.dart';
import '../../../app/theme/takt_colors.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/sensors/parallax_controller.dart';

class ChronoDialWidget extends ConsumerStatefulWidget {
  const ChronoDialWidget({super.key});

  @override
  ConsumerState<ChronoDialWidget> createState() => _ChronoDialWidgetState();
}

class _ChronoDialWidgetState extends ConsumerState<ChronoDialWidget>
    with SingleTickerProviderStateMixin {
  // Visual only: the controller owns the countdown (1 update/s). This ticker
  // just glides the needle between those updates; each update re-syncs it.
  late final Ticker _ticker;
  final ValueNotifier<double> _remainingSecondsNotifier = ValueNotifier<double>(0.0);
  // Whole seconds shown on the counter; only changes once per second
  final ValueNotifier<int> _displaySecondNotifier = ValueNotifier<int>(0);
  Duration? _lastElapsed;

  void _syncDisplaySecond() =>
      _displaySecondNotifier.value = _remainingSecondsNotifier.value.floor();

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(chronoDialProvider);
    _remainingSecondsNotifier.value = initialState.remainingSeconds;
    _syncDisplaySecond();
    _remainingSecondsNotifier.addListener(_syncDisplaySecond);

    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      if (_lastElapsed != null) {
        final delta = (elapsed - _lastElapsed!).inMicroseconds / 1000000.0;
        // Never run more than a second ahead of the controller's value
        final floor = (ref.read(chronoDialProvider).remainingSeconds - 1.0).clamp(0.0, 90 * 60.0);
        _remainingSecondsNotifier.value =
            (_remainingSecondsNotifier.value - delta).clamp(floor, 90 * 60.0);
      }
      _lastElapsed = elapsed;
    });

    if (initialState.isRunning) {
      _lastElapsed = null;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _remainingSecondsNotifier.removeListener(_syncDisplaySecond);
    _remainingSecondsNotifier.dispose();
    _displaySecondNotifier.dispose();
    super.dispose();
  }

  String _semanticDialLabel(TimerState state) {
    final total = state.remainingSeconds.ceil();
    final m = total ~/ 60;
    final sec = total % 60;
    final phase = switch (state.phase) {
      PomodoroPhase.focus => 'Focus',
      PomodoroPhase.shortBreak => 'Short break',
      PomodoroPhase.longBreak => 'Long break',
    };
    final status = state.isRunning ? 'running' : 'paused';
    return '$phase timer, $m minutes $sec seconds remaining, $status';
  }

  void _handleToggle() {
    final state = ref.read(chronoDialProvider);
    if (state.setupStage.isActive) {
      ref.read(chronoDialProvider.notifier).advanceCalibrationStage();
      return;
    }
    if (state.isRunning) {
      ref.read(chronoDialProvider.notifier).pause();
    } else {
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
    // Start/stop of the countdown and the background service live in the
    // controller; here we only drive the needle animation.
    ref.listen<bool>(
      chronoDialProvider.select((s) => s.isRunning),
      (previous, isRunning) {
        _lastElapsed = null;
        _remainingSecondsNotifier.value = ref.read(chronoDialProvider).remainingSeconds;
        if (isRunning && !_ticker.isActive) {
          _ticker.start();
        } else if (!isRunning && _ticker.isActive) {
          _ticker.stop();
        }
      },
    );

    ref.listen<double>(
      chronoDialProvider.select((s) => s.remainingSeconds),
      (previous, nextRemaining) {
        _remainingSecondsNotifier.value = nextRemaining;
        // The update already includes the time up to now; don't subtract it again next frame
        _lastElapsed = null;
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
      case HardwareEditionType.braunAtelierCream:
        lightDialColor = const Color(0xFFDDD9CE);
        break;
      case HardwareEditionType.bauhausHeritage:
        lightDialColor = const Color(0xFFF0EDE4);
        break;
      case HardwareEditionType.industrialMonoSteel:
        lightDialColor = const Color(0xFFD4D7DB);
        break;
      case HardwareEditionType.titaniumStealth:
        lightDialColor = const Color(0xFFD3D8E0);
        break;
      case HardwareEditionType.rawBrassPatina:
        lightDialColor = const Color(0xFFE2DCB8);
        break;
      case HardwareEditionType.midCenturyWalnut:
        lightDialColor = const Color(0xFFEFEBE2);
        break;
      case HardwareEditionType.forgedCarbon:
        lightDialColor = const Color(0xFFE5E8EC);
        break;
      case HardwareEditionType.obsidianCeramic:
        lightDialColor = const Color(0xFFE4E5E8);
        break;
      case HardwareEditionType.copperHearthAsh:
        lightDialColor = const Color(0xFFE8E0D7);
        break;
      case HardwareEditionType.britishRacingGreen:
        lightDialColor = const Color(0xFFDBE5DF);
        break;
      case HardwareEditionType.indigoAstronomical:
        lightDialColor = const Color(0xFFD4DCEB);
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
                              ? Colors.black.withValues(alpha: 0.16)
                              : const Color(0x0D000000),
                          blurRadius: 5.0,
                          offset: Offset(
                            (-parallax.tiltX * 30.0).clamp(-3.0, 3.0),
                            2.0 + (-parallax.tiltY * 30.0).clamp(-3.0, 3.0),
                          ),
                        ),
                      ],
                    ),
                    child: Semantics(
                      container: true,
                      button: true,
                      label: _semanticDialLabel(state),
                      hint: state.isRunning ? 'Double tap to pause' : 'Double tap to start',
                      onTap: _handleToggle,
                      excludeSemantics: true,
                      child: GestureDetector(
                      onTap: _handleToggle,
                      onPanStart: (details) => _handleRotaryPan(details.localPosition, dialDimensions),
                      onPanUpdate: (details) => _handleRotaryPan(details.localPosition, dialDimensions),
                      child: SizedBox(
                        width: dialDimensions.width,
                        height: dialDimensions.height,
                        // Three layers so a running countdown only redraws the needle:
                        // static face (own raster layer) -> counter (rebuilds once a
                        // second) -> hand (repaints straight from the notifier).
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            RepaintBoundary(
                              child: CustomPaint(
                                size: dialDimensions,
                                isComplex: true,
                                painter: ChronoDialPainter(
                                  remainingSeconds: state.remainingSeconds,
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
                                  darkDialFaceColor: themeState.edition.darkDialFace,
                                  drawHand: false,
                                ),
                              ),
                            ),
                            Center(
                              child: Transform.translate(
                                offset: const Offset(0, 40.0),
                                child: IgnorePointer(
                                  child: ValueListenableBuilder<int>(
                                    valueListenable: _displaySecondNotifier,
                                    builder: (context, total, _) => MechanicalCounterDisplay(
                                      minutes: total ~/ 60,
                                      seconds: total % 60,
                                      isDialInset: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            RepaintBoundary(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  size: dialDimensions,
                                  painter: ChronoDialHandPainter(
                                    remaining: _remainingSecondsNotifier,
                                    needleColor: effectiveNeedleColor,
                                    hubCapColor: themeState.isDarkMode
                                        ? const Color(0xFF22252A)
                                        : const Color(0xFF2B2E34),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                  ),
                ),
                // Top Crown Push-Button seated directly into the 12 o'clock dial bezel socket
                // top: 6 seats the collar 2 px into the bezel (bezel edge is at
                // y = 24 + 8); at top: 0 it hovered 4 px above the dial.
                Positioned(
                  top: 6,
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
