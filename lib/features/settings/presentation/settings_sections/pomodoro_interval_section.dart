part of '../takt_settings_sheet.dart';

// Pomodoro profile presets and the custom focus/break steppers.

class _PomodoroIntervalEngineSection extends ConsumerWidget {
  final bool isDark;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color panelBgColor;
  final Color borderColor;

  const _PomodoroIntervalEngineSection({
    required this.isDark,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.panelBgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(chronoDialProvider);
    final controller = ref.read(chronoDialProvider.notifier);
    final activeProfile = timerState.profile;
    final customProfile = timerState.customProfile;
    final isRunning = timerState.isRunning;
    final prefsGoal = ref.watch(deskPreferencesControllerProvider.select((p) => p.dailyGoalCycles));
    final autoStart = ref.watch(deskPreferencesControllerProvider.select((p) => p.autoStartNextPhase));
    final dayStart = ref.watch(deskPreferencesControllerProvider.select((p) => p.dayStartHour));
    final weekSunday = ref.watch(deskPreferencesControllerProvider.select((p) => p.weekStartsOnSunday));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'POMODORO INTERVAL ENGINE',
          textColor: secondaryTextColor,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: panelBgColor,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Active profile indicator
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'ACTIVE PROFILE',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: primaryTextColor,
                    ),
                  ),
                  Text(
                    activeProfile.type.label,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: TaktColors.amberText(isDark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Quick preset selector cassette keys
              Row(
                children: [
                  _buildPresetButton(
                    label: '25/5 CLS',
                    type: PomodoroProfileType.classic,
                    isSelected: activeProfile.type == PomodoroProfileType.classic,
                    isRunning: isRunning,
                    onTap: () => controller.setProfile(PomodoroProfile.classic),
                    primaryTextColor: primaryTextColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(width: 6),
                  _buildPresetButton(
                    label: '50/10 MON',
                    type: PomodoroProfileType.monastic,
                    isSelected: activeProfile.type == PomodoroProfileType.monastic,
                    isRunning: isRunning,
                    onTap: () => controller.setProfile(PomodoroProfile.monastic),
                    primaryTextColor: primaryTextColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(width: 6),
                  _buildPresetButton(
                    label: '15/3 SPR',
                    type: PomodoroProfileType.sprint,
                    isSelected: activeProfile.type == PomodoroProfileType.sprint,
                    isRunning: isRunning,
                    onTap: () => controller.setProfile(PomodoroProfile.sprint),
                    primaryTextColor: primaryTextColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(width: 6),
                  _buildPresetButton(
                    label: 'CUSTOM',
                    type: PomodoroProfileType.custom,
                    isSelected: activeProfile.type == PomodoroProfileType.custom,
                    isRunning: isRunning,
                    onTap: () => controller.setProfile(customProfile),
                    primaryTextColor: primaryTextColor,
                    borderColor: borderColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: borderColor.withValues(alpha: 0.5), height: 1),
              const SizedBox(height: 12),

              // Stepper 1: Focus Duration
              _stepperRow(
                isDark: isDark,
                title: 'FOCUS DURATION',
                subtitle: 'Work interval (1 – 90 min)',
                value: '${activeProfile.focusMinutes} MIN',
                valueKey: const ValueKey('custom_focus_value'),
                minusKey: const ValueKey('custom_focus_minus'),
                plusKey: const ValueKey('custom_focus_plus'),
                canDecrement: !isRunning && activeProfile.focusMinutes > 1,
                canIncrement: !isRunning && activeProfile.focusMinutes < 90,
                onDecrement: () => controller.updateCustomDurations(
                  focusMinutes: activeProfile.focusMinutes - 1,
                  activate: true,
                ),
                onIncrement: () => controller.updateCustomDurations(
                  focusMinutes: activeProfile.focusMinutes + 1,
                  activate: true,
                ),
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 10),

              // Stepper 2: Short Break
              _stepperRow(
                isDark: isDark,
                title: 'SHORT BREAK',
                subtitle: 'Cycle rest interval (1 – 30 min)',
                value: '${activeProfile.shortBreakMinutes} MIN',
                valueKey: const ValueKey('custom_short_break_value'),
                minusKey: const ValueKey('custom_short_break_minus'),
                plusKey: const ValueKey('custom_short_break_plus'),
                canDecrement: !isRunning && activeProfile.shortBreakMinutes > 1,
                canIncrement: !isRunning && activeProfile.shortBreakMinutes < 30,
                onDecrement: () => controller.updateCustomDurations(
                  shortBreakMinutes: activeProfile.shortBreakMinutes - 1,
                  activate: true,
                ),
                onIncrement: () => controller.updateCustomDurations(
                  shortBreakMinutes: activeProfile.shortBreakMinutes + 1,
                  activate: true,
                ),
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 10),

              // Stepper 3: Long Break
              _stepperRow(
                isDark: isDark,
                title: 'LONG BREAK',
                subtitle: 'Extended recovery (1 – 45 min)',
                value: '${activeProfile.longBreakMinutes} MIN',
                valueKey: const ValueKey('custom_long_break_value'),
                minusKey: const ValueKey('custom_long_break_minus'),
                plusKey: const ValueKey('custom_long_break_plus'),
                canDecrement: !isRunning && activeProfile.longBreakMinutes > 1,
                canIncrement: !isRunning && activeProfile.longBreakMinutes < 45,
                onDecrement: () => controller.updateCustomDurations(
                  longBreakMinutes: activeProfile.longBreakMinutes - 1,
                  activate: true,
                ),
                onIncrement: () => controller.updateCustomDurations(
                  longBreakMinutes: activeProfile.longBreakMinutes + 1,
                  activate: true,
                ),
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 10),

              // Stepper 4: Cycle Count
              _stepperRow(
                isDark: isDark,
                title: 'CYCLE COUNT',
                subtitle: 'Cycles to long recovery (2 – 8)',
                value: '${activeProfile.longBreakInterval} CYCLES',
                valueKey: const ValueKey('custom_cycle_count_value'),
                minusKey: const ValueKey('custom_cycle_count_minus'),
                plusKey: const ValueKey('custom_cycle_count_plus'),
                canDecrement: !isRunning && activeProfile.longBreakInterval > 2,
                canIncrement: !isRunning && activeProfile.longBreakInterval < 8,
                onDecrement: () => controller.updateCustomDurations(
                  longBreakInterval: activeProfile.longBreakInterval - 1,
                  activate: true,
                ),
                onIncrement: () => controller.updateCustomDurations(
                  longBreakInterval: activeProfile.longBreakInterval + 1,
                  activate: true,
                ),
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 10),

              // Daily goal: drives the desk "TODAY: x / N CYCLES" plate and the
              // analytics goal meter. Editable while a session runs (it is not a
              // timer setting).
              _stepperRow(
                isDark: isDark,
                title: 'DAILY GOAL',
                subtitle: 'Completed cycles per day (1 – 12)',
                value: '$prefsGoal CYCLES',
                valueKey: const ValueKey('daily_goal_value'),
                minusKey: const ValueKey('daily_goal_minus'),
                plusKey: const ValueKey('daily_goal_plus'),
                canDecrement: prefsGoal > DeskPreferencesController.minDailyGoal,
                canIncrement: prefsGoal < DeskPreferencesController.maxDailyGoal,
                onDecrement: () => ref
                    .read(deskPreferencesControllerProvider.notifier)
                    .setDailyGoalCycles(prefsGoal - 1),
                onIncrement: () => ref
                    .read(deskPreferencesControllerProvider.notifier)
                    .setDailyGoalCycles(prefsGoal + 1),
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 10),

              // Day start: stats, streak and analytics roll over at this hour (night owls).
              _stepperRow(
                isDark: isDark,
                title: 'DAY STARTS AT',
                subtitle: 'Focus before this hour counts for the day before',
                value: '${dayStart.toString().padLeft(2, '0')}:00',
                valueKey: const ValueKey('day_start_value'),
                minusKey: const ValueKey('day_start_minus'),
                plusKey: const ValueKey('day_start_plus'),
                canDecrement: dayStart > 0,
                canIncrement: dayStart < DeskPreferencesController.maxDayStartHour,
                onDecrement: () =>
                    ref.read(deskPreferencesControllerProvider.notifier).setDayStartHour(dayStart - 1),
                onIncrement: () =>
                    ref.read(deskPreferencesControllerProvider.notifier).setDayStartHour(dayStart + 1),
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 12),

              _settingSwitchRow(
                title: 'WEEK STARTS ON SUNDAY',
                subtitle: 'Analytics weeks run Sunday to Saturday.',
                value: weekSunday,
                switchKey: const ValueKey('week_starts_sunday_switch'),
                onChanged: (val) => ref.read(deskPreferencesControllerProvider.notifier).setWeekStartsOnSunday(val),
              ),
              const SizedBox(height: 12),

              // Auto-start: the break follows the focus (and the focus the break) without pressing START.
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AUTO-START NEXT PHASE',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'When a phase ends, the next one starts on its own after the chime.',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.0,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    key: const ValueKey('auto_start_next_phase_switch'),
                    value: autoStart,
                    activeThumbColor: TaktColors.filamentAmber,
                    activeTrackColor: TaktColors.filamentAmber.withValues(alpha: 0.5),
                    inactiveThumbColor: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                    inactiveTrackColor: isDark ? TaktColors.slateLight : TaktColors.paperBorder,
                    onChanged: (val) =>
                        ref.read(deskPreferencesControllerProvider.notifier).setAutoStartNextPhase(val),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required Key switchKey,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontFamily: 'monospace', fontSize: 9.0, color: secondaryTextColor),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          key: switchKey,
          value: value,
          activeThumbColor: TaktColors.filamentAmber,
          activeTrackColor: TaktColors.filamentAmber.withValues(alpha: 0.5),
          inactiveThumbColor: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          inactiveTrackColor: isDark ? TaktColors.slateLight : TaktColors.paperBorder,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPresetButton({
    required String label,
    required PomodoroProfileType type,
    required bool isSelected,
    required bool isRunning,
    required VoidCallback onTap,
    required Color primaryTextColor,
    required Color borderColor,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isRunning ? null : onTap,
          borderRadius: BorderRadius.circular(4.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            decoration: BoxDecoration(
              color: isSelected
                  ? TaktColors.filamentAmber.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(
                color: isSelected
                    ? TaktColors.filamentAmber
                    : borderColor.withValues(alpha: 0.5),
                width: isSelected ? 1.2 : 0.8,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 4.0,
                  height: 4.0,
                  margin: const EdgeInsets.only(bottom: 3.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? TaktColors.filamentAmber
                        : borderColor.withValues(alpha: 0.4),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: TaktColors.filamentAmber.withValues(alpha: 0.6),
                              blurRadius: 3.0,
                            ),
                          ]
                        : null,
                  ),
                ),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.5,
                    color: isSelected
                        ? TaktColors.amberText(isDark)
                        : (isRunning
                            ? primaryTextColor.withValues(alpha: 0.35)
                            : primaryTextColor.withValues(alpha: 0.8)),
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

/// Stepper row shared by the settings section and the quick sheets
/// (CUSTOM long-press, desk plate goal).
Widget _stepperRow({
  required bool isDark,
  required String title,
  required String subtitle,
  required String value,
  required Key valueKey,
  required Key minusKey,
  required Key plusKey,
  required bool canDecrement,
  required bool canIncrement,
  required VoidCallback onDecrement,
  required VoidCallback onIncrement,
  required Color primaryTextColor,
  required Color secondaryTextColor,
  required Color borderColor,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 8.5,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            key: minusKey,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            icon: Icon(
              Icons.remove_circle_outline,
              color: canDecrement ? primaryTextColor : borderColor,
              size: 18,
            ),
            onPressed: canDecrement ? onDecrement : null,
          ),
          Container(
            width: 70,
            alignment: Alignment.center,
            child: Text(
              value,
              key: valueKey,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: TaktColors.amberText(isDark),
              ),
            ),
          ),
          IconButton(
            key: plusKey,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            icon: Icon(
              Icons.add_circle_outline,
              color: canIncrement ? primaryTextColor : borderColor,
              size: 18,
            ),
            onPressed: canIncrement ? onIncrement : null,
          ),
        ],
      ),
    ],
  );
}
