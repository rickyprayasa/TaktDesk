import 'package:flutter/material.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/takt_typography.dart';

/// Top control housing and recessed aperture mouth for the thermal paper dispenser.
class DispenserSlotHeader extends StatelessWidget {
  final int taskCount;
  final int maxTasks;
  final VoidCallback? onAddTap;

  const DispenserSlotHeader({
    super.key,
    required this.taskCount,
    this.maxTasks = 5,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFull = taskCount >= maxTasks;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Control & Capacity Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Model Label
            const Expanded(
              child: Text(
                'DISPENSER: 5 MAX',
                style: TaktTypography.controlLabel,
              ),
            ),
            // 5 Segmented Pip LEDs
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(maxTasks, (index) {
                final isLit = index < taskCount;
                final ledColor = isFull
                    ? TaktColors.mutedOchre
                    : (isLit ? TaktColors.filamentAmber : const Color(0xFF2B2E34));
                return Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ledColor,
                    boxShadow: isLit
                        ? [
                            BoxShadow(
                              color: ledColor.withValues(alpha: 0.8),
                              blurRadius: 2.5,
                              spreadRadius: 0.5,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(width: 8),
            // Tactile Feed Push Button
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.add,
                color: onAddTap != null
                    ? TaktColors.warmBone
                    : TaktColors.warmBone.withValues(alpha: 0.25),
                size: 18,
              ),
              onPressed: onAddTap,
            ),
          ],
        ),
        const SizedBox(height: 10),
        // 2. Recessed Mechanical Feeder Aperture Slit
        Container(
          height: 8,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0C0D0F),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: const Color(0xFF1E2126),
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xDD000000),
                offset: Offset(0, 1.5),
                blurRadius: 2.5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Aluminum Cutter Lip Highlight
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1.2,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF32363D),
                        Color(0xFF6B7280),
                        Color(0xFF32363D),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
