import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takt_desk/app/theme/takt_colors.dart';
import 'package:takt_desk/app/theme/takt_typography.dart';
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
        ref.read(audioServiceProvider).play(SoundEffect.dialClick);
        HapticService.lightClick();
      }
    });

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _isCompleted = true;
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

    return AnimatedBuilder(
      animation: _holdController,
      builder: (context, _) {
        final progress = _holdController.value;

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
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 38,
              decoration: BoxDecoration(
                color: TaktPalette.obsidian,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: progress > 0.0
                      ? TaktPalette.mutedOchre
                      : TaktPalette.thermalCarbon,
                  width: 1.2,
                ),
              ),
              child: Stack(
                children: [
                  // Progress Fill
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: TaktPalette.mutedOchre.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  // Center Label
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.power_settings_new_rounded,
                          size: 14,
                          color: TaktPalette.mutedOchre,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          progress > 0.0
                              ? 'HOLDING... ${(5 - (progress * 5)).toStringAsFixed(1)}s'
                              : 'HOLD 5s TO UNLATCH',
                          style: TaktTypography.labelSmall.copyWith(
                            color: progress > 0.0
                                ? TaktPalette.warmBone
                                : TaktPalette.warmBone.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
