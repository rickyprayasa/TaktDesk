import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/pomodoro_phase.dart';
import '../../domain/pomodoro_profile.dart';
import '../chrono_dial_controller.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/theme_controller.dart';

/// Consolidated Horizontal Industrial Control Console for Pomodoro.
///
/// Mounted directly beneath the Chrono Dial on the 280px modular console grid.
/// Combines:
/// 1. Upper Telemetry Row: Phase status with glowing micro-LED (tappable to advance phase),
///    recessed Mechanical MM:SS Counter Display, and cycle count indicator.
/// 2. Hairline Separator.
/// 3. Lower Preset Cassette Row: 4 tactile keys [ 25/5 CLS ] [ 50/10 MON ] [ 15/3 SPR ] [ CUSTOM ].
class ChronoProfileSelectorWidget extends ConsumerWidget {
  final int? remainingMinutes;
  final int? seconds;

  const ChronoProfileSelectorWidget({
    super.key,
    this.remainingMinutes,
    this.seconds,
  });

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
    final textColor = isDark ? const Color(0xFF8A909A) : const Color(0xFF656A72);

    final plaqueText = timerState.setupStage.isActive
        ? timerState.setupStage.telemetryLabel
        : (timerState.isRunning ? 'RUNNING // SEC-ROLL' : 'STANDBY // READY');
    final isCalibrating = timerState.setupStage.isActive;
    final plaqueColor = isCalibrating
        ? TaktColors.filamentAmber
        : (timerState.isRunning ? TaktColors.filamentAmber : textColor);

    Widget plaqueWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121416) : const Color(0xFFDDD8CD),
        borderRadius: BorderRadius.circular(3.0),
        border: Border.all(
          color: isDark ? const Color(0xFF262930) : const Color(0xFFC7C2B4),
          width: 0.8,
        ),
      ),
      child: Text(
        plaqueText,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 8.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: plaqueColor,
        ),
      ),
    );

    if (timerState.setupStage.isActive) {
      plaqueWidget = GestureDetector(
        onTap: () => ref.read(chronoDialProvider.notifier).cancelCalibration(),
        behavior: HitTestBehavior.opaque,
        child: plaqueWidget,
      );
    }

    Color phaseLedColor;
    switch (timerState.phase) {
      case PomodoroPhase.focus:
        phaseLedColor = themeState.filamentColor;
        break;
      case PomodoroPhase.shortBreak:
        phaseLedColor = TaktColors.patinaOlive;
        break;
      case PomodoroPhase.longBreak:
        phaseLedColor = const Color(0xFFC85A32);
        break;
    }

    return Container(
      width: 280,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Upper Telemetry Bar (Phase LED + Label, Status Plaque, 4-Cycle Gauge)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Phase Indicator
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: timerState.isRunning
                          ? null
                          : () => ref.read(chronoDialProvider.notifier).advancePhase(),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF16181B) : const Color(0xFFE4DFD4),
                          borderRadius: BorderRadius.circular(3.5),
                          border: Border.all(
                            color: isDark ? const Color(0xFF262930) : const Color(0xFFCCC7B8),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 4.5,
                              height: 4.5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: phaseLedColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: phaseLedColor.withValues(alpha: 0.65),
                                    blurRadius: 3.5,
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatPhase(timerState.phase),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: phaseLedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Center: Telemetry Status Plaque (Theme-Adaptive Anodized Finish)
                plaqueWidget,
                const SizedBox(width: 4),
                // Right: 4-Cycle Pomodoro Gauge (Cycle Label + Tactile Micro-Pips)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'CYCLE ${timerState.cycleCount}/${timerState.profile.longBreakInterval}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.0,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: themeState.chassisTextColor.withValues(alpha: 0.70),
                          ),
                        ),
                        const SizedBox(width: 4),
                        for (int c = 1; c <= timerState.profile.longBreakInterval; c++) ...[
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.2),
                            width: 5.0,
                            height: 5.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c < timerState.cycleCount
                                  ? activeColor.withValues(alpha: 0.55)
                                  : (c == timerState.cycleCount
                                      ? activeColor
                                      : inactiveLedColor),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF33373E)
                                    : const Color(0xFFB5B0A4),
                                width: 0.6,
                              ),
                              boxShadow: c == timerState.cycleCount
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
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Hairline separator
          Container(
            height: 1.0,
            color: themeState.borderColor.withValues(alpha: 0.5),
          ),
          // 2. Lower Preset Cassette Keys Bar
          SizedBox(
            height: 35,
            child: Row(
              children: [
                for (int i = 0; i < _segments.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 1.0,
                      height: 20,
                      color: themeState.borderColor.withValues(alpha: 0.45),
                    ),
                  Expanded(
                    child: _buildSegmentButton(
                      context: context,
                      ref: ref,
                      segment: _segments[i],
                      isActive: timerState.profile.type == _segments[i].type,
                      isRunning: timerState.isRunning,
                      isDark: isDark,
                      activeColor: activeColor,
                      inactiveLedColor: inactiveLedColor,
                      themeTextColor: themeState.chassisTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPhase(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.focus:
        return 'FOCUS';
      case PomodoroPhase.shortBreak:
        return 'SHORT BRK';
      case PomodoroPhase.longBreak:
        return 'LONG BRK';
    }
  }

  Widget _buildSegmentButton({
    required BuildContext context,
    required WidgetRef ref,
    required ({PomodoroProfileType type, String label, PomodoroProfile profile}) segment,
    required bool isActive,
    required bool isRunning,
    required bool isDark,
    required Color activeColor,
    required Color inactiveLedColor,
    required Color themeTextColor,
  }) {
    final textColor = isActive
        ? activeColor
        : (isRunning ? themeTextColor.withValues(alpha: 0.35) : themeTextColor.withValues(alpha: 0.70));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isRunning
              ? null
              : () {
                  if (isActive) {
                    if (segment.type == PomodoroProfileType.custom) {
                      ref.read(chronoDialProvider.notifier).enterCustomCalibration();
                    }
                    return;
                  }
                  final currentState = ref.read(chronoDialProvider);
                  final targetProfile = (segment.type == PomodoroProfileType.custom)
                      ? currentState.customProfile
                      : segment.profile;
                  ref.read(chronoDialProvider.notifier).setProfile(targetProfile);
                },
          onLongPress: segment.type == PomodoroProfileType.custom
              ? () => ref.read(chronoDialProvider.notifier).enterCustomCalibration()
              : null,
          borderRadius: BorderRadius.circular(4.0),
          child: Container(
            decoration: isActive
                ? BoxDecoration(
                    color: isDark ? const Color(0xFF131518) : const Color(0xFFE2DDD1),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                      color: activeColor.withValues(alpha: isDark ? 0.35 : 0.45),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? const Color(0x66000000) : const Color(0x1A000000),
                        offset: const Offset(0, 1),
                        blurRadius: 2.0,
                        spreadRadius: -0.5,
                      ),
                    ],
                  )
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
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
        ),
      ),
    );
  }
}
