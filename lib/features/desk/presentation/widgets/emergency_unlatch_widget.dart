import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takt_desk/app/theme/takt_colors.dart';
import 'package:takt_desk/app/theme/takt_typography.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/audio/sound_effect.dart';
import 'package:takt_desk/core/focus/focus_lock_controller.dart';
import 'package:takt_desk/core/haptics/haptic_service.dart';

class EmergencyUnlatchWidget extends ConsumerStatefulWidget {
  const EmergencyUnlatchWidget({super.key});

  @override
  ConsumerState<EmergencyUnlatchWidget> createState() => _EmergencyUnlatchWidgetState();
}

class _EmergencyUnlatchWidgetState extends ConsumerState<EmergencyUnlatchWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _holdController;
  int _lastTickSecond = 0;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _holdController.addListener(() {
      if (!mounted) return;
      final progress = _holdController.value;
      ref.read(focusLockProvider.notifier).updateHoldProgress(progress);

      final currentTick = (progress * 10).floor();
      if (currentTick != _lastTickSecond && currentTick > 0 && currentTick < 10) {
        _lastTickSecond = currentTick;
        HapticService.lightClick();
      }
    });

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _isCompleted = true;
        ref.read(audioServiceProvider).play(SoundEffect.switchClick);
        HapticService.heavyClick();
        ref.read(focusLockProvider.notifier).completeUnlock();
        _holdController.reset();
      }
    });
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent _) {
    _isCompleted = false;
    _lastTickSecond = 0;
    _holdController.forward();
  }

  void _onPointerUpOrCancel(PointerEvent _) {
    if (!_isCompleted && (_holdController.isAnimating || _holdController.value < 1.0)) {
      _holdController.reset();
      if (mounted) {
        ref.read(focusLockProvider.notifier).cancelHold();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final focusState = ref.watch(focusLockProvider);
    if (!focusState.isLocked) {
      return const SizedBox.shrink();
    }

    final themeState = ref.watch(chassisThemeProvider);
    final isDark = themeState.isDarkMode;

    return AnimatedBuilder(
      animation: _holdController,
      builder: (context, _) {
        final progress = _holdController.value;
        final borderColor = progress > 0.0
            ? TaktColors.filamentAmber
            : (isDark ? themeState.edition.darkBorder : themeState.edition.lightBorder);
        final rivetColor = isDark ? themeState.edition.rivetDark : themeState.edition.rivetLight;
        final plateColors = isDark
            ? [const Color(0xFF191B1F), const Color(0xFF101215)]
            : [const Color(0xFFECE8DF), const Color(0xFFE0DBD0)];
        final textColor = progress > 0.0
            ? (isDark ? TaktColors.warmBone : TaktColors.chassisObsidian)
            : (isDark
                ? TaktColors.warmBone.withValues(alpha: 0.75)
                : const Color(0xFF32363E));
        final iconColor = progress > 0.0
            ? TaktColors.filamentAmber
            : (isDark ? TaktColors.mutedOchre : const Color(0xFFBF5700));

        return Semantics(
          button: true,
          label: progress > 0.0
              ? 'Emergency unlatch, holding ${(5 - (progress * 5)).toStringAsFixed(1)} seconds remaining'
              : 'Emergency unlatch, hold 5 seconds to unlock',
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _onPointerDown,
            onPointerUp: _onPointerUpOrCancel,
            onPointerCancel: _onPointerUpOrCancel,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: plateColors,
                    ),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: borderColor,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                        offset: const Offset(0, 1.5),
                        blurRadius: 3.0,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Corner micro rivets
                      Positioned(top: 3.5, left: 4.5, child: _RivetMicroDot(color: rivetColor, isDark: isDark)),
                      Positioned(top: 3.5, right: 4.5, child: _RivetMicroDot(color: rivetColor, isDark: isDark)),
                      Positioned(bottom: 3.5, left: 4.5, child: _RivetMicroDot(color: rivetColor, isDark: isDark)),
                      Positioned(bottom: 3.5, right: 4.5, child: _RivetMicroDot(color: rivetColor, isDark: isDark)),

                      // Hazard knurled micro notches on left and right flanks
                      Positioned(
                        left: 12,
                        top: 13,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            3,
                            (i) => Container(
                              margin: const EdgeInsets.only(right: 2.5),
                              width: 1.5,
                              height: 11,
                              decoration: BoxDecoration(
                                color: progress > 0.0
                                    ? TaktColors.filamentAmber.withValues(alpha: 0.70)
                                    : (isDark ? Colors.white12 : Colors.black12),
                                borderRadius: BorderRadius.circular(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 13,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            3,
                            (i) => Container(
                              margin: const EdgeInsets.only(left: 2.5),
                              width: 1.5,
                              height: 11,
                              decoration: BoxDecoration(
                                color: progress > 0.0
                                    ? TaktColors.filamentAmber.withValues(alpha: 0.70)
                                    : (isDark ? Colors.white12 : Colors.black12),
                                borderRadius: BorderRadius.circular(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Progress Fill (Luminescent Amber Sweep)
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                TaktColors.filamentAmber.withValues(alpha: isDark ? 0.30 : 0.38),
                                TaktColors.filamentAmber.withValues(alpha: isDark ? 0.50 : 0.60),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            border: progress > 0.02
                                ? const Border(
                                    right: BorderSide(
                                      color: TaktColors.filamentAmber,
                                      width: 2.0,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),

                      // Center Label & Warning Icon
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.power_settings_new_rounded,
                              size: 13.5,
                              color: iconColor,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              progress > 0.0
                                  ? 'HOLDING... ${(5 - (progress * 5)).toStringAsFixed(1)}s'
                                  : 'HOLD 5s TO UNLATCH',
                              style: TaktTypography.labelSmall.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                fontSize: 9.5,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RivetMicroDot extends StatelessWidget {
  final Color color;
  final bool isDark;

  const _RivetMicroDot({required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3.5,
      height: 3.5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.black45 : Colors.black12,
          width: 0.5,
        ),
      ),
    );
  }
}
