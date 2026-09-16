import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/theme_controller.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/audio/sound_effect.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../domain/focus_analytics_models.dart';
import '../focus_analytics_controller.dart';
import 'focus_bar_chart_widget.dart';

/// Modal dialog presenting Dieter Rams modernist focus analytics & reports.
class FocusAnalyticsDialog extends ConsumerWidget {
  const FocusAnalyticsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      barrierDismissible: true,
      builder: (ctx) => const FocusAnalyticsDialog(),
    );
  }

  String _formatTotalTime(int totalMinutes) {
    if (totalMinutes <= 0) return '0 MIN';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
    if (hours > 0) return '${hours}h';
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(chassisThemeProvider);
    final isDark = themeState.isDarkMode;
    final state = ref.watch(focusAnalyticsControllerProvider);
    final notifier = ref.read(focusAnalyticsControllerProvider.notifier);

    final bgColor = isDark ? TaktColors.basaltSlate : const Color(0xFFEDEAE2);
    final panelBg = isDark ? const Color(0xFF16191D) : const Color(0xFFE2DFD6);
    final borderColor = isDark ? TaktColors.slateBorder : TaktColors.lightChassisBorder;
    final primaryTextColor = isDark ? TaktColors.warmBone : const Color(0xFF141618);
    final secondaryTextColor = isDark ? const Color(0xFF9E9B93) : const Color(0xFF2D3139);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: borderColor, width: 1.0),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FOCUS ANALYTICS',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: primaryTextColor,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('focus_analytics_close_btn'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: secondaryTextColor,
                    ),
                    onPressed: () {
                      HapticService.selectionClick();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Period Segmented Switch (DAY / WEEK / MONTH)
              Container(
                decoration: BoxDecoration(
                  color: panelBg,
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: FocusAnalyticsPeriod.values.map((p) {
                    final isSelected = state.period == p;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ref.read(audioServiceProvider).play(SoundEffect.dialClick);
                          HapticService.selectionClick();
                          notifier.setPeriod(p);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? TaktColors.slateBorder : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4.0),
                            border: isSelected
                                ? Border.all(
                                    color: TaktColors.filamentAmber.withValues(alpha: 0.6),
                                    width: 0.8,
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            p.label,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              letterSpacing: 0.8,
                              color: isSelected ? TaktColors.filamentAmber : secondaryTextColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),

              // Date Navigation Row (< Date Range >)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    key: const ValueKey('focus_nav_prev'),
                    icon: Icon(Icons.chevron_left, size: 20, color: primaryTextColor),
                    onPressed: () {
                      ref.read(audioServiceProvider).play(SoundEffect.dialClick);
                      HapticService.selectionClick();
                      notifier.previousPeriod();
                    },
                  ),
                  GestureDetector(
                    onTap: () {
                      ref.read(audioServiceProvider).play(SoundEffect.dialClick);
                      HapticService.selectionClick();
                      notifier.resetToToday();
                    },
                    child: Text(
                      state.dateRangeLabel,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: primaryTextColor,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('focus_nav_next'),
                    icon: Icon(Icons.chevron_right, size: 20, color: primaryTextColor),
                    onPressed: () {
                      ref.read(audioServiceProvider).play(SoundEffect.dialClick);
                      HapticService.selectionClick();
                      notifier.nextPeriod();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Primary Telemetry Summary Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: panelBg,
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL FOCUS TIME',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8.0,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTotalTime(state.totalMinutes),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 20.0,
                            fontWeight: FontWeight.w800,
                            color: TaktColors.filamentAmber,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'COMPLETION RATE',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8.0,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(state.completionRate * 100).round()}%',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 18.0,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Bar Chart Histogram
              FocusBarChartWidget(
                bars: state.bars,
                isDark: isDark,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                height: 135.0,
              ),
              const SizedBox(height: 12),

              // 4-Card Industrial Metrics Grid
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'TOTAL SESSIONS',
                      value: '${state.totalSessions}',
                      isDark: isDark,
                      panelBg: panelBg,
                      borderColor: borderColor,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(
                      label: 'COMPLETED CYCLES',
                      value: '${state.completedSessions}',
                      isDark: isDark,
                      panelBg: panelBg,
                      borderColor: borderColor,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'DAILY AVERAGE',
                      value: '${state.dailyAverageMinutes.toStringAsFixed(0)} MIN',
                      isDark: isDark,
                      panelBg: panelBg,
                      borderColor: borderColor,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(
                      label: 'BEST FOCUS',
                      value: state.bestDayLabel,
                      isDark: isDark,
                      panelBg: panelBg,
                      borderColor: borderColor,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
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

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color panelBg;
  final Color borderColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.isDark,
    required this.panelBg,
    required this.borderColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13.0,
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
