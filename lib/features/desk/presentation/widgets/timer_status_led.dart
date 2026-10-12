import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/theme_controller.dart';
import '../../../../core/focus/focus_lock_controller.dart';
import '../../../timer/presentation/chrono_dial_controller.dart';

/// The status LED beside the ZYKL wordmark: dark while the timer stands by, filament amber while a focus session
/// runs (or Monastic Lockdown holds the phone), patina green while a break runs.
class TimerStatusLed extends ConsumerWidget {
  const TimerStatusLed({super.key, this.size = 6});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(chronoDialControllerProvider.select((s) => (s.isRunning, s.isBreak)));
    final locked = ref.watch(focusLockProvider.select((s) => s.isLocked));
    final darkChassis = ref.watch(chassisThemeProvider.select((t) => t.hasDarkChassis));
    final running = timer.$1;
    final Color? lit = locked || (running && !timer.$2)
        ? TaktColors.filamentAmber
        : (running ? TaktColors.patinaOlive : null);
    final label = locked
        ? 'Lockdown active'
        : (running ? (timer.$2 ? 'Break running' : 'Focus running') : 'Timer on standby');

    return Semantics(
      label: label,
      child: AnimatedContainer(
        key: const ValueKey('desk_status_led'),
        duration: MediaQuery.maybeDisableAnimationsOf(context) == true
            ? Duration.zero
            : const Duration(milliseconds: 300),
        width: size,
        height: size,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: lit ?? (darkChassis ? const Color(0xFF2B2E34) : const Color(0xFFBBB6AC)),
          boxShadow: lit == null ? null : [BoxShadow(color: lit.withValues(alpha: 0.6), blurRadius: 4)],
        ),
      ),
    );
  }
}
