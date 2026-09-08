import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'vinyl_controller.dart';
import 'vinyl_deck_painter.dart';
import '../domain/vinyl_track.dart';
import '../../../app/theme/takt_colors.dart';
import '../../../app/theme/takt_typography.dart';

class VinylPlayerWidget extends ConsumerStatefulWidget {
  const VinylPlayerWidget({super.key});

  @override
  ConsumerState<VinylPlayerWidget> createState() => _VinylPlayerWidgetState();
}

class _VinylPlayerWidgetState extends ConsumerState<VinylPlayerWidget>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _rotationNotifier = ValueNotifier<double>(0.0);
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      if (_lastElapsed != Duration.zero) {
        final delta = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
        const speed = 3.49; // ~33 1/3 RPM in rad/sec
        _rotationNotifier.value =
            (_rotationNotifier.value + delta * speed) % (2 * math.pi);
      }
      _lastElapsed = elapsed;
    });

    if (ref.read(vinylProvider).needleOnRecord) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _rotationNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(
      vinylProvider.select((s) => s.needleOnRecord),
      (previous, needleOnRecord) {
        if (needleOnRecord) {
          _lastElapsed = Duration.zero;
          if (!_ticker.isActive) {
            _ticker.start();
          }
        } else {
          if (_ticker.isActive) {
            _ticker.stop();
          }
        }
      },
    );

    final state = ref.watch(vinylProvider);
    final controller = ref.read(vinylProvider.notifier);

    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TaktColors.basaltSlate,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TaktColors.slateBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: state.needleOnRecord ? 'Lift tonearm' : 'Drop needle',
            child: GestureDetector(
              onTap: () => controller.toggleNeedle(),
              child: SizedBox(
                width: 240,
                height: 140,
                child: ValueListenableBuilder<double>(
                  valueListenable: _rotationNotifier,
                  builder: (context, angle, _) {
                    return CustomPaint(
                      painter: VinylDeckPainter(
                        rotationAngle: angle,
                        needleOnRecord: state.needleOnRecord,
                        labelColor: state.currentTrack.labelColor,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  state.currentTrack.name.toUpperCase(),
                  style: TaktTypography.controlLabel.copyWith(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: state.selectedTrackIndex,
                isDense: true,
                dropdownColor: TaktColors.basaltSlate,
                style: TaktTypography.controlLabel.copyWith(fontSize: 10),
                underline: const SizedBox(),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: TaktColors.warmBone,
                  size: 16,
                ),
                selectedItemBuilder: (BuildContext context) {
                  return VinylTrack.presets.map((t) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'TRACK 0${t.index + 1}',
                        style: TaktTypography.controlLabel.copyWith(
                          fontSize: 10,
                          color: TaktColors.filamentAmber,
                        ),
                      ),
                    );
                  }).toList();
                },
                items: VinylTrack.presets
                    .map((t) => DropdownMenuItem(value: t.index, child: Text(t.name)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) controller.selectTrack(val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
