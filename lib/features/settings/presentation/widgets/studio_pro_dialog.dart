import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/hardware_edition.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/theme_controller.dart';
import '../../../../app/theme/widgets/material_texture_painter.dart';
import '../../../../app/theme/widgets/rsquare_hardware_plaque.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../vinyl/domain/vinyl_track.dart';
import '../../../vinyl/presentation/vinyl_controller.dart';
import '../settings_controller.dart';

void showStudioProDialog(
  BuildContext context,
  WidgetRef ref, {
  HardwareEdition? edition,
  VinylTrack? vinylTrack,
  VinylTrack? track,
  bool? isDark,
  Color? primaryTextColor,
  Color? secondaryTextColor,
}) {
  final targetTrack = vinylTrack ?? track;
  final dark = isDark ?? ref.read(chassisThemeProvider).isDarkMode;
  final primary = primaryTextColor ??
      (dark ? TaktColors.warmBone : const Color(0xFF141618));
  final secondary = secondaryTextColor ??
      (dark ? const Color(0xFF9E9B93) : const Color(0xFF5A5D64));

  final subtitleText = targetTrack != null
      ? 'UNLOCK ${targetTrack.name.toUpperCase()} & ALL STUDIO PRO RECORDS'
      : 'UNLOCK STUDIO PRO CLEARANCE';

  final bodyText = edition != null
      ? 'Lifetime clearance gives you access to aerospace titanium, Bauhaus primary palettes, burnished marine brass, and all future hardware materials.'
      : targetTrack != null
          ? 'Lifetime clearance gives you access to ${targetTrack.name}, all exclusive Studio Pro ambient soundscapes, and future analog master recordings.'
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
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'ZYKL STUDIO PRO',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RsquareHardwarePlaque(
                size: 24,
                isDark: dark,
                showRivets: false,
              ),
              const SizedBox(width: 6),
              const Text(
                'RSQUARE',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: TaktColors.filamentAmber,
                ),
              ),
            ],
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lifetime Architecture Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: TaktColors.filamentAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: TaktColors.filamentAmber.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'LIFETIME ARCHITECTURE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: TaktColors.filamentAmber,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ZERO SUBSCRIPTION',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Launch Promo Pricing Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF14171A) : const Color(0xFFE2DFD7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: dark ? TaktColors.slateBorder : TaktColors.lightChassisBorder,
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FOUNDER LAUNCH EDITION · 47% OFF',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: TaktColors.filamentAmber,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            'Rp 69.000',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 15.0,
                              fontWeight: FontWeight.w800,
                              color: primary,
                            ),
                          ),
                          Text(
                            'Rp 129.000',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.0,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.lineThrough,
                              color: secondary,
                            ),
                          ),
                          Text(
                            '· \$9.99',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9.0,
                              fontWeight: FontWeight.w600,
                              color: secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: TaktColors.filamentAmber,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'PAY ONCE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF121315),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            if (edition != null) ...[
              _MaterialShowcasePlaque(
                edition: edition,
                isDark: dark,
              ),
              const SizedBox(height: 10),
            ],
            if (edition == null) ...[
              Text(
                subtitleText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: TaktColors.filamentAmber,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              bodyText,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9.5,
                color: secondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),

            // Benefit feature list
            _buildBenefitItem('✓ 5 Artisanal Materials (Walnut, Carbon, Titanium, Brass, Bauhaus)', secondary),
            _buildBenefitItem('✓ 4 Master Analog Soundscapes (Campfire, Forest, Cosmic...)', secondary),
            _buildBenefitItem('✓ Monastic Focus Lock & Retro Binaural Audio Engine', secondary),
            _buildBenefitItem('✓ Android AOD Notification & 2x2 Desktop Horological Widget', secondary),
            _buildBenefitItem('✓ 100% Offline Privacy: Zero telemetry, zero recurring bills', secondary),
          ],
        ),
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
            if (targetTrack != null) {
              ref
                  .read(vinylProvider.notifier)
                  .selectTrack(targetTrack.index, isPro: true);
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

class _MaterialShowcasePlaque extends StatelessWidget {
  final HardwareEdition edition;
  final bool isDark;

  const _MaterialShowcasePlaque({
    required this.edition,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? edition.darkBorder : edition.lightBorder;
    final rivetColor = isDark ? edition.rivetDark : edition.rivetLight;

    return Container(
      key: const ValueKey('material_showcase_plaque'),
      height: 96,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: borderColor, width: 1.2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? edition.plateGradientDark : edition.plateGradientLight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5.0),
        child: Stack(
          children: [
            // Procedural surface texture
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: MaterialTexturePainter(
                    textureType: edition.textureType,
                    isDark: isDark,
                    chassisColor: isDark ? edition.darkModuleBg : edition.lightModuleBg,
                  ),
                ),
              ),
            ),
            // Rivets at 4 corners
            Positioned(top: 5, left: 5, child: _PlaqueRivet(color: rivetColor)),
            Positioned(top: 5, right: 5, child: _PlaqueRivet(color: rivetColor)),
            Positioned(bottom: 5, left: 5, child: _PlaqueRivet(color: rivetColor)),
            Positioned(bottom: 5, right: 5, child: _PlaqueRivet(color: rivetColor)),

            // Interactive showcase content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // Mini Horological Dial & Needle
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.black45 : Colors.white54,
                      border: Border.all(color: borderColor, width: 1.0),
                    ),
                    child: Center(
                      child: Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          color: edition.needleColor,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: edition.filamentColor.withValues(alpha: 0.6),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          edition.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark ? TaktColors.warmBone : const Color(0xFF141618),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${edition.yearLabel} · ${edition.subtitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8.5,
                            color: isDark ? const Color(0xFF9E9B93) : const Color(0xFF5A5D64),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: edition.filamentColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'STUDIO PRO FINISH',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 7.5,
                                fontWeight: FontWeight.w700,
                                color: edition.filamentColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaqueRivet extends StatelessWidget {
  final Color color;

  const _PlaqueRivet({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

Widget _buildBenefitItem(String text, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
              color: color,
              height: 1.3,
            ),
          ),
        ),
      ],
    ),
  );
}


