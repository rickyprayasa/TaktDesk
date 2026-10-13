import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'vinyl_controller.dart';
import 'vinyl_deck_painter.dart';
import '../../../app/theme/takt_typography.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../app/theme/widgets/material_chassis_box.dart';
import 'widgets/vinyl_disc_drawer_widget.dart';
import '../../../core/services/display_service.dart';

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

  }

  /// System "remove animations" setting: the platter stays still (the tonearm
  /// and strobe still show the playing state) and no per-frame ticker runs.
  bool _reduceMotion = false;

  /// Desk clock has dimmed the screen: the platter rests (nobody is watching it spin, the ticker ran all night).
  bool _deskDimmed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncPlatter(ref.read(vinylProvider).needleOnRecord);
  }

  void _syncPlatter(bool needleOnRecord) {
    final shouldSpin = needleOnRecord && !_reduceMotion && !_deskDimmed;
    if (shouldSpin && !_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    } else if (!shouldSpin && _ticker.isActive) {
      _ticker.stop();
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
    ref.listen<bool>(deskClockDimmedProvider, (_, dimmed) {
      _deskDimmed = dimmed;
      _syncPlatter(ref.read(vinylProvider).needleOnRecord);
    });
    ref.listen<bool>(
      vinylProvider.select((s) => s.needleOnRecord),
      (previous, needleOnRecord) {
        if (needleOnRecord) {
          _armController.forward();
        } else {
          _armController.reverse();
        }
        _syncPlatter(needleOnRecord);
      },
    );

    final state = ref.watch(vinylProvider);
    final controller = ref.read(vinylProvider.notifier);
    final themeState = ref.watch(chassisThemeProvider);

    return MaterialChassisBox(
      key: const ValueKey('vinyl_player_deck_chassis'),
      rivetKeyPrefix: 'vinyl_rivet',
      width: 340,
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
                  'ZYKL TP-01',
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
                          ? (themeState.isDarkMode ? themeState.filamentColor : const Color(0xFFB45309))
                          : (themeState.isDarkMode ? const Color(0xFF2C3036) : const Color(0xFFB5B0A4)),
                      boxShadow: state.needleOnRecord
                          ? [
                              BoxShadow(
                                color: (themeState.isDarkMode ? themeState.filamentColor : const Color(0xFFB45309)).withValues(alpha: 0.8),
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
                          ? (themeState.isDarkMode ? themeState.filamentColor : const Color(0xFFB45309))
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
                width: 280,
                height: 155,
                // Three layers: the static deck is painted once, the record is painted once into its own
                // layer and only rotated per frame (compositing, no repaint), the tonearm repaints while it moves.
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: VinylDeckPainter(
                          layer: VinylDeckLayer.base,
                          rotationAngle: 0,
                          needleOnRecord: state.needleOnRecord,
                        ),
                      ),
                    ),
                    RepaintBoundary(
                      child: ValueListenableBuilder<double>(
                        valueListenable: _rotationNotifier,
                        builder: (context, angle, disc) => Transform.rotate(
                          key: const ValueKey('vinyl_disc_spin'),
                          angle: angle,
                          // the record's centre: (0.44 w, 0.5 h) in the painter
                          alignment: const Alignment(-0.12, 0),
                          child: disc,
                        ),
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: VinylDeckPainter(
                              layer: VinylDeckLayer.disc,
                              rotationAngle: 0,
                              needleOnRecord: state.needleOnRecord,
                              labelColor: themeState.accentColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _armAnimation,
                        builder: (context, _) => CustomPaint(
                          painter: VinylDeckPainter(
                            layer: VinylDeckLayer.arm,
                            rotationAngle: 0,
                            needleOnRecord: state.needleOnRecord,
                            armProgress: _armAnimation.value,
                            tonearmGradient: themeState.plateGradient,
                            armPivotBorderColor: themeState.borderColor,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                        ? (themeState.isDarkMode ? themeState.filamentColor : const Color(0xFFB45309))
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
                      ? (themeState.isDarkMode ? themeState.filamentColor : const Color(0xFFB45309))
                      : themeState.chassisMutedTextColor,
                ),
              ),
            ],
          ),
          // Slide-Out Archival Disc Drawer
          const VinylDiscDrawerWidget(),
        ],
      ),
    );
  }
}

