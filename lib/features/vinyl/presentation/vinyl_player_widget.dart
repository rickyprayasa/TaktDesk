import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'vinyl_controller.dart';
import 'vinyl_deck_painter.dart';
import '../../../app/theme/takt_typography.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../app/theme/widgets/material_chassis_box.dart';
import 'widgets/turntable_mixer_strip.dart';
import 'widgets/vinyl_disc_drawer_widget.dart';

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

    return MaterialChassisBox(
      key: const ValueKey('vinyl_player_deck_chassis'),
      rivetKeyPrefix: 'vinyl_rivet',
      width: 280,
      borderRadius: BorderRadius.circular(10),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Turntable Deck Top Banner
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'BRAUN TP-1',
                  style: TaktTypography.controlLabel.copyWith(
                    color: themeState.chassisTextColor,
                  ),
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
                          ? themeState.filamentColor
                          : const Color(0xFF2C3036),
                      boxShadow: state.needleOnRecord
                          ? [
                              BoxShadow(
                                color: themeState.filamentColor.withValues(alpha: 0.8),
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
                          ? themeState.filamentColor
                          : themeState.chassisMutedTextColor,
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
          // Track Name and Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  state.currentTrack.name.toUpperCase(),
                  style: TaktTypography.controlLabel.copyWith(
                    fontSize: 10,
                    color: state.needleOnRecord
                        ? themeState.filamentColor
                        : themeState.chassisTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                state.needleOnRecord ? '33 RPM // ON' : '33 RPM // STANDBY',
                style: TaktTypography.controlLabel.copyWith(
                  fontSize: 9,
                  color: state.needleOnRecord
                      ? themeState.filamentColor
                      : themeState.chassisMutedTextColor,
                ),
              ),
            ],
          ),
          // Slide-Out Archival Disc Drawer
          const VinylDiscDrawerWidget(),
          const SizedBox(height: 10),
          // 3-Channel Soundscape Mixer Strip
          const TurntableMixerStrip(),
        ],
      ),
    );
  }
}

