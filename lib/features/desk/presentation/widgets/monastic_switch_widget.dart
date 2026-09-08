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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: TaktPalette.basalt,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isLocked
                  ? TaktPalette.filamentAmber.withValues(alpha: 0.8)
                  : TaktPalette.thermalCarbon,
              width: 1.2,
            ),
            boxShadow: isLocked
                ? [
                    BoxShadow(
                      color: TaktPalette.filamentAmber.withValues(alpha: 0.35),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicator vacuum tube lamp
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLocked
                      ? TaktPalette.filamentAmber
                      : TaktPalette.thermalCarbon,
                  boxShadow: isLocked
                      ? [
                          BoxShadow(
                            color: TaktPalette.filamentAmber.withValues(alpha: 0.9),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MONASTIC',
                    style: TaktTypography.labelSmall.copyWith(
                      color: isLocked ? TaktPalette.warmBone : TaktPalette.warmBone.withValues(alpha: 0.6),
                      fontSize: 9,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    isLocked ? 'ENGAGED' : 'LOCKDOWN',
                    style: TaktTypography.labelSmall.copyWith(
                      color: isLocked ? TaktPalette.filamentAmber : TaktPalette.warmBone.withValues(alpha: 0.4),
                      fontSize: 8,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
