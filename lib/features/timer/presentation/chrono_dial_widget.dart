import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chrono_dial_controller.dart';
import 'chrono_dial_painter.dart';
import 'widgets/crown_push_button.dart';
import 'widgets/mechanical_flip_digit.dart';
import '../../../app/theme/takt_colors.dart';
import '../../../app/theme/takt_typography.dart';

class ChronoDialWidget extends ConsumerStatefulWidget {
  const ChronoDialWidget({super.key});

  @override
  ConsumerState<ChronoDialWidget> createState() => _ChronoDialWidgetState();
}

class _ChronoDialWidgetState extends ConsumerState<ChronoDialWidget>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);
  Duration? _lastElapsed;
  double _accumulatedDelta = 0.0;

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(chronoDialProvider);
    _progressNotifier.value = initialState.progressPercent;

    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      if (_lastElapsed != null) {
        final delta = (elapsed - _lastElapsed!).inMicroseconds / 1000000.0;
        final currentState = ref.read(chronoDialProvider);
        final totalSeconds = currentState.targetMinutes * 60.0;
        if (totalSeconds > 0) {
          _progressNotifier.value =
              (_progressNotifier.value + delta / totalSeconds).clamp(0.0, 1.0);
        }

        _accumulatedDelta += delta;
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
    _progressNotifier.dispose();
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

    // Only respond to drag along the outer rotary rim
    if (dist < 40 || dist > dialSize.width / 2 + 30) return;

    var angle = math.atan2(dy, dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;

    final fraction = angle / (2 * math.pi);
    final minutes = (fraction * 60).round().clamp(1, 90);
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
          _progressNotifier.value = ref.read(chronoDialProvider).progressPercent;
          if (!_ticker.isActive) {
            _ticker.start();
          }
        } else {
          if (_ticker.isActive) {
            _ticker.stop();
          }
          _lastElapsed = null;
          _accumulatedDelta = 0.0;
          _progressNotifier.value = ref.read(chronoDialProvider).progressPercent;
        }
      },
    );

    ref.listen<double>(
      chronoDialProvider.select((s) => s.remainingSeconds),
      (previous, nextRemaining) {
        if (!ref.read(chronoDialProvider).isRunning) {
          _progressNotifier.value = ref.read(chronoDialProvider).progressPercent;
        }
      },
    );

    final state = ref.watch(chronoDialProvider);
    final remainingMinutes = (state.remainingSeconds / 60).floor();
    final remainingSeconds = (state.remainingSeconds % 60).floor();
    const dialDimensions = Size(240, 240);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Top Crown Push-Button (Physical Stopwatch Crown)
        CrownPushButton(
          isPressed: state.isRunning,
          onTap: _handleToggle,
        ),
        // 2. Main Dial Canvas with 3D Depth & Odometer Sub-Window
        GestureDetector(
          onTap: _handleToggle,
          onPanUpdate: (details) => _handleRotaryPan(details.localPosition, dialDimensions),
          child: SizedBox(
            width: dialDimensions.width,
            height: dialDimensions.height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 60/120 FPS continuous sweep Canvas painter
                ValueListenableBuilder<double>(
                  valueListenable: _progressNotifier,
                  builder: (context, progress, _) {
                    return CustomPaint(
                      size: dialDimensions,
                      painter: ChronoDialPainter(
                        progressPercent: progress,
                        targetMinutes: state.targetMinutes,
                        isRunning: state.isRunning,
                      ),
                    );
                  },
                ),
                // Recessed Odometer Sub-Window at lower-center
                Positioned(
                  bottom: 42,
                  child: MechanicalCounterDisplay(
                    minutes: remainingMinutes,
                    seconds: remainingSeconds,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // 3. Tactile Duration Preset Selectors
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: TaktColors.basaltSlate,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: TaktColors.slateBorder, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: state.isRunning ? TaktColors.slateBorder : TaktColors.warmBone,
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
                    color: state.isRunning ? TaktColors.filamentAmber : TaktColors.warmBone,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.add_circle_outline,
                  color: state.isRunning ? TaktColors.slateBorder : TaktColors.warmBone,
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
      ],
    );
  }
}
