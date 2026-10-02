part of '../takt_settings_sheet.dart';

// Quick-access sheets opened from the desk, so the instrument stays uncluttered
// while the settings stay one gesture away:
//   - long-press CUSTOM on the dial console -> Interval Engine
//   - tap the TODAY tally on the desk plate  -> Daily Goal
// They reuse the exact settings widgets (_PomodoroIntervalEngineSection, _stepperRow).

class _QuickSheetColors {
  final bool isDark;
  final Color bg;
  final Color panel;
  final Color border;
  final Color primary;
  final Color secondary;

  _QuickSheetColors(this.isDark)
      : bg = isDark ? TaktColors.chassisObsidian : const Color(0xFFE3E0D8),
        panel = isDark ? TaktColors.basaltSlate : const Color(0xFFEDEAE2),
        border = isDark ? TaktColors.slateBorder : TaktColors.lightChassisBorder,
        primary = isDark ? TaktColors.warmBone : const Color(0xFF141618),
        secondary = isDark ? const Color(0xFF9E9B93) : const Color(0xFF2D3139);
}

Future<void> _showQuickSheet(
  BuildContext context, {
  required Key key,
  required Widget Function(_QuickSheetColors c) builder,
}) {
  HapticService.selectionClick();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final c = _QuickSheetColors(ref.watch(chassisThemeProvider).isDarkMode);
        return Container(
          key: key,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border(top: BorderSide(color: c.border)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  builder(c),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Interval Engine (presets + custom durations + daily goal), from the console.
Future<void> showIntervalEngineSheet(BuildContext context) => _showQuickSheet(
      context,
      key: const ValueKey('interval_engine_sheet'),
      builder: (c) => _PomodoroIntervalEngineSection(
        isDark: c.isDark,
        primaryTextColor: c.primary,
        secondaryTextColor: c.secondary,
        panelBgColor: c.panel,
        borderColor: c.border,
      ),
    );

/// Daily goal only, from the desk plate's TODAY tally.
Future<void> showDailyGoalSheet(BuildContext context) => _showQuickSheet(
      context,
      key: const ValueKey('daily_goal_sheet'),
      builder: (c) => _DailyGoalPanel(colors: c),
    );

class _DailyGoalPanel extends ConsumerWidget {
  final _QuickSheetColors colors;
  const _DailyGoalPanel({required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = colors;
    final goal = ref.watch(deskPreferencesControllerProvider.select((p) => p.dailyGoalCycles));
    final today = ref.watch(todayFocusStatsProvider).valueOrNull ?? const TodayFocusStats();
    final notifier = ref.read(deskPreferencesControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionHeader(title: 'DAILY FOCUS GOAL', textColor: c.secondary),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _stepperRow(
                isDark: c.isDark,
                title: 'DAILY GOAL',
                subtitle: 'Completed cycles per day (1 – 12)',
                value: '$goal CYCLES',
                valueKey: const ValueKey('sheet_daily_goal_value'),
                minusKey: const ValueKey('sheet_daily_goal_minus'),
                plusKey: const ValueKey('sheet_daily_goal_plus'),
                canDecrement: goal > DeskPreferencesController.minDailyGoal,
                canIncrement: goal < DeskPreferencesController.maxDailyGoal,
                onDecrement: () => notifier.setDailyGoalCycles(goal - 1),
                onIncrement: () => notifier.setDailyGoalCycles(goal + 1),
                primaryTextColor: c.primary,
                secondaryTextColor: c.secondary,
                borderColor: c.border,
              ),
              const SizedBox(height: 10),
              Text(
                'TODAY ${today.completedCount} / $goal CYCLES · ${today.totalMinutes} MIN'
                '${today.streakDays > 0 ? ' · ${today.streakDays}D STREAK' : ''}',
                key: const ValueKey('sheet_daily_goal_today'),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: c.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
