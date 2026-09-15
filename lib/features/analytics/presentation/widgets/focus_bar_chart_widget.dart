import 'package:flutter/material.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../domain/focus_analytics_models.dart';

/// Industrial Dieter Rams-styled histogram presenting focus duration distribution.
class FocusBarChartWidget extends StatelessWidget {
  final List<FocusBarData> bars;
  final bool isDark;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final double height;

  const FocusBarChartWidget({
    super.key,
    required this.bars,
    required this.isDark,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    this.height = 140.0,
  });

  String _formatDuration(int minutes) {
    if (minutes <= 0) return '';
    if (minutes >= 60) {
      final hours = minutes / 60.0;
      return hours % 1 == 0 ? '${hours.toInt()}h' : '${hours.toStringAsFixed(1)}h';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'NO TELEMETRY LOGGED',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: secondaryTextColor,
            ),
          ),
        ),
      );
    }

    int maxVal = 0;
    for (final b in bars) {
      if (b.valueMinutes > maxVal) maxVal = b.valueMinutes;
    }
    if (maxVal == 0) maxVal = 60; // baseline scale 60m

    final trackBg = isDark ? const Color(0xFF1B1E22) : const Color(0xFFDEDACF);
    final trackBorder = isDark ? TaktColors.slateBorder : TaktColors.lightChassisBorder;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14171A) : const Color(0xFFE4E0D6),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: trackBorder, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: bars.map((bar) {
          final factor = (bar.valueMinutes / maxVal).clamp(0.0, 1.0);
          final isAmber = bar.isHighlighted || bar.isToday;

          final fillColor = bar.valueMinutes > 0
              ? (isAmber ? TaktColors.filamentAmber : (isDark ? TaktColors.warmBone : const Color(0xFF4A4D53)))
              : Colors.transparent;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Column(
                children: [
                  // Value label above bar
                  SizedBox(
                    height: 14,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatDuration(bar.valueMinutes),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8.5,
                          fontWeight: bar.isHighlighted ? FontWeight.w800 : FontWeight.w600,
                          color: isAmber ? TaktColors.filamentAmber : secondaryTextColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Vertical pill track
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: trackBg,
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(
                          color: isAmber && bar.valueMinutes > 0
                              ? TaktColors.filamentAmber.withValues(alpha: 0.4)
                              : trackBorder.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      alignment: Alignment.bottomCenter,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: factor),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        builder: (context, val, _) {
                          return FractionallySizedBox(
                            heightFactor: val,
                            widthFactor: 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: fillColor,
                                borderRadius: BorderRadius.circular(3.0),
                                boxShadow: isAmber && bar.valueMinutes > 0
                                    ? [
                                        BoxShadow(
                                          color: TaktColors.filamentAmber.withValues(alpha: 0.35),
                                          blurRadius: 4.0,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Bottom label
                  SizedBox(
                    height: 14,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        bar.label,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8.5,
                          fontWeight: bar.isToday ? FontWeight.w800 : FontWeight.w600,
                          color: bar.isToday
                              ? TaktColors.filamentAmber
                              : (bar.isHighlighted ? primaryTextColor : secondaryTextColor),
                        ),
                      ),
                    ),
                  ),

                  // Today indicator pip
                  Container(
                    width: 3.5,
                    height: 3.5,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bar.isToday ? TaktColors.filamentAmber : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
