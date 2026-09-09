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

    final primaryTextColor = isDark ? TaktColors.warmBone : const Color(0xFF141618);
    final secondaryTextColor = isDark
        ? TaktColors.warmBone.withValues(alpha: 0.6)
        : const Color(0xFF5A5D64);

    final borderColor = isDark ? TaktColors.slateBorder : const Color(0xFFC4C8D0);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7.0),
            border: Border.all(color: borderColor, width: 1.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF282B32), Color(0xFF1E2126), Color(0xFF17191C)]
                  : const [Color(0xFFE4E1D9), Color(0xFFDDD9D0), Color(0xFFCFCAC0)],
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
                  const Positioned(top: 4, left: 4, child: _RivetDot()),
                  const Positioned(top: 4, right: 4, child: _RivetDot()),
                  const Positioned(bottom: 4, left: 4, child: _RivetDot()),
                  const Positioned(bottom: 4, right: 4, child: _RivetDot()),

                  // Main Plate Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                              Text(
                                'TAKT DESK · MOD. 01 · 2026',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: primaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'GERMANIC MINIMALISM · STEREO 44.1kHz',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 8.0,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.8,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),

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
                                  margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isLit
                                        ? TaktColors.filamentAmber
                                        : (isDark ? const Color(0xFF181A1E) : const Color(0xFFBBB6AA)),
                                    border: Border.all(
                                      color: isLit
                                          ? const Color(0xFFFFD59E)
                                          : (isDark ? const Color(0xFF141517) : const Color(0xFF9E998E)),
                                      width: 0.8,
                                    ),
                                    boxShadow: isLit
                                        ? [
                                            BoxShadow(
                                              color: TaktColors.filamentAmber.withValues(alpha: 0.8),
                                              blurRadius: 4.0,
                                              spreadRadius: 1.0,
                                            ),
                                          ]
                                        : null,
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'TODAY: ${stats.completedCount} / 4 CYCLES',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${stats.totalMinutes} MIN FOCUSED',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 8.0,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                                color: secondaryTextColor,
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

class _RivetDot extends ConsumerWidget {
  const _RivetDot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(chassisThemeProvider).isDarkMode;
    return Container(
      width: 3.5,
      height: 3.5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF101214) : const Color(0xFFA8A398),
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
