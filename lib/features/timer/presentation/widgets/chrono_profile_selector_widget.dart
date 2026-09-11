import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/pomodoro_profile.dart';
import '../chrono_dial_controller.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/theme_controller.dart';

/// Horizontal Industrial Cassette Preset Selector for Pomodoro Intervals.
///
/// Mounted directly beneath the Chrono Dial on the 280px modular console grid.
/// Features 4 tactile cassette keys: [ 25/5 CLS ] [ 50/10 MON ] [ 15/3 SPR ] [ CUSTOM ].
/// Micro-LED indicators illuminate the active profile with Braun amber or Patina Olive during breaks.
class ChronoProfileSelectorWidget extends ConsumerWidget {
  const ChronoProfileSelectorWidget({super.key});

  static const List<({PomodoroProfileType type, String label, PomodoroProfile profile})> _segments = [
    (
      type: PomodoroProfileType.classic,
      label: '25/5 CLS',
      profile: PomodoroProfile.classic,
    ),
    (
      type: PomodoroProfileType.monastic,
      label: '50/10 MON',
      profile: PomodoroProfile.monastic,
    ),
    (
      type: PomodoroProfileType.sprint,
      label: '15/3 SPR',
      profile: PomodoroProfile.sprint,
    ),
    (
      type: PomodoroProfileType.custom,
      label: 'CUSTOM',
      profile: PomodoroProfile(
        type: PomodoroProfileType.custom,
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(chronoDialProvider);
    final themeState = ref.watch(chassisThemeProvider);
    final isDark = themeState.isDarkMode;

    final activeColor = timerState.isBreak ? TaktColors.patinaOlive : themeState.filamentColor;
    final inactiveLedColor = isDark ? const Color(0xFF22252A) : const Color(0xFFC0BCB2);

    return Container(
      width: 280,
      height: 38,
      decoration: BoxDecoration(
        color: themeState.moduleChassisColor,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: themeState.borderColor, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < _segments.length; i++) ...[
            if (i > 0)
              Container(
                width: 1.0,
                height: 24,
                color: themeState.borderColor.withValues(alpha: 0.6),
              ),
            Expanded(
              child: _buildSegmentButton(
                context: context,
                ref: ref,
                segment: _segments[i],
                isActive: timerState.profile.type == _segments[i].type,
                isRunning: timerState.isRunning,
                activeColor: activeColor,
                inactiveLedColor: inactiveLedColor,
                themeTextColor: themeState.chassisTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required BuildContext context,
    required WidgetRef ref,
    required ({PomodoroProfileType type, String label, PomodoroProfile profile}) segment,
    required bool isActive,
    required bool isRunning,
    required Color activeColor,
    required Color inactiveLedColor,
    required Color themeTextColor,
  }) {
    final textColor = isActive
        ? activeColor
        : (isRunning ? themeTextColor.withValues(alpha: 0.35) : themeTextColor.withValues(alpha: 0.70));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isRunning
            ? null
            : () {
                if (isActive) return;
                // If switching to custom, preserve existing custom minutes if controller state was already custom
                final currentState = ref.read(chronoDialProvider);
                final targetProfile = (segment.type == PomodoroProfileType.custom &&
                        currentState.profile.type == PomodoroProfileType.custom)
                    ? currentState.profile
                    : segment.profile;
                ref.read(chronoDialProvider.notifier).setProfile(targetProfile);
              },
        borderRadius: BorderRadius.circular(5.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Micro-LED indicator dot
            Container(
              width: 4.5,
              height: 4.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? activeColor : inactiveLedColor,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.65),
                          blurRadius: 3.5,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 3),
            // Segment Monospace Label
            Text(
              segment.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9.0,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
