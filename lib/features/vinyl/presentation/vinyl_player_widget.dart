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
  double _rotationAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (!mounted) return;
      final state = ref.read(vinylProvider);
      if (state.needleOnRecord && state.turntableSpeed > 0) {
        setState(() {
          _rotationAngle = (_rotationAngle + 0.04) % (2 * math.pi);
        });
      }
    });

    if (ref.read(vinylProvider).needleOnRecord) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(
      vinylProvider.select((s) => s.needleOnRecord),
      (previous, needleOnRecord) {
        if (needleOnRecord) {
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
          GestureDetector(
            onTap: () => controller.toggleNeedle(),
            child: SizedBox(
              width: 240,
              height: 140,
              child: CustomPaint(
                painter: VinylDeckPainter(
                  rotationAngle: _rotationAngle,
                  needleOnRecord: state.needleOnRecord,
                  labelColor: state.currentTrack.labelColor,
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
