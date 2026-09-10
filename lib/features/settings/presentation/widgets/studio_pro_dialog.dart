import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/hardware_edition.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/theme_controller.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../vinyl/domain/vinyl_track.dart';
import '../../../vinyl/presentation/vinyl_controller.dart';
import '../settings_controller.dart';

void showStudioProDialog(
  BuildContext context,
  WidgetRef ref, {
  HardwareEdition? edition,
  VinylTrack? vinylTrack,
  bool? isDark,
  Color? primaryTextColor,
  Color? secondaryTextColor,
}) {
  final dark = isDark ?? ref.read(chassisThemeProvider).isDarkMode;
  final primary = primaryTextColor ??
      (dark ? TaktColors.warmBone : const Color(0xFF141618));
  final secondary = secondaryTextColor ??
      (dark ? const Color(0xFF9E9B93) : const Color(0xFF5A5D64));

  final subtitleText = edition != null
      ? 'UNLOCK ${edition.title} & ALL HARDWARE FINISHES'
      : vinylTrack != null
          ? 'UNLOCK ${vinylTrack.name.toUpperCase()} & ALL STUDIO PRO RECORDS'
          : 'UNLOCK STUDIO PRO CLEARANCE';

  final bodyText = edition != null
      ? 'Lifetime clearance gives you access to aerospace titanium, Bauhaus primary palettes, burnished marine brass, and all future hardware materials.'
      : vinylTrack != null
          ? 'Lifetime clearance gives you access to ${vinylTrack.name}, all exclusive Studio Pro ambient soundscapes, and future analog master recordings.'
          : 'Lifetime clearance gives you access to all exclusive hardware finishes, premium analog ambient soundscapes, and all future Studio Pro features.';

  showDialog<void>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor:
          dark ? TaktColors.basaltSlate : const Color(0xFFEDEAE2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(
          color: dark ? TaktColors.slateBorder : TaktColors.lightChassisBorder,
        ),
      ),
      title: Text(
        'TAKT DESK STUDIO PRO',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: primary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitleText,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: TaktColors.filamentAmber,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bodyText,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: secondary,
              height: 1.4,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(),
          child: Text(
            'CANCEL',
            style: TextStyle(
              fontFamily: 'monospace',
              color: secondary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
        ElevatedButton(
          key: const ValueKey('pro_dialog_unlock_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: TaktColors.filamentAmber,
            foregroundColor: TaktColors.chassisObsidian,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          onPressed: () async {
            await ref
                .read(deskPreferencesControllerProvider.notifier)
                .setProSimulated(true);
            if (edition != null) {
              await ref
                  .read(deskPreferencesControllerProvider.notifier)
                  .setHardwareEdition(edition.type);
            }
            if (vinylTrack != null) {
              ref
                  .read(vinylProvider.notifier)
                  .selectTrack(vinylTrack.index, isPro: true);
            }
            HapticService.selectionClick();
            if (dialogCtx.mounted) {
              Navigator.of(dialogCtx).pop();
            }
          },
          child: const Text(
            'UNLOCK NOW (SIMULATED)',
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ],
    ),
  );
}
