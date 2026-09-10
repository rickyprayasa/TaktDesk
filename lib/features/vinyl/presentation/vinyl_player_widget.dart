import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'vinyl_controller.dart';
import 'vinyl_deck_painter.dart';
import '../domain/vinyl_track.dart';
import '../../../app/theme/takt_colors.dart';
import '../../../app/theme/takt_typography.dart';
import '../../../app/theme/theme_controller.dart';

class VinylPlayerWidget extends ConsumerStatefulWidget {
  const VinylPlayerWidget({super.key});

  @override
  ConsumerState<VinylPlayerWidget> createState() => _VinylPlayerWidgetState();
}

class _VinylPlayerWidgetState extends ConsumerState<VinylPlayerWidget>
    with TickerProviderStateMixin {
  late final Ticker _ticker;
  late final AnimationController _armController;
  late final Animation<double> _armAnimation;
  final ValueNotifier<double> _rotationNotifier = ValueNotifier<double>(0.0);
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _armController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _armAnimation = CurvedAnimation(
      parent: _armController,
      curve: Curves.easeInOutCubic,
    );

    if (ref.read(vinylProvider).needleOnRecord) {
      _armController.value = 1.0;
    }

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
    _armController.dispose();
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
          _armController.forward();
          if (!_ticker.isActive) {
            _ticker.start();
          }
        } else {
          _armController.reverse();
          if (_ticker.isActive) {
            _ticker.stop();
          }
        }
      },
    );

    final state = ref.watch(vinylProvider);
    final controller = ref.read(vinylProvider.notifier);
    final themeState = ref.watch(chassisThemeProvider);

    return Container(
      key: const ValueKey('vinyl_player_deck_chassis'),
      width: 280,
      decoration: BoxDecoration(
        color: themeState.moduleChassisColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: themeState.borderColor, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 4 Corner Mechanical Rivets
          Positioned(
            top: 6,
            left: 6,
            child: _buildCornerRivet(0, themeState.rivetColor),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: _buildCornerRivet(1, themeState.rivetColor),
          ),
          Positioned(
            bottom: 6,
            left: 6,
            child: _buildCornerRivet(2, themeState.rivetColor),
          ),
          Positioned(
            bottom: 6,
            right: 6,
            child: _buildCornerRivet(3, themeState.rivetColor),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Turntable Deck Top Banner
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'BRAUN TP-1',
                        style: TaktTypography.controlLabel,
                        overflow: TextOverflow.ellipsis,
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
                            color: state.needleOnRecord
                                ? TaktColors.filamentAmber
                                : const Color(0xFF2C3036),
                            boxShadow: state.needleOnRecord
                                ? [
                                    BoxShadow(
                                      color: TaktColors.filamentAmber.withValues(alpha: 0.8),
                                      blurRadius: 2.5,
                                      spreadRadius: 0.5,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '33 RPM',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            color: state.needleOnRecord
                                ? TaktColors.filamentAmber
                                : TaktColors.warmBone.withValues(alpha: 0.4),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Interactive Turntable Platter and Tonearm
                Semantics(
                  button: true,
                  label: state.needleOnRecord ? 'Lift tonearm' : 'Drop needle',
                  child: GestureDetector(
                    onTap: () => controller.toggleNeedle(),
                    child: SizedBox(
                      width: 240,
                      height: 140,
                      child: AnimatedBuilder(
                        animation: _armAnimation,
                        builder: (context, _) {
                          return ValueListenableBuilder<double>(
                            valueListenable: _rotationNotifier,
                            builder: (context, angle, _) {
                              return CustomPaint(
                                painter: VinylDeckPainter(
                                  rotationAngle: angle,
                                  needleOnRecord: state.needleOnRecord,
                                  armProgress: _armAnimation.value,
                                  labelColor: themeState.accentColor,
                                  tonearmGradient: themeState.plateGradient,
                                  armPivotBorderColor: themeState.borderColor,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Track Name and Preset Dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        state.currentTrack.name.toUpperCase(),
                        style: TaktTypography.controlLabel.copyWith(
                          fontSize: 10,
                          color: state.needleOnRecord
                              ? TaktColors.filamentAmber
                              : TaktColors.warmBone,
                        ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildCornerRivet(int index, Color color) {
    return IgnorePointer(
      child: Container(
        key: ValueKey('vinyl_rivet_$index'),
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              offset: Offset(0, 0.5),
              blurRadius: 0.5,
            ),
          ],
        ),
      ),
    );
  }
}

