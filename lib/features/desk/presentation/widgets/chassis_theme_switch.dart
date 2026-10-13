import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/theme_controller.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../settings/presentation/settings_controller.dart';
import '../../../../app/motion.dart';

/// Physical mechanical rocker / slider switch to toggle chassis finish (Braun Dark vs Light).
class ChassisThemeSwitch extends ConsumerWidget {
  const ChassisThemeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(chassisThemeProvider);
    final isDark = themeState.isDarkMode;

    return Semantics(
      button: true,
      label: isDark ? 'Switch to light theme' : 'Switch to dark theme',
      excludeSemantics: true,
      child: InkWell(
        onTap: () {
          HapticService.selectionClick();
          ref.read(deskPreferencesControllerProvider.notifier).toggleDarkMode();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1D21) : const Color(0xFFDFDBD2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF32363D) : const Color(0xFFB5B0A4),
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                offset: Offset(0, 1.5),
                blurRadius: 2.0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sliding Rocker Thumb
              AnimatedContainer(
                duration: motion(context, const Duration(milliseconds: 240)),
                curve: Curves.easeOutCubic,
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? TaktColors.filamentAmber
                      : const Color(0xFF4A4E55),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? TaktColors.filamentAmber.withValues(alpha: 0.6)
                          : Colors.black26,
                      blurRadius: 3.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isDark ? 'DARK' : 'LIGHT',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? TaktColors.warmBone : const Color(0xFF1A1C20),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
