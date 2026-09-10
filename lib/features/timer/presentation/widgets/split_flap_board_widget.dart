import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/pomodoro_phase.dart';
import '../chrono_dial_controller.dart';
import 'split_flap_tile.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/theme_controller.dart';

/// 3D Mechanical Split-Flap Board mounted above the Chrono Dial.
/// Displays Pomodoro Phase (FOCUS / SHORT BRK / LONG BRK) and Cycle Count (CYCLE 1/4).
class SplitFlapBoardWidget extends ConsumerWidget {
  const SplitFlapBoardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chronoDialProvider);
    final themeState = ref.watch(chassisThemeProvider);
    final controller = ref.read(chronoDialProvider.notifier);

    final phaseText = _formatPhaseText(state.phase);
    final cycleText = 'CYCLE ${state.cycleCount}/4';

    Color ledColor;
    switch (state.phase) {
      case PomodoroPhase.focus:
        ledColor = TaktColors.filamentAmber;
        break;
      case PomodoroPhase.shortBreak:
        ledColor = TaktColors.patinaOlive;
        break;
      case PomodoroPhase.longBreak:
        ledColor = TaktColors.mutedOchre;
        break;
    }

    return InkWell(
      onTap: state.isRunning ? null : controller.advancePhase,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: themeState.moduleChassisColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: themeState.borderColor, width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x77000000),
              offset: Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Phase Split-Flap Row + Mode LED
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Phase LED Indicator
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ledColor,
                    boxShadow: [
                      BoxShadow(
                        color: ledColor.withValues(alpha: 0.6),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                // Split-Flap characters for phase
                ...phaseText.split('').map((c) => SplitFlapTile(
                      char: c,
                      width: 15,
                      height: 20,
                    )),
              ],
            ),
            const SizedBox(height: 4),
            // Bottom Row: Cycle Split-Flap Row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...cycleText.split('').map((c) => SplitFlapTile(
                      char: c,
                      width: 13,
                      height: 18,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPhaseText(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.focus:
        return '  FOCUS  ';
      case PomodoroPhase.shortBreak:
        return 'SHORT BRK';
      case PomodoroPhase.longBreak:
        return 'LONG  BRK';
    }
  }
}
