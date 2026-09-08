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
  late Ticker _ticker;
  Duration? _lastElapsed;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (_lastElapsed != null) {
        final delta = (elapsed - _lastElapsed!).inMicroseconds / 1000000.0;
        ref.read(chronoDialProvider.notifier).tick(delta);
      }
      _lastElapsed = elapsed;
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chronoDialProvider);
    final remainingMinutes = (state.remainingSeconds / 60).floor();
    final remainingSeconds = (state.remainingSeconds % 60).floor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (state.isRunning) {
              ref.read(chronoDialProvider.notifier).pause();
            } else {
              ref.read(chronoDialProvider.notifier).start();
            }
          },
          child: SizedBox(
            width: 220,
            height: 220,
            child: CustomPaint(
              painter: ChronoDialPainter(
                progressPercent: state.progressPercent,
                targetMinutes: state.targetMinutes,
                isRunning: state.isRunning,
              ),
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
              icon: const Icon(Icons.remove_circle_outline, color: TaktColors.warmBone),
              onPressed: () => ref
                  .read(chronoDialProvider.notifier)
                  .setTargetMinutes(state.targetMinutes - 5),
            ),
            Text('${state.targetMinutes} MIN', style: TaktTypography.controlLabel),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: TaktColors.warmBone),
              onPressed: () => ref
                  .read(chronoDialProvider.notifier)
                  .setTargetMinutes(state.targetMinutes + 5),
            ),
          ],
        ),
      ],
    );
  }
}
