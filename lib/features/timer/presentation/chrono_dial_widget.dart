import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chrono_dial_controller.dart';
import 'chrono_dial_painter.dart';
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
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
          },
          child: SizedBox(
            width: 220,
            height: 220,
            child: ValueListenableBuilder<double>(
              valueListenable: _progressNotifier,
              builder: (context, progress, child) {
                return CustomPaint(
                  painter: ChronoDialPainter(
                    progressPercent: progress,
                    targetMinutes: state.targetMinutes,
                    isRunning: state.isRunning,
                  ),
                  child: child,
                );
              },
              child: Center(
                child: Text(
                  '${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}',
                  style: TaktTypography.timerCounter,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline,
                color: state.isRunning ? TaktColors.slateBorder : TaktColors.warmBone,
              ),
              onPressed: state.isRunning
                  ? null
                  : () => ref
                      .read(chronoDialProvider.notifier)
                      .setTargetMinutes(state.targetMinutes - 5),
            ),
            Text('${state.targetMinutes} MIN', style: TaktTypography.controlLabel),
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: state.isRunning ? TaktColors.slateBorder : TaktColors.warmBone,
              ),
              onPressed: state.isRunning
                  ? null
                  : () => ref
                      .read(chronoDialProvider.notifier)
                      .setTargetMinutes(state.targetMinutes + 5),
            ),
          ],
        ),
      ],
    );
  }
}
