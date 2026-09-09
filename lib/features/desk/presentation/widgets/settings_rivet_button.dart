import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/theme_controller.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../settings/presentation/takt_settings_sheet.dart';

/// Tactile screw-head / knurled gear button triggering the Service Hatch sheet.
class SettingsRivetButton extends ConsumerWidget {
  const SettingsRivetButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(chassisThemeProvider);
    final isDark = themeState.isDarkMode;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? TaktColors.basaltSlate : const Color(0xFFD2D6DC),
        border: Border.all(
          color: isDark ? TaktColors.slateBorder : const Color(0xFFB0B5BC),
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticService.lightClick();
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => const TaktSettingsSheet(),
            );
          },
          child: Center(
            child: Icon(
              Icons.tune,
              size: 16,
              color: isDark ? TaktColors.warmBone : const Color(0xFF2C3038),
            ),
          ),
        ),
      ),
    );
  }
}
