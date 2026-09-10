import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/theme_controller.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/audio/sound_effect.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../settings/presentation/settings_controller.dart';

/// Industrial spec plate anchoring the lower desk canvas.
///
/// Features debossed brushed aluminum / slate aesthetics, corner rivet accents,
/// Germanic manufacturer metadata stamp, and an analog daily focus tally
/// accompanied by a 4-micro-LED quadrant progress meter.
class DeskSpecPlateWidget extends ConsumerWidget {
  const DeskSpecPlateWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(chassisThemeProvider);
    final isDark = themeState.isDarkMode;
    final statsAsync = ref.watch(todayFocusStatsProvider);
    final stats = statsAsync.valueOrNull ?? const TodayFocusStats(completedCount: 0, totalMinutes: 0);

    final completedCount = stats.completedCount;
    final activeLeds = (completedCount > 0 && completedCount % 4 == 0)
        ? 4
        : (completedCount % 4);

    final primaryTextColor = isDark ? TaktColors.warmBone : TaktColors.chassisObsidian;
    final secondaryTextColor = isDark
        ? TaktColors.warmBone.withValues(alpha: 0.6)
        : const Color(0xFF5A5D64);

    final borderColor = isDark ? themeState.edition.darkBorder : themeState.edition.lightBorder;
    final rivetColor = isDark ? themeState.edition.rivetDark : themeState.edition.rivetLight;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7.0),
            border: Border.all(color: borderColor, width: 1.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? themeState.edition.plateGradientDark
                  : themeState.edition.plateGradientLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                offset: const Offset(0, 2),
                blurRadius: 4.0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(7.0),
              onTap: () {
                ref.read(audioServiceProvider).play(SoundEffect.dialClick);
                HapticService.lightClick();
              },
              child: Stack(
                children: [
                  // Corner mechanical rivets
                  Positioned(top: 4, left: 4, child: _RivetDot(color: rivetColor, isDark: isDark)),
                  Positioned(top: 4, right: 4, child: _RivetDot(color: rivetColor, isDark: isDark)),
                  Positioned(bottom: 4, left: 4, child: _RivetDot(color: rivetColor, isDark: isDark)),
                  Positioned(bottom: 4, right: 4, child: _RivetDot(color: rivetColor, isDark: isDark)),

                  // Main Plate Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Column: Manufacturer Stamp
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  themeState.edition.title,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: primaryTextColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  themeState.edition.yearLabel,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 7.8,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 1),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${themeState.edition.subtitle} · STEREO 44.1kHz',
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 7.0,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.4,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Right Column: Daily Focus Tally & Quadrant LEDs
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 4 Micro-LED indicators
                            Row(
                              key: const ValueKey('spec_plate_led_row'),
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(4, (i) {
                                final isLit = i < activeLeds;
                                return Container(
                                  key: ValueKey('spec_plate_led_$i'),
                                  margin: EdgeInsets.only(left: i == 0 ? 0 : 3.5),
                                  width: 5.5,
                                  height: 5.5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isLit
                                        ? themeState.filamentColor
                                        : TaktColors.basaltSlate,
                                    border: Border.all(
                                      color: isLit
                                          ? const Color(0xFFFFD59E)
                                          : TaktColors.chassisObsidian,
                                      width: 0.8,
                                    ),
                                    boxShadow: isLit
                                        ? [
                                            BoxShadow(
                                              color: themeState.filamentColor.withValues(alpha: 0.8),
                                              blurRadius: 4.0,
                                              spreadRadius: 1.0,
                                            ),
                                          ]
                                        : null,
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                'TODAY: ${stats.completedCount} / 4 CYCLES',
                                maxLines: 1,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: primaryTextColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 1),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${stats.totalMinutes} MIN FOCUSED',
                                maxLines: 1,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                  color: secondaryTextColor,
                                ),
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
          ),
        ),
      ),
    );
  }
}

class _RivetDot extends StatelessWidget {
  final Color color;
  final bool isDark;

  const _RivetDot({required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3.5,
      height: 3.5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x33FFFFFF) : const Color(0x66FFFFFF),
            offset: const Offset(0.5, 0.5),
            blurRadius: 0.5,
          ),
        ],
      ),
    );
  }
}
