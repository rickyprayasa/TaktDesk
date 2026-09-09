import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takt_desk/app/theme/takt_colors.dart';
import 'package:takt_desk/app/theme/takt_typography.dart';
import 'package:takt_desk/core/focus/focus_lock_controller.dart';

class MonasticSwitchWidget extends ConsumerWidget {
  const MonasticSwitchWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusState = ref.watch(focusLockProvider);
    final isLocked = focusState.isLocked;

    return Semantics(
      button: true,
      toggled: isLocked,
      enabled: !isLocked,
      label: isLocked ? 'Monastic Focus Engaged' : 'Monastic Focus Inactive',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!isLocked) {
            ref.read(focusLockProvider.notifier).engageLock();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: TaktColors.basaltSlate,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLocked
                  ? TaktColors.filamentAmber.withValues(alpha: 0.8)
                  : TaktColors.slateBorder,
              width: 1.0,
            ),
            boxShadow: isLocked
                ? [
                    BoxShadow(
                      color: TaktColors.filamentAmber.withValues(alpha: 0.3),
                      blurRadius: 6,
                      spreadRadius: 0.5,
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sleek LED status indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLocked
                      ? TaktColors.filamentAmber
                      : const Color(0xFF4A4E55),
                  boxShadow: isLocked
                      ? [
                          BoxShadow(
                            color: TaktColors.filamentAmber.withValues(alpha: 0.8),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'MONASTIC',
                style: TaktTypography.labelSmall.copyWith(
                  color: isLocked ? TaktPalette.warmBone : TaktPalette.warmBone.withValues(alpha: 0.6),
                  fontSize: 9,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isLocked ? 'ENGAGED' : 'LOCKDOWN',
                style: TaktTypography.labelSmall.copyWith(
                  color: isLocked ? TaktPalette.filamentAmber : TaktPalette.warmBone.withValues(alpha: 0.4),
                  fontSize: 9,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
