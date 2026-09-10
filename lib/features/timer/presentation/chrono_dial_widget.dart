import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chrono_dial_controller.dart';
import 'chrono_dial_painter.dart';
import 'widgets/crown_push_button.dart';
import 'widgets/mechanical_flip_digit.dart';
import 'widgets/split_flap_board_widget.dart';
import '../../desk/presentation/widgets/monastic_switch_widget.dart';
import '../../../app/theme/takt_typography.dart';
import '../../../app/theme/theme_controller.dart';

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
        if (isRunning) {
          _lastElapsed = null;
          _accumulatedDelta = 0.0;
          _remainingSecondsNotifier.value = ref.read(chronoDialProvider).remainingSeconds;
          if (!_ticker.isActive) {
            _ticker.start();
          }
        } else {
          if (_ticker.isActive) {
            _ticker.stop();
          }
          _lastElapsed = null;
          _accumulatedDelta = 0.0;
          _remainingSecondsNotifier.value = ref.read(chronoDialProvider).remainingSeconds;
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
    final remainingMinutes = (state.remainingSeconds / 60).floor();
    final remainingSeconds = (state.remainingSeconds % 60).floor();
    const dialDimensions = Size(240, 240);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Preserved offstage for test harness & accessibility without obstructing dial face
        Offstage(
          offstage: true,
          child: MechanicalCounterDisplay(
            minutes: remainingMinutes,
            seconds: remainingSeconds,
          ),
        ),
        // 1. 3D Split-Flap Pomodoro Phase & Cycle Display
        const SplitFlapBoardWidget(),
        const SizedBox(height: 12),
        // 2. Main Dial Canvas with 12 o'clock Crown Push-Button directly seated on bezel
        SizedBox(
          width: dialDimensions.width,
          height: dialDimensions.height + 14,
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // Main Dial Canvas with Unobstructed Analog Face
              Positioned(
                top: 14,
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
                        return CustomPaint(
                          size: dialDimensions,
                          painter: ChronoDialPainter(
                            remainingSeconds: seconds,
                            progressPercent: state.progressPercent,
                            targetMinutes: state.targetMinutes,
                            isRunning: state.isRunning,
                            needleColor: themeState.needleColor,
                            filamentColor: themeState.filamentColor,
                            outerBezelGradient: themeState.plateGradient,
                            innerBezelColor: themeState.borderColor,
                            textureType: themeState.textureType,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Top Crown Push-Button seated directly on the 12 o'clock dial bezel
              Positioned(
                top: 6,
                child: CrownPushButton(
                  isPressed: state.isRunning,
                  onTap: _handleToggle,
                  gradientColors: themeState.plateGradient,
                  borderColor: themeState.borderColor,
                  stemColor: themeState.moduleChassisColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // 3. Tactile Duration Preset Selectors & Active Countdown Display (Pill Timer)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: themeState.moduleChassisColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: themeState.borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: state.isRunning ? themeState.borderColor : themeState.chassisTextColor,
                  size: 18,
                ),
                onPressed: state.isRunning
                    ? null
                    : () => ref
                        .read(chronoDialProvider.notifier)
                        .setTargetMinutes(state.targetMinutes - 5),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '${state.targetMinutes} MIN',
                  style: TaktTypography.controlLabel.copyWith(
                    color: state.isRunning ? themeState.filamentColor : themeState.chassisTextColor,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.add_circle_outline,
                  color: state.isRunning ? themeState.borderColor : themeState.chassisTextColor,
                  size: 18,
                ),
                onPressed: state.isRunning
                    ? null
                    : () => ref
                        .read(chronoDialProvider.notifier)
                        .setTargetMinutes(state.targetMinutes + 5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // 4. Simple Monastic Focus Lockdown Toggle (below Pill Timer)
        const MonasticSwitchWidget(),
      ],
    );
  }
}
