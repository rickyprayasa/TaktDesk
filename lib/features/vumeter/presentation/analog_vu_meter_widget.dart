import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'vu_meter_controller.dart';
import 'vu_meter_painter.dart';
import '../../timer/presentation/chrono_dial_controller.dart';
import '../../vinyl/presentation/vinyl_controller.dart';
import '../../../app/theme/takt_colors.dart';
import '../../../app/theme/takt_typography.dart';

/// Standalone 4th modular instrument housing twin backlit galvanometer VU meters.
class AnalogVuMeterWidget extends ConsumerStatefulWidget {
  const AnalogVuMeterWidget({super.key});

  @override
  ConsumerState<AnalogVuMeterWidget> createState() => _AnalogVuMeterWidgetState();
}

class _AnalogVuMeterWidgetState extends ConsumerState<AnalogVuMeterWidget>
    with SingleTickerProviderStateMixin {
  late final Ticker _ballisticsTicker;
  Duration _lastElapsed = Duration.zero;
  double _waveformPhase = 0.0;

  @override
  void initState() {
    super.initState();
    _ballisticsTicker = createTicker((elapsed) {
      if (!mounted) return;
      if (_lastElapsed != Duration.zero) {
        final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
        final vinylState = ref.read(vinylProvider);
        final vuController = ref.read(analogVuMeterProvider.notifier);

        if (vinylState.needleOnRecord) {
          _waveformPhase += dt * 4.0;
          // Organic stereo audio waveform synthesis (L/R stereo divergence)
          final baseL = 0.38 + 0.28 * math.sin(_waveformPhase) + 0.12 * math.cos(_waveformPhase * 2.3);
          final baseR = 0.35 + 0.30 * math.sin(_waveformPhase * 1.15 + 0.4) + 0.10 * math.cos(_waveformPhase * 3.1);
          vuController.updateLevels(
            left: baseL.clamp(0.0, 0.96),
            right: baseR.clamp(0.0, 0.94),
          );
        } else {
          vuController.tickDecay(dt);
        }
      }
      _lastElapsed = elapsed;
    });

    _ballisticsTicker.start();
  }

  @override
  void dispose() {
    _ballisticsTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to timer ticks to pulse galvanometer needles
    ref.listen<double>(
      chronoDialProvider.select((s) => s.remainingSeconds),
      (prev, next) {
        if (prev != null && prev != next) {
          ref.read(analogVuMeterProvider.notifier).pulseTick(0.28);
        }
      },
    );

    final state = ref.watch(analogVuMeterProvider);
    final controller = ref.read(analogVuMeterProvider.notifier);

    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TaktColors.basaltSlate,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TaktColors.slateBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Bar: Model & Mode Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'STEREO VU METER',
                  style: TaktTypography.controlLabel,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'ZYKL VU-01',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: TaktColors.warmBone.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 2. Twin Backlit Galvanometer Meters
          Center(
            child: SizedBox(
              width: 252,
              height: 76,
              child: CustomPaint(
                painter: VuMeterPainter(
                  leftLevel: state.leftLevel,
                  rightLevel: state.rightLevel,
                  peakLeft: state.peakLeft,
                  peakRight: state.peakRight,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 3. Tactile Ballistics Rocker Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => controller.toggleBallistics(),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1D21),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF2E323A), width: 1.0),
                  ),
                  child: Text(
                    'BALLISTICS: ${state.isFastBallistics ? "FAST" : "SLOW"}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8.0,
                      fontWeight: FontWeight.w700,
                      color: state.isFastBallistics ? TaktColors.filamentAmber : TaktColors.warmBone,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (state.peakLeft || state.peakRight)
                          ? TaktColors.mutedOchre
                          : const Color(0xFF2C3036),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LIMITER',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8.0,
                      fontWeight: FontWeight.w600,
                      color: (state.peakLeft || state.peakRight)
                          ? TaktColors.mutedOchre
                          : TaktColors.warmBone.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
