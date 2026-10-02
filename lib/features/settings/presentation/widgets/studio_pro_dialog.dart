import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/hardware_edition.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/theme_controller.dart';
import '../../../../app/theme/widgets/material_texture_painter.dart';
import '../../../../app/theme/widgets/rsquare_hardware_plaque.dart';
import '../../../../core/billing/pro_purchase_controller.dart';
import '../../../../core/config/app_security_config.dart';
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

  // Keep in sync with the website (Terms, FAQ, HonestSpecs): PRO is a single
  // payment for every edition and soundscape, including everything added in
  // future updates at no extra cost (owner decision 2026-10-02: no paid packs).
  final bodyText = edition != null
      ? 'One payment unlocks every Studio PRO hardware edition, including every new edition added in future updates.'
      : targetTrack != null
          ? 'One payment unlocks ${targetTrack.name} and every Studio PRO soundscape, including every new soundscape added in future updates.'
          : 'One payment unlocks every Studio PRO hardware edition and soundscape, including everything added in future updates.';

  showDialog<void>(
    context: context,
    builder: (dialogCtx) => Consumer(builder: (consumerCtx, dref, _) {
      const simulated = AppSecurityConfig.isProSimulationEnabled;
      final pro = dref.watch(proPurchaseProvider);
      final price = pro.price ?? 'Rp 69.000';

      Future<void> applyUnlock() async {
        final prefsNotifier = dref.read(deskPreferencesControllerProvider.notifier);
        await prefsNotifier.setProSimulated(true);
        if (edition != null) {
          await prefsNotifier.setHardwareEdition(edition.type);
        }
        if (targetTrack != null) {
          dref.read(vinylProvider.notifier).selectTrack(targetTrack.index, isPro: true);
        }
        HapticService.selectionClick();
        if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
      }

      // Real purchase: Google Play reports ownership asynchronously.
      dref.listen<bool>(proPurchaseProvider.select((s) => s.isOwned), (was, owned) {
        if (owned && was != true) applyUnlock();
      });

      return AlertDialog(
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
              Text(
                'RSQUARE',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: TaktColors.amberText(dark),
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
                  Expanded(
                    child: Text(
                      'LIFETIME ARCHITECTURE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: TaktColors.amberText(dark),
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
                        Text(
                          'LAUNCH PRICE · ONE-TIME',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: TaktColors.amberText(dark),
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
                            price,
                            key: const ValueKey('pro_dialog_price'),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 15.0,
                              fontWeight: FontWeight.w800,
                              color: primary,
                            ),
                          ),
                          Text(
                            'no subscription',
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
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: TaktColors.amberText(dark),
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
            _buildBenefitItem('✓ 8 more hardware editions (12 in total)', secondary),
            _buildBenefitItem('✓ 12 more acoustic soundscapes (20 in total)', secondary),
            _buildBenefitItem('✓ Every new edition & soundscape in future updates', secondary),
            _buildBenefitItem('✓ Pay once: no subscription, no ads, no account', secondary),
            _buildBenefitItem('✓ Restore on a new phone with the same Google account', secondary),
            if (pro.status == ProPurchaseStatus.pending) ...[
              const SizedBox(height: 6),
              Text(
                'Payment pending. Studio PRO unlocks automatically once Google Play confirms it, even if you close ZYKL.',
                key: const ValueKey('pro_dialog_pending'),
                style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: TaktColors.amberText(dark), height: 1.3),
              ),
            ],
            if (pro.message != null) ...[
              const SizedBox(height: 6),
              Text(
                pro.message!,
                key: const ValueKey('pro_dialog_message'),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: TaktColors.mutedOchre, height: 1.3),
              ),
            ],
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
        if (!simulated)
          TextButton(
            key: const ValueKey('pro_dialog_restore_button'),
            onPressed: pro.isBusy ? null : () => dref.read(proPurchaseProvider.notifier).restore(),
            child: Text(
              'RESTORE',
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
          onPressed: pro.isBusy
              ? null
              : () {
                  if (simulated) {
                    applyUnlock();
                  } else {
                    dref.read(proPurchaseProvider.notifier).buy();
                  }
                },
          child: Text(
            simulated
                ? 'UNLOCK NOW (SIMULATED)'
                : switch (pro.status) {
                    ProPurchaseStatus.purchasing => 'OPENING GOOGLE PLAY…',
                    ProPurchaseStatus.pending => 'PAYMENT PENDING',
                    _ => 'UNLOCK · $price',
                  },
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
    }),
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


